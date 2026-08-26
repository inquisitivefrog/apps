# grid-meter-app — Autoscaling scope

## Why this doc exists

This project wasn't originally designed with autoscaling as a goal — the emphasis was on
monitoring and demonstrating the ability to read a dashboard, respond to real alerts, and debug
failures (see `docs/architecture.md`'s Observability section, and the Grafana dashboard +
alerting work in `observability/`). Traffic spikes are common enough in practice, though, that at
least one real autoscaling example is worth having. This doc records why that example is scoped
to the `api` layer only, and what would actually be involved in extending it — so the boundary
reads as a decision, not an oversight.

## Decision: autoscaling tests target `api` only

`api` is the **only** component in this architecture designed to be stateless and interchangeable.
Any Tomcat replica can answer any request — Traefik's Docker provider auto-discovers replicas and
round-robins across them with no coordination needed between instances. Adding a second `api`
container is safe by construction: `docker compose up -d --scale api=2` (or a real k8s HPA) just
works, because there's no shared mutable state living inside the `api` process itself.

Postgres, Kafka, and Redis are excluded not because scaling them is "more configuration," but
because naively running a second instance of any of them **doesn't scale the system — it breaks
it**:

- **Postgres** — this project's system of record, a single writer. Two Postgres containers behind
  a load balancer would just be two independent, unsynchronized databases; there's no primitive
  that makes them one logical store. Real horizontal scaling means streaming replication (read
  replicas, which only helps read-heavy paths and needs read/write query splitting in the app) or
  sharding (a shard-key strategy and cross-shard query handling) — a data-access redesign, not a
  deployment-config change.
- **Kafka** — runs as a single broker in KRaft mode (`KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1`,
  one controller voter), a deliberate choice to avoid a separate ZooKeeper JVM on the 24GB budget
  (see `docs/architecture.md`'s resource budget notes). Real Kafka horizontal scaling means adding
  *brokers* to one cluster with partition replication across them and controller voters that know
  about each other ahead of time — a different shape of problem than "run another copy," not a
  bigger version of the same one.
- **Redis** — used here as a shared cache of the latest reading per meter (see
  `docs/architecture.md`'s data flow). Two independent Redis instances would silently split that
  cache: a write lands on one, a read gets routed to the other, and the app serves a stale or
  missing value without any error. Real Redis horizontal scaling is Redis Cluster (hash-slot
  sharding, client-side cluster-aware routing) or Sentinel (failover, not capacity) — again a
  different mechanism, not a replica count.

Retrofitting real distributed-data architecture into all three to make them safely scalable would
be a substantial project in its own right, and runs directly against this project's stated
minimal-scope ethos (the same reasoning already applied to ruling Terraform out of scope in
`architecture.md`, and to deferring k8s HPA in
`docs/k8s-terraform-decisions-2026-08-19.md`). It is not something a load-test feature should
casually pull in as a side effect.

## Docker Compose `--scale` is a real mechanism, not a simulation

Worth stating plainly, since it's easy to undersell: Docker Compose's `--scale` flag is a
legitimate, production-grade scaling primitive — the same one Docker Swarm mode uses. The only
piece Compose doesn't provide out of the box is an automatic controller loop that watches a metric
and calls `--scale` on its own; that's a real but small gap (a watcher script), not a fundamental
limitation. This project's autoscaling demo (`load-tests/autoscale-watcher.sh` +
`load-tests/autoscale-demo.sh`) closes exactly that gap for the `api` layer: it polls
`docker stats` for CPU%/memory% on the running `api` container(s) and calls
`docker compose up -d --scale api=<n>` itself when a sustained threshold is crossed in either
direction (scale-out fast, scale-in slower, to avoid flapping) — a real, if self-built, autoscaling
loop, not a k8s HPA stand-in.

## What real scaling for Postgres/Kafka/Redis would actually require (not planned, for reference)

If this project's scope ever grows to need it:

- **Postgres**: standing up streaming replication (at least one read replica), then routing reads
  vs. writes in the service layer — a real code change, not just infrastructure.
- **Kafka**: moving from one broker to a multi-broker cluster, setting a replication factor > 1 on
  the `readings` topic, and updating `KAFKA_CONTROLLER_QUORUM_VOTERS` to list every controller.
- **Redis**: switching to Redis Cluster (cluster-mode-enabled, hash slots, a cluster-aware client
  configuration in the Spring Data Redis setup) or accepting Sentinel's failover-only semantics
  instead of a capacity story.

**Revisit only if** this project's scope ever grows to include a real need for data-tier capacity
under load — the same "revisit only if" framing already used for Terraform and TLS elsewhere in
these docs. Until then, `api` is the sole target for autoscaling work, by design.
