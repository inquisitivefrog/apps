import { test, expect } from '@playwright/test';
import { loginAsDemoUser } from './helpers';

test('login lands on the Meters page, logout returns to the login page', async ({ page }) => {
  await loginAsDemoUser(page);
  await expect(page.getByRole('button', { name: 'New Meter' })).toBeVisible();

  await page.getByRole('button', { name: 'Log out' }).click();
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByLabel('Username')).toBeVisible();
});
