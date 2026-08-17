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
  it's just another JUnit test class, no separate runner to maintain.

## Load testing

JMeter test plans live in `load-tests/` and are versioned like code. Profiles
to maintain:

- **Steady state** — realistic sustained traffic, the baseline
- **Ramp-up** — gradually increasing load, to find the knee of the curve
- **Spike** — sudden burst, to check Traefik/Tomcat behavior under shock
- **Soak** — extended duration at moderate load, to catch slow leaks
  (connection pool exhaustion, unbounded caches)

Automated gates on load test runs are intentionally coarse — error rate
< 1%, a p95 latency ceiling — because interpreting *why* a run looks the way
it does needs a human watching Grafana while it runs, not a pass/fail gate
pretending to replace that.

## CI wiring (GitHub Actions)

1. Unit + component tests — every push, blocks merge on failure
2. API tests — every push, after bringing up a throwaway environment,
   blocks merge on failure
3. Load tests — `workflow_dispatch` (manual) or nightly `schedule`, results
   posted for review, does not block anything
