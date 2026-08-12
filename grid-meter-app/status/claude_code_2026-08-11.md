# grid-meter-app — Status: 2026-08-11 (Claude Code)

Done:
- Restructured session status reporting: status is no longer appended inline
  to CLAUDE.md (which would grow unboundedly and dilute the standing
  instructions it's supposed to hold). Created `status/`, archived the two
  prior inline blocks as `status/claude_chat_2026-08-07.md` and
  `status/claude_chat_2026-08-10.md`, and left a short pointer in CLAUDE.md.
  Naming convention going forward: `claude_chat_<date>.md` for sessions run
  via Claude Chat, `claude_code_<date>.md` for sessions run via Claude Code.
- Verified `docker compose up -d` after a Docker Desktop restart — all 11
  services came back healthy, no lingering issues from the restart.
- Cleaned up Claude Code permissions: found the existing `.claude/
  settings.local.json` at the `apps/` git root was cluttered with brittle
  one-off literal entries (exact curl calls with hardcoded UUIDs, one-off
  echo strings) that wouldn't match future invocations. Ran the
  `fewer-permission-prompts` skill and created a new, **committed**
  `apps/.claude/settings.json` (repo-wide, applies to all Java apps in this
  monorepo, not just grid-meter-app) with 9 curated, safe patterns (`mvn
  test*`, `mvn -q -DskipTests*`, `mvn dependency:tree*`, `mvn
  help:effective-pom*`, `docker compose logs/ps/up -d/build *`).
  Deliberately did NOT allowlist `mvn *` or `docker compose *` broadly (both
  can execute arbitrary commands via specific goals/subcommands — `exec:*`/
  `antrun:run` for Maven, `exec`/`run` for Compose), nor `docker volume rm`/
  `docker compose down` (destructive), nor a `curl` localhost wildcard
  (transcripts mixed read-only GETs with data-mutating POSTs). Left
  `settings.local.json` (personal, gitignored) untouched.
- **Wrote the first real Testcontainers-backed component tests**, per
  docs/testing-strategy.md's planned layering (Testcontainers blocker was
  resolved in the prior Claude Chat session):
  - `support/ComponentTestSupport.java` — shared base class starting real
    Postgres 18.4 / Kafka 4.3.1 / Redis 8.10 (via GenericContainer — no
    official Testcontainers Redis module exists) once per JVM run via a
    static initializer (the "singleton container" pattern), not
    `@Testcontainers`/`@Container`, since that annotation pair would tear
    the container down after the first test class and break the next one.
  - `MeterComponentTest` (8 tests) — create/find/search/update/delete
    against real Postgres, including the unique-serial-number constraint
    (a real DB-level check a mocked test can't catch).
  - `ReadingComponentTest` (6 tests) — the full async path: ingest →
    Kafka → `ReadingEventConsumer` → Postgres write + Redis cache, polled
    with Awaitility (added as a new test dependency, v4.3.0, verified
    current on Maven Central) rather than `Thread.sleep`. Deliberately does
    NOT test PUT-rejection — that's an HTTP-level (405) concern for the
    future REST Assured API test layer, out of scope for this
    service-level component suite.
  - `mvn test`: 15 new tests + the existing smoke test, all green, exit 0.
- **Found and fixed a real production bug via the new tests**: `RedisConfig`'s
  `GenericJacksonJsonRedisSerializer` never enabled default typing, so any
  read through the generic `RedisTemplate<String, Object>` silently
  deserialized as a raw `LinkedHashMap` instead of its real class — a
  `ClassCastException` waiting to happen in real usage, not just in the
  test. Fixed with `enableDefaultTyping()` scoped to a
  `BasicPolymorphicTypeValidator` trusting only `com.gridmeter.api.reading`
  + `BigDecimal`, mirroring the existing Kafka `spring.json.trusted.packages`
  trust boundary, instead of the unsafe blanket-typing option.
  - Side discovery while chasing this: Spring Boot 4.1 runs **two Jackson
    generations side by side** on this classpath — the classic
    `com.fasterxml.jackson` 2.21.4 line (our explicit `jackson-databind`
    dependency) and a newer `tools.jackson` 3.1.4 line (pulled in
    transitively via `spring-boot-jackson` for some newer Spring
    integrations, including this Redis serializer). Not currently causing
    problems elsewhere, but worth remembering if a future Jackson-related
    error references an unfamiliar package.
- **Stood up the first real CI pipeline** (`.github/workflows/
  grid-meter-app-ci.yml`, repo root, matching the existing path-filtered
  convention of `claude-code-review.yml`/`claude.yml`): runs `mvn -B test`
  (Java 25 Temurin, Maven-cached) on push/PR touching `grid-meter-app/**`,
  plus `workflow_dispatch` for manual runs. Covers testing-strategy.md's
  stage 1 (unit + component tests) only — API/load test stages aren't
  wired since those suites don't exist yet. First real run on GitHub's
  runners surfaced `actions/checkout@v4`/`setup-java@v4` deprecation
  warnings; bumped to `checkout@v7`/`setup-java@v5`/`upload-artifact@v7`
  (versions verified via the GitHub releases API, not assumed) and
  confirmed a clean second run.
- **Enabled branch protection on `main`**, requiring the "Unit + component
  tests" check to pass before merge (`strict: true`). Left
  `enforce_admins: false` and no required PR reviewer, since
  testing-strategy.md explicitly frames this as solo-owned — gates
  contributors/PRs without locking the owner out of direct pushes (a
  direct push during today's session correctly showed a "bypassed rule
  violations" notice rather than being blocked, confirming the intended
  behavior).
- **Repo hygiene**: the whole `apps/` monorepo had no `.gitignore` at all.
  Added one (OS junk, Maven `target/`, IDE dirs, Node artifacts ahead of
  the frontend scaffold). Untracked `grid-meter-app/.DS_Store` (already
  committed) and, on request, `house-price-app/target/` — 23 compiled
  `.class`/`.jar`/surefire-report files that had been accidentally
  committed before any `.gitignore` existed. Files stay on disk, just
  untracked.
- Split the morning's work into 7 focused commits (component tests + Redis
  fix; status/ restructure; CI workflow + settings.json; gitignore/DS_Store;
  action version bumps; workflow_dispatch addition; house-price-app/target/
  untracking) and pushed all of them to `origin/main`.

**Second phase — frontend scaffold + backend JWT auth:**
- Confirmed routing (React Router) and styling (MUI, not Tailwind) with the
  user before scaffolding `frontend/`, per CLAUDE.md. SPA itself was
  already documented in architecture.md; auth-gated pages were new scope.
- Defined the auth scope with the user: real Spring Security + JWT, not a
  mock gate. All `/api/v1/**` routes protected, including `POST /readings`
  — accepted tradeoff: a future JMeter plan will need a login step before
  its load-generating thread group.
- **Backend** (`com.gridmeter.api.auth` package, matching the existing
  feature-package convention): added `spring-boot-starter-security` +
  `io.jsonwebtoken` (JJWT) 0.13.0. Self-issued stateless HS256 JWTs, not
  `spring-boot-starter-oauth2-resource-server` (this app issues its own
  tokens; it doesn't validate an external IdP's). 60-minute TTL, no refresh
  token. Added `POST /api/v1/auth/login`, `V3__create_users_table.sql`
  (Flyway-seeded demo user: `demo` / `GridMeter!Demo2026`, real bcrypt hash
  via `htpasswd`), and `SecurityConfig` (`permitAll()` on
  `/actuator/health`, `/actuator/prometheus`, `/auth/login`;
  `anyRequest().authenticated()` for everything else).
- **Found and fixed a real pre-existing routing bug**: Traefik's `api`
  router only matched `PathPrefix(/api)`, so `/actuator/*` was never routed
  to the backend — it fell through to the frontend's catch-all router and
  returned placeholder HTML instead of a health payload. Unnoticed until
  now because Prometheus scrapes `/actuator/prometheus` directly over the
  Docker network, bypassing Traefik. Fixed by adding `||
  PathPrefix(/actuator)` to the router rule.
- **Tests**: `JwtServiceTest` (unit — round-trip, expiry, tampered
  signature, wrong key), `AuthComponentTest` (extends
  `ComponentTestSupport`, real Postgres — valid/invalid login, asserts the
  unknown-username-vs-wrong-password anti-enumeration behavior is
  intentional), `ApiSecurityComponentTest` (the suite's first HTTP-level
  test — used `RestTestClient` instead of `TestRestTemplate`, which is
  deprecated in Spring Boot 4). `mvn -B test`: 27 tests, all green.
- Verified the full auth flow through Traefik via curl: actuator now
  reachable and open, unauthenticated request → 401, wrong password → 401,
  valid login → real JWT, authenticated request with that JWT → 200 with
  real data.
- **Frontend**: wrote the Vite scaffold by hand instead of running `npm
  create vite`, to avoid overwriting the existing, already-correct
  `Dockerfile`/`nginx.conf`. React 19.2.8, React Router 8.3.0, MUI 9.3.1,
  TanStack Query 5.101.4, Vite 8.2.1, TypeScript 7.0.2 — versions checked
  against real npm/Maven Central results this session. `src/` includes: an
  in-memory token store (not `localStorage`, to limit XSS exposure — costs
  the session on a hard refresh, by design) plus `AuthContext` and
  `ProtectedRoute`; an API client layer matching each controller; TanStack
  Query hooks per resource; pages for Login, Meters (search/filter/CRUD),
  Meter detail, and read-only Readings (no create/edit — readings are
  immutable and API-ingested). Fixed two TypeScript errors: `BrowserRouter`
  comes from the main `react-router` export, not `react-router/dom`; and
  `interface`-declared param types don't get an implicit index signature
  the way `type` aliases do.
- Ran `npm install` to generate a real lockfile (the old one was an empty
  stub). Untracked the force-tracked placeholder `frontend/dist/index.html`
  now that `dist/` holds a real Vite build. Added `*.tsbuildinfo` to the
  root `.gitignore`.
- **Verified in a real browser** (via `claude-in-chrome`, not just curl),
  through both the full `docker compose up --build` path and the Vite
  dev-server proxy path: login with real credentials redirects to
  `/meters` with real API data, meter detail pre-populates via `GET
  /meters/{id}`, Readings page loads real data, a hard reload on a deep
  link or `/readings` correctly bounces to `/login` (confirms both the
  in-memory-token tradeoff and nginx's SPA fallback), logout clears state,
  no console errors. **Not** tested in the browser: the "New Meter" create
  dialog, saving an edit, search/filter fields, pagination, a failed login
  attempt via the UI, or the dev-proxy path's UI (only its proxy config was
  curl-verified).
- **Documented the full feature**, per explicit request (this app demos
  SRE knowledge, so the docs need to hold up as real reference material):
  new "Auth" section in `api-and-data-model.md` (User entity, login
  contract, error shapes); "Authentication" and "Frontend structure"
  sections in `architecture.md` (why JWT over sessions, why self-issued
  tokens over an OAuth2 resource server, the no-refresh-token tradeoff, why
  in-memory token storage) plus a system-diagram update; new dependency
  rows in `tech-stack-versions.md`; new test classes and an honest note on
  the frontend-testing gap in `testing-strategy.md`; a decision bullet and
  a local dev-workflow note in `CLAUDE.md`.
- Made 3 commits (`7f0e7ff` backend JWT auth, `65810ec` frontend scaffold,
  `369e171` docs) on `main`. **Not yet pushed to `origin`.**

Open:
- frontend/ is real now, but **no frontend test tier exists yet** — no
  Vitest, no Testing Library, no Playwright. `tsc -b` and a real `vite
  build` are the only current checks. Flagged in `testing-strategy.md`.
- Browser verification covered the golden path only — meter creation,
  editing, search/filter, pagination, and a failed login attempt were never
  tested through the UI.
- CI (`grid-meter-app-ci.yml`) still only runs `mvn -B test` in `api/` —
  no frontend build/typecheck step, and the API (REST Assured) / load
  (JMeter) test stages from testing-strategy.md's plan still aren't wired.
- REST Assured API test layer not started — PUT `/readings/{id}` rejection
  (405) still has no HTTP-level assertion.
- `PaginationProperties` unit test still not written.
- `settings.local.json` (personal) still has its pre-cleanup one-off
  entries — harmless, superseded by `apps/.claude/settings.json`.
- Mockito self-attach and Netty macOS DNS resolver warnings, carried over
  from 2026-08-10 — cosmetic, not blocking.
- User mentioned Terraform as part of the eventual SRE/k8s demo — not in
  any doc yet (`architecture.md` currently only covers Docker Compose +
  `kind`); noted, not scoped this session.
- Today's 3 new commits (backend auth, frontend scaffold, docs) are local
  only — not pushed to `origin/main` yet.

Next:
- Push today's 3 commits to `origin/main` when ready.
- Build out the REST Assured API test layer (covers PUT-rejection at the
  HTTP level) and wire it into CI as testing-strategy.md's stage 2.
- Add a frontend test tier (Vitest for unit/component, maybe Playwright for
  E2E) now that there's real frontend code to test.
- Test the remaining frontend flows in a browser (create/edit dialogs,
  search/filter, pagination) if live-verified coverage is wanted beyond
  what the code and backend tests already cover.
- `load-tests/` (JMeter) doesn't exist yet — when it's built, it needs a
  login step up front given the "protect everything" auth decision.
- `PaginationProperties` unit test as a small, cheap follow-up.
- `house-price-app/target/` untracking only removed already-committed
  files from git tracking going forward from this point — if a clean
  local rebuild is wanted, `mvn clean` there would remove the actual files
  on disk too (not done today, out of scope for this session).
