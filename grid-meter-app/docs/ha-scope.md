# grid-meter-app — High-availability scope (data tier)

## Why this doc exists

Chaos testing (`load-tests/chaos-demo.sh`) validated the single-instance
failure case for each data-tier layer: kill the one instance, confirm an
alert fires. That's a real and useful test, but it only proves "we notice
when the only copy of something dies" — it says nothing about actual fault
tolerance, since there was never a second instance to fail over to. This
doc records the decision to move part of the data tier toward genuine
multi-node redundancy, why it's scoped to Kafka first rather than all
three layers at once, and the quorum reasoning behind "3, not 2" — the
same "decision, not oversight" framing already used for the api-only
autoscaling boundary in `autoscaling-scope.md` and the Terraform/k8s
scoping in `k8s-terraform-decisions-2026-08-19.md`.

This is also a deliberate shift in *what the project demonstrates*: the
single-instance setup demonstrated observability (notice and diagnose a
failure). Multi-node redundancy demonstrates a different, equally real
skill set — designing for fault tolerance, reasoning about quorum and
split-brain risk, and testing planned-maintenance and partial-failure
scenarios the way a production on-call engineer actually encounters them.

## Decision: this pass scopes to Kafka only

Kafka moves from single-broker KRaft to a real multi-broker cluster with
replication. Redis (via Sentinel) and PostgreSQL (via Patroni or
equivalent) are **explicitly deferred**, not silently dropped — see
"Deferred layers" below for what each would require and what triggers
revisiting them.

**Why Kafka first:**

- Multi-broker replication and leader election are native, built-in Kafka
  capabilities in KRaft mode — no extra coordination tooling needed, just
  additional broker processes with distinct node IDs and a replication
  factor above the current `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1`.
  Already flagged as a single point of failure in `autoscaling-scope.md`.
- Highest ratio of real fault-tolerance payoff to implementation
  complexity of the three layers.
- Produces a genuinely different, well-scoped test suite (below) without
  first having to make a call on Postgres's much harder automatic-failover
  question.

## Quorum mechanics: why 3, not 2

"Two instances" and "three instances" are not points on the same line —
they mean structurally different things for anything that does leader
election (Kafka controller quorum, Patroni + etcd/Consul, Redis Sentinel).

- Majority = `floor(N/2) + 1`. For `N=3`, majority is 2.
- A 3-node cluster tolerates **one** node loss — planned or unplanned —
  and still holds a working majority (2 of 3). This is what makes a single
  maintenance window ("take one node offline to patch/migrate/upgrade")
  safe by construction.
- The real danger is a **second, independent loss while already down to
  2** — at that point the cluster is at 1 of 3, below majority, and can no
  longer safely elect a leader or accept writes without risking split
  brain. This is exactly the "maintenance window guaranteed not to impact
  production" scenario that broke in practice when an unrelated failure
  (an upstream router reboot, an unplanned host migration issue) landed
  concurrently. The maintenance itself wasn't the problem — the *overlap*
  with a second, unrelated failure was.
- Two instances gives you data replication (a copy exists elsewhere) but
  not safe automatic failover — with no tiebreaker, two nodes disagreeing
  about who's primary has no majority to resolve it, which is why the
  smallest safe quorum-capable size is 3, not 2.
- DR (a fully separate, independently-operated environment) is a real
  mitigation for exactly this compounding-failure scenario, but it's only
  as strong as its least-adopted component — a technology that hasn't
  wired up DR support yet reintroduces the single-point-of-failure risk
  underneath an otherwise-redundant surface. Worth stating as an explicit
  caveat when DR gets discussed for this project, not assumed as a
  blanket guarantee once "DR" is checked off.

## Deferred layers (not built this pass, for reference)

- **Redis, via Sentinel**: primary + replica + Sentinel processes
  (typically 3 Sentinels, lightweight, ~16–32MB each) gives real automatic
  failover. Standard, well-documented pattern — a moderate step up from
  Kafka, not a hard one. Revisit once Kafka's multi-broker pass is
  validated.
- **PostgreSQL, via Patroni**: a primary + streaming replica alone gives
  data redundancy but *not* automatic failover — the app's connection
  string still points at one instance. Real automatic failover needs a
  coordinator (Patroni) backed by an external consensus store. Patroni's
  own documentation supports etcd, Consul, or ZooKeeper interchangeably
  for this — Consul is a fully legitimate choice here, not a fallback,
  and directly reuses prior Consul-with-Docker experience rather than
  requiring etcd learned from scratch. This is the hard layer regardless
  of consensus-store choice: single-primary architecture (unlike
  Redis/Kafka's more flexible multi-writer-capable models), a real
  operational dependency on the consensus store's own health, and the
  biggest resource line-item of the three. Scope this as its own decision
  doc when it comes up — don't fold it into "the data tier" as if it were
  the same size of change as Kafka or Redis.
  - **Lighter alternatives to Patroni**, worth knowing about before
    committing to the Patroni+consensus-store path: `repmgr` (more
    manual, no external consensus store, less automatic — a smaller step
    up from plain streaming replication) and `pg_auto_failover`
    (Citus/Microsoft's tool, uses a built-in monitor node instead of an
    external consensus store — simpler operationally, still automatic).
    Neither reuses the Consul experience the way Patroni+Consul does, but
    both are real options if Patroni's operational weight turns out to be
    more than this project wants to take on.
  - **ZooKeeper does not re-enter the picture here** even though it's a
    valid Patroni backend in general — this project's Kafka already moved
    to KRaft specifically to avoid running a separate ZooKeeper JVM (see
    `architecture.md`'s resource budget notes), and reintroducing it for
    Postgres would undo that reasoning for a different layer. Prior
    ZooKeeper+Cassandra/Spark experience is the right mental model for
    consensus-store-backed coordination in general; it doesn't map onto a
    new tool to install here.

## Edge and observability tier HA — explicitly out of scope

Raised during scoping and worth recording as a deliberate boundary, the
same way `architecture.md` marks Terraform out of scope rather than
leaving it a vague "maybe someday": none of Traefik, Prometheus,
Loki/Tempo, or Alloy are candidates for HA work in this project, and each
has a different reason.

- **Traefik**: stateless, so running multiple instances is simple in
  principle — but it recreates the exact "who load-balances the load
  balancer" problem a redundant HAProxy pair would have. The standard
  on-prem answer is **keepalived implementing VRRP** (Virtual Router
  Redundancy Protocol): primary and secondary exchange heartbeats over
  multicast, and whichever is master claims a shared virtual IP that
  clients actually connect to, so a failover needs no client
  reconfiguration. This has no natural home in a laptop Compose setup —
  there's no floating-IP mechanism to put in front of it — so Traefik
  redundancy is left out of scope here, matching the same call most teams
  make about "do I really need 2 HAProxies" in an equivalently small
  environment. Worth revisiting only if this project ever gets a real
  externally-reachable, multi-host deployment target (same trigger
  condition already used for Terraform and TLS in `identity.md`).
- **Prometheus**: no built-in clustering in the open-source core. Real HA
  means either two fully independent instances scraping the same targets
  (simple, but no gap-filling if one is down) or adopting Thanos, Cortex,
  or Mimir for genuine federated HA plus long-term storage — a
  substantial, separate project in its own right, not a config change.
- **Loki / Tempo**: both support a "microservices mode" for horizontal
  scaling and HA, but it requires switching off local filesystem storage
  onto an object store (S3/GCS/MinIO) and splitting each into several
  independently-scalable components — a real architecture change, not a
  tuning knob.
- **Alloy**: not an HA candidate in the same sense as the others — it's a
  per-host log/metrics collection agent, conceptually closer to "one
  instance per node" than "a cluster to make redundant."

Given that spread, the payoff-to-cost ratio for any of these is low
relative to the data-tier work above, and none is revisited unless the
project's deployment surface itself changes (see the Traefik trigger
condition, which applies equally to the rest of this list).

## Resource budget

Docker Desktop's VM (not the 24GB host) is the real ceiling: **7.748 GiB
total**. Current per-container limits across all 11 services sum to
roughly 3.97 GiB with `api` at 1 replica; actual measured usage is closer
to 1.94 GiB. That leaves real headroom for a 3-broker Kafka expansion
without touching the VM allocation.

A full 3× expansion of all three data-tier layers (Kafka, Redis+Sentinel,
Postgres+Patroni+etcd/Consul) was estimated at ~8.2–8.9 GiB total,
exceeding the current VM ceiling regardless of which Postgres option is
chosen — meaning that scenario would require raising the Docker Desktop
VM allocation (e.g. to 12–16 GiB), a one-time, low-risk host setting
change, not a hard constraint. Not needed for this pass's Kafka-only
scope, but worth keeping in mind for when Redis/Postgres get scoped.

## HikariCP connection-timeout: reframed, not settled

The 5-second `spring.datasource.hikari.connection-timeout` (shortened
from Spring Boot's undeclared 30s default during the chaos-testing
investigation) should be understood as a demo-scoped value tied to a
specific goal — making a fast, alert-worthy failure signal — not a
production-validated number.

The right value is a function of two things this project doesn't have
real numbers for yet: callers' acceptable latency, and the infrastructure's
actual recovery time (RTO). Once Postgres has real automatic failover
(Patroni), that failover typically completes in single-digit seconds, and
a short client-side timeout becomes well-matched: fail fast enough to
retry while the infrastructure is already recovering on its own. Without
real HA, a longer timeout is arguably *more* defensible — a slow-but-
eventually-successful request during a human-driven manual recovery beats
a hard failure that arrives before any recovery could plausibly finish
anyway.

**Action:** leave at 5s for now (it correctly serves this pass's chaos/
alerting demo goals), but re-measure and re-tune once Postgres HA exists
and a real failover RTO can be measured, rather than treating 5s as a
final production-tuned value.

**Note (2026-08-27):** a bounded-retry + circuit-breaker pattern
(Resilience4j — see the queued `docs/resilience-scope.md`) is actually a
more direct fix than waiting on Patroni here. The circuit breaker's open
state *is* the fail-fast behavior this section is reaching for — it stops
calling a failing dependency after a few failures rather than letting
every request pay the full connection-timeout cost, independent of
whether real Postgres failover exists yet. The Hikari timeout value and
the circuit breaker are complementary, not either/or: Hikari bounds how
long any single connection attempt can hang; the breaker bounds how many
attempts get made at all once failures start piling up.

## Revisit triggers

- **Redis**: revisit once Kafka's multi-broker pass is built, tested, and
  its own status log closed out.
- **Postgres**: revisit as its own explicit scope decision — not bundled
  automatically with Redis — given Patroni's materially higher
  operational complexity and resource cost.
- **VM allocation bump**: only needed once Redis and/or Postgres HA scope
  is actually decided; not required for the Kafka-only pass this doc
  covers.
- **Note (2026-08-27)**: the "revisit only if a real externally-reachable
  deployment target is added" trigger named in this doc's edge/
  observability-tier section has since fired — see
  `docs/cloud-deployment-scope.md`. That doc adds a second, cloud-based
  deployment track (managed Postgres/Redis, self-hosted Kafka, per
  provider) but does not change any decision in *this* doc — the local
  track's Kafka-first, self-hosted, Redis/Postgres-deferred scope stands
  independently, per that doc's own "Two tracks" framing.
