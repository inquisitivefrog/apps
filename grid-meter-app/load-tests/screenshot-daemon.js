// Persistent-session dashboard screenshotter for chaos-demo.sh. Launches one headless Chromium
// session and navigates to the dashboard exactly once, then reuses that same already-loaded page
// for every screenshot request -- no reload, no fresh browser+context per shot.
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
// Protocol: reads one absolute output path per line on stdin, waits for the dashboard's own
// refresh=15s auto-refresh to pick up a fresh tick, screenshots the current page state to that
// path, and prints "DONE:<path>" on stdout as an ack. GRAFANA_URL must be set in the environment.
// Not meant to be run directly -- chaos-demo.sh manages its lifecycle via a FIFO.
const { chromium } = require('playwright');
const readline = require('readline');

const url = process.env.GRAFANA_URL;
if (!url) {
  console.error('GRAFANA_URL not set');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1600, height: 1400 } });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(2000);

  const rl = readline.createInterface({ input: process.stdin });
  for await (const line of rl) {
    const outputPath = line.trim();
    if (!outputPath) continue;
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
