import type { APIRequestContext, Page } from '@playwright/test';

// Seeded demo user (V3__create_users_table.sql) — same convention the backend's own
// component/API tests use (see CLAUDE.md). No separate E2E user for this phase.
export const DEMO_USERNAME = 'demo';
export const DEMO_PASSWORD = 'GridMeter!Demo2026';

export async function loginAsDemoUser(page: Page): Promise<void> {
  await page.goto('/login');
  await page.getByLabel('Username').fill(DEMO_USERNAME);
  await page.getByLabel('Password').fill(DEMO_PASSWORD);
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForURL(/\/meters$/);
}

// For API-level fixture cleanup (afterEach/afterAll) — independent of whatever
// session state the UI login above leaves behind.
export async function getApiToken(request: APIRequestContext): Promise<string> {
  const response = await request.post('/api/v1/auth/login', {
    data: { username: DEMO_USERNAME, password: DEMO_PASSWORD },
  });
  const body = await response.json();
  return body.accessToken as string;
}
