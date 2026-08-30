# grid-meter-app — Status: 2026-08-27 (Claude Chat)

A long scoping-and-review session spanning HA, multi-cloud, observability
taxonomy, multi-tenancy, and resilience — five new decision docs, two
implemented and verified via Claude Code, plus live review/debugging of a
real k8s observability slice as it was built. Several corrections landed
mid-session, on both sides, and are recorded as such rather than smoothed
over.

Done:

- **`docs/ha-scope.md` created**: scoped local HA work to Kafka multi-
  broker only this pass (native KRaft, cheap, high payoff); Redis
  (Sentinel) and Postgres (Patroni, with Consul/repmgr/pg_auto_failover
  named as real alternatives) explicitly deferred with their own revisit
  triggers. Recorded the quorum-math reasoning (why 3 nodes tolerate one
  loss safely, why 2 don't) directly against real prior production
  incidents (planned-maintenance-plus-concurrent-unrelated-failure).
  Reframed (not retuned) the HikariCP 5s connection-timeout as demo-scoped
  rather than production-final. Later updated with a pointer to
  `resilience-scope.md`'s circuit breaker as a more direct fix, and a note
  that `cloud-deployment-scope.md`'s deployment-target trigger has fired.

- **`docs/testing-strategy-ha-supplement.md` created**: first pass at an
  incident-vs-trend alert taxonomy, plus a concrete 3-broker Kafka test
  plan (failover/RTO, quorum-loss, rolling maintenance) replacing the
  old single-instance chaos test. Later marked as superseded/extended by
  `observability-taxonomy.md` without deleting its content.

- **`docs/cloud-deployment-scope.md` created**: reversed
  `architecture.md`'s Terraform-out-of-scope and `identity.md`'s
  TLS-not-needed decisions (both had explicitly named "a real external
  deployment target" as their own revisit trigger — AWS/GCP/Azure
  deployability for interviews is that trigger firing). Decided: separate
  per-cloud Terraform configs, structured in parallel across all three
  from day one, built and validated one at a time (AWS first, given real
  prior experience); managed PostgreSQL and Redis per cloud; Kafka
  self-hosted identically across all three (deliberate — no cloud has a
  truly comparable native managed Kafka); Traefik stays the constant
  in-cluster ingress across all three, cloud LBs sit in front of it purely
  for TLS/public IP; cert-manager + Let's Encrypt for TLS. Recorded a
  generalizable "self-host + hand-instrument when the managed layer
  hasn't caught up" principle, illustrated via blockchain/AI/quantum
  examples, landing on "write your own Prometheus exporter" as the
  reusable skill. Doc-edit text for `architecture.md`/`identity.md`
  included but not yet applied to those files.

- **`docs/observability-taxonomy.md` created**: organized everything
  raised across a set of SRE-experience questions into four categories —
  incident alerts (threshold + new anomaly/undershoot sub-type + synthetic-
  canary signal source), trend alerts (resource-capacity + new meta/
  derivative + adoption sub-types), notices (failover/scale/flag/breaker
  state changes), and reports & dashboards (seasonal rollups, quiet-period
  heatmap, high-water-mark, blast-radius, flag adoption). Surfaced two
  real prerequisite gaps and queued them as their own docs.

- **`docs/multi-tenancy-scope.md` created, implemented, and verified —
  fully closed out.** Decision: observability-only tenancy (add a
  `Customer` entity, propagate via Loki/Tempo for reporting, no API
  access-control change) — smaller of two options, explicitly confirmed.
  Corrected an earlier suggestion of mine mid-doc: `customerId` belongs on
  Loki/Tempo, not as a raw Prometheus label (cardinality risk). Claude
  Code built: `Customer` entity + `V4` migration (892 existing meters
  backfilled), JWT claim, MDC/Tempo propagation,
  `MeterController.create()` deriving `customerId` from the caller's own
  token rather than the request body. Initially skipped the doc's two
  testing-implication items (seed ≥2 customers, assert cross-customer
  visibility); pushed back correctly when asked to add them, citing this
  session's own HikariCP/Kafka-outage "verify, don't assume" precedent —
  added both, and found a real latent Awaitility race bug
  (`awaitPersisted()` missing `.ignoreExceptions()`) in the process,
  reproduced and fixed. 60 tests green, 16/16 black-box `*ApiIT`.
  Committed as `aa9cea3`.

- **`docs/resilience-scope.md` created**: Spring Boot 4's native
  `@Retryable`/`@ConcurrencyLimit` identified as covering plain retry —
  Resilience4j scoped narrowly to circuit breaking (Postgres `existsById`
  and Kafka `send()`, as two independent breaker instances), with a real
  `resilience4j-spring-boot4`/BOM gap flagged for verification before
  pinning. Corrected an earlier claim of mine: Spring Boot Actuator does
  **not** ship a built-in Kafka health indicator (a custom one is real,
  bounded work). Outbox pattern scoped for Kafka-publish failure — simple
  polling reconciler confirmed for this pass, Debezium named as the "more
  correct," not-built future upgrade. A real 46-second single-broker
  Kafka outage test (`b388bi7hg`: 88 requests, 0 errors, 5 requests
  blocked ~49.7s each, exact Postgres count match) informed a key
  sequencing decision: declare `max.block.ms` explicitly now near its
  current ~60s value, but do **not** shorten it until the outbox exists —
  shortening it early would convert a proven zero-loss behavior into
  unhandled failures with nowhere to land. Committed as `a46b5af`
  (declaration only; circuit breaker and outbox not yet built).

- **k8s observability follow-up slice — built, debugged live across
  several rounds, and fully validated end-to-end; committed and torn
  down.** Resolved the slice's one open architectural fork
  (`k8s-terraform-decisions-2026-08-19.md` hadn't pinned it down): one
  unified `kube-prometheus-stack` (its bundled Prometheus scrapes both
  cluster and `api` metrics; Loki/Tempo/Alloy stay separate plain YAML,
  wired in as extra Grafana datasources) — chosen over two separate
  stacks, on resource-cost and interview-clarity grounds. I incorrectly
  suggested `PrometheusRule` for migrating the existing alerts; corrected
  once Claude Code found this project's alerts are Grafana-native
  provisioned alerts, and `extraConfigmapMounts` was the right mechanism
  instead. Debugged, in order: a Compose-vs-`kind` port-80 collision (both
  want host port 80; can't run concurrently as currently scoped — needs a
  one-line `architecture.md` note, not yet written); an `api`/`postgres`/
  `redis` cold-start crash-loop on a fresh cluster (dependency race,
  consistent with Compose's existing `restart: on-failure:5` rationale;
  surfaced a real gap — no `readinessProbe` on `api` in the manifest
  scope); a Grafana pod that failed twice for different reasons (slow
  cold image pull hitting the liveness budget, then genuine memory
  pressure). On the memory issue, I incorrectly cited Compose's 768Mi as
  a transferable precedent; Claude Code correctly refuted it (768Mi's
  real justification was an unrelated screenshot-automation Playwright
  leak) and fixed it properly via direct cgroup measurement (99.99% of
  256Mi) → 512Mi, plus a readiness-timeout bump (1s → 5s). Diagnosed and
  fixed all 4 alert rules false-firing continuously — Compose-specific
  PromQL label values (`job="grid-meter-api"`, `service="api@docker"`)
  didn't exist under k8s's real values — fixed via scrape-time
  `relabelings`/`metricRelabelings` normalizing both environments to
  shared canonical labels, not hardcoding either snapshot. Final
  from-scratch rebuild validated clean: 7 real bugs found and fixed total
  (River's `//` comment syntax, a `ServiceMonitor` selector trap,
  `hostPort`+`RollingUpdate` deadlock fixed via `Recreate`, a chart-default
  Grafana version drift, a self-healing SQLite lock contention left
  as-is/documented, the memory fix, the label-normalization fix).

- **`docs/cross-project-lessons.md` rewritten**: added a new "Kubernetes
  and infrastructure-as-code pitfalls" section capturing 5 portable
  lessons from the k8s slice above (River comments, `ServiceMonitor`
  selector semantics, `hostPort`/`Recreate`, don't-borrow-resource-limits-
  by-analogy, cross-environment alert-label normalization), plus a Helm
  sub-chart-version-drift entry folded into the existing "Dependency and
  tool versions" section. Delivered as a full replacement file, not yet
  confirmed copied back into the repo.

- **Live-diagnosed, fix identified but not yet applied**: a `NewTopic`
  bean declaring `replicationFactor=3` against every actual environment
  (Testcontainers, Compose, not-yet-built k8s), all single-broker today —
  produces a benign-for-now (`KafkaAdmin` swallows it by default) but
  fragile `InvalidReplicationFactorException` on every context load.
  Almost certainly written ahead of `ha-scope.md`'s future 3-broker work
  rather than after it. Fix: revert to `replicas(1)` until the real
  multi-broker cluster exists, per that doc's own sequencing.

Open:

- **Kafka `replicationFactor=3` bug** — fix identified, not yet applied
  or confirmed; a repo-wide grep for other `replicas(3)`-style
  assumptions hasn't been run either.
- **Outbox max-depth/max-age bound values** — walked through the
  mechanics twice, never landed on real numbers.
- **Resilience4j `spring-boot4` BOM gap** — flagged for a
  `check-maven-central-version.sh` check before pinning; not yet run.
- **The "outage longer than `max.block.ms`" test** — still the missing
  empirical step confirming today's actual failure mode before the outbox
  gets built against an assumed one.
- **Kafka multi-broker HA** (`ha-scope.md`'s core scope) — confirmed,
  not started.
- **Multi-cloud Terraform** (`cloud-deployment-scope.md`) — confirmed,
  not started; real cloud accounts/state-backend credentials are a
  prerequisite outside what Claude Code can set up alone.
- **Synthetic/canary monitoring** — discussed and recommended more than
  once, never actually scoped into its own doc.
- **Redis Sentinel / Postgres Patroni HA, enforced tenant isolation,
  multi-user-per-customer, subscription tier** — all explicitly deferred
  with their own named revisit triggers per `ha-scope.md` and
  `multi-tenancy-scope.md`; untouched this session, as intended.
- **Compose-vs-`kind` concurrent port-80 conflict** — diagnosed; the
  one-line `architecture.md` Deployment-model note documenting it as a
  known, deliberate constraint (stop one before starting the other) isn't
  written yet.
- **`tech-stack-versions.md`** — a matching entry for the Helm
  sub-chart-version-drift lesson was offered but not confirmed/added; a
  `kube-prometheus-stack` row for the main version table was also offered
  as optional, not requested.
- **`docs/cross-project-lessons.md`** — rewritten file delivered this
  session; not yet confirmed copied back into the actual repo.

Next:

- Apply and confirm the Kafka replication-factor fix; grep for any other
  premature 3-broker assumptions in the codebase.
- Pick a real, concrete outbox tolerance window (a tolerable outage-
  buffering duration) and use it to size max-depth/max-age before Claude
  Code builds the outbox.
- Run the Resilience4j BOM check and the longer-than-`max.block.ms`
  outage test before building the circuit breaker/outbox on assumptions.
- Decide sequencing between Kafka multi-broker HA and multi-cloud
  Terraform work — both are confirmed and unstarted, competing for
  attention next.
- Confirm whether the `tech-stack-versions.md` addition and the
  `architecture.md` port-80 note should be written now or queued.
