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

## Open

- **Nothing is committed yet.** The full diff from both phases above is sitting uncommitted in the
  working tree (see `git status` — 6 modified files, 5 new files). Live-verified and tests green,
  per this project's own "verify before commit" standard, but not yet checked in — needs explicit
  go-ahead before committing/pushing, per this project's standing convention of only committing on
  request.
- `kafka-leader-failover-rto.sh`'s own JVM-spawn-cost measurement fix — named in
  `docs/testing-strategy.md`, not yet built.
- Everything else carried over from `status/claude_code_2026-09-10.md` and untouched this
  session: cloud-deployment (Terraform) scope decision, Part 2/3 of `docs/testing-expansion-scope.md`
  (HA regression promotion, multi-tenant blast-radius demo, §1.2 soak validation), §4.1/§1.5.

## Next

- Get explicit go-ahead to commit today's work (recommend splitting into two commits matching the
  two phases above — the load-test build/finding, then the fix + re-verification — rather than one
  large commit, matching this project's own "split unrelated changes" convention; these two are
  related but temporally and logically distinct enough to read better separately).
- Decide whether to pick up `kafka-leader-failover-rto.sh`'s measurement fix now or leave it queued.
- Resume `docs/testing-expansion-scope.md`'s build order (paused at task #9) whenever this thread
  is closed out.
