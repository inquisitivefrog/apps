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

Open:
- **Still no E2E tier** (Playwright) — deliberately deferred; revisit
  once there's a concrete need beyond what component tests + manual
  browser verification already cover.
- REST Assured API test layer (backend) still not started — PUT
  `/readings/{id}` 405-rejection still has no HTTP-level assertion.
  Carried over from 2026-08-11, untouched this session.
- `load-tests/` (JMeter) still doesn't exist.
- `PaginationProperties` unit test (backend) still not written.
- Today's changes are **local only — not yet committed or pushed**.

Next:
- Commit and push today's frontend-test-tier work (config + auth-path
  tests + Node pin + Meters/Readings page tests — likely worth splitting
  into a couple of focused commits rather than one, given the session
  had two distinct phases).
- Build out the REST Assured API test layer and wire it into CI as
  testing-strategy.md's stage 2 (still the most-carried-over open item
  across sessions).
