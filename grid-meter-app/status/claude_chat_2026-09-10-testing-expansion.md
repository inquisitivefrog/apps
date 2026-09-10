# grid-meter-app — Status: 2026-09-10 (Claude Chat) — Testing expansion scope

Separate thread from today's earlier k8s Redis Sentinel review session
(see `status/claude_chat_2026-09-10.md`). This session started fresh from
a docs review, then moved into scoping and kicking off a new body of work:
closing the soak/leak-detection gap, promoting HA proof scripts to real
regression coverage, and building the multi-tenant blast-radius demo. Paused
mid-build for the day, with Part 1 partially landed and pushed.

## Done

- **Reviewed the full doc set** (architecture, data model, all `*-ha-scope.md`
  docs, `testing-strategy.md`, `testing-strategy-ha-supplement.md`,
  `resilience-scope.md`, `multi-tenancy-scope.md`, `observability-taxonomy.md`,
  `vendor-bug-report-process.md`, and the 2026-09-06 through 09-10 status
  logs from both Chat and Code) to come up to speed after a checkpoint.
  Note: five of the uploaded docs weren't fully visible in the chat context
  and had to be read directly off disk to get accurate content
  (`postgres-ha-scope.md`, `redis-ha-scope.md`, `resilience-scope.md`,
  `testing-strategy-ha-supplement.md`, `testing-strategy.md`) — worth
  remembering if this happens again.

- **Reconciled a user-recalled list of "still open" tasks against the actual
  docs.** Of five items recalled: the k8s Kafka HA slice was actually
  **done**, not open (closed 2026-09-06); the cloud-deployment decision's
  blockers are cleared (both Kafka and Redis k8s HA closed) but the decision
  itself hasn't moved; the `external_confirm_s` root-cause investigation is
  open but deliberately bounded (localized to a `ListPartitionReassignments`
  stall, not chased into KRaft internals, per Chat's own prior scope call);
  the circuit-breaker concurrent-load test is confirmed still open, not
  started; the full-cluster-Postgres-outage scenario's substance was
  actually exercised live on 2026-09-04 (found and fixed the fabricated-`200`
  bug) but the formal named `chaos-demo.sh` case was never built and
  silently dropped off every "carried forward" list after 2026-09-06 — a
  real bookkeeping gap, not a decision either way.

- **Worked through a memory-leak/soak-testing line of inquiry** prompted by
  a real past incident (an unclosed Java object accumulating over a weekend
  run). Established: static analysis (SpotBugs/fb-contrib) only catches the
  narrower unclosed-`Closeable` category, not unbounded-cache/collection
  growth; JMeter is being used correctly (API-level load, not UI rendering)
  but `soak.jmx` has never been run at anywhere near leak-detection
  timescale; identified the JWT-TTL wall as a hard blocker on any extended
  run; distinguished time-based vs. volume-based leak framing as a
  consequential decision that changes whether a multi-day run is even
  necessary.

- **Worked through a multi-tenancy expansion line of inquiry**, grounded in
  a real prior corporate use case (per-company customers, annual contracts,
  outage-driven discounting). Landed on: expand seed data from 1 customer to
  10 with realistic acquisition-date and usage skew; actually build the
  blast-radius query that `multi-tenancy-scope.md` only ever designed on
  paper; demo it against two contrasting scenarios — killing one-of-three
  at the data tier (HA protects, blast radius = 0) versus killing Traefik
  (a single point of failure `ha-scope.md` already names as deliberately
  out of scope for HA, blast radius = everyone) — plus a frontend-kill
  scenario proving the SPA has no role in the ingest path, and a negative
  control via seeded dormant customers.

- **Also folded in a smaller UI load-testing gap**: confirmed JMeter's
  API-only scope is intentional and normal (it doesn't render a DOM); the
  frontend does have real test coverage (Vitest/RTL unit/component tests,
  a Playwright E2E tier added 09-08) but none of it is load testing;
  Nginx serving the static SPA build under concurrent load has never been
  exercised at all.

- **Wrote `docs/testing-expansion-scope.md`**, consolidating all of the
  above into one scope doc (Why this doc exists → four parts, each with
  reasoning → deliverables table → 5 explicit open decisions → suggested
  build order), matching this project's existing `*-scope.md` convention.

- **Claude Code reviewed the doc**, verified one factual claim against the
  live codebase before treating it as settled (confirmed
  `PostgresUnavailableComponentTest` is already in the CI-required `mvn
  test` tier, closing Part 2 item 2 as anticipated), and surfaced the 5
  flagged open decisions for sign-off via an interactive elicitation flow.

- **All 5 decisions resolved**:
  1. Soak leak framing (§1.2): **volume-based/accelerated**, not
     time-based — no specific time-driven suspect was ever named, and the
     originally-recalled leak (repeated-task object accumulation) is
     structurally volume-shaped.
  2. HA regression failure policy (Part 2): **auto-file a GitHub Issue** on
     nightly failure, non-blocking, per the project's existing
     Issues-for-bug-tracking convention.
  3. Seed customer naming (§3.1): **synthetic company names**, not generic
     "Customer A–J" labels — reads better for an interview demo.
  4. UI load-test timing (§4.1): **build alongside Part 3**, not batched
     separately later — it's cheap and has no dependencies.
  5. JFR timing (§1.4): defaulted to the doc's own recommendation
     (**defer** until the heap-trend metric actually signals a leak worth
     diagnosing) — no objection raised.
  - Doc updated in place with the resolved decisions; Claude Code set up
    an 11-item task list (#7–17) to work through the doc's stated build
    order.

- **§1.1 built and live-verified**: `soak.jmx` gained a concurrent "token
  refresh" Thread Group that re-runs the login fragment on an interval,
  overwriting the shared `${__P(accessToken)}` JMeter property that every
  request already reads fresh on each call — no per-thread token-passing
  needed. Caught and fixed one real bug before testing:
  `TestPlan.serialize_threadgroups` was `true`, which would have run the
  new group sequentially *after* soak load finished instead of
  concurrently — silently defeating the whole point. Also cleaned up an
  invalid raw XML comment (contained `--`, invalid per the XML spec) in
  favor of this project's existing convention of `stringProp` comment
  fields. **Functionally verified**, not just XML-validated: a 60s
  accelerated run (15s re-auth interval, 5 threads) showed the token-refresh
  group firing 3 logins at 15s/30s/45s exactly as configured, running
  genuinely concurrently with soak load (confirmed via
  `serialize_threadgroups=false` actually taking effect), and all 1395
  `POST /readings` samples across the run succeeded (0% errors) — the
  shared-property refresh never disrupted live traffic.

- **§1.3 built and live-verified**: a new Prometheus alert rule in
  `observability/alerting/rules.yml`, tracking heap **after major GC
  events** rather than raw heap, phrased as a projected-exhaustion trend
  per the existing resource-capacity-trend category in
  `observability-taxonomy.md`. Verified the GC pool label name against the
  live running JVM rather than guessed. Confirmed the rule provisions into
  Grafana (the alerting rules file is directly mounted into Grafana's
  provisioning path) and evaluates cleanly (`Normal`, 0% projected slope,
  correctly reflecting that no major GC had occurred yet during the short
  verification run) — end-to-end verified, not just YAML-valid.

- **One incidental environment scare, resolved without incident**: bringing
  the stack up for soak testing found a partial stack already running
  (some but not all of consul/kafka/patroni's usual instances) that hadn't
  been started this session. Checked GitHub's API for an in-progress
  self-hosted workflow run before touching anything, per the project's
  standing caution about colliding with CI-owned state; found none
  in-progress, but rechecked once more before acting rather than trusting
  the first read. Confirmed it was a same-day E2E workflow's teardown still
  settling — resolved itself, environment was genuinely clean.

- **Committed** (`2dbc21f`): `soak.jmx`'s re-auth Thread Group, the new
  heap-trend alert rule, and `docs/testing-expansion-scope.md`'s
  resolved-decisions update, all in one batch. **Pushed to `origin/main`**
  per explicit confirmation.

## Open / paused for the day

- **Task #9 (§1.2 validation) was chosen as the next step but not started
  before pausing.** The plan: now that §1.1 (re-auth) and §1.3 (heap-trend
  detection) are both landed, run a genuinely longer accelerated
  volume-based soak (not just the 60s smoke test used to verify §1.1/§1.3
  individually) to confirm the combination holds up — i.e., that a real
  extended run stays clean on both error rate and heap trend, not just that
  each mechanism works in isolation.
- Tasks #10–17 (the rest of the doc's build order — Part 3's seed
  migration/blast-radius demo, Part 2's HA regression promotion, §4.1's
  Nginx load profile) are queued but untouched.
- Today's earlier, separate Redis Sentinel review session (see
  `status/claude_chat_2026-09-10.md`) is fully closed and unrelated to this
  thread.

## Next

1. Resume with task #9: run a longer accelerated volume-based soak,
   confirming §1.1 (no 401 bursts) and §1.3 (heap-trend alert stays
   `Normal` or correctly fires if something's actually wrong) hold together
   over a real extended duration, not just the short smoke-test window.
2. Continue down the doc's stated build order from there: §3.1 (seed
   migration) → §3.2 (blast-radius query) → §3.3/§3.4 (Scenario A/B kill
   tests with negative control) → §3.6 (frontend-kill) → Part 2 (HA
   regression promotion wiring) → §4.1 (Nginx load profile) → §1.5 (static
   analysis, no dependencies, can slot in any time).
