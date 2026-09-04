import { test, expect } from '@playwright/test';
import { dockerComposeExec } from './cli-helpers';

// Separate from Phase 2b's UI-based check (grafana.spec.ts / consul.spec.ts) — this
// exercises the consul CLI binary itself via docker exec, confirming the same 3-node
// cluster the UI spec screenshotted, but through the tool an operator would actually
// reach for at a terminal.
test('Consul: consul members and consul operator raft list-peers confirm 3 healthy nodes and a leader', async () => {
  const { stdout: membersOut } = await dockerComposeExec('consul-1', 'consul', 'members');
  const memberLines = membersOut
    .trim()
    .split('\n')
    .slice(1) // drop the header row
    .filter(Boolean);
  expect(memberLines).toHaveLength(3);
  for (const line of memberLines) {
    expect(line).toContain('alive');
  }

  const { stdout: raftOut } = await dockerComposeExec(
    'consul-1',
    'consul',
    'operator',
    'raft',
    'list-peers',
  );
  const leaderLines = raftOut
    .trim()
    .split('\n')
    .filter((line) => line.includes('leader'));
  expect(leaderLines).toHaveLength(1);
});
