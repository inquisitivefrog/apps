// Persistent-session screenshotter for chaos-demo.sh. Launches one headless Chromium browser and
// keeps TWO pages open for the whole run -- the dashboard and the Grafana Alerting rules list --
// navigating each exactly once, then reusing the already-loaded page for every screenshot request
// instead of a fresh browser+context (or a reload) per shot.
//
// Why this exists, not just `npx playwright screenshot` per call: each fresh anonymous-auth
// session against Grafana (GF_AUTH_ANONYMOUS_ENABLED) was observed costing ~80-170MB server-side
// and never releasing it -- 2-3 fresh-session screenshots in a row reliably OOM-killed Grafana
// regardless of its container memory limit (tried 384m/768m/1024m, all pegged and crashed the
// same way). A single reused session grows far more slowly, but was STILL observed OOM-ing under
// real chaos-demo.sh conditions when calling page.reload() before every shot -- a full reload
// re-bootstraps Grafana's entire frontend and re-initializes a fresh server-side dashboard view
// even within the same browser session. Navigating exactly once and then just re-screenshotting
// the already-loaded, auto-refreshing page (refresh=15s in the URL) plateaus memory instead of
// climbing -- verified: 11 no-reload shots held stable at ~417MB. See
// status/claude_code_2026-08-24.md for the full investigation.
//
// The alerting page's rule group is collapsed by default and has no URL query param to force it
// open, so this clicks the group's disclosure chevron once at startup -- also verified working via
// a throwaway diagnostic script before landing here (coordinate-based, since getByText matched the
// wrong element in the group hierarchy).
//
// Protocol: reads one line per screenshot request on stdin, formatted "TYPE|path" where TYPE is
// "dashboard" or "alerts". Screenshots the requested page's current state to that path and prints
// "DONE:<path>" on stdout as an ack, or "FAILED:<path>: <message>" on error. GRAFANA_URL and
// ALERTING_URL must be set in the environment. Not meant to be run directly -- chaos-demo.sh
// manages its lifecycle via a FIFO.
const { chromium } = require('playwright');
const readline = require('readline');

const dashboardUrl = process.env.GRAFANA_URL;
const alertingUrl = process.env.ALERTING_URL;
if (!dashboardUrl || !alertingUrl) {
  console.error('GRAFANA_URL and ALERTING_URL must both be set');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1600, height: 1400 } });

  const dashboardPage = await context.newPage();
  await dashboardPage.goto(dashboardUrl, { waitUntil: 'load' });
  await dashboardPage.waitForTimeout(2000);

  const alertsPage = await context.newPage();
  await alertsPage.goto(alertingUrl, { waitUntil: 'load' });
  await alertsPage.waitForTimeout(2000);
  // Expand the "grid-meter-alerts" rule group so individual rule states are visible, not just the
  // collapsed group row. Coordinates match this page's fixed layout (Alert rules list, "Grouped"
  // view, first custom folder) -- re-verify if Grafana's alerting UI layout changes.
  await alertsPage.mouse.click(647, 396);
  await alertsPage.waitForTimeout(1000);

  const pages = { dashboard: dashboardPage, alerts: alertsPage };

  const rl = readline.createInterface({ input: process.stdin });
  for await (const line of rl) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const [type, outputPath] = trimmed.split('|');
    const page = pages[type];
    if (!page || !outputPath) {
      console.error(`FAILED:${outputPath || trimmed}: unknown type "${type}", expected "dashboard" or "alerts"`);
      continue;
    }
    try {
      await page.waitForTimeout(4000);
      await page.screenshot({ path: outputPath, fullPage: true });
      console.log(`DONE:${outputPath}`);
    } catch (err) {
      console.error(`FAILED:${outputPath}: ${err.message}`);
    }
  }
  await browser.close();
})();
