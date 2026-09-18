# grid-meter-app — Status: 2026-09-11 (Claude Code)

Picked up the circuit-breaker follow-up named as still open at the end of the prior sessions:
`docs/resilience-scope.md`'s "What's still open" note under "Circuit breaker: built" and Open
Decisions item 4 — load-testing the `kafka-publish` breaker's thread-pool protection under
*sustained concurrent* Kafka failure, not just the sequential single-call reproduction every prior
verification used. Two phases: build and run the load test (found a real gap), then a same-day
approved follow-up (fix the gap, re-verify).

## Done — Phase 1: built and ran the sustained-concurrent-Kafka-outage load test

- **New load-test tooling**: `load-tests/kafka-outage-concurrent.jmx` (a sixth JMeter profile,
  same shared fragments as the other five) + `load-tests/kafka-circuitbreaker-loadtest.sh`
  (orchestrates JMeter in the background around a real `docker compose stop/start
  kafka-1 kafka-2 kafka-3`, same shape as `misconfigured-spike-demo.sh`'s two-phase pattern) +
  `load-tests/kafka-cb-loadtest-poller.py` (polls `api`'s own `/actuator/prometheus` directly at
  0.2s resolution — Prometheus's own 15s `scrape_interval` is too coarse) +
  `load-tests/kafka-cb-loadtest-analyze.py` (combines the poller CSV with JMeter's `results.jtl`
  into a real-numbers report).
- **Two real test-methodology bugs found and fixed before trusting any run**: a fixed pre-kill
  sleep racing the SetupThreadGroup's own warmup (classic fixed-sleep-vs-unbounded-readiness bug,
  fixed by polling the growing `.jtl` for the main group's own real traffic label before starting
  the countdown); and an initial 8-second outage that was too short to trigger any breaker
  activity at all (mirrors `kafka-ha-demo.sh`'s own documented Scenario 2 gap — needed the same
  150s, past `delivery.timeout.ms`, to see real failures).
- **The real finding**: correctness holds under real concurrency (hundreds of thousands of real
  concurrent `503`s, sub-second every time, no lock contention). But "does the breaker protect the
  thread pool" resolved to a measured **no, not by itself** — under a clean 150-thread load well
  under the 200-thread ceiling, `tomcat_threads_busy_threads` still reached its full `200/200`
  ceiling twice during one 150-second outage, in bursts tied exactly to the breaker's own
  open/half-open transitions. Root cause: calls that pass the permission gate *before* the breaker
  has enough failures to open can then block inside Kafka's own `max.block.ms`-bounded synchronous
  path (60000ms at the time) — entirely outside the breaker's control once in flight. Also
  surfaced a related, separate gap: `GlobalExceptionHandler` had no handler for a bare Kafka
  exception, so that path returned a raw `500` instead of the app's usual `503`.
- **Documented** as a new dated section in `docs/resilience-scope.md`, with the two gaps named as
  new Open Decisions items (5, 6) for sign-off — nothing changed unilaterally. Updated `CLAUDE.md`
  and `load-tests/README.md` to match.

## Done — Phase 2: both approved items built and re-verified same day

- **Item 6 (exception handler) built first**, since item 5's safety margin needed a *confirmed*
  exception type, not an assumed one. Ran a small live repro against a real stopped cluster before
  writing any code and captured the actual stack trace: `KafkaTemplate.doSend()` wraps a
  synchronously-failed send as `org.springframework.kafka.KafkaException("Send failed", cause)` —
  Spring's own wrapper class, not the raw Kafka client class — with root cause
  `org.apache.kafka.common.errors.TimeoutException`. Added
  `@ExceptionHandler(KafkaException.class)` to `GlobalExceptionHandler`, mapped to `503`/`ApiError`,
  confirmed via `javap` that it shares no hierarchy with `CallNotPermittedException` (the two can
  never fire for the same call). New `GlobalExceptionHandlerTest` (3 unit tests). Confirmed live
  against a real outage, not just the unit test: `{"status":503,"error":"Service
  Unavailable","message":"A dependency (kafka-publish) is currently failing..."}` — the real body.
- **Item 5 (`max.block.ms`) shortened 60000ms → 5000ms** — but not blindly using the sign-off
  brief's own suggested range without checking its citations first. Two of the three RTO figures
  the brief cited didn't hold up: "~2.44s" turned out to be `docs/k8s-kafka-ha-scope.md`'s k8s
  pod-*recreation* time (a different metric, different investigation — re-confirmed directly
  against the doc a second time after Claude Chat proposed a different, also-incorrect
  re-attribution to the k8s Redis doc); and `kafka-leader-failover-rto.sh`'s own reported
  "~3.7–3.9s" turned out to still use the same `kafka-topics.sh --describe`-polling-loop pattern
  this project already found and fixed once in `kafka-ha-demo.sh`'s sibling measurement, so it's
  very likely inflated by that same JVM-spawn-cost artifact rather than real election time. The
  real, most-scrutinized figure is `kafka-ha-demo.sh`'s own log-tail-based measurement:
  0.098–0.167s across 9 samples in 3 independent passes. 5000ms clears that by ~30x, picked at the
  higher end of the brief's suggested 3000–5000ms range specifically as a hedge in case the
  unconfirmed 3.7–3.9s figure has some real signal after all.
- **Re-verified with the identical primary scenario** (150 threads, 150s outage) after both
  changes:

  | | Before | After |
  |---|---|---|
  | Status on timeout path | `500` | `503` |
  | Time at full pool saturation | ~20–30s (two windows) | **0s** |
  | Worst-case slow-path latency | ~60.8s | **5.9s** |

  Not fully eliminated, as expected: one brief ~2s/88.5%-busy window remains — the very first
  in-flight batch, already past the breaker's permission gate before the outage was even detected,
  now bounded to ≤5s instead of ≤60s rather than prevented outright (no breaker-side config could
  prevent it). Full suite: 91/91 green (88 pre-existing + 3 new).
- **Documented** as a second dated section in `docs/resilience-scope.md` with the real before/after
  table and both citation corrections spelled out; Open Decisions items 5 and 6 marked resolved.
  Updated `CLAUDE.md` and `load-tests/README.md` to match.
- **A follow-up named but explicitly not done this session** (per Claude Chat's own flag,
  confirmed worth tracking rather than losing): `kafka-leader-failover-rto.sh` still has the
  unfixed JVM-spawn-polling-cost measurement pattern that produced its suspect ~3.7–3.9s figure.
  Added a dated entry under `docs/testing-strategy.md`'s existing "polling loop's own per-call
  cost" standing lesson naming this as a known, unfixed second instance, so it doesn't sit
  forgotten in a status log alone.

**Committed as one combined commit, not the two recommended above**: `d227150` — "Load-test
kafka-publish circuit breaker under concurrent failure, fix the gap it found" — covers both phases
(the load-test build/finding and the fix/re-verification) in a single commit rather than split.
Pushed to `origin/main`.

## Done — cloud-deployment gating read-through: closed the app/manifest-readiness gaps ahead of Terraform

Picked up `docs/cloud-deployment-scope.md`'s own stated blocker before any Terraform work starts:
re-check the doc's "the same manifests running on `kind`, EKS, GKE, and AKS alike" reuse claim
against the actual current code, not recalled from when the doc was first written (2026-08-27) —
`k8s-kafka-ha-scope.md` and `k8s-redis-ha-scope.md` have both added real complexity since then that
the cloud doc never re-examined.

- **Scoped precisely first**: the reuse claim only ever applied to Kafka. Postgres and Redis both
  become *managed* cloud services (RDS/Cloud SQL/Azure DB; ElastiCache/Memorystore/Azure Cache) per
  the doc's own per-layer strategy — neither Patroni+Consul nor the Sentinel StatefulSet work ports
  to cloud at all, so only Kafka's manifest reuse was actually the right thing to check.
- **Postgres — confirmed clean, no code change needed**: `SPRING_DATASOURCE_URL` and
  `PrimaryFailoverSQLExceptionOverride` are both fully generic (read directly, not assumed) — no
  Patroni/Traefik awareness baked in anywhere. Carries over to managed Postgres as-is (not yet
  live-verified against a real RDS/Cloud SQL failover, since none exists yet — flagged as a real,
  not-yet-closed caveat, not a blocker).
- **Redis — a real gap, closed**: `spring.data.redis.sentinel.*` was active in every profile except
  `test`, with no third mode for a managed single-endpoint Redis at all. Added a new `cloud` Spring
  profile (`!test & !cloud` gates Sentinel; a new `on-profile: "cloud"` block sets plain
  `spring.data.redis.host`/`port`). Property names and the actual mode-selection mechanism confirmed
  against the real `spring-boot-data-redis-4.1.0.jar` and Spring Boot 4.1's real source, not assumed.
  New `RedisCloudProfileComponentTest` confirms standalone mode, a real `RedisStandaloneConfiguration`,
  and a live `PING`/`PONG` round-trip.
- **Kafka — bootstrap-servers config already fine; two real manifest gaps, now closed and
  live-verified against a real `kind` cluster**: `k8s/kafka.yaml` had zero `volumeClaimTemplates`
  (fully ephemeral) and zero AZ-spread mechanism. Added `volumeClaimTemplates` (12Gi/broker, sized
  from this project's own measured throughput — `steady-state.jmx`'s ~95 readings/s, 72h retention,
  RF=3 — not a guess) and `topologySpreadConstraints` (zone-keyed, `maxSkew: 1`, `ScheduleAnyway`
  chosen explicitly over `DoNotSchedule` so `kind`'s single node never gets stuck scheduling — a
  soft preference, not an enforced guarantee, noted explicitly). Live-verified: full `kind` deploy,
  a real functional check, and a `kubectl delete pod` kill test confirming the same PV re-attaches
  with data intact.
- **Full suite: 92/92 green** (91 pre-existing + `RedisCloudProfileComponentTest`).
- Documented in full in `docs/cloud-deployment-scope.md`'s new "Gating read-through" section.
  Committed as `32dbef1` — "Close cloud-deployment gaps: Redis cloud profile, Kafka PVCs, Kafka AZ
  spread" — and pushed.

## Done — same-day correction: PVC lifecycle claim was imprecise, fixed and re-verified

Claude Chat caught that the Kafka PVC work above had only checked `kubectl get pv`'s
`RECLAIM POLICY` column (the StorageClass's own knob) and never actually exercised
`persistentVolumeClaimRetentionPolicy.whenDeleted` by deleting the StatefulSet itself — three
separate lifecycle knobs had been conflated into one "confirmed" claim.

- **Verified live, on a throwaway `kind` cluster, as three distinct checks**: does a pod restart
  preserve data (yes — same PV re-attaches, already covered above); does deleting the StatefulSet
  itself trigger PVC cleanup (yes — `whenDeleted: Delete` confirmed for real, all 3 PVCs
  `Terminating`→deleted within seconds); does deleting the PVC also delete the underlying disk, or
  just orphan it (confirmed on `kind` — zero orphaned PVs afterward, `kind`'s own default
  StorageClass `reclaimPolicy: Delete` completes the chain).
- **A real, version-dependent gap surfaced while checking this, flagged as a prerequisite for the
  Terraform work about to start**: GKE and AKS both reliably auto-mark a default StorageClass
  (`reclaimPolicy: Delete`), but **EKS 1.30+ stopped auto-marking any StorageClass as default** —
  this manifest's deliberately-unset `storageClassName` would fail to bind on a current EKS cluster
  unless the Terraform-provisioned EKS setup explicitly creates and marks one.
- Also added an explicit note that `topologySpreadConstraints`' `ScheduleAnyway` is a soft
  preference, not an enforced guarantee (tightening the wording added above, not a new finding).
- Committed as `dacb4be` — "Correct PVC reclaim-policy claim, distinguish the three lifecycle
  knobs" — and pushed. **This is `HEAD`/`origin/main` as of this update.**

## Open

- `kafka-leader-failover-rto.sh`'s own JVM-spawn-cost measurement fix — named in
  `docs/testing-strategy.md`, not yet built.
- **The EKS default-StorageClass gap found above is a real, live prerequisite for the AWS Terraform
  work about to start** — needs an explicit decision (create+mark a default `gp3` StorageClass as
  part of the Terraform-provisioned EKS cluster, or set `storageClassName` explicitly in
  `k8s/kafka.yaml` for the AWS target) before `k8s/kafka.yaml` is applied against a real EKS
  cluster, not discovered mid-`apply`.
- Postgres's cloud-readiness claim (`SPRING_DATASOURCE_URL` generic, carries over as-is) is
  reasoned, not yet live-verified against a real managed-Postgres failover — nothing to fail over to
  yet; revisit once RDS/Cloud SQL/Azure DB actually exists.
- Everything else carried over from `status/claude_code_2026-09-10.md` and untouched this
  session: Part 2/3 of `docs/testing-expansion-scope.md` (HA regression promotion, multi-tenant
  blast-radius demo, §1.2 soak validation), §4.1/§1.5.

## Next

- **Cloud-deployment's gating read-through is now closed** — `docs/cloud-deployment-scope.md`
  itself states "Terraform itself is the next brief." Per the doc's own sequencing: establish the
  shared `terraform/{aws,gcp,azure}/` directory structure and naming conventions across all three
  providers first, then build and fully validate **AWS first** (closest match to real prior
  experience), then replicate the established pattern to GCP, then Azure.
- Decide whether to pick up `kafka-leader-failover-rto.sh`'s measurement fix now or leave it queued.
- Resume `docs/testing-expansion-scope.md`'s build order (paused at task #9) whenever this thread
  is closed out.
