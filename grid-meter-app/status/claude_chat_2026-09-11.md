# grid-meter-app — Status: 2026-09-11 (Claude Chat)

Continuation from the resilience-scope decision made at the end of
`claude_chat_2026-09-10.md`'s thread (resilience before cloud-deployment).
Covers the full arc: scoping and reviewing Claude Code's sustained-
concurrent-Kafka-outage load test, the two real findings it produced, and
the follow-up fix-and-reverify pass that closed both.

## Done

- **Reviewed the freshly-uploaded doc batch** (`postgres-ha-scope.md`,
  `redis-ha-scope.md`, `resilience-scope.md`, `testing-expansion-scope.md`,
  `testing-strategy-ha-supplement.md`, `testing-strategy.md`,
  `multi-tenancy-scope.md`, `observability-taxonomy.md`,
  `tech-stack-versions.md`, `vendor-bug-report-process.md`, and the full
  `claude_chat_*`/`claude_code_*` status log set through 2026-09-10) to
  come up to speed on the project's actual current state before doing any
  new work.

- **Confirmed resilience should come before cloud-deployment**, per
  explicit user question. Reasoning: the resilience follow-up is small
  and already fully scoped in `resilience-scope.md`; `cloud-deployment-
  scope.md` isn't actually ready to start (needs its own read-through
  first, per 09-10's own "Next" note, to confirm the manifest-reuse
  assumption still holds against the now-more-complex Kafka/Redis
  StatefulSet wiring); cloud work carries real cost/teardown discipline
  the laptop-only resilience work doesn't; and it's in the same tooling
  groove (JMeter, Kafka kill scenarios, Micrometer metrics) as the
  paused `testing-expansion-scope.md` task #9 soak work, rather than a
  context switch into a different mode of work.

- **Drafted and handed off the load-test task brief** to Claude Code:
  extend/add a `load-tests/` JMeter scenario driving all 3 Kafka brokers
  into a sustained outage under real concurrent load (not sequential
  probing, which is all prior verification had used), watch
  `tomcat_threads_busy_threads` via already-scraped Actuator/Micrometer
  metrics, and answer two questions with real numbers: does the breaker
  open before the pool saturates, and does concurrent traffic actually
  get shed fast once it's open.

- **Reviewed Claude Code's first load-test results and caught a real
  confound before accepting them.** The initial 150- and 300-thread runs
  both showed the pool pinned at 200/200 throughout, but the 300-thread
  run's own pre-kill baseline showed the pool already near-saturated
  from raw JMeter concurrency alone (300 threads > 200-thread Tomcat
  cap), independent of Kafka ever failing. Flagged this back to Claude
  Code rather than accepting the confounded result, along with a
  separate secondary finding worth investigating on its own merits: the
  poller's own `/actuator/prometheus` scrape was timing out / getting
  `503`s during the highest-contention window, suggesting the metrics
  endpoint shares Tomcat's saturated pool with business traffic.

- **Reviewed the corrected, unconfounded 150-thread re-run and confirmed
  a real, non-trivial finding, not a clean pass.** At 150 threads
  (baseline `busy≈151`, comfortably under the 200 cap), the pool still
  spiked to 200/200 in two ~10–15s bursts, each aligned to the
  millisecond with the breaker's own `OPEN`/`HALF_OPEN` state
  transitions. Root cause, confirmed via the raw `.jtl`: ~150 requests
  already in flight at the instant Kafka died block synchronously inside
  `max.block.ms` (then 60s) before failing — entirely outside the
  breaker's control, since they'd already passed `tryAcquirePermission()`
  before the breaker had enough failures to open. Fast-fail correctness
  under real concurrency (hundreds of thousands of `503`s, sub-second
  every time, no lock-contention signal) was confirmed clean — the gap
  is specifically "does the breaker protect the thread pool," which
  resolves to a real, measured **no, not by itself**.

- **Reviewed Claude Code's write-up in `resilience-scope.md` and judged
  it held to this project's own rigor bar** — the mechanism claim (burst
  timing vs. breaker-transition timing) is confirmed at the level of
  precision this project holds other mechanism claims to, and the one
  genuinely unresolved detail (why the burst peaks at exactly 200 and
  not some other number) is explicitly flagged as unchased rather than
  rounded into the headline finding.

- **Reviewed and approved both new Open Decisions items** Claude Code's
  load test surfaced (not fixed unilaterally, per `CLAUDE.md`'s
  check-in convention):
  - **#6 (missing `KafkaException` handler, bare `500` instead of `503`)**
    — approved outright, no real tradeoff, same shape as two existing
    fixes in the same file.
  - **#5 (shorten `max.block.ms` from 60000ms)** — approved, and
    recommended pairing it with #6 in one pass rather than shipping
    separately, since shortening alone would just change "60s hang →
    wrong 500" into "5s hang → still-wrong 500." Confirmed shortening
    doesn't affect delivery durability (that's `delivery.timeout.ms`'s
    job) — it only bounds how long the *synchronous* `send()` call can
    hold a thread.

- **Drafted the combined follow-up brief**: add the handler, confirm the
  live exception type rather than guessing, pick a `max.block.ms` value
  checked against this project's own measured Kafka failover RTO
  figures, re-run the identical 150-thread/150s scenario, and document
  real before/after numbers.

- **Caught an unverified config-check gap mid-session, before trusting
  the re-run.** Claude Code's two attempts to confirm the new
  `max.block.ms` value was actually live in the rebuilt container both
  dead-ended (a `/actuator/prometheus` grep that could never have
  worked, since it's a producer config value not a scraped metric; an
  `env | grep` that came back empty with no follow-up) — it was about to
  proceed into a 14-minute load-test run without confirming the setting
  had actually taken effect. Flagged this explicitly as the same
  "assumed applied, not verified against the live system" pattern
  `CLAUDE.md` already tracks nine times over. Claude Code produced a
  real confirmation before the run proceeded.

- **A citation error surfaced and worked through, worth recording
  honestly rather than smoothing over.** The original task brief cited
  "~2.44s" as a Kafka leader-failover RTO figure to check the new
  `max.block.ms` value against. Claude Code's re-verification found this
  didn't hold up as a *failover* RTO citation — investigated further, and
  in relaying that back, Claude Chat then mis-attributed the figure's
  source doc (guessed Redis, without checking). Claude Code checked
  directly and confirmed the figure genuinely is in
  `docs/k8s-kafka-ha-scope.md` (the 2026-09-08 live-re-verification
  section) — but it measures **k8s pod-recreation time** (`kubectl
  delete` to `Running`+`Ready` on a new pod UID), a categorically
  different thing from the **application-level, client-visible Kafka
  leader-failover RTO** that's actually relevant to bounding
  `max.block.ms`. The real, correctly-categorized ceiling Claude Code
  used instead was `kafka-ha-demo.sh`'s own log-tail-based measurement
  (0.098–0.167s). Two separate citation slips compounded here — the
  original brief's category mismatch (pod-recovery time cited as if it
  were failover RTO) and Chat's own uncorroborated re-guess at the
  source doc — both corrected by checking the live docs directly rather
  than either version being trusted on recall.

- **Reviewed and accepted the final before/after results:**

  | | Before | After |
  |---|---|---|
  | Status on timeout path | `500` | `503` |
  | Time at full pool saturation | ~20–30s | 0s |
  | Worst-case slow-path latency | ~60.8s | 5.9s |

  `max.block.ms` shortened 60000ms → 5000ms (picked at the high end of
  the suggested 3–5s range, as a deliberate hedge given the uncertainty
  in the (ultimately set-aside) `kafka-leader-failover-rto.sh` figure).
  One residual ~2s/88.5%-busy window remains — reviewed and confirmed
  this is the expected, already-understood residual of the same
  first-in-flight-batch mechanism, not a new or partially-understood
  gap, and Claude Code tightened the doc's wording to state this
  explicitly rather than leave it ambiguous.

- **Caught and resolved a smaller, informal-only test-count discrepancy.**
  An earlier chat-relayed aside ("91/91 pass... was 87, now 90 + 3...")
  didn't arithmetically add up. Flagged rather than let it stand.
  Confirmed by Claude Code: the doc itself was always correct (91 total
  = 88 pre-existing + 3 new `GlobalExceptionHandlerTest` cases); the bad
  arithmetic was in Chat's own informal relay, not in the work or the
  documentation.

- **A real, separate follow-up surfaced along the way and tracked, not
  just mentioned in passing**: `kafka-leader-failover-rto.sh`'s own
  ~3.7–3.9s figure is flagged as plausibly inflated by the same
  JVM-spawn polling-cost artifact this project already found and fixed
  in a sibling script, but never ported to this one. Claude Code added a
  named, dated entry under `testing-strategy.md`'s existing "polling
  loop's own per-call cost" lesson, with a concrete next step (port the
  log-tail technique already proven in `kafka-ha-demo.sh`) — durably
  tracked rather than left to be rediscovered.

- **Resilience thread fully closed**: both Open Decisions items 5 and 6
  resolved with real before/after evidence; `resilience-scope.md`,
  `CLAUDE.md`, and `load-tests/README.md` all updated to match; full
  test suite green (91/91); stack left healthy.

## Open

- **`kafka-leader-failover-rto.sh`'s suspect ~3.7–3.9s figure** — named
  and tracked in `testing-strategy.md`, not yet fixed. Concrete next
  step already identified (port `kafka-ha-demo.sh`'s log-tail technique).
- **Cloud-deployment (multi-cloud Terraform) scope decision** — still
  the next major open thread, per 09-10's own "Next" note: needs a fresh
  read-through of `cloud-deployment-scope.md` first to confirm the
  k8s-manifest-reuse assumption still holds against the now-more-complex
  Kafka/Redis StatefulSet wiring, before any AWS-first design work
  starts.
- Carried forward, untouched this session: `testing-expansion-scope.md`
  task #9 (the longer accelerated soak validation run, paused mid-build);
  tasks #10–17 of that same doc's build order; the unfiled Kafka KRaft
  JIRA report (evidence-ready, pending account approval); the
  `ListPartitionReassignments`-stalls mechanism (named, deliberately not
  chased further).

## Next

1. Decide whether to resume `testing-expansion-scope.md`'s task #9
   (soak validation) or move to the cloud-deployment read-through next —
   both are legitimate next threads; no blocker either way.
2. When cloud-deployment work resumes: re-read `cloud-deployment-scope.md`
   in full as a gating sanity check before any Terraform design work,
   per 09-10's own note.
3. Optionally: pick up the `kafka-leader-failover-rto.sh` polling-cost
   fix-porting — small, well-scoped, no dependencies.
