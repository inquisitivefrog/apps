# grid-meter-app — Testing strategy

Solo-owned project — no separate QA function downstream. The pyramid shape
doesn't change for that reason, but *when things run* and *who reads the
output* does. Discipline about where effort goes matters more than volume
when there's no second reviewer.

## Layers

| Layer | Tool | Scope | Runs |
|---|---|---|---|
| Unit | JUnit 5 + Mockito | Service layer logic, mocked dependencies | Every local save; every push (CI) |
| Component | JUnit 5 + Testcontainers | A service against real Postgres/Kafka/Redis (ephemeral, pinned to the versions in `tech-stack-versions.md`) | Every push (CI) |
| API | REST Assured (JVM, JUnit-integrated) + Bruno (manual/exploratory) | Black-box HTTP calls against the contract in `api-and-data-model.md` | Every push, after deploy to a throwaway Compose/`kind` environment (CI) |
| Frontend unit/component | Vitest + React Testing Library | `frontend/src/**` logic and components, colocated `*.test.ts(x)` files | Every local save; every push (CI) |
| Load | JMeter `.jmx` plans | Throughput, latency, error rate under varying load profiles | Manual trigger or nightly schedule — never blocks a PR |

## Where effort concentrates

- **Service layer** gets the heaviest unit test investment — this is where
  actual business-logic bugs live.
- **Controllers** are thin by design (see `architecture.md`) — not worth
  unit testing directly; API tests cover them for free as a side effect of
  testing the contract.
- **Readings are immutable** (see `api-and-data-model.md`) — tests should
  assert `PUT /readings/{id}` is rejected, not just that it's absent.
- **Auth** gets three test classes under `api/src/test/java/com/gridmeter/api/auth/`:
  `JwtServiceTest` (pure unit — token round-trip, expiry, tampered
  signature, wrong key), `AuthComponentTest` (extends
  `ComponentTestSupport`, real Postgres — valid/invalid login, the
  unknown-username-vs-wrong-password anti-enumeration behavior asserted as
  intentional), and `ApiSecurityComponentTest` (the one HTTP-level test in
  the suite so far — per-class `@Testcontainers`, `RANDOM_PORT`, Spring's
  `RestTestClient` since `TestRestTemplate` is deprecated in Spring Boot 4 —
  unauthenticated/invalid-token requests get `401`, actuator stays open,
  login-then-authenticated-request succeeds). All three run in the existing
  CI job (`mvn -B test`) with no workflow changes needed.
- **Frontend unit/component tests** (Vitest + React Testing Library),
  colocated as `*.test.ts`/`*.test.tsx` next to the source they cover.
  Auth-path coverage (where this frontend's actual logic lives):
  `tokenStore.test.ts` (the in-memory token store — get/set, listener
  notify/unsubscribe), `client.test.ts` (the `apiClient` request wrapper —
  Authorization header attach/omit, 401 clears the token and throws, error
  body → message mapping, 204 handling), `AuthContext.test.tsx` (`useAuth`
  via `renderHook` — login success/failure, logout), `ProtectedRoute
  .test.tsx` (redirect vs. render-through, via a real `MemoryRouter`),
  `LoginPage.test.tsx` (form submit → navigate, failed login → error
  alert, already-authenticated → immediate redirect). Page-level coverage:
  `MetersPage.test.tsx` (search re-fires on location/status filter change
  with page reset to 0, row click navigates to detail, pagination advance,
  the New Meter dialog's Create button stays disabled until required
  fields are filled, create-then-close, cancel-without-creating),
  `MeterDetailPage.test.tsx` (loading state, form pre-populates from the
  loaded meter, Save sends the edited fields and navigates back to
  `/meters`, Cancel navigates back without saving), `ReadingsPage.test.tsx`
  (search re-fires on the meter ID filter, pagination advance, and —
  mirroring the backend's "assert the PUT is rejected, not just absent"
  principle for immutability — an explicit assertion that no create/edit/
  save affordance renders anywhere on the page). `metersApi.test.ts` /
  `readingsApi.test.ts` cover query-string building for search params
  (each API module builds its own — not shared — so both get the same
  coverage). Page-level tests mock at the `api/*` module boundary (not
  the TanStack Query hooks) so the real hooks, query keys, and cache
  invalidation run for real against a fresh no-retry `QueryClient` per
  test (`src/testUtils.tsx`). `npm test` (`vitest run`) runs in the
  existing frontend CI job alongside `tsc -b`/`vite build`. **No E2E tier
  (Playwright) yet** — deferred until there's a concrete need beyond what
  component tests + manual browser verification already cover.

## API tooling

- **Bruno** for manual/exploratory testing — collections stored as plain
  text in `api/bruno/`, versioned in git, reviewable in a PR like any other
  change. Chosen over Postman specifically because it needs no cloud account
  and nothing leaves the machine.
- **REST Assured** for the automated suite that runs in CI — JVM-native, so
  it's just another JUnit test class, no separate runner to maintain. A
  shared-base-class design (`MeterApiTestBase`/`ReadingApiTestBase`, holding
  the `@Test` methods) lets two thin concrete subclasses each run the
  *identical* assertions against two different targets: `MeterApiComponentTest`/
  `ReadingApiComponentTest` (embedded server via Testcontainers +
  `RANDOM_PORT`, runs via Surefire on every push, no deployed stack needed)
  and `MeterApiIT`/`ReadingApiIT` (plain JUnit, no Spring context, points at
  `API_BASE_URL` — default `http://localhost/api/v1`, matching local
  `docker compose up` — runs via Failsafe against a real deployed stack).
  `rest-assured` 5.5.2 transitively pulls a Groovy version it doesn't
  support yet, requiring a direct Groovy 4.0.32 pin to win Maven's
  nearest-wins mediation; see `tech-stack-versions.md` for the full version
  list and upstream issue link.
- **Black-box `*ApiIT` root-cause note**: this tier was blocked for a full
  session by a `SocketException: Connection reset` that only reproduced
  through REST Assured, never through curl/raw-socket/JDK-HttpClient/plain
  Apache HttpClient probes against the identical running stack. Root cause:
  REST Assured's static `RestAssured.port` defaults to 8080 and is silently
  applied to any request URL without an explicit port, so every black-box
  request was landing on Traefik's *dashboard* port (8080, which resets
  unrecognized connections) instead of the real API on port 80 — nothing to
  do with Docker Desktop's networking, which was the leading suspicion at
  the time. Found via a `tcpdump` packet capture comparing a working probe
  against the failing one. Fixed by deriving `RestAssured.port` explicitly
  from the configured base URL in both `*ApiIT` classes; see their Javadoc
  and `scripts/README.md`'s "Diagnostic HTTP probes" section for the full
  investigation and the probe scripts it left behind.

## Load testing

JMeter test plans live in `load-tests/` and are versioned like code. Profiles
to maintain:

- **Steady state** — realistic sustained traffic, the baseline
- **Ramp-up** — gradually increasing load, to find the knee of the curve
- **Rapid spike** — sudden burst (10s ramp), to check Traefik/Tomcat
  behavior under a near-instant shock
- **Gentle spike** — the same target overload as rapid spike, reached via a
  much longer, gentler ramp (60s) instead — isolates onset speed from
  sustained overload as separate variables; see `load-tests/README.md`
  for what a real-run comparison between the two showed
- **Misconfigured for bursts** (`load-tests/misconfigured-spike-demo.sh`,
  not a distinct `.jmx` profile) — runs the identical sharp burst against
  `api` twice, once with Tomcat's properly-configured `accept-count`
  (100) and once deliberately under-provisioned (5), demonstrating why
  that queue size is a real capacity-planning knob: same load, same
  everything else, 0.00% errors vs. 7.6-8.6% (all genuine `502`s), see
  `load-tests/README.md`
- **Soak** — extended duration at moderate load, to catch slow leaks
  (connection pool exhaustion, unbounded caches)

The four `.jmx` profiles above (not the misconfigured-for-bursts scenario)
each include a **JVM warm-up phase** (`common/warmup.jmx`, 50 throwaway
requests by default) before their real measurement window starts —
standard practice for any Java performance test whose goal is a
representative steady-state average, not skewed by cold-start behavior. A
real investigation while building the misconfigured-for-bursts scenario
found this the hard way: looping the same burst repeatedly without a cold
JVM showed the error rate decaying from ~6% to under 1% purely from
JIT/warm-up effects, not from anything about the test itself. The
misconfigured-for-bursts scenario deliberately skips warm-up — its whole
point is testing a *cold* JVM's behavior, since that's the realistic
danger window (a freshly-started replica meeting a burst during
autoscaling scale-out or a rolling deploy).

Automated gates on load test runs are intentionally coarse — error rate
< 1%, a p95 latency ceiling — because interpreting *why* a run looks the way
it does needs a human watching Grafana while it runs, not a pass/fail gate
pretending to replace that.

## Test-infrastructure lesson: fixed sleeps racing unbounded readiness signals

**Confirmed as a real, recurring category of test-script bug for this
project (2026-08-28), not a one-off — three independent occurrences
found across two different technologies within the same HA testing
effort.** In every case, a test script used a fixed-duration `sleep N`
to wait for some asynchronous condition to become true, and the actual
condition took longer than `N` under real (if unremarkable) contention —
either producing a false result, or, worse, producing a correct result
for the wrong stated reason.

- **Redis Finding B** (`docs/redis-ha-scope.md`): a fixed `sleep 8` after
  topology reset was racing Sentinel's own replica-discovery poll
  (normally ~2–4s, not reliably bounded under contention). This one
  **did** produce a false verdict — a real failover was aborted
  (`-failover-abort-no-good-slave`) and misread as a defect, when the
  actual cause was the test not waiting long enough before asserting.
- **Redis Stage 5's own quorum check**: a stale quorum check reading
  ~3 seconds too early, caught while building Stage 5's chaos test
  itself, same underlying pattern.
- **Kafka `kafka-ha-demo.sh` Scenario 3**: a fixed `sleep 8` assumed to
  represent real ISR-rejoin time. Measured directly across two full
  runs: **actual rejoin time was 13–30 seconds — 2 to nearly 4x the
  assumed 8s, every single time.** This one did **not** produce a false
  verdict (the scenario's "zero client impact" result held in both
  runs) — but it meant the test's own explanation for *why* it passed
  was wrong. The corrected explanation is actually the stronger finding:
  zero client impact was demonstrated while a broker was genuinely still
  mid-rejoin, not merely after things had already quietly settled —
  direct, measured proof that `min.insync.replicas=2` provides real
  margin during a slow, in-progress recovery, not just once recovery is
  complete.

**The general lesson, worth applying to any future test-script work in
this project**: a fixed sleep after triggering an asynchronous condition
(topology reset, broker restart, leader election, replica rejoin) is
never really "waiting for X" — it's "guessing how long X usually takes."
When it guesses short, you get a false failure or a misdiagnosed defect
(as in Redis's two cases). When it guesses long enough by luck, you get
a result that happens to be correct but is unverified against the
actual condition (as in Kafka's case) — and the real margin/behavior the
test was supposed to characterize goes unmeasured and unreported.

**Standing guidance**: new chaos/failover test scripts in this project
should poll for the actual readiness condition (a specific log line, a
specific `CONFIG GET`/`SENTINEL`/`kafka-topics.sh` state, a successful
direct read) rather than sleeping a fixed duration and assuming success,
even when the fixed duration "usually works." Where a fixed wait is
kept for simplicity, report the actual measured convergence time
alongside the pass/fail result (as `kafka-ha-demo.sh`'s Scenario 3 now
does) rather than only the boolean outcome — the real number is often
the more useful finding, as it was here.

**Not yet audited**: `kafka-ha-demo.sh`'s Scenario 2 (20s recovery-wait —
checked and ruled out; those records are discarded client-side by
`delivery.timeout.ms` expiry during the outage, independent of the
post-recovery wait duration) and Scenario 1 (5s pre-send sleep — lower
risk, since the script already treats `S1_FAIL` skeptically rather than
asserting a blind pass on it). Both reviewed and closed as part of this
same pass, not left as open questions.

## Test-infrastructure lesson: GNU-vs-BSD tooling assumptions in local chaos scripts

**A third named, recurring category of test-script bug for this project
(2026-08-31), distinct from the two above.** Development happens on
macOS, whose bundled command-line tools are BSD-derived and differ from
the GNU/Linux tools these scripts are usually written against by habit —
and unlike a missing command (a loud, obvious failure), a GNU-only flag
silently accepted by a differently-behaving BSD tool can fail quietly,
producing wrong output instead of an error. Two confirmed instances so
far, same root cause, different specific shape:

- **`timeout`/`gtimeout` don't exist on this Mac at all**
  (`docs/postgres-ha-scope.md`'s Stage 0) — a write-refusal check silently
  became a no-op (fails open, the worst variant: it can mask a total
  absence of verification, not just add imprecision). Fixed by removing
  the dependency entirely once it was confirmed unnecessary (Consul fails
  fast with a real `500` on quorum loss). A repo-wide audit at the time
  found no other real instances (remaining `timeout` grep hits were
  false positives — config-parameter names like `failover-timeout`).
- **`date +%3N` silently misparses** (found 2026-08-31 building
  `docs/postgres-ha-scope.md`'s Stage 3 script) — this Mac's `date`
  supports bare `%N` (real nanosecond precision) but not GNU's
  field-width digit-prefix modifier; `%3N` produces the literal
  characters `3N` appended to the seconds value instead of milliseconds.
  The consequence was worse than a wrong number: the resulting bash
  arithmetic error, occurring inside a `for` loop's `then` branch,
  silently terminated the loop after its first iteration while the
  script's own post-loop summary line still printed "5/5 succeeded" —
  a **false positive on the exact behavior the test existed to verify**
  (whether repeated writes succeed during an outage), not merely a
  cosmetic timing glitch. The identical broken idiom was found already
  committed in `load-tests/kafka-acks-gap-repro.sh` (a secondary
  diagnostic print there, not the separately-reported and unaffected
  3.7s Kafka RTO figure) and in cosmetic-only form (no arithmetic, just
  a garbled printed timestamp) in `scripts/capture-connection-reset.sh`
  — all three fixed the same way: bare `%N`, with any needed unit
  conversion done explicitly via division rather than a width-modifier
  flag. A repo-wide audit for other GNU-only flags (`sed -i` without a
  BSD-style extension argument, `date -d`, `stat --format`/`-c`,
  `grep -P`, `md5sum`, `base64 -w`, `readlink -f`) found no further
  instances.

**The general lesson**: assuming a script's target execution environment
shares a Linux/GNU toolchain's exact flag semantics — rather than the
BSD-derived tools actually bundled with macOS — is a real, standing risk
for any local (not containerized) shell script in this project, and the
failure mode ranges from a loud missing-command error (easy to notice)
to a silently-wrong result (hard to notice, and in the `date +%3N` case,
actively misleading about the very thing being tested). Two independent
hits from the same root cause is enough to treat this as a standing
category, the same way the undeclared-default and fixed-sleep patterns
were promoted after repeating.

**Standing guidance**: any new local shell script that shells out to
`date`, `sed`, `stat`, `grep`, `timeout`, or similar coreutils-family
tools should be checked against this Mac's actual (BSD-derived) tool
behavior before being trusted, not assumed to match GNU/Linux semantics
from habit or from an online example. Prefer flags confirmed portable
across both (bare `date +%N`, `sed -i ''` with an explicit empty
extension argument, avoiding `-P`/`-d`/`--format` entirely) over
GNU-specific shorthand, even when a GNU-only form would be more
convenient to write.

## CI wiring (GitHub Actions)

All three jobs below run on every push/PR touching `grid-meter-app/**`
(`.github/workflows/grid-meter-app-ci.yml`). `test`, `black-box-api-test`,
and `frontend-test` are all required status checks on `main`'s branch
protection — `frontend-test` was promoted on 2026-08-24 after confirming a
clean run across the prior 10 CI runs (including two where the overall
workflow failed due to the other jobs, not this one).

1. **`test`** ("Unit + component tests") — `mvn -B test`, blocks merge on
   failure (required check).
2. **`black-box-api-test`** ("Black-box API tests (deployed stack)") —
   brings up a throwaway Docker Compose stack via
   `scripts/run-black-box-api-tests.sh`, runs the Failsafe-bound `*ApiIT`
   suite against it, tears the stack down. Blocks merge on failure
   (required check).
3. **`frontend-test`** ("Frontend typecheck, tests, build") — `npm test`
   (Vitest) + `tsc -b`/`vite build`. Required check as of 2026-08-24.
4. Load tests — `workflow_dispatch` (manual) or nightly `schedule`, results
   posted for review, does not block anything. `load-tests/` (JMeter plans:
   `steady-state`/`ramp-up`/`rapid-spike`/`gentle-spike`/`soak`, see
   `load-tests/README.md`) now exists and is runnable locally via
   `load-tests/run.sh`; CI wiring itself is still a follow-up.
