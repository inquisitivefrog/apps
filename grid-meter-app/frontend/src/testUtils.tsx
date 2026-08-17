import { QueryClient } from '@tanstack/react-query';

// Shared by page-level component tests: a fresh, no-retry QueryClient per test so a
// mocked API rejection resolves (and gets asserted on) immediately instead of retrying.
export function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
    },
  });
}
