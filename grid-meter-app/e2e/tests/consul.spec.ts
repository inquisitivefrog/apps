import { test, expect } from '@playwright/test';
import { UI_SERVICES } from './ui-services';

const consul = UI_SERVICES.find((s) => s.name === 'Consul')!;

// No login step here — see ui-services.ts's credentialsNote: ACLs are disabled
// (confirmed live), so this navigates directly rather than authenticating.
test('Consul UI loads and shows the 3-node cluster membership list', async ({ page }) => {
  await page.goto(`${consul.baseUrl}/ui/dc1/nodes`);
  await expect(page.getByText('3 total')).toBeVisible();

  await expect(page.getByText('consul-1', { exact: true })).toBeVisible();
  await expect(page.getByText('consul-2', { exact: true })).toBeVisible();
  await expect(page.getByText('consul-3', { exact: true })).toBeVisible();

  // Confirms this is actually a live Raft cluster reporting real leadership, not a
  // static/placeholder page.
  await expect(page.getByText('Leader')).toBeVisible();

  await page.screenshot({ path: 'screenshots/consul-nodes.png', fullPage: true });
});
