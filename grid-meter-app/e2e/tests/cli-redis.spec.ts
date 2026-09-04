import { test, expect } from '@playwright/test';
import { dockerComposeExec } from './cli-helpers';

// Discover the current primary via Sentinel rather than PINGing a static host — see
// cli-services.ts for why this is the more representative post-HA-cutover check.
test('Redis: Sentinel discovers the primary, which responds to PING', async () => {
  const { stdout: masterAddr } = await dockerComposeExec(
    'sentinel-1',
    'redis-cli',
    '-p',
    '26379',
    'SENTINEL',
    'get-master-addr-by-name',
    'mymaster',
  );
  const [host, port] = masterAddr.trim().split('\n');
  expect(host, 'Sentinel should return a master host').toBeTruthy();
  expect(port, 'Sentinel should return a master port').toBeTruthy();

  const { stdout: pingResult } = await dockerComposeExec(
    'sentinel-1',
    'redis-cli',
    '-h',
    host,
    '-p',
    port,
    'PING',
  );
  expect(pingResult.trim()).toBe('PONG');
});
