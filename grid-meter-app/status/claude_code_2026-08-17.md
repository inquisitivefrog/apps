# grid-meter-app — Status: 2026-08-17 (Claude Code)

Done:
- **Stood up the frontend test tier** flagged as an open gap since the
  2026-08-11 session. Checked in with the user first per CLAUDE.md (this
  was an unpinned structural choice): confirmed Vitest + Testing Library
  only for this session (Playwright E2E deferred) and colocated
  `*.test.ts(x)` files over a parallel `__tests__/` tree.
- Verified every new dependency against the real npm registry before
  pinning (matching this repo's version-verification convention): Vitest
  4.1.10, `@testing-library/react` 16.3.2, `@testing-library/jest-dom`
  7.0.1, `@testing-library/user-event` 14.6.4, jsdom 30.0.1,
  `@vitest/coverage-v8` 4.1.10 — all confirmed compatible with Vite 8 /
  React 19 via their published `peerDependencies`.
- **Config**: wired Vitest into `vite.config.ts`'s `test` block (via the
  `/// <reference types="vitest/config" />` triple-slash approach) rather
  than a separate `vitest.config.ts`, so it reuses the same
  `@vitejs/plugin-react` setup instead of duplicating it. `globals: false`
  (explicit `describe`/`it`/`expect` imports per file, no ambient
  globals) — which meant React Testing Library's automatic
  unmount-between-tests cleanup didn't fire on its own; wired it
  explicitly via `afterEach(cleanup)` in the new `src/setupTests.ts`
  after a first real test run showed DOM from a prior test leaking into
  the next one. Added `test`/`test:watch`/`test:coverage` npm scripts.
- **Wrote 35 tests across 6 files**, concentrated on the auth path since
  that's where this frontend's actual logic lives (pages are largely MUI
  + TanStack Query wiring, already exercised indirectly by backend
  API/component tests):
  - `auth/tokenStore.test.ts` (6) — get/set, listener notify, unsubscribe
  - `api/client.test.ts` (11) — `apiClient`'s request wrapper against a
    mocked `fetch`: Authorization header attach/omit, 401 clears the
    token store and throws, error-body → message mapping, malformed-JSON
    fallback, 204 handling, GET/POST/PUT/DELETE wiring
  - `auth/AuthContext.test.tsx` (4) — `useAuth` via `renderHook`: initial
    unauthenticated state, login success/failure, logout
  - `auth/ProtectedRoute.test.tsx` (2) — real `MemoryRouter`:
    unauthenticated redirect vs. authenticated render-through
  - `pages/LoginPage.test.tsx` (4) — form render, successful submit →
    navigate, failed submit → error alert (no navigate), already-
    authenticated → immediate redirect
  - `api/metersApi.test.ts` (8) — query-string building for search
    params (omits `undefined`/empty, includes set values) plus the
    other CRUD calls' path/method/body wiring
  - All green: `npm test` → 35 passed; `npx tsc -b --force` and
    `npm run build` both clean (test files live under `src/`, so `tsc -b`
    typechecks them too, but Vite's build only bundles what's actually
    imported from `index.html` — test files aren't in the shipped
    bundle).
- **CI**: added a new `frontend-test` job to
  `.github/workflows/grid-meter-app-ci.yml` (`setup-node@v7` — verified
  current via the GitHub releases API rather than assumed — Node 24,
  confirmed Active LTS via nodejs.org, `npm ci` → `npm test` →
  `npm run build`) alongside the existing `test` (API) job. Moved the
  `defaults.run.working-directory` from workflow-level down to each job
  individually, since the two jobs now point at different directories
  (`grid-meter-app/api` vs. `grid-meter-app/frontend`).
- **Docs**: `testing-strategy.md`'s "No frontend testing tier exists yet"
  gap note replaced with a real description of the test files and what
  they cover, plus a new row in the layers table. `tech-stack-versions.md`
  got new rows for all new frontend test dependencies.
- **Pinned Node.js 24 (LTS)** in `tech-stack-versions.md` — previously
  unpinned anywhere in the docs, surfaced by the jsdom `EBADENGINE`
  warning above. Confirmed Active LTS via nodejs.org's release schedule
  (v22 is Maintenance LTS, v26 is the current non-LTS "Current" line as
  of May 2026). Matches what was already in CI (`setup-node@v7`,
  `node-version: "24"`) and the frontend `Dockerfile` (`node:24-alpine`,
  already correct, no change needed there). Added `coverage/` to the
  root `.gitignore`.
- **Extended the test tier to the Meters/Readings pages** (the gap called
  out as open above), adding 20 more tests across 4 new files (55 total
  now, up from 35, across 10 files):
  - `pages/MetersPage.test.tsx` (8) — search re-fires on location/status
    filter change with page reset to 0 (MUI `Select` interaction driven
    via `role="combobox"`/`role="option"`, not a native `<select>`), row
    click navigates to the detail route, pagination advance, the New
    Meter dialog's Create button disabled until required fields are
    filled, create-then-close, cancel-without-creating (needed an
    explicit `waitFor` around the dialog's unmount — MUI's close
    transition isn't synchronous)
  - `pages/MeterDetailPage.test.tsx` (4) — loading state (an
    intentionally never-resolving mocked promise), form pre-populates
    from the loaded meter, Save sends edited fields and navigates back to
    `/meters`, Cancel navigates back without saving
  - `pages/ReadingsPage.test.tsx` (4) — search re-fires on the meter ID
    filter, pagination advance, and an explicit assertion that **no**
    create/edit/save control renders anywhere — the frontend analog of
    testing-strategy.md's "assert PUT is rejected, not just absent"
    principle, applied to the read-only Readings page
  - `api/readingsApi.test.ts` (4) — query-string building, mirroring
    `metersApi.test.ts` (the two API modules don't share a
    `toQueryString` helper, so both got the same coverage)
  - New shared `src/testUtils.tsx` — a `createTestQueryClient()` factory
    (fresh, no-retry `QueryClient` per test) used by all three new page
    test files, since each needs a real `QueryClientProvider` (page tests
    mock at the `api/*` module boundary, not the TanStack Query hooks
    themselves, so real query keys/cache invalidation run for real)
  - All green: `npm test` → 55 passed across 10 files; `npx tsc -b
    --force` and `npm run build` both still clean.

**Third phase — REST Assured API test layer.** Frontend-test-tier work above
(both commits: `fbcaee3`, `56ba256`) is already pushed to `origin/main`.
This phase is **local only, not committed**.

- User wanted "both ways" tested before deployment (QA instinct): a fast
  tier blocking every push, AND a real black-box tier against an actual
  deployed stack — not just one or the other. Landed on a shared-base-class
  design so both tiers run the *identical* assertions: `MeterApiTestBase`/
  `ReadingApiTestBase` (abstract, package-private, hold the `@Test`
  methods) with two thin concrete subclasses each:
  - `MeterApiComponentTest`/`ReadingApiComponentTest` — embedded server via
    Testcontainers + `RANDOM_PORT` (same pattern as the existing
    `ApiSecurityComponentTest`), runs via **Surefire** (`mvn test`),
    blocks every push, **no CI changes needed** — it's picked up
    automatically by the existing job.
  - `MeterApiIT`/`ReadingApiIT` — plain JUnit, no Spring context, points
    at `API_BASE_URL` env var (default `http://localhost/api/v1`,
    matching local `docker compose up`), runs via **Failsafe**
    (`mvn verify`) against a real deployed stack. Not yet wired into CI
    (next open item).
  - Added `rest-assured` 5.5.2 + `maven-failsafe-plugin` (already managed
    by `spring-boot-starter-parent`, just needed activating) to `pom.xml`.
- **Found and fixed a real production bug** via this new fast tier:
  every 404/405 under `/api/v1/**` was being masked as a 401. Root cause:
  Spring Boot renders 404s/405s via an internal forward to `/error`, which
  re-enters Spring Security's filter chain as a fresh `ERROR`-dispatch
  request; `JwtAuthenticationFilter` (a plain `OncePerRequestFilter`)
  doesn't re-run on that dispatch type by default, so the re-check finds
  no authentication and the entry point overwrites the real 404/405 with
  401. Fixed with `.requestMatchers("/error").permitAll()` in
  `SecurityConfig` — the standard fix for this well-known Spring Security
  + Boot interaction. Verified via curl before/after (`PUT
  /readings/{id}` now correctly 405s with `Allow: GET, DELETE`, unrelated
  401s for genuinely missing/invalid tokens still work). This is exactly
  the kind of bug the black-box tier was built to catch — the embedded
  fast-tier component tests also exercise `SecurityConfig` and now catch
  it too, so it's covered going forward by the tier that runs on every
  push.
- **Found and worked around a Groovy 5 incompatibility**: `rest-assured`
  5.5.2 transitively pulls Groovy 5.0.6, but rest-assured doesn't support
  Groovy 5 yet (open upstream issue,
  [rest-assured/rest-assured#1846](https://github.com/rest-assured/rest-assured/issues/1846)
  — same root cause breaks Spring REST Docs too,
  [spring-restdocs#1000](https://github.com/spring-projects/spring-restdocs/issues/1000)).
  Symptom: every GET/PUT call threw a `NullPointerException` deep in
  Groovy's `ClosureMetaClass`; POST happened to work. Fixed by pinning
  `groovy`/`groovy-xml`/`groovy-json` to 4.0.32 as direct test-scope
  dependencies (wins over rest-assured's transitive pull under Maven's
  nearest-wins mediation). Fast tier (`MeterApiComponentTest`,
  `ReadingApiComponentTest`) is fully green after this fix: 16/16 passing,
  full `mvn test` suite 43/43.
- **New `scripts/` directory** (per explicit user request, to make
  repeated multi-step commands easier for `.claude/settings.local.json`
  to match and for status to be reviewable after the fact, rather than
  ad hoc one-off shell invocations):
  - `check-maven-central-version.sh` — prints current versions for a
    Maven Central artifact
  - `wait-for-health.sh` — polls a health-check URL with a timeout
  - `run-black-box-api-tests.sh` — `docker compose up` the
    traefik/api/postgres/kafka/redis tier, wait for health, run the
    Failsafe-bound `*ApiIT` suite via `test-compile failsafe:integration-test
    failsafe:verify` (NOT `verify -DskipTests` — that skips Failsafe too,
    since Surefire and Failsafe share the `skipTests` property by design;
    invoking Failsafe's goals directly sidesteps Surefire's `test` phase
    entirely without needing a skip flag at all)
  - `RawHttpProbe.java` / `probe-raw-http.sh` — sends a request over a
    bare `java.net.Socket`, bypassing any HTTP client library
  - `JdkHttpClientProbe.java` / `probe-jdk-http-client.sh` — same, via
    the JDK's built-in `java.net.http.HttpClient`
  - `build-test-classpath.sh` — writes the api module's test classpath to
    a file, for compiling ad hoc diagnostic Java programs against the
    same dependency versions the real suite uses
  - All three probe mechanisms (`.java` files use JDK 25's single-file
    source-launch mode, no separate compile step) were written while
    diagnosing the still-open blocker below.
  - Added `scripts/README.md` indexing all of the above, grouped by
    purpose (version verification / black-box test tier / diagnostic HTTP
    probes), so the directory is self-explanatory without re-reading each
    script's header comment.
- **Committed and pushed today's work**, in the shape flagged as the plan
  in this file's own "Next" section — 3 focused commits: the
  `SecurityConfig` `/error`-masking bug fix, the REST Assured test infra
  (`pom.xml` + the 6 new `Meter/ReadingApi*` test classes), and the new
  `scripts/` directory (including its README). `api/pom.xml` and
  `SecurityConfig.java` were previously modified-but-uncommitted per this
  file's earlier entries; `mvn -f api/pom.xml test-compile` re-verified
  clean before committing. Docs (`testing-strategy.md`/
  `tech-stack-versions.md`) for this phase are still **not** updated —
  carried into tomorrow, see Open/Next below.

Open:
- **Black-box tier (`*ApiIT`) doesn't work locally yet — root cause still
  unknown.** Every request through Traefik (`http://localhost/api/v1`)
  fails with `SocketException: Connection reset`, but only via REST
  Assured's bundled Apache HttpClient 4.5.13. Ruled out as the cause so
  far, all confirmed working against the exact same running stack:
  plain `curl`, a raw `java.net.Socket` (`scripts/probe-raw-http.sh`),
  and the JDK's own `java.net.http.HttpClient`
  (`scripts/probe-jdk-http-client.sh`). Tried and did NOT fix it:
  disabling `Expect: 100-continue` via `HttpClientConfig`. Wire-level
  debug logging via `-Dorg.apache.commons.logging.*` system properties
  passed through Failsafe's `argLine` did not actually produce any log
  output — worth revisiting (may need Logback config instead, since the
  test JVM has no Spring Boot context to honor `logging.level.*`
  properties). Strong suspicion: something specific to Apache HttpClient
  4.5.13's classic API interacting with Docker Desktop for Mac's
  port-forwarding proxy for port 80 — plausible this is Mac-only and
  won't reproduce on GitHub Actions' native Linux runners with a real
  Docker Engine, but that's untested. **Next session: either keep
  isolating (a raw Apache `HttpClient` reproduction bypassing REST
  Assured/Groovy entirely is the next concrete step, using
  `scripts/build-test-classpath.sh`), or just wire the CI job and see if
  it reproduces there — cheaper signal either way.**
  Docker Compose stack (traefik/api/postgres/kafka/redis) is currently
  **left running** on this machine for whenever debugging resumes —
  `docker compose down` when done with it.
- Black-box CI job (task: "Wire black-box CI job") not started — blocked
  on the above.
- `testing-strategy.md`/`tech-stack-versions.md` docs not yet updated for
  this phase's work (rest-assured/failsafe/groovy pin, the two-tier
  design, the `/error` permitAll fix) — planned but not done.
- `load-tests/` (JMeter) still doesn't exist.
- `PaginationProperties` unit test (backend) still not written.
- Session ended here for the day (user fatigue/distraction, not a
  blocker) — everything above (bug fix, REST Assured test infra,
  `scripts/`) is now committed and pushed to `origin/main`; nothing
  pending in the working tree. The Docker Compose stack (traefik/api/
  postgres/kafka/redis) noted as left running above is still up on this
  machine — `docker compose down` whenever convenient, no rush.

Next:
- Resume the black-box connection-reset investigation (see above) or
  pivot straight to CI wiring to get a faster signal on whether it's
  Mac-specific.
- Once resolved: wire the black-box CI job.
- Update `testing-strategy.md`/`tech-stack-versions.md` for this phase's
  work — still outstanding, independent of the connection-reset blocker.
- `load-tests/` (JMeter) doesn't exist yet — needs a login step given the
  auth-everything decision. Still not started.
- `PaginationProperties` unit test — small, cheap, still not done.
