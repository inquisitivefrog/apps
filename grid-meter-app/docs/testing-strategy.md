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
- **No frontend testing tier exists yet.** `frontend/` has TypeScript
  compilation (`tsc -b`, catches type errors) and a real Vite production
  build as its only current checks — no unit tests (Vitest), no
  component tests (Testing Library), no E2E (Playwright). This is an
  honest gap, not an oversight: worth adding before the frontend grows
  past its current handful of pages, but out of scope for the auth/scaffold
  work that introduced it.

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
