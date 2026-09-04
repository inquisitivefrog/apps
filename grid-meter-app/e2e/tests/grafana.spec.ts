import { test, expect } from '@playwright/test';
import { UI_SERVICES } from './ui-services';

const grafana = UI_SERVICES.find((s) => s.name === 'Grafana')!;

// No login step here — see ui-services.ts's credentialsNote: anonymous Admin access is
// deliberate config, not an oversight, so this navigates directly rather than logging in.
test('Grafana dashboard loads and renders live data', async ({ page }) => {
  await page.goto(`${grafana.baseUrl}/grafana/d/grid-meter-overview/grid-meter-api-overview`);
  await expect(page.getByText('Grid Meter API — Overview')).toBeVisible();

  // The chart itself renders to <canvas> (uPlot) — its axis labels aren't real DOM text
  // Playwright can read, so scraping a byte value off it isn't viable. Instead: confirm
  // the panel actually mounted a sized chart (not a collapsed/errored panel), and rely on
  // Grafana's own "No data" indicator — which it explicitly renders whenever a query
  // returns empty — as the honest, literal "this panel has non-zero data" signal, since
  // JVM heap used is always > 0 while the API is running regardless of app traffic.
  const heapPanel = page
    .getByText('JVM heap used', { exact: true })
    .locator('xpath=ancestor::*[contains(@class, "panel-container")][1]');
  await expect(heapPanel).toBeVisible();
  await expect(heapPanel.locator('canvas')).toBeVisible();
  await expect(page.getByText('No data')).toHaveCount(0);

  await page.screenshot({ path: 'screenshots/grafana-dashboard.png', fullPage: true });
});
