import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: 'html',
  use: {
    // Traefik's edge on the real deployed stack (docker compose up --build),
    // not the Vite dev server proxy — same PathPrefix(/api) routing production
    // and kind use. No dev-server involved, this always targets the real edge.
    baseURL: 'http://localhost',
    trace: 'on-first-retry',
  },

  // Chromium only for now. Expanding to Firefox/WebKit is a deliberate future
  // decision (Batch/Phase scoping), not an oversight — see status/ for when
  // that decision gets made.
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
