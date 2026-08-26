# grid-meter-app — Status: 2026-08-24 (Claude Code)

Six phases: closed out the GitHub Issues bug-tracking gap flagged as open
since 2026-08-18/19; fixed the long-carried-over Mockito/Netty test
warnings; promoted `frontend-test` to a required CI check; fixed issue #2
itself (the `MetersPage` date-display bug); ran the real 2-replica spike
load-test validation; ran the remaining steady-state/ramp-up/soak profiles
at real 2-replica scale too, closing out the whole `load-tests/` "not yet
run at real scale" gap.

Done:

- **Confirmed GitHub Issues is enabled** at the repo level
  (`inquisitivefrog/apps`, already on — nothing to toggle). The real gap
  was the labeling/template convention from `architecture.md`'s CI/CD
  section ("labeled by severity/component, with an issue template
  capturing repro steps and expected/actual behavior"), not the feature
  flag itself.
- **Checked in with the user before scoping labels** (repo hosts 4 sibling
  apps — `grid-meter-app`, `house-price-app`, `four-tier-app`,
  `simple-app` — and labels/templates are repo-wide, not per-directory):
  confirmed grid-meter-app-only component scope rather than a
  monorepo-wide per-app scheme.
- **Created 9 labels** via `gh label create`: `severity: critical/high/
  medium/low` and `component: api/frontend/k8s/infra-observability/
  load-tests` (the last covers Compose/Traefik/Prometheus-Grafana-Loki-
  Tempo, matching grid-meter-app's actual layer split).
- **Added `.github/ISSUE_TEMPLATE/grid-meter-app-bug-report.yml`** (repo
  root's `.github/`, per `apps/` being the actual git root) — a GitHub
  issue form with description, component dropdown, severity dropdown,
  repro steps, expected/actual behavior, and optional additional context.
  Title-prefixed `[grid-meter-app]` and named
  `grid-meter-app-bug-report.yml` (not a generic `bug_report.yml`) so it
  reads unambiguously in a 4-app repo's issue-template chooser.
- **Filed the known `MetersPage` date-off-by-one-day bug as issue #2**
  (github.com/inquisitivefrog/apps/issues/2) — the first real issue
  through the new template. `bug` / `severity: low` / `component:
  frontend`. This was the last "Next" item from `status/
  claude_code_2026-08-19.md`; the bug itself (likely a UTC-parsed/
  local-rendered date-only value in the read-only Meters table, while the
  detail page's edit form renders it correctly) is documented in the issue
  but **not yet fixed**.
- Committed (`cd15fc2`, template file only — the labels/issue live only on
  GitHub, nothing to commit for those) and **pushed to `origin/main`**
  (direct push, bypassed the 2 required status checks, same
  documented-intentional solo-owner behavior as every prior session).

**Second phase — fixed the Mockito/Netty test warnings**, the last
cosmetic item carried over since 2026-08-10:

- Ran `mvn -f api/pom.xml test` (after starting Docker Desktop, which
  wasn't running) to capture the exact current warning text rather than
  fixing from memory of the old status-log description:
  - `Mockito is currently self-attaching to enable the inline-mock-maker.
    This will no longer work in future releases of the JDK...`
  - `Can not find io.netty.resolver.dns.macos.MacOSDnsServerAddressStream
    Provider in the classpath, fallback to system defaults...`
- **Mockito fix**: added `maven-dependency-plugin`'s `properties` goal
  (resolves `mockito-core`'s jar path into a build property) plus a
  `maven-surefire-plugin` `argLine` of `-javaagent:${org.mockito:mockito-
  core:jar}`, loading Mockito as a real Java agent instead of letting its
  inline-mock-maker self-attach at runtime — the fix Mockito's own warning
  points to.
  - **Netty fix**: added `io.netty:netty-resolver-dns-native-macos` as a
  test-scope-only dependency, classifier `osx-aarch_64` (confirmed via
  `uname -m` — this Mac is arm64). Scoped to test only because this
  warning only fires when a JVM runs directly on macOS, which for this
  project only happens during `mvn test` on the dev machine — the real
  app always runs inside a Linux container (Compose/`kind`), so the
  dependency would be dead weight anywhere else.
- Verified both fixes by re-running the full suite: warning text confirmed
  gone via `grep`, `mvn test` still green (53/53, `BUILD SUCCESS`).
- Confirmed no orphaned Docker state afterward beyond the expected
  singleton-pattern Testcontainers (Postgres/Kafka/Redis, per
  `ComponentTestSupport`'s documented design) and the still-running `kind`
  control-plane container from the 2026-08-19 session.
- `tech-stack-versions.md` gained rows for both new build-time
  dependencies (`netty-resolver-dns-native-macos` 4.2.15.Final,
  `maven-dependency-plugin`), each explaining why it's needed and why it's
  scoped the way it is.
- Committed (`9a1922d`, `api/pom.xml` + `tech-stack-versions.md`).

**Third phase — promoted `frontend-test` to a required branch-protection
check**, the last item from `testing-strategy.md`'s CI section still
marked "not yet a required check":

- Checked the actual track record before promoting rather than assuming
  "it's been fine": pulled the last 10 `grid-meter-app-ci.yml` runs on
  `main` via `gh api`, and confirmed the `Frontend typecheck, tests,
  build` job specifically (not just overall workflow conclusion) had
  succeeded in all 10 — including the two runs where the *overall*
  workflow failed, because the failure was in `test`/`black-box-api-test`,
  not this job.
- Promoted via `gh api -X PATCH .../branches/main/protection/
  required_status_checks`, adding `Frontend typecheck, tests, build`
  alongside the existing two contexts (`strict: true` preserved). Verified
  via the API response — all three now listed under `contexts`.
- Updated `testing-strategy.md`'s CI wiring section (the "not yet a
  required check, promoting it is a deliberate follow-up" language) to
  reflect the promotion and the date/reasoning.
- This is a GitHub-side branch-protection setting, not a file — nothing to
  commit for the promotion itself, only the doc update. Committed
  (`a97aaf9`, `testing-strategy.md` only).
- **Both commits above (`9a1922d`, `a97aaf9`) pushed to `origin/main`**
  on request, `cd15fc2..a97aaf9`. Push bypassed the (now 3, post-
  promotion) required status checks — same documented-intentional
  solo-owner behavior as every prior session; confirmed via the bypass
  notice explicitly listing "3 of 3 required status checks are expected."

**Fourth phase — fixed issue #2 itself** (`MetersPage`'s date-off-by-one-
day bug), first real exercise of the `Fixes #123` Issues → PR linking
convention now that Issues has real content:

- Read the issue via `gh issue view 2` rather than working from memory of
  the filed description, then found the exact line:
  `MetersPage.tsx`'s table cell rendered `new Date(meter.installedAt)
  .toLocaleDateString()`. Root cause confirmed by comparing against
  `MeterDetailPage.tsx`, which reads the same field correctly via a plain
  `meter.installedAt.slice(0, 10)` — a string slice, never constructing a
  `Date` at all. `installedAt` is a date-only value (a `type="date"` form
  input) stored as UTC midnight; parsing it into a `Date` and rendering
  with the *local* timezone rolls the displayed calendar date back a day
  for any timezone west of UTC (this Mac's PDT included).
- Fixed with a one-line change: render with `{ timeZone: 'UTC' }` passed
  to `toLocaleDateString()` explicitly, instead of letting it default to
  the browser's local timezone. Confirmed no other call site in the
  frontend touches `installedAt` for display (only this one and the two
  form round-trips), so no shared date-utility helper was warranted for a
  single occurrence.
- **Added a regression test** in `MetersPage.test.tsx` that pins the
  timezone via `vi.stubEnv('TZ', 'America/Los_Angeles')` — necessary
  because GitHub Actions runners default to UTC, where this exact bug
  would *not* reproduce, so an un-pinned test would have silently passed
  in CI both before and after the fix without ever exercising the actual
  regression. Verified the test methodology itself, not just the fix: ran
  it against the reverted (buggy) code first and confirmed it failed
  (rendered `1/14/2026`, expected `1/15/2026`), then restored the fix and
  confirmed it passed — the "prove the test would have caught it" step,
  not just "the fix makes tests green."
- First attempt used raw `process.env.TZ` directly, which failed `tsc -b`
  (`Cannot find name 'process'` — this frontend has no `@types/node`,
  deliberately browser-only). Switched to Vitest's own `vi.stubEnv`/
  `vi.unstubAllEnvs`, which is properly typed by Vitest itself and avoids
  adding a Node-types dependency to a browser-only project for one test.
- Full verification pass: `npx vitest run` (56/56 passing, up from 55),
  `npx tsc -b --force` clean, `npm run build` clean.
- **Live-verified in a real running stack**, not just tests: brought up
  `docker compose up -d --build traefik api postgres kafka redis
  frontend` to rebuild the frontend image with the fix. Hit a port-80
  conflict first — the `kind` cluster's control-plane container from the
  2026-08-19 session was still holding it. Checked in with the user rather
  than unilaterally tearing down another session's state; user chose
  `kind delete cluster --name grid-meter` (they can recreate it later via
  `k8s/kind-config.yaml` whenever the k8s demo is needed again). A second,
  unrelated hiccup after that: Traefik came up without actually publishing
  port 80 to the host (a stale container config from the first failed
  `up` attempt) — fixed with `docker compose up -d --force-recreate
  traefik`.
- Created a real meter via the API (`SN-DATE-BUG-CHECK`, `installedAt:
  "2026-01-01T00:00:00Z"`) to have a concrete, known-bad-under-the-old-code
  case to check. The Chrome extension wasn't connecting in this
  environment (tried twice, then stopped rather than loop on it per
  standing practice), so handed the user the login credentials and asked
  them to check the Meters table directly — **user confirmed correct
  (`1/1/2026`) in their own browser.** Cleaned up the test meter via
  `scripts/delete-meter.sh` afterward.
- Committed (`ed099b3`, `MetersPage.tsx` + `MetersPage.test.tsx`) with
  `Fixes #2` in the commit message, then **pushed to `origin/main`**
  (`a97aaf9..ed099b3`). Confirmed via `gh issue view 2` that GitHub
  actually auto-closed the issue on push (`closedAt: 2026-08-24T20:53:54Z`)
  rather than just trusting the `Fixes #2` syntax was right — first real,
  verified exercise of `architecture.md`'s Issues → PR linking convention.

**Fifth phase — ran the real 2-replica spike load-test validation**, the
last remaining item from `load-tests/README.md`'s "Not yet run at real
scale" section:

- Scaled to the real documented setup: `docker compose up -d --scale
  api=2` plus `GRID_METER_TRACING_SAMPLING_PROBABILITY=0.05` on both
  replicas (per the README's stated real-run prerequisite — 100% tracing
  is fine for dev, not for hundreds of req/s). First attempt used
  `--no-recreate` and left `api-1` at the default 100% sampling while only
  `api-2` picked up the override — caught by checking `docker inspect`'s
  env vars directly rather than assuming the flag did what it sounded
  like; fixed with `--force-recreate` on both.
- Ran `./run.sh spike` with **no** `-J` overrides this time, so the full
  documented defaults ran: 600 threads, 10s ramp, 60s duration (vs. the
  earlier 15s/1-replica smoke check that overrode duration down).
- **Result**: 348,697 samples, 0% errors, mean 94.5ms, p95 164ms, p99
  220ms, max 3560ms. Both `check-thresholds.sh` gates passed (error rate
  < 1%, p95 < 500ms ceiling). The max-response-time climb from the ~85-99ms
  baseline average is the real saturation signal — consistent with the
  earlier single-replica smoke run's pattern (85ms→1474ms), so this isn't
  a fluke of either run.
- **Honest caveat, not glossed over**: this was an unattended run — no
  Prometheus/Grafana stack was up alongside it, so `tomcat.threads.busy`/
  `tomcat.connections.current` (the metrics the README says to watch
  during a spike run) weren't directly observed. The saturation evidence
  here is the JMeter-side response-time climb, not a live Tomcat-metrics
  confirmation.
- Updated `load-tests/README.md`'s two relevant sections ("What's actually
  been validated" and "Not yet run at real scale") to describe precisely
  what ran, following this doc's own established discipline — Claude Chat
  caught this same README overclaiming once before, in the 2026-08-18
  session.
- Committed (`22e9f85`, `load-tests/README.md` only) — not yet pushed.

**Sixth phase — ran the remaining load-test profiles** (steady-state,
ramp-up, soak) at real 2-replica scale, closing the rest of the "not yet
run at real scale" gap:

- **Disk check first, on user request**: host free space was down to
  16Gi available (`df -h /`) — the same pattern that caused a crash back
  in the 2026-08-19 session. Checked `docker system df` before assuming
  anything: 9.49GB build cache (8.97GB reclaimable), 7.27GB images
  (2.94GB reclaimable), 5.2GB local volumes (4.95GB reclaimable, but
  shared across every project on this machine, not just grid-meter-app).
  User chose build-cache + image prune only (not volumes, given the
  shared-project risk). `docker builder prune -f && docker image prune -f`
  freed the host from 16Gi to 21Gi available — image prune reclaimed 0B
  since nothing was dangling (this stack's images are all actively in use
  by running containers), which is expected, not a failure.
- **`steady-state`** (full defaults: 20 threads, 10s ramp, 300s duration):
  28,441 samples, 0% errors, p95 11ms. Clean baseline, as expected.
- **`ramp-up`** (full defaults: 0→150 threads over 150s, holds for the
  rest of a 300s duration): 165,241 samples, p95 10ms, **1 error**
  (0.0006% error rate) — noted honestly rather than rounded away, though
  it's two orders of magnitude under the 1% gate and didn't recur; not
  investigated further given how isolated it was.
- **`soak`** (full defaults: 35 threads, 30s ramp, **3600s/1hr** duration)
  — launched in the background (exceeds what a single foreground command
  can wait on). **Completed**: 340,304 samples, 0.031% error rate, mean
  5.6ms, p95 8ms, p99 11ms, max 268ms — both gates passed, no connection-
  pool-exhaustion or heap-leak signal over the full hour.
  - **Real finding in the error breakdown, not glossed over**: all 105
    errors were `401 Unauthorized`, all within a ~23ms window across all
    35 threads simultaneously, exactly at the 1-hour mark. Root cause:
    `soak.jmx` logs in once via `common/login.jmx` and never
    re-authenticates, and the JWT's TTL is a documented, deliberate 60
    minutes with **no refresh token** (`architecture.md`'s "Authentication"
    section — an accepted tradeoff for this project's scope, not a defect).
    Confirmed via `results.jtl`: every failing row is `401`, all clustered
    at the exact run-duration boundary — this is the documented tradeoff
    actually manifesting in a real test for the first time, not an app or
    test bug. Any soak run ≥60 minutes will show this same tail-end burst
    by design.
  - **Checked in before changing anything**: asked whether to add mid-run
    re-authentication to `soak.jmx` or just document the behavior.
    User chose **document only** — keeps the test's actual purpose
    (leak/exhaustion detection) separate from re-exercising a tradeoff
    already covered by the auth test suite. No code change to `soak.jmx`.
- All runs used the same 2-replica/reduced-sampling stack already up from
  the spike run — no rebuild needed.
- `load-tests/README.md` updated with a consolidated results table for all
  four profiles plus the soak token-TTL explanation; the earlier
  spike-only paragraph trimmed to avoid duplicating numbers now in the
  table. Not yet committed.

**Seventh phase — found and fixed a real flaky test, surfaced by the
user spotting a CI failure email** for the `ed099b3` push (issue #2 fix):
`Unit + component tests` failed on GitHub Actions run #16, even though
that commit touched only frontend files. Confirmed it wasn't a real
regression before looking deeper: the Java source was byte-identical
across the run before (`a97aaf9`, passed) and after (`22e9f85`, passed) —
same code, different outcome, so genuinely flaky rather than a fluke of
that one commit.

- Root cause, fully explained rather than dismissed as "just flaky":
  `JwtServiceTest.extractUsername_tamperedSignature_throwsJwtException`
  tampered a JWT by flipping only the token's very last character. An
  HS256 signature is 32 bytes (256 bits); base64url-without-padding needs
  43 characters to encode that (43×6=258 bits), so the *last* character's
  bottom 2 bits are unused zero-padding, not real signature bits. Verified
  with `python3`: `'A'` and `'B'` (the two characters the test's ternary
  swapped between) share the same top-4 real bits, differing only in that
  padding — so roughly 1 run in 16 (whenever the real generated
  signature's last character happened to be `'A'`), the "tampered" token
  decoded to byte-identical signature bytes and correctly-still-valid,
  and the test's `assertThatThrownBy` failed because nothing was thrown.
- **Verified empirically, not just mathematically**: wrote a throwaway
  stress harness (`/tmp/JwtTamperStress.java`, JJWT direct, not committed)
  generating 500 distinct tokens (varying subject to force distinct
  signatures, since `issuedAt`/`expiration` are second-precision
  `NumericDate`s and would otherwise repeat within the same wall-clock
  second). Old approach: reproduced the "no exception thrown" bug **24/500
  times (4.8%)** — matching the predicted ~6.25% (1-in-16) within normal
  sampling variance. New approach (tamper the *second*-to-last character
  instead, which sits in the final base64 group's real-bits region with no
  padding ambiguity): **0 failures across all 500.**
- Fixed in `JwtServiceTest.java` with a comment explaining the full
  reasoning (so a future reader doesn't "simplify" it back to the buggy
  version). Verified: `JwtServiceTest` 4/4, full suite 53/53, `BUILD
  SUCCESS`.
- Committed (`11bd642` README consolidation, `516fc9a` the flaky-test fix)
  and **pushed to `origin/main`** (`22e9f85..516fc9a`). Watched the
  resulting CI run to completion rather than assuming the fix worked:
  all three required checks green, including `Unit + component tests`
  (the job that failed on `ed099b3`) — confirmed fixed on real CI
  infrastructure, not just locally.

**Eighth phase — trimmed `apps/.claude/settings.local.json` and wrote a
cross-project lessons doc**, both prompted by the user questioning how
portable this session's permission-request pattern and "subdirectory of
learnings" idea actually were:

- **Settings trim**: reviewed all 164 entries individually rather than
  bulk-deleting. Removed genuinely dead ones — hardcoded UUIDs and `/tmp`
  paths that can never recur, references to a deleted `_harness.jmx`,
  literal invocations of probe scripts tied to the now-resolved
  connection-reset investigation, one-off narrative `echo` statements,
  entries already redundant against a broader wildcard elsewhere in the
  file. Also removed `tcpdump *` (granted for that same resolved
  investigation, and a more sensitive capability than the rest of the
  list) — flagged explicitly to the user rather than silently dropped.
  Result: **164 → 90 entries**.
  - Where a narrow one-off represented a real recurring *pattern*,
    generalized it into a wildcard instead of just deleting it — e.g.
    `./run.sh steady-state *` → `./run.sh *` (now covers all four
    profiles), a hardcoded-meter-ID `delete-meter.sh` entry → a wildcard
    covering any meter ID, three narrow `mvn test -Dtest=<exact-class>`
    entries → three wildcard equivalents covering any test class.
  - The committed, repo-wide `apps/.claude/settings.json` (9 entries) was
    already clean — not touched.
- **`docs/cross-project-lessons.md`**: per the user's call — no new
  subdirectory, just one file in the existing `docs/` (the only real
  `docs/` in the monorepo so far). Six lessons distilled from this
  project's actual history, each stating the symptom, the fix, and
  explicitly why it's not grid-meter-app-specific: verify versions against
  the real registry before pinning; a major version bump can rename
  artifact IDs, not just bump a number; a dependent tool (JMeter) doesn't
  have to share the app's own JDK pin; don't tamper-test encoded data by
  flipping only its last character (base64 padding-bit pitfall); Spring's
  `/error` re-dispatch needs its own security exemption; a test HTTP
  client can have footguns independent of the app under test (REST
  Assured's port-8080 default); Mockito's javaagent fix; Maven's
  nearest-wins mediation surprise; verify a specific CI job's track record
  before promoting it to required, not the whole workflow's; and
  `settings.local.json` needs periodic trimming.
- `cross-project-lessons.md` committed (`5b0f02c`), not yet pushed.
  `settings.local.json` confirmed excluded by a **global** git config rule
  (`~/.config/git/ignore`, not just this repo's `.gitignore`) — asked the
  user explicitly whether to force-add it past that rule now that it's
  trimmed; they chose to leave it personal/untracked, matching its
  original 2026-08-11 design intent. `settings.json` (the shared,
  committed one) had no changes this session.

Open (all carried over, untouched this session unless noted):

- `load-tests/` CI's nightly `schedule` trigger still hasn't fired for
  real (only `workflow_dispatch` verified).
- Frontend E2E tier (Playwright) — still explicitly deferred; discussed
  this session (dependencies, what it'd take) but confirmed no concrete
  need has arisen to justify reopening that decision.
- k8s observability follow-up slice (`kube-prometheus-stack`, in-cluster
  Alloy/Loki/Tempo) — deferred per the 2026-08-19 scope decision, not
  started; `kind` cluster torn down this session, see fourth phase above.
- `docs/cross-project-lessons.md` (eighth phase) is uncommitted.
- The stack is currently up locally with `api` scaled to 2 replicas and
  reduced tracing sampling (0.05) — worth knowing if picking this back up
  expecting the normal 1-replica/100%-sampling dev default.
- Docker build cache/image prune freed 16Gi→21Gi host disk; local volumes
  (4.95GB reclaimable, shared across all projects on this machine) were
  deliberately left alone this session.
- A "manually disable a service, watch the alert fire in Grafana" chaos-
  style exercise was raised (possibly discussed in an earlier Claude Chat
  session, unconfirmed — nothing found in any doc or status log) —
  **built this session, see ninth phase below.**

**Ninth phase — built a real Grafana dashboard, `load-tests/chaos-demo.sh`,
and automated screenshotting**, reframed mid-session from a nice-to-have
into a stated **must-have**: user needs a demoable app with a standard
Grafana dashboard, plus reviewable screenshots of various states, for
interview prep. This phase was long and hit several real bugs in
sequence — recorded in full because each one is a genuine, portable
lesson, not because the false starts matter on their own.

- **Real dashboard, not just Explore ad hoc queries** (all prior sessions
  only ever used Explore): `observability/dashboards/
  grid-meter-overview.json` (9 panels — request rate/error rate/p95-p99
  latency, Tomcat threads/connections, JVM heap, Kafka lag, HikariCP
  connections, Redis command rate) + `observability/grafana-dashboards.yml`
  (file-provisioning config) + a `docker-compose.yml` volume mount, same
  provisioning pattern as the existing datasources. Gave the Prometheus/
  Loki/Tempo datasources explicit `uid:` fields so the dashboard JSON can
  reference them reliably instead of relying on Grafana's auto-generated
  ones.
- **Found two real, pre-existing metrics gaps** while designing panels
  against actually-scraped Prometheus data (not assumed metric names):
  `tomcat_threads_busy_threads`/`tomcat_connections_current` — the exact
  metrics `load-tests/README.md` had already been telling readers to
  "watch in Grafana during spike/soak" since the load-test tier was
  built — were never actually exposed (`server.tomcat.mbeanregistry.
  enabled` was never set, so Micrometer's Tomcat binder had no JMX data
  to read). Similarly, `http_server_requests_seconds` had no histogram
  buckets (`management.metrics.distribution.percentiles-histogram`
  unset), so no p95/p99 panel was possible at all. Both fixed in
  `application.yml` with comments explaining the gap; verified via real
  `/actuator/prometheus` output before and after, not assumed fixed.
- **`load-tests/chaos-demo.sh`**: brings up a background steady-state
  load, then takes each link in the request chain offline in turn
  (`traefik`, `api`, `kafka`, `postgres`, `redis`, matching
  `architecture.md`'s diagram — user confirmed all five, not just the
  data tier), screenshotting the dashboard before, during, and after each
  outage. Added a direct host port (`3001:3000`) to `grafana` bypassing
  Traefik, specifically so screenshots keep working when Traefik itself
  is the link being taken offline.
- **A second, real, currently-open finding, not glossed over**: `api`
  crashed once during testing (`ClassicKafkaConsumer` — "No resolvable
  bootstrap urls" — a fresh JVM boot racing Docker's embedded DNS
  re-registering "kafka" on `api`'s own restart) and stayed dead — no
  `restart:` policy existed. Added `restart: on-failure:5` to `api`.
  Honestly: 5 rapid stop/start stress cycles afterward did **not**
  reproduce the original race (`RestartCount=0` both times), so the fix
  is a sound standard mitigation, verified not to break normal operation,
  but the race itself was never deterministically re-triggered to prove
  it's what actually gets caught by the new policy.
- **The screenshot mechanism itself took four real iterations to get
  right** — each one found via actual verification, not assumed:
  1. First cut: `npx playwright screenshot` per shot (fresh anonymous
     Grafana session each time). Reproduced fast and clean once isolated:
     each fresh session cost ~80-170MB server-side and never released
     it — 2-3 fresh-session screenshots reliably OOM-killed Grafana
     regardless of container memory limit (tried 384m, 768m, 1024m — all
     three climbed to *whatever the ceiling was* and crashed, not a fixed
     absolute number).
  2. Bumped Grafana's memory limit three times chasing this (256m → 384m
     → 768m → 1024m) before recognizing "pegs at whatever the limit is"
     as a real unbounded-growth signal rather than "just needs more
     headroom" — a mistake worth naming plainly rather than glossing
     over, since the pattern was visible after the second bump and should
     have been caught sooner.
  3. Rewrote to a persistent-session model instead: `load-tests/
     screenshot-daemon.js`, one headless Chromium session reused for the
     whole run, coordinated with the bash script via a FIFO (`shoot()`
     writes a path, polls the daemon's log for a `DONE:`/`FAILED:` ack).
     Hit two real mechanical bugs building this, both fixed and verified
     in isolation before retrying: `npx -p playwright node <script>`
     resolves `require('playwright')` inconsistently depending on the
     script's own directory (worked from `/tmp`, not from `load-tests/`)
     — fixed by self-bootstrapping a plain local `load-tests/node_modules`
     on first run instead; and macOS's `mktemp` only randomizes trailing
     `X`s when they're at the *very end* of the template — a `.log`
     suffix after `XXXXXX` silently produced the same literal filename
     every run, colliding on the second invocation. Added an explicit
     empty-path check after both `mktemp` calls so this fails loudly next
     time instead of cascading into a silent hang.
  4. Still OOM'd once even with a persistent session, under real
     chaos-demo.sh conditions (background load + real outages) though not
     in an isolated clean test — traced to `page.reload()` being called
     before every shot: a full reload re-bootstraps Grafana's entire
     frontend and re-initializes a fresh server-side dashboard view even
     within the same browser session. Fixed by navigating exactly once
     and reusing the already-loaded, `refresh=15s`-auto-refreshing page
     for every subsequent screenshot instead. Verified in isolation first
     (11 shots, no reload: plateaued ~417-420MB, stable) before re-testing
     under real full conditions.
  5. **Real full-length verification** (default 45s outage/20s recovery
     timings, ~7-8 minutes, background load + all 5 real outages + 11
     screenshots): completed successfully end-to-end for the first time
     (`exit 0`, all 11 files present) — but memory still climbed to the
     full 512m ceiling by the end, meaning real combined load pushes
     higher than the isolated ~420MB figure. Bumped to 768m for actual
     headroom rather than calling "didn't crash this once" sufficient.
     `GF_LIVE_MAX_CONNECTIONS: "0"` was tried as an earlier hypothesis
     for the same bug, tested, and honestly ruled out (didn't stop the
     growth) — left disabled anyway since it's genuinely unused here, but
     the comment doesn't overclaim it as the fix.
  6. Visually verified one real outage screenshot (`02-api-outage.png`):
     Tomcat connections/threads and HikariCP connections all visibly dip
     at the correct timestamp — confirmed as real, meaningful signal, not
     just "a file exists."
- **Resource-consumption checks, per explicit user request**: checked
  real host-level numbers mid-run (not just the one container that was
  crashing) — `memory_pressure` (64% system-wide free, healthy), 0 swap
  activity all session, moderate load average, all other containers well
  within their own limits. The Grafana issue was genuinely isolated to
  that one container's workload, not a whole-stack resource problem —
  confirmed with real numbers, not asserted.
- Cleaned up ~11 intermediate smoke-test screenshot directories, kept only
  the final successful full run
  (`load-tests/screenshots/20260825-132010/`, itself gitignored).
- **Not yet committed**: `observability/dashboards/grid-meter-overview
  .json`, `observability/grafana-dashboards.yml`, `observability/
  grafana-datasources.yml` (uid fields), `docker-compose.yml` (grafana
  port/memory/plugin-env/GF_LIVE, api restart policy), `api/src/main/
  resources/application.yml` (mbeanregistry + histogram config),
  `load-tests/chaos-demo.sh`, `load-tests/screenshot-daemon.js`.
- **One open item raised but not chased**: the dashboard's panel colors
  weren't rigorously audited against the user's colorblindness — a quick
  look at one real screenshot showed green/yellow/blue series, not an
  apparent red/green pairing, but this was a glance, not a real pass.

Open (all carried over, untouched this session unless noted):

- `load-tests/` CI's nightly `schedule` trigger still hasn't fired for
  real (only `workflow_dispatch` verified).
- Frontend E2E tier (Playwright) — still explicitly deferred; discussed
  this session (dependencies, what it'd take) but confirmed no concrete
  need has arisen to justify reopening that decision. (Note: Playwright
  itself is now a real dependency of `load-tests/`, just not wired up as
  a frontend E2E tier — different scope.)
- k8s observability follow-up slice (`kube-prometheus-stack`, in-cluster
  Alloy/Loki/Tempo) — deferred per the 2026-08-19 scope decision, not
  started; `kind` cluster torn down this session, see fourth phase above.
- `docs/cross-project-lessons.md` (eighth phase) — committed (`5b0f02c`),
  not yet pushed.
- Ninth phase's full set of dashboard/chaos-demo/metrics-fix changes
  (listed above) — uncommitted.
- Dashboard panel colors not rigorously audited for colorblind-safety —
  worth a real pass before relying on this for the actual interview,
  not just the one screenshot glanced at this session.
- The `api` restart-policy fix (`restart: on-failure:5`) mitigates a real
  observed crash but the underlying DNS race was never deterministically
  reproduced again to prove the policy actually catches it — worth
  keeping in mind if `api` is ever seen dead with no obvious cause.
- The stack is currently up locally with `api` scaled to 2 replicas,
  reduced tracing sampling (0.05), and the full observability tier
  (Prometheus/Grafana/Loki/Tempo/Alloy) running for the first time
  alongside it this session — worth knowing if picking this back up
  expecting the normal minimal dev default.
- Docker build cache/image prune freed 16Gi→21Gi host disk earlier this
  session; local volumes (shared across all projects on this machine)
  were deliberately left alone.

Next:

- Commit and push the ninth phase's work (dashboard, chaos-demo script,
  metrics fixes, restart policy) — large diff, probably worth splitting
  into a few focused commits (metrics fixes / dashboard+provisioning /
  chaos-demo+screenshot-daemon / api restart policy) rather than one.
- A real colorblind-safe pass over the dashboard's panel colors.
- All four `load-tests/` profiles are validated at real scale — that
  tier's work is essentially done pending the CI schedule-trigger
  verification.
- Whenever picking this back up: this file plus
  `status/claude_code_2026-08-19.md` cover current repo state; no other
  session context needed.
