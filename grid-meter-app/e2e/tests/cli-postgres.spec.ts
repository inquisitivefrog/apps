import { test, expect } from '@playwright/test';
import { dockerComposeExec } from './cli-helpers';

interface PatroniMember {
  Member: string;
  Host: string;
  Role: string;
}

// patroni-1 is just used as a shell here (its own psql/patronictl clients) — patronictl
// queries cluster-wide state regardless of which node happens to be leader right now,
// so this works whether or not patroni-1 itself is the current leader.
test('PostgreSQL: reaches the primary through Traefik, and pg_is_in_recovery() distinguishes primary from replica', async () => {
  const { stdout: listJson } = await dockerComposeExec(
    'patroni-1',
    'patronictl',
    '-c',
    '/etc/patroni.yml',
    'list',
    '-f',
    'json',
  );
  const members: PatroniMember[] = JSON.parse(listJson);
  const leader = members.find((m) => m.Role === 'Leader');
  const replica = members.find((m) => m.Role !== 'Leader');
  expect(leader, 'a Leader should be reported').toBeTruthy();
  expect(replica, 'a non-Leader replica should be reported').toBeTruthy();

  // Through Traefik's :55432 HA entrypoint — routes to whichever node is currently
  // primary. Addressed via Traefik's internal DNS name from an already-running
  // container rather than the host-published port, to avoid a throwaway image pull;
  // host-reachability of :55432 itself was separately confirmed live (see cli-services.ts).
  const { stdout: selectOneOut } = await dockerComposeExec(
    'patroni-1',
    'psql',
    'postgresql://gridmeter:gridmeter@traefik:55432/gridmeter',
    '-t',
    '-c',
    'SELECT 1;',
  );
  expect(selectOneOut.trim()).toBe('1');

  const { stdout: primaryRecoveryOut } = await dockerComposeExec(
    'patroni-1',
    'psql',
    'postgresql://gridmeter:gridmeter@traefik:55432/gridmeter',
    '-t',
    '-c',
    'SELECT pg_is_in_recovery();',
  );
  expect(primaryRecoveryOut.trim()).toBe('f');

  // Direct to the live-discovered replica (not through Traefik, which only ever
  // routes to the primary) — confirms the same function actually reports the other
  // role too, not just that the primary check happens to say "f".
  const { stdout: replicaRecoveryOut } = await dockerComposeExec(
    'patroni-1',
    'psql',
    `postgresql://gridmeter:gridmeter@${replica!.Host}:5432/gridmeter`,
    '-t',
    '-c',
    'SELECT pg_is_in_recovery();',
  );
  expect(replicaRecoveryOut.trim()).toBe('t');
});
