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
- **Soak** — extended duration at moderate load, to catch slow leaks
  (connection pool exhaustion, unbounded caches)

Automated gates on load test runs are intentionally coarse — error rate
< 1%, a p95 latency ceiling — because interpreting *why* a run looks the way
it does needs a human watching Grafana while it runs, not a pass/fail gate
pretending to replace that.

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
