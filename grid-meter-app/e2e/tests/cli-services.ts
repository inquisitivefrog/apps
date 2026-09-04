// Fixture describing the CLI-reachable data/DCS services Phase 2c tests, one entry per
// service — same shape and same reasoning as ui-services.ts: recording *why* each
// service's access story is what it is, live-verified rather than assumed, so that
// story stays legible without having to re-derive it from docker-compose.yml later.
export interface CliService {
  name: string;
  accessMethod: 'host-direct' | 'docker-exec';
  execCommand: string;
  authMethod: string;
  purpose: string;
}

export const CLI_SERVICES: CliService[] = [
  {
    name: 'Redis',
    accessMethod: 'docker-exec',
    execCommand: "redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster, then redis-cli -h <discovered> PING",
    authMethod:
      'None. `requirepass` is empty on both the primary and a replica — confirmed live via ' +
      'CONFIG GET requirepass against the running containers, not just the absence of a ' +
      'password in docker-compose.yml. No host port is published for Redis or any Sentinel ' +
      'either (confirmed live: nothing listening on 6379 on the host) — exec is the only ' +
      'option, not a stylistic choice.',
    purpose:
      'Performance — latest-reading cache. The check discovers the primary via Sentinel ' +
      "rather than PINGing a static host, since that's the actual post-HA-cutover access " +
      'pattern the app itself uses (docs/redis-ha-scope.md Stage 6), not a shortcut around it.',
  },
  {
    name: 'PostgreSQL',
    accessMethod: 'host-direct',
    execCommand: 'psql postgresql://gridmeter:gridmeter@localhost:55432/gridmeter',
    authMethod:
      'Password (gridmeter/gridmeter, dev-only hardcoded per docker-compose.yml). ' +
      "Host-reachable via Traefik's :55432 entrypoint — confirmed live (a direct connection " +
      "from the host succeeded and returned pg_is_in_recovery()=f) and against the live " +
      'compose file / patroni.yml, not assumed still-current from older docs. The spec itself ' +
      "connects via an already-running container's psql client addressing Traefik's internal " +
      'DNS name instead of a throwaway image pull — same entrypoint, faster in CI.',
    purpose:
      'Status/config — system of record. The check also connects directly to a live-discovered ' +
      'replica (not through Traefik, which only ever routes to the primary) to confirm ' +
      'pg_is_in_recovery() actually distinguishes the two roles, since this is an HA cluster, ' +
      'not just a database.',
  },
  {
    name: 'Kafka',
    accessMethod: 'docker-exec',
    execCommand: 'kafka-topics.sh --bootstrap-server kafka-1:9092 --list',
    authMethod:
      'None (PLAINTEXT listener, no SASL). The bootstrap port is not published to the host at ' +
      'all — confirmed live (nothing listening on 9092 on the host) and in docker-compose.yml ' +
      '(no ports: block on any kafka-* service, advertised listener only uses the internal ' +
      'kafka-N Docker DNS name) — exec into a broker container is the only option.',
    purpose: 'Status/config — async ingest event bus for reading submissions.',
  },
  {
    name: 'Consul',
    accessMethod: 'docker-exec',
    execCommand: 'consul members, and consul operator raft list-peers for leader status',
    authMethod:
      'None — ACLs are disabled (Consul default; confirmed live in Phase 2b against ' +
      '/v1/agent/self, ACLDatacenter unset). Deliberately separate from Phase 2b\'s UI check ' +
      '(which uses the host-published :8500 HTTP API) — this exercises the consul CLI binary ' +
      'itself via docker exec, matching how you\'d actually inspect a DCS backend\'s cluster ' +
      'membership in practice rather than through a browser.',
    purpose: 'Status/config — DCS cluster membership, KV store, leader lock for Patroni.',
  },
];
