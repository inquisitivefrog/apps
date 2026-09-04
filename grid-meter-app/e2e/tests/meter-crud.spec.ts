import { test, expect } from '@playwright/test';
import { loginAsDemoUser, getApiToken } from './helpers';

test.describe('meter create, edit, and cleanup journey', () => {
  let createdMeterId: string | undefined;
  let apiToken: string;

  test.beforeAll(async ({ request }) => {
    apiToken = await getApiToken(request);
  });

  // API-level cleanup regardless of where the test finished — avoids accumulating
  // E2E- junk meters in the shared dev database across runs.
  test.afterEach(async ({ request }) => {
    if (createdMeterId) {
      await request.delete(`/api/v1/meters/${createdMeterId}`, {
        headers: { Authorization: `Bearer ${apiToken}` },
      });
      createdMeterId = undefined;
    }
  });

  test('create an E2E-prefixed meter, find it in search, edit it, verify the edit persisted', async ({
    page,
  }) => {
    await loginAsDemoUser(page);

    const stamp = Date.now();
    const serialNumber = `E2E-${stamp}`;
    const location = `E2E Test Site ${stamp}`;

    await page.getByRole('button', { name: 'New Meter' }).click();
    const dialog = page.getByRole('dialog');
    await dialog.getByLabel('Serial Number').fill(serialNumber);
    await dialog.getByLabel('Location').fill(location);
    await dialog.getByLabel('Installed At').fill('2026-01-01');
    await dialog.getByRole('button', { name: 'Create' }).click();
    await expect(dialog).toBeHidden();

    // Filter by the unique location so the new meter is the only search result.
    await page.getByLabel('Location').fill(location);
    const cell = page.getByRole('cell', { name: serialNumber });
    await expect(cell).toBeVisible();

    await cell.click();
    await expect(page).toHaveURL(/\/meters\/[0-9a-f-]+$/);
    createdMeterId = page.url().split('/meters/')[1];
    // The URL updates before the route swap finishes rendering — wait for a
    // MeterDetailPage-specific element, not just the URL, or this can still hit
    // MetersPage's stale, about-to-unmount Location filter instead of the real field.
    await expect(page.getByRole('button', { name: 'Save' })).toBeVisible();

    const editedLocation = `${location} EDITED`;
    await page.getByLabel('Location').fill(editedLocation);
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page).toHaveURL(/\/meters$/);

    // Re-open the meter via a real client-side navigation (search + click), not
    // page.goto — a hard reload wipes the in-memory-only auth token by design
    // (see identity.md/architecture.md), which would just bounce us to /login.
    await page.getByLabel('Location').fill(editedLocation);
    const editedCell = page.getByRole('cell', { name: serialNumber });
    await expect(editedCell).toBeVisible();
    await editedCell.click();
    await expect(page).toHaveURL(new RegExp(`/meters/${createdMeterId}$`));
    await expect(page.getByRole('button', { name: 'Save' })).toBeVisible();
    await expect(page.getByLabel('Location')).toHaveValue(editedLocation);
  });
});
