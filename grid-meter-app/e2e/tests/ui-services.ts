// Fixture describing the observability-tier UIs Phase 2b tests, one entry per service.
// Keeping this as data (not just inlined URLs in each spec) is deliberate: the point
// isn't just "make the test pass," it's recording *why* each service's auth story is
// what it is, so that story stays legible on its own rather than living only in a
// git-blame comment someone has to go dig up later.
export interface UiService {
  name: string;
  baseUrl: string;
  credentials: null;
  credentialsNote: string;
  purpose: string;
}

export const UI_SERVICES: UiService[] = [
  {
    name: 'Grafana',
    baseUrl: 'http://localhost:3001',
    credentials: null,
    credentialsNote:
      'No login required. GF_AUTH_ANONYMOUS_ENABLED=true + GF_AUTH_ANONYMOUS_ORG_ROLE=Admin ' +
      '(docker-compose.yml) grants anonymous Admin access. Confirmed live against the running ' +
      "container's env, not just the compose file. Deliberate dev-only convenience for a stack " +
      'nobody outside this machine can reach — not representative of a production posture.',
    purpose: 'Dashboards — metrics/logs/traces + alerting.',
  },
  {
    name: 'Consul',
    baseUrl: 'http://localhost:8500',
    credentials: null,
    credentialsNote:
      "No login required. ACLs are disabled (Consul's default) — confirmed live against " +
      '/v1/agent/self (ACLDatacenter unset), not just the absence of an acl{} block in the ' +
      'compose file or patroni/ config. UI port only exposed on consul-1 (one node is enough ' +
      "to see cluster-wide membership); wasn't reachable from the host at all until this port " +
      'mapping was added.',
    purpose: 'Status/config — DCS cluster membership, KV store, leader lock for Patroni.',
  },
];
