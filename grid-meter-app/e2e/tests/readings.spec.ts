import { test, expect } from '@playwright/test';
import { loginAsDemoUser, getApiToken } from './helpers';

// Readings are immutable (api-and-data-model.md: no PUT /readings/{id}) — this is the
// frontend half of that same architectural decision, not an arbitrary UI check. The
// dashboard deliberately has no reading-entry affordance at all (architecture.md);
// readings only ever arrive via the API/JMeter.
test('Readings page has no create or edit affordance', async ({ page }) => {
  await loginAsDemoUser(page);
  await page.getByRole('tab', { name: 'Readings' }).click();
  await expect(page).toHaveURL(/\/readings$/);

  await expect(page.getByRole('button', { name: /new|create|add|edit|save/i })).toHaveCount(0);
  await expect(page.getByRole('dialog')).toHaveCount(0);

  // The only input on the page is the Meter ID search filter — nothing to type
  // reading data into.
  await expect(page.getByRole('textbox')).toHaveCount(1);
  await expect(page.getByLabel('Meter ID')).toBeVisible();
});

test.describe('readings search, filter, and pagination', () => {
  // Both tests share one seeded fixture (meterId/readingIds below) — force them onto
  // the same worker so beforeAll seeds exactly once instead of once per worker under
  // fullyParallel, which would otherwise both duplicate the seeding and risk two
  // workers computing the same Date.now() millisecond and colliding on the meters
  // table's unique serial-number constraint.
  test.describe.configure({ mode: 'serial' });

  const READING_COUNT = 12;

  let apiToken: string;
  let meterId: string;
  let readingIds: string[] = [];

  // Fully self-contained: its own E2E--prefixed meter (same pattern as
  // meter-crud.spec.ts) plus a known set of readings, so this spec leaves nothing
  // behind and doesn't depend on run order relative to any other spec.
  test.beforeAll(async ({ request }) => {
    apiToken = await getApiToken(request);

    const stamp = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const meterRes = await request.post('/api/v1/meters', {
      headers: { Authorization: `Bearer ${apiToken}` },
      data: {
        serialNumber: `E2E-${stamp}`,
        location: `E2E Readings Fixture ${stamp}`,
        status: 'ACTIVE',
        installedAt: '2026-01-01T00:00:00Z',
      },
    });
    expect(meterRes.ok()).toBe(true);
    meterId = (await meterRes.json()).id;

    const baseTime = Date.now();
    for (let i = 0; i < READING_COUNT; i++) {
      const res = await request.post('/api/v1/readings', {
        headers: {
          Authorization: `Bearer ${apiToken}`,
          'Idempotency-Key': `e2e-readings-seed-${stamp}-${i}`,
        },
        data: {
          meterId,
          readingTimestamp: new Date(baseTime - i * 60_000).toISOString(),
          value: String(100 + i),
        },
      });
      expect(res.ok()).toBe(true);
      readingIds.push((await res.json()).id);
    }

    // Readings are ingested async via Kafka (POST returns before the consumer writes
    // the row) — poll for the real condition instead of assuming a fixed delay covers
    // it (this project's own standing test-infra lesson, applied here to a Kafka
    // consumer lag instead of an HA failover).
    await expect(async () => {
      const searchRes = await request.get(
        `/api/v1/readings?meterId=${meterId}&size=${READING_COUNT}`,
        { headers: { Authorization: `Bearer ${apiToken}` } },
      );
      const body = await searchRes.json();
      expect(body.totalElements).toBe(READING_COUNT);
    }).toPass({ timeout: 20_000 });
  });

  test.afterAll(async ({ request }) => {
    for (const id of readingIds) {
      await request.delete(`/api/v1/readings/${id}`, {
        headers: { Authorization: `Bearer ${apiToken}` },
      });
    }
    if (meterId) {
      await request.delete(`/api/v1/meters/${meterId}`, {
        headers: { Authorization: `Bearer ${apiToken}` },
      });
    }
  });

  test('search by meter ID shows exactly the seeded readings', async ({ page }) => {
    await loginAsDemoUser(page);
    await page.getByRole('tab', { name: 'Readings' }).click();
    await expect(page).toHaveURL(/\/readings$/);

    await page.getByLabel('Meter ID').fill(meterId);
    await expect(page.getByText(`of ${READING_COUNT}`)).toBeVisible();
    await expect(page.locator('table tbody tr')).toHaveCount(READING_COUNT);
  });

  test('pagination controls advance through the seeded readings', async ({ page }) => {
    await loginAsDemoUser(page);
    await page.getByRole('tab', { name: 'Readings' }).click();
    await expect(page).toHaveURL(/\/readings$/);
    await page.getByLabel('Meter ID').fill(meterId);
    await expect(page.getByText(`of ${READING_COUNT}`)).toBeVisible();

    // Drop to the smallest page size (10) so 12 seeded readings span two pages.
    await page.getByRole('combobox', { name: 'Rows per page:' }).click();
    await page.getByRole('option', { name: '10', exact: true }).click();

    await expect(page.locator('table tbody tr')).toHaveCount(10);
    const nextButton = page.getByRole('button', { name: 'Go to next page' });
    const prevButton = page.getByRole('button', { name: 'Go to previous page' });
    await expect(prevButton).toBeDisabled();
    await expect(nextButton).toBeEnabled();

    await nextButton.click();
    await expect(page.locator('table tbody tr')).toHaveCount(READING_COUNT - 10);
    await expect(nextButton).toBeDisabled();
    await expect(prevButton).toBeEnabled();

    await prevButton.click();
    await expect(page.locator('table tbody tr')).toHaveCount(10);
  });
});
