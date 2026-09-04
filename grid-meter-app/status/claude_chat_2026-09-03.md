# grid-meter-app — Status: 2026-09-03 (Claude Chat)

Long session, mostly Claude Chat directing/reviewing Claude Code's work
across three threads: closing out the 2026-09-02 carried-over list, an
exhaustive repo-wide sweep for hardcoded-cluster-target and unguarded
`set -e` bugs (triggered by chasing down a "possible 4th `set -e`
occurrence"), and building the previously-scoped-but-unbuilt circuit
breaker. Reviewed changes were committed and pushed throughout, per the
standing workflow.

## Done

- **09-02 carried-over list, closed out:**
  - `CLAUDE.md`'s undeclared-default count at 9 — confirmed already
    correct on disk; the "not yet confirmed" note was itself stale
    bookkeeping, not a real gap.
  - Possible 4th `set -e` instance — investigated via commit-history
    audit and a repo-wide grep of every `set -e` script; no distinct
    4th occurrence exists. The three known instances (Redis's
    `grep -c` zero-match trap, Postgres Stage 4's asymmetric guard,
    Postgres Stage 7's backgrounded-loop bug) are the whole set. The
    3rd instance's missing `cross-project-lessons.md` writeup (it only
    had a narrative in `postgres-ha-scope.md`) is now added.
  - Kafka RTO archival gap — closed. Added a `--pass-label` CLI arg to
    `kafka-controller-failover-rto-test.py` (defaults to a UTC
    timestamp) so results/log-slice filenames can never collide again.
    Re-ran the full 6-trial suite under a fresh label; confirmed the
    prior corrected pass's files were untouched (unchanged mtimes)
    before trusting anything. New samples land just below the
    previously-stated tight bands — reported honestly as the expected
    effect of more data, not smoothed over. Conclusion unchanged;
    secondary `external_confirm_s` finding strengthened to 12-of-12
    clean separation across 4 total passes (relabeled by date after
    catching a numbering collision with the doc's own pre-existing
    pass-numbering scheme).

- **Exhaustive hardcoded-cluster-target / unguarded-`set -e` sweep**
  (triggered while investigating the "4th occurrence," then
  deliberately expanded end-to-end per explicit instruction to leave no
  stone unturned):
  - Fixed 2 originally-flagged bugs: unguarded `consul-1` raft-leader
    check (`postgres-consul-nonleader-agent-loss-test.sh`, first line
    of the script, silently fatal under `set -euo pipefail`) and
    hardcoded `patroni-1` show-config check
    (`postgres-consul-partition-test.sh`). Both fixed with dynamic
    3-node discovery, both live-verified with a genuine negative
    control (confirmed the pre-fix code actually dies silently under
    the identical fault) before trusting the fix.
  - Fixed the same hardcoded-target pattern in
    `postgres-app-primary-failure-test.sh` (line 49, `patroni-2`) —
    replaced with a fallback-discovery loop, live-verified via a
    surgical isolated test after an organic real-world trigger
    (`patroni-2` was actually down mid-session) already proved the old
    code's failure mode directly.
  - Full-repo audit surfaced far more instances than originally asked
    for. All fixed, live-verified (happy path for cosmetic/low-risk
    sites, full fault-injection + negative control for anything inside
    real chaos-injection logic):
    - `consul-quorum-loss.sh` (3 sites, reused its own existing
      `any_running_consul()` helper)
    - `postgres-traefik-routing-register.sh` (cosmetic display line)
    - `postgres-patroni-fresh-bootstrap-test.sh` (2 sites; verified via
      isolated extraction rather than re-running the script's own
      destructive live-data wipe unnecessarily)
    - `redis-ha-demo.sh`, `redis-primary-failover-rto.sh` (1 unused
      `sentinel-1` each — the second fix accidentally reintroduced the
      project's own named `grep -c`-zero-match trap, caught and
      re-fixed properly with a clean `if`/`else`)
    - `redis-quorum-loss.sh` (1 of 5 `sentinel-1` refs was arbitrary;
      the other 4 confirmed correct-by-design)
    - `kafka-acks-gap-repro.sh`'s `describe_topic()` `kafka-1` hardcode
      (confirmed live-firing during today's own verification runs, not
      theoretical)
    - `kafka-ha-demo.sh`'s 4 pre-chaos setup-phase `kafka-1` refs
    - `postgres-consul-self-demotion-timing-test.py`'s `get_leader()`
      hardcoded `patroni-1` (Python; matched the proven bash pattern
      via container-status check rather than error-string matching)
  - **Category C (needed real judgment, not mechanical fixing):**
    - Dead standalone-`postgres`-container references in
      `kafka-acks-gap-repro.sh` (2 sites) and
      `kafka-leader-failover-rto.sh` (1 site) — these failed
      unconditionally, every run, since Postgres Stage 7 retired that
      container. Fixed by routing through Traefik's `:55432` entrypoint
      + `PGPASSWORD`, reusing `kafka-ha-demo.sh`'s own proven pattern.
      Verified the fix genuinely crosses Traefik to the real primary
      (`pg_is_in_recovery()` check), not just connecting successfully
      to a local replica.
    - `kafka-leader-failover-rto.sh`'s stale `LEADER_SVC="kafka-2"`
      assumption — replaced with dynamic detection of whichever broker
      currently leads the most partitions. Caught and fixed a real bug
      in this fix's own first attempt (an end-of-line-anchored `grep`
      pattern that never matched real output, silently reporting
      "0 of 3 partitions" under output showing 2 of 3). Re-verified
      clean across two runs against different real leadership
      distributions.
    - `postgres-replica-failure-test.sh`'s deliberate `patroni-1`
      hardcode — reviewed, confirmed correct by design (not the same
      bug shape), left as-is; strengthened the explanatory comment so
      a future reader won't "fix" it back into a bug.
  - **Confirmed correct-by-design, no action (Category D):** Redis
    primary-container refs, `redis-quorum-loss.sh`'s post-kill
    survivor refs, `postgres-patroni-fresh-bootstrap-test.sh`'s
    only-node-running-at-that-point refs, `kafka-ha-demo.sh`'s WITNESS
    mechanism, all `kafka-unclean-election-*`/`kafka-debug-snapshot.sh`
    scripts (already using proven dynamic discovery).
  - **A serious, unrelated tooling incident, root-caused and closed**:
    an accidental `docker compose kill $(docker compose ps -q)` was
    issued mid-session — a spurious action, not a scoping slip in an
    otherwise-sound command. Verified no actual damage across all 23
    containers (not just the ones in the immediate task) — `RestartCount:
    0` everywhere, every later `StartedAt` traced to a separately-
    identifiable legitimate test action. Documented as a standing
    `cross-project-lessons.md` caution: pause and re-read any
    stack-wide destructive compose command against stated intent before
    running it.
  - **A related contamination gap found via the Redis investigation
    below, closed proactively**: built `scripts/check-no-stray-traffic.sh`
    (mirrors `check-disk-headroom.sh`'s pre-flight pattern) — hard-stops
    a measurement script if any `/api/v1/*` traffic hit the API in the
    last 5s. Wired into the 5 scripts that generate/measure real app
    HTTP traffic (not the infra-only chaos scripts). Confirmed no
    false-positive risk against each script's own login/setup preamble.
    New, distinct `cross-project-lessons.md` entry: a chaos/measurement
    script's preconditions should include "is anything else already
    generating traffic against this target," separate from the
    existing fixed-sleep/hardcoded-target/GNU-vs-BSD lessons.

- **Three carried-over "mechanism hypothesis" items, resolved:**
  - Postgres App RTO variance — already resolved 2026-09-02 (not part
    of today's work, confirmed via commit history): refuted as a
    `SECONDS`-quantization artifact; real mechanism confirmed via
    Patroni source read + empirical scaling test
    (`~90–103% of loop_wait + retry_timeout`).
  - Kafka RTO variance — already substantially resolved 2026-09-02:
    original spread was test-harness JVM-spawn overhead, not a real
    Kafka mechanism; corrected bands cross-validated against production
    runs. (Secondary `external_confirm_s` finding's own root cause
    remains a minor separate open thread.)
  - **Redis's Lettuce/Kafka-consumer-retry theory — isolated and
    refuted today.** Built a compose override
    (`docker-compose.redis-retry-isolation-test.yml`) forcing Spring
    Kafka's consumer to a single delivery attempt (no redelivery), plus
    consumer instrumentation, to separate the two mechanisms. Result:
    Kafka's redelivery is never engaged in any run, with or without it
    available (confirmed across 2 baseline + 2 isolation runs). The
    real mechanism is simpler and different from the original theory:
    the async Kafka-consumer thread's Redis write just blocks
    synchronously for Lettuce's own ~10.1–10.9s reconnect window, then
    completes normally — no exception, no retry needed. **Real,
    forward-looking implication flagged in `redis-ha-scope.md`**: this
    only works because the write sits on an async background thread;
    if it were ever moved onto a synchronous (HTTP request) path, the
    same Lettuce behavior would hang requests ~10s per failover instead
    of silently self-healing. A stray 5-hour-old leftover script from
    earlier in the session contaminated the first baseline run (stale-
    token 401 flooding) — found and killed by exact PID before trusting
    further runs. Isolation tooling kept in the repo as reusable
    diagnostics.

- **Circuit breaker (Resilience4j) — built, tested, live-verified.**
  Previously scoped in `resilience-scope.md` but never built; picked up
  end-to-end this session.
  - **Phase 0 (pre-build verification, not assumed)**: confirmed live
    against real Maven Central repo metadata (not the stale
    search.maven.org index) that `resilience4j-spring-boot4:2.4.0` is
    published and natively targets Spring Boot 4/Framework 7, but the
    BOM gap is still real — `resilience4j-bom` still only lists the
    `-spring-boot3` module. Evaluated and **rejected** the
    `spring-cloud-starter-circuitbreaker-resilience4j` fallback — it
    turned out to be *less* aligned (older Resilience4j module, older
    Boot 4.0.x patch line), not a safer default. Decision: pin
    `resilience4j-spring-boot4:2.4.0` explicitly, bypassing the BOM for
    that one artifact. `mvn dependency:tree -Dverbose=true` confirmed
    zero new version conflicts (Spring/Security/Jackson all resolve
    cleanly; the only 3 conflicts anywhere in the tree are pre-existing,
    unrelated test-scope noise).
  - **Two independent breaker instances**, not one shared — per
    `resilience-scope.md`'s own explicit design: `postgres-existence-
    check` and `kafka-publish`, so a Kafka-only outage can't incorrectly
    start rejecting Postgres-only-dependent requests. Wired
    programmatically (`executeSupplier()` for the synchronous Postgres
    call; manual `tryAcquirePermission()`/`onSuccess()`/`onError()` for
    Kafka's async `send()`, since its real outcome isn't known until the
    returned future completes) rather than via method-level
    `@CircuitBreaker` annotations, which can't apply two different
    breaker instances within one method. All thresholds declared
    explicitly in `application.yml` (10th instance of this project's
    now-standard "never trust an undeclared default" discipline).
  - **Unit tests**: breaker-open/half-open/closed behavior, and breaker
    independence (a Kafka-only failure never opens the Postgres
    breaker and vice versa) — 8 new/updated tests. Caught and fixed a
    real Mockito gotcha along the way (`when(...).thenReturn(...)`
    re-triggering an existing `thenThrow` stub during setup itself;
    fixed with `doReturn().when(...)`).
  - **Live verification against the real stack**: Kafka — full 3-broker
    outage, first calls hit a real synchronous `KafkaException`
    (confirming the defensive try/catch was necessary, not
    theoretical), breaker opened exactly at the configured
    threshold, every subsequent call failed fast (~32ms) with a proper
    `503`, full CLOSED→OPEN→HALF_OPEN→CLOSED recovery confirmed on
    Kafka's return. Postgres — full 3-node Patroni outage tested for
    the first time in this project's history (all prior Postgres
    testing was failover-focused, not total-outage); breaker's own
    open/close/fast-fail lifecycle confirmed correct, but this exposed
    a much more serious, unrelated bug (below).
  - **New component test with real measured latency**
    (`ReadingIngestCircuitBreakerLatencyComponentTest`): asserts real
    HTTP-level wall-clock time (not an internal breaker metric) stays
    well under a 200ms ceiling once a breaker is OPEN. 4 runs: Postgres
    breaker 5–12ms, Kafka breaker 11–24ms — both 8–40x under ceiling,
    consistent with live-stack numbers. Caught and fixed a real
    Testcontainers gotcha along the way (a container's host port isn't
    guaranteed stable across stop()/start(), but HikariCP's `DataSource`
    bean holds whatever URL it was built with at context startup and
    never re-resolves — fixed with `@DirtiesContext`). Explicitly
    documented (Javadoc + inline) that the test's own tuned-down
    thresholds are test-speed tunables only, not production-equivalent
    values — points back to `application.yml`/`ReadingServiceTest` for
    the real numbers.
  - **A significant, unrelated bug found, root-caused, and fixed along
    the way — arguably the most consequential finding of the whole
    pass**: during the first-ever total Postgres outage test, some
    requests returned a silently-fabricated `200 OK` with an empty body
    instead of an error. Root cause, confirmed against Spring Framework
    source directly: `spring-web` 7.0.8's `DisconnectedClientHelper`
    explicitly excludes `DataAccessException` from its "client
    disconnected" heuristic, but not the separate
    `TransactionException` hierarchy — so an uncaught
    `CannotCreateTransactionException` (HikariCP failing to acquire a
    connection against a dead Postgres) fell through the gap and got
    misdiagnosed as an HTTP client disconnect. Confirmed systemic, not
    caused by the circuit-breaker code, by reproducing on a plain,
    unmodified `GET /api/v1/meters`. **Fixed** in `GlobalExceptionHandler`
    by explicitly claiming both exception hierarchies, mapped to `503`,
    before Spring's ambiguous fallback path is ever reached. New
    regression test (`PostgresUnavailableComponentTest`) — required
    real iteration to get a deterministic, honest reproduction (the
    first attempt hit a different, already-safe exception variant;
    Testcontainers' single-container-stop produces a different failure
    shape than a genuine sustained multi-node outage, which the test's
    own doc comment now states plainly rather than glossing over).
    Live re-verified: 8/8 clean `503`s against a real sustained 3-node
    outage, zero fabricated `200`s, full recovery confirmed. Documented
    prominently — a full dated section in `resilience-scope.md`, plus a
    dedicated `CLAUDE.md` architectural-decision entry (not folded into
    the circuit-breaker entry) generalizing into a standing instruction:
    any future global exception handling in this project should assume
    Postgres/Kafka/Redis unavailability needs explicit exception-type
    handling, not Spring's own default fallback.
  - **Load-test tie-in (thread-pool protection under sustained
    concurrent load) — deliberately scoped, not built.** All
    verification above was sequential single-call reproduction; the
    original motivating concern from `resilience-scope.md` (protecting
    Tomcat's thread pool under sustained *concurrent* failure) remains
    untested. `resilience-scope.md`'s "Open decisions" item 4 now
    carries an explicit addendum naming this as the one still-open
    piece, with a concrete next step (a JMeter scenario driving Kafka
    into sustained failure under real concurrent load, checked against
    the existing Actuator/Micrometer Tomcat thread-pool metrics,
    following `misconfigured-spike-demo.sh`'s before/after comparison
    precedent). `CLAUDE.md`'s circuit-breaker entry carries the same
    caveat inline, so it can't be mistaken for end-to-end validated.

## Open

- **Load-test validation of circuit-breaker thread-pool protection
  under sustained concurrent failure** — scoped, not started. Named,
  concrete next step above.
- **Kafka's `external_confirm_s` secondary finding's own root cause**
  (why controller-identity correlates with slower *external* metadata
  visibility, separate from the already-refuted internal-RTO question)
  — still just a plausible, unisolated hypothesis (ISR catch-up lag or
  GC-pause noise, per `testing-strategy-ha-supplement.md`). Low
  priority, "nice to have," not a correctness gap.
- **`resilience-scope.md`'s exact new section wording** (the
  `DisconnectedClientHelper` writeup, the "What's still open"/"Scoped
  as a specific, pick-up-able follow-up" paragraphs) has not been
  independently re-verified against the live file by Chat this
  session — only `CLAUDE.md`'s two new entries were directly reviewed.
  Worth a follow-up read if precision on the doc's exact wording
  matters later.
- **Four "separate, not-yet-started tracks" from outside this session's
  scope**, status as of tonight:
  1. Circuit breaker — now done (see above), with the concurrent-load
     piece named as its own follow-up.
  2. Cloud-deployment track (`cloud-deployment-scope.md`) — content
     never reviewed this session; status unknown/unverified.
  3. k8s Kafka HA follow-up slice (3-broker StatefulSet in `kind`) —
     no supporting doc reviewed this session; existence/status
     unverified.
  4. E2E (Playwright) tier + CI wiring for load tests — confirmed
     still explicitly deferred in `testing-strategy.md`, no trigger to
     revisit either.

## Next

1. Decide whether to build the circuit-breaker load-test scenario now
   or leave it queued — no urgency signal beyond "the motivating
   question is technically still open."
2. If picking a next major thread: cloud-deployment scope and the k8s
   Kafka HA slice both need their source docs reviewed before any real
   work can start — neither has been read this session.
3. Otherwise, no further HA-effort work is currently planned; today's
   sweep and the three mechanism-hypothesis items were the last known
   loose ends from that whole effort.
