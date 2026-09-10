# grid-meter-app — Testing expansion scope: leak detection, HA regression coverage, multi-tenant blast-radius demo

## Why this doc exists

Four related but separately-motivated gaps surfaced together in one review
session and are consolidated here rather than left scattered across chat
history, per this project's own convention of writing a durable scope doc
before scaffolding (`CLAUDE.md`):

1. **Soak testing can't currently catch the memory-leak failure mode it was
   built for** — a real gap found by asking what `soak.jmx` actually proves
   versus what it claims to.
2. **HA findings are proven once, not protected going forward** — the
   extensive Kafka/Redis/Postgres HA investigations produced real fixes and
   one-time proof, but almost none of that work blocks CI if a fix later
   regresses.
3. **Multi-tenancy is real in the schema but inert in the demo** —
   `Customer`/`customerId` exist and propagate correctly, but the
   blast-radius reporting query they were built to enable was only ever
   designed on paper (`multi-tenancy-scope.md`), never built or exercised
   against real multi-customer traffic.
4. **The UI has never been load-tested** — a smaller, lower-priority gap
   found while confirming JMeter's API-only scope was intentional (it is).

Each part below can be picked up independently, but Part 1's two mandatory
items block all soak work, and Part 3 depends on nothing from Parts 1–2.

---

## Part 1 — Soak / leak-detection testing

### 1.1 JWT re-authentication in `soak.jmx` — mandatory, blocks everything else in this part

**Current state**: `soak.jmx` logs in once at the start. The JWT has a
60-minute TTL, no refresh token. A real 1-hour run already surfaced this
live: all 105 errors were a 401 burst exactly at the 60-minute mark. Since
the thread group continues on error, any run pushed past an hour doesn't
just show that burst once — it spends the rest of the duration hammering a
rejected-login path instead of real ingestion traffic.

**Fix**: add periodic re-authentication — a controller that re-issues
`POST /auth/login` on an interval comfortably under 60 minutes (e.g. every
45 min) and refreshes each thread's stored token, rather than authenticating
once at setup.

**Validate**: re-run the existing 1-hour baseline, confirm the 401 burst is
gone and error rate stays at the prior 0.031% baseline.

### 1.2 Decide the leak framing before sizing any run

Two structurally different failure modes hide under "memory leak," and they
need different test designs:

- **Time-based** — grows regardless of traffic (a scheduled task, a timer,
  something that fires on a clock). Genuinely needs long wall-clock
  duration; no way to compress it.
- **Volume-based** — grows with requests processed (an unclosed resource
  per request, a cache keyed by request data that never evicts). Can be
  reproduced by running a much shorter, much higher-throughput soak —
  same accumulated object count, a fraction of the wall-clock exposure.

**Recommendation**: default to volume-based/high-throughput framing unless
there's a specific time-driven suspect already named, since it's far more
practical on this hardware and doesn't require an unattended multi-day run
at all. Needs explicit sign-off either way (see Open Decisions).

### 1.3 Automated leak-detection signal — the real blocking prerequisite

**Status (2026-09-10): built** — `observability/alerting/rules.yml`'s
`heap-after-gc-trend` rule. Verified live: provisioned into a running
Grafana without error, then polled until it left its initial `NoData`
startup state and settled into `Normal` (0% projected slope, correctly
reflecting that this JVM hasn't run a major GC yet — no false signal from
a flat/empty series). See "Fix" below for the metric choice and its
live-confirmed rationale.

**Current state**: `soak.jmx`'s own header comment says outright to "watch
JVM heap trend... in Grafana over the full run" — the design assumes a
human is watching live. Nobody watches an unattended weekend run at 3am,
and even a shorter accelerated run shouldn't depend on someone staring at a
dashboard.

**Fix**: add a Prometheus query/alert following the existing
**resource-capacity trend** category already defined in
`observability-taxonomy.md` — track heap **after major GC events**
specifically (not raw heap, which oscillates with allocation/collection
noise) and phrase it as a slope toward a projected exhaustion point, not a
hard threshold. This is what actually turns "ran for N hours without
crashing" into "provably didn't leak," and it's needed before any extended
run is worth executing. Implementation note: this app's JVM was assumed to
be running G1 (Java's modern default) until checked live against a real
`/actuator/prometheus` scrape — it's actually Serial GC (`gc="Copy"`,
pool id `"Tenured Gen"`, not `"G1 Old Gen"`), a JVM ergonomics choice
driven by the small `-Xmx384m` heap (`docker-compose.yml`). The rule uses
Micrometer's `jvm_gc_live_data_size_bytes`/`jvm_gc_max_data_size_bytes`,
which track old-gen size after a full/major GC under either collector, so
this doesn't need revisiting if the heap size or GC choice changes later —
still worth recording as another instance of this project's standing
"verify the live system, don't assume the default" pattern (`CLAUDE.md`).
Without this rule, even a clean multi-hour soak run proves nothing more
than "didn't crash," which was never in doubt.

### 1.4 JFR recording — root-cause layer, build if a leak is actually found

Attach Java Flight Recorder to the API container during soak runs —
built into the JDK, near-zero overhead. Pair with Eclipse MAT for offline
heap-dump diffing if the trend metric in 1.3 actually fires. This answers
*what's* accumulating and *what's holding the reference*, which the trend
metric alone can't. Lower priority than 1.1–1.3: only worth building once
there's a real signal to investigate, not preemptively.

### 1.5 Static analysis — cheap, narrow, add regardless

Add SpotBugs + fb-contrib (or Error Prone's `MustBeClosedChecker`) to CI.
This catches a real, distinct category — an unclosed `Closeable`/
`AutoCloseable` not wrapped in try-with-resources — cheaply and at compile
time. **Explicitly does not catch** the unbounded-cache/growing-collection
leak class this whole effort is really aimed at (whether a collection's
size stays bounded across a million iterations is a property of runtime
behavior, not code structure — not generally statically decidable). Worth
adding anyway as a cheap first filter; don't treat it as closing the real
gap.

### 1.6 Traffic-mix realism — optional, low priority

Current `soak.jmx` (like all five load profiles) exclusively hammers
`POST /readings`. This is a **deliberate, defensible** choice — isolating
the most resource-intensive path (Kafka producer → consumer → Postgres +
Redis) — not an oversight. A mixed-traffic variant (weaving in
`GET /meters`, `GET /readings` search) would be more realistic but isn't
required to catch the leak class this effort targets. Defer unless there's
spare capacity after the items above.

---

## Part 2 — HA regression coverage: promote proof to protection

**Current state, confirmed against `testing-strategy.md`'s own CI wiring
section**: unit/component/API tests (`mvn -B test`, the Failsafe `*ApiIT`
tier) are required CI checks and block merge. Everything in
`load-tests/` — every HA kill-test script (`kafka-ha-demo.sh`,
`redis-*-test.sh`, `postgres-*-test.sh`) and every JMeter load profile —
runs only via manual `workflow_dispatch` or nightly schedule, and per the
doc's own words, "does not block anything." The real HA investigations
(Kafka's unlabeled unclean election, Redis's split-brain fix, Postgres's
fabricated-`200` bug) each produced a genuine one-time proof that a fix
works — almost none of that is protected against a future regression.

**Decision needed first**: does a nightly failure today actually get
triaged by anyone, or does it sit in a log nobody reads? Confirm this
explicitly before promoting anything — promoting scripts into a pipeline
nobody watches doesn't add real protection.

**Promotion priority** — favor scripts where a regression would be
**silent** (wrong status code, split-brain, data loss with no error) over
ones where it would be **loud** (a crash, an obvious failure), since loud
regressions tend to get noticed by accident and silent ones don't:

1. Redis split-brain fix — the Stage 4 reproduction / the fixed
   `redis-entrypoint.sh` flags-gate logic. Highest priority: this is the
   textbook silent-regression case.
2. Postgres fabricated-`200` fix — confirm `PostgresUnavailableComponentTest`
   is genuinely in the CI-required `mvn test` tier already (it should be,
   per `resilience-scope.md`) rather than living in `load-tests/`; if it's
   already CI-enforced, this item is closed, just confirm it.
3. Kafka kill-test zero-failure invariant (`kafka-ha-demo.sh`) — promote
   the pass/fail assertion (zero request failures across a kill window),
   not the full script's exploratory output.

**For each promoted script**: define a clear, machine-readable pass/fail
signal (not "eyeball the log output"), wire into the nightly workflow, and
decide alerting policy explicitly. Recommendation: on failure, auto-file a
GitHub Issue via this project's existing Issues-for-bug-tracking
convention rather than blocking PRs — these are environment-dependent
chaos tests, not appropriate as merge gates, but a failure should produce
something a person actually sees.

---

## Part 3 — Multi-tenant blast-radius demo

### 3.1 Seed data expansion: 1 → 10 customers

New Flyway migration (next available version after the existing `V4`).
Ten `Customer` rows, replacing/extending the single seeded "Default
Customer":

- **Staggered `createdAt`** — a few early-adopter customers, most
  mid-cohort, one or two recent, reflecting a normal acquisition spread
  rather than everyone onboarding on the same day.
- **Skewed meter/usage distribution** — 2–3 heavy-usage customers (many
  meters, frequent submissions), most light/moderate, **1–2 genuinely
  dormant** (zero active traffic during any demo scenario). The dormant
  customers are not filler — they're the built-in negative control for
  3.5 below.
- Confirm `customerId` propagation (JWT claim, Loki MDC field, Tempo span
  attribute) actually holds up at this scale — the only prior verification
  was the 2-customer component-test fixture, never real seeded data at 10.

### 3.2 Build the blast-radius query for real

`multi-tenancy-scope.md` already designed this shape (a Loki query grouped
by `customerId`, counting distinct `userId`/`meterId` within an incident's
firing window) but it has never been implemented as a runnable artifact.
Build it as an actual Grafana panel or saved Loki query, parameterized by
time window. It must correctly return an **empty set** when queried against
a window with no correlated failures — this is the mechanism the negative
control in 3.5 depends on, not an incidental nice-to-have.

### 3.3 Demo Scenario A — HA protected you (blast radius = 0)

Kill one of three Kafka brokers / Redis nodes / Postgres replicas while
quorum holds — reusing an already-proven kill test. Drive correlated
traffic from a known subset of the 10 seeded customers' meters through the
kill window.

**Expected outcome**: a failover/scale-event **notice** fires (per
`observability-taxonomy.md`'s existing taxonomy — not an incident), zero
request failures (matching every prior kill-test result), and the
blast-radius query returns **zero customers** for the window.

This is the concrete demo of the annual-contract framing: an outage notice
exists in the system's own records, but nobody qualifies for a discount,
because HA delivered exactly what it's supposed to.

### 3.4 Demo Scenario B — a downstream single point of failure doesn't care about your HA (blast radius = all active customers)

Kill the single Traefik instance. This is not hypothetical — `ha-scope.md`
already names Traefik explicitly as a deliberate, out-of-scope-for-HA
single point of failure (redundancy would need keepalived/VRRP and a
floating virtual IP, which has no home on a single-laptop deployment).
Drive the same correlated per-customer traffic used in Scenario A.

**Expected outcome**: a real **incident alert** fires (`API is down`),
100% request failure for every customer with active traffic during the
window, and the blast-radius query returns **every one of them** —
demonstrating that the data tier's carefully-built HA is entirely
irrelevant once the edge tier in front of it is gone.

Run back-to-back with Scenario A using the same query and the same
customer population, so the contrast is direct: identical tooling, opposite
outcome, because the failure happened at a different layer.

### 3.5 Negative control (both scenarios)

Assert the dormant customers seeded in 3.1 **never** appear in either
scenario's blast-radius result, regardless of which component failed. This
is what actually proves the query is correlating real impact rather than
just returning "everyone" or "everyone with any data ever" — without it,
"the query works" is an assumption, not a verified fact, which this project
has a standing habit of not accepting (see the HikariCP and Kafka-outage
investigations, both of which checked real behavior rather than trusting
it).

### 3.6 Frontend-kill scenario — decoupling proof, smaller addition

Stop the frontend/Nginx container specifically — not Traefik, not a
data-tier node. Drive continuous `POST /readings` directly through
Traefik → API. Confirm 100% ingestion success and correct Postgres landing
throughout; confirm `/` genuinely fails (proving the isolation is real, not
assumed); bring the frontend back; confirm recovery.

This demonstrates a real structural fact worth proving rather than just
asserting: the frontend has no role in the ingest path at all (meters/
JMeter submit directly to the API; the SPA is a read-only dashboard on a
fully independent route). Not paired with the blast-radius query — frontend
health isn't customer-differentiated the way an outage of a data-tier
component is. Add as a standalone scenario alongside the existing chaos
family (`chaos-demo.sh`, `kafka-ha-demo.sh`, etc.), not folded into A/B.

---

## Part 4 — UI load-testing gap

Two distinct gaps found while confirming JMeter's API-only scope was
intentional (it is — JMeter operates at the HTTP/protocol level and
doesn't render a DOM; load-testing actual UI rendering needs a different
tool class). Different priority:

1. **Nginx static-asset serving under concurrent load** — never tested;
   all five JMeter profiles target `/api/*` exclusively, none ever hit `/`.
   Cheap to add: a small JMeter (or even `ab`/`hey`) profile driving
   concurrent requests at `/`, checking response time/error rate.
   **Recommend adding** — low cost, closes a real blind spot.
2. **Client-side React rendering performance under load** (large datasets,
   many concurrent sessions) — a genuinely different, heavier tool
   investment (k6's browser module or Playwright-under-load). **Recommend
   naming as a known, deliberately-not-built gap** rather than building it
   now, unless UI performance becomes an actual focus of the demo.

---

## Deliverables summary

| Item | Artifact |
|---|---|
| 1.1 | `soak.jmx` re-auth controller |
| 1.3 | Prometheus heap-after-GC trend query/alert |
| 1.5 | SpotBugs/fb-contrib CI step |
| 2 | Promoted pass/fail checks for Redis/Postgres/Kafka HA scripts + nightly-failure alerting policy |
| 3.1 | New Flyway seed migration, 10 customers |
| 3.2 | Blast-radius Grafana panel / saved Loki query |
| 3.3–3.5 | Scenario A + Scenario B kill-test scripts, with negative-control assertions |
| 3.6 | Frontend-kill chaos scenario script |
| 4.1 | Nginx concurrent-load JMeter profile |

## Open decisions needing explicit sign-off

**All five resolved (2026-09-10), user sign-off via Claude Code:**

1. ~~**Soak leak framing** (§1.2)~~ — **Resolved: volume-based/accelerated**,
   per the recommendation. §1.1/§1.3 sized accordingly — no unattended
   multi-day run required.
2. ~~**HA regression promotion policy** (Part 2)~~ — **Resolved: auto-file a
   GitHub Issue** on nightly failure, per the recommendation. Does not
   block PRs.
3. ~~**JFR integration timing** (§1.4)~~ — **Resolved: defer** until §1.3's
   trend metric actually signals a problem worth diagnosing, per the
   recommendation. Not built this pass.
4. ~~**Seed customer naming/shape** (§3.1)~~ — **Resolved: synthetic company
   names** (e.g. "Acme Utilities"), not generic "Customer A"–"Customer J".
   Meter-count skew follows §3.1's own stated shape (2–3 heavy, most
   light/moderate, 1–2 dormant) without further sign-off needed.
5. ~~**UI load-test gap #1** (§4.1)~~ — **Resolved: build alongside Part 3**,
   not batched separately.

## Suggested build order

1. §1.1 (JWT re-auth) + §1.3 (heap-trend metric) together — mandatory,
   unblocks everything else in Part 1, and makes any future soak run
   actually mean something.
2. §3.1 (seed migration) + §3.2 (blast-radius query) — foundational for all
   of Part 3.
3. §3.3 → §3.4 (Scenario A, then B) with §3.5 (negative control) built in
   from the start, not bolted on after.
4. §3.6 (frontend-kill).
5. Part 2 (HA regression promotion) — policy decision first, then wiring.
6. §4.1 (Nginx concurrent load).
7. §1.5 (static analysis) — no dependencies on anything above, can slot in
   any time.
8. §1.4 (JFR) — only if/when §1.3's trend metric actually signals a leak.
