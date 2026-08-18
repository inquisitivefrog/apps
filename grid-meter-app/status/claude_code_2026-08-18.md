# grid-meter-app — Status: 2026-08-18 (Claude Code)

Done:

- **Committed the leftover `verify-auth-security.sh`** from the 2026-08-17
  session (uncommitted at session start) after confirming it actually
  passes against a running stack: actuator open, unauthenticated/invalid-
  token rejection, login, `PUT /readings/{id}` 405. (`1604721`)

- **Resolved the black-box `*ApiIT` connection-reset investigation**
  flagged as the top open item from 2026-08-17. Root cause, found via a
  `tcpdump` packet capture comparing a working probe against the failing
  one: REST Assured's static `RestAssured.port` defaults to **8080** and
  is silently applied to any request URL without an explicit port — every
  black-box request was landing on Traefik's *dashboard* port (8080,
  which resets unrecognized connections), not the real API on port 80.
  Nothing to do with Docker Desktop's networking, which was the leading
  suspicion at the end of the prior session. Isolated one layer at a time
  with new diagnostic probes (`scripts/ApacheHttpClientProbe.java`,
  `ApacheHttpClientLegacyProbe.java`, `RestAssuredMinimalProbe.java`,
  `capture-connection-reset.sh`) before the packet capture pinned it down
  — Apache HttpClient itself (modern and legacy execution paths, REST
  Assured's own actual internal client class) was cleared in every
  configuration; only REST Assured's Groovy `HTTPBuilder` layer was
  affected. Fixed by deriving `RestAssured.port` explicitly from the
  configured base URL in `MeterApiIT`/`ReadingApiIT` instead of leaving it
  at REST Assured's default; the previously-added (and never actually
  effective) Expect-Continue workaround was removed along with it. `mvn
  verify`: 16/16 black-box tests passing. (`b120d7b`, `a31d8fb`)

- **Wired the black-box API test CI job**: new `black-box-api-test` job in
  `grid-meter-app-ci.yml`, running `scripts/run-black-box-api-tests.sh`
  against a throwaway Docker Compose stack with its own teardown step.
  Verified locally against a clean `docker compose down` + fresh `up` (no
  race with a pre-existing stack). Promoted to a **required** branch-
  protection status check on `main`, alongside the existing "Unit +
  component tests". (`098332e`, `7309dcf`)

- **Docs**: `testing-strategy.md` now describes the shared-base-class
  two-tier REST Assured design (`MeterApiTestBase`/`ReadingApiTestBase` +
  thin `*ApiComponentTest`/`*ApiIT` subclasses) and the connection-reset
  root cause/fix; `tech-stack-versions.md` gained rows for Testcontainers,
  Awaitility, REST Assured, Groovy, and `maven-failsafe-plugin` (the first
  two were a pre-existing gap, not new this session). (`28f7f57`)

- **`PaginationProperties` unit test** — the last small item carried over
  from 2026-08-11: 10 pure-unit tests covering the page/size clamping
  logic (null defaults, negative page, size clamped into `[1, maxSize]`,
  boundary values, sort pass-through). `mvn test`: 53/53. (`3427ca5`)

- **`load-tests/` — the full JMeter scaffold**, the last remaining item
  from `testing-strategy.md`'s planned layering:
  - All four profiles from the doc (`steady-state`/`ramp-up`/`spike`/
    `soak.jmx`), each self-contained: a setUp Thread Group pulls in two
    shared Test Fragments (`common/login.jmx`, `common/
    provision-meters.jmx`) via Include Controller to log in and provision
    a real meter pool before load generation starts — no manual DB
    seeding needed. Auth token and provisioned meter IDs are shared via
    JMeter **Properties**/a CSV file rather than Variables, since
    Variables don't cross Thread Group boundaries.
  - `check-thresholds.sh` reads a run's HTML dashboard `statistics.json`
    and gates on error rate < 1% / p95 latency, deliberately outside
    JMeter itself (a Backend Listener is for streaming live metrics, not
    post-run pass/fail logic) — `run.sh` invokes it after every run.
    `smoke-test.sh` bundles the "quickly re-validate every profile" loop
    that got run by hand repeatedly while building this.
  - Design came from a Claude Chat session (structural choices — file
    layout, Include Controller vs Module Controller, meter-provisioning
    approach, threshold-gate mechanism, spike's 600-thread peak relative
    to a newly-explicit 400-thread Tomcat connector ceiling) relayed
    through the user per the established Chat-designs/Code-implements
    split; Code then validated every design decision by actually running
    it, not just trusting the plan.
  - **Two real bugs found and fixed during that validation**: a
    PreProcessor scoped to a whole Loop Controller was resetting the
    meter-pool CSV before *every* iteration instead of once (fixed by
    using a plain one-time Sampler instead of a PreProcessor); and
    JMeter's `-p` flag replaces its own default properties file entirely
    rather than merging into it, which silently broke HTML report
    generation (`Cannot assign "${jmeter.reportgenerator.
    apdex_satisfied_threshold}"...`) — fixed by using `-q` instead.
  - All four profiles validated end-to-end against a real `docker compose`
    stack, including a full run of spike at its real 600-thread default
    (92,866 requests, 0% errors, latency climbing 85ms→1474ms under load
    — the expected saturation signal).
  - `application.yml`: `server.tomcat.threads.max`/`min-spare`/
    `accept-count` made explicit (same values as the parent POM's
    defaults — not raised, just written down deliberately, since spike's
    whole purpose is probing this exact ceiling). Tracing sampling
    probability made overridable via `GRID_METER_TRACING_SAMPLING_
    PROBABILITY` (a general Spring property override, not load-test-
    specific) — required a `docker-compose.yml` passthrough fix to
    actually reach the container, since it wasn't wired through when
    first added. (`efaad02`, `eebf8e9`, `79f9cd8`)

- **Wired `load-tests/` into CI**: new `grid-meter-app-load-test.yml` —
  `workflow_dispatch` (profile picker + optional duration override) and a
  nightly steady-state smoke (120s, to bound CI minutes), never on push/PR
  so it structurally can't block a merge. Verified with real triggered
  runs on GitHub's own runners, not just locally. **Found and fixed a real
  bug this way**: the first real run failed with `Unsupported class file
  major version 69` — JMeter 5.6.3's bundled Groovy/ASM can't compile the
  JSR223 scripts in `common/login.jmx`/`provision-meters.jmx` under Java
  25; never reproduced locally because Homebrew's own `jmeter` formula
  hardcodes `JAVA_HOME` to `openjdk@21` for this exact reason. Fixed by
  pinning the CI job's `setup-java` step to 21 — JMeter is an external
  tool here, not part of the app under test, so there's no reason for its
  JRE to match the app's own Java 25 pin. Confirmed green afterward: 2,470
  samples, 0% errors, 8ms p95. (`f7a12cd`, `148fbc5`)

- **Correction pass** after Claude Chat reviewed the above and asked
  precise questions rather than taking "CI-verified" at face value:
  - `tech-stack-versions.md`'s JMeter row corrected — it said "Java 17+
    recommended, satisfied by Java 25" before the Java 21 discovery above;
    now documents the real requirement.
  - `architecture.md` gained a line making explicit that the tracing-
    sampling override is a general mechanism, not CI-only.
  - `load-tests/README.md` was overclaiming the spike/400-thread-ceiling
    validation — corrected to precisely describe what actually ran (a
    15s single-replica smoke check, not the documented 60s/2-replica
    scenario) and that its 0%-error result is a latency-based saturation
    signal (85ms→1474ms), not "no saturation."
  - The `workflow_dispatch`-only nature of the CI verification was called
    out honestly (the `schedule` trigger's distinct code path — no
    `inputs` object at all — hasn't fired for real), and rather than
    leave that as a caveat, the profile/duration fallback was rewritten
    to resolve in bash (`${VAR:-default}`) instead of GitHub Actions
    expression syntax (`${{ a || b }}`), removing any reliance on the
    latter's behavior for that untested path. Re-verified with one more
    real `workflow_dispatch` run afterward (green). (`5e1c4c1`)

- All 13 commits above pushed to `origin/main`.

Open:

- **k8s/`kind` demo** — still just a paragraph in `architecture.md`'s
  Deployment model section while Compose has full manifests, CI wiring,
  and load-test validation behind it. Claude Chat proposed a first-slice
  scope (core app manifests — API, frontend, Postgres/Kafka/Redis as
  either manifests or acknowledged-as-out-of-cluster-for-now — + Traefik
  IngressRoute in `kind`, with observability in-cluster wiring explicitly
  deferred to a follow-up) rather than attempting the whole deployment
  model in one session. **Awaiting the user's go-ahead** before Code
  starts, per CLAUDE.md's check-in-before-scaffolding convention.
- **Terraform** — mentioned once in an earlier session's status log as a
  future SRE-demo idea, never scoped in any doc. Claude Chat flagged this
  as an actual gap: either scope what it would provision (given
  everything currently runs on Compose/`kind` locally with no real cloud
  target) or mark it explicitly out-of-scope in `architecture.md` — left
  ambiguous is worse than either choice. **Awaiting the user's decision.**
- `load-tests/` spike profile still not validated at its documented real
  scale (60s duration, 2 `api` replicas) — only a 15s single-replica smoke
  check has run. `docker compose up --scale api=2` + `./run.sh spike` is
  the next concrete step whenever that validation is wanted.
- `load-tests/` CI's `schedule` trigger hasn't fired for real yet (only
  `workflow_dispatch` has a verified run) — the code path is now written
  defensively so this shouldn't matter, but the actual nightly firing is
  still unobserved.
- `api/bruno/` (manual/exploratory API collections) named in
  `testing-strategy.md` but never created.
- Frontend E2E tier (Playwright) — explicitly deferred, no concrete need
  yet.
- `frontend-test` CI job still not a required branch-protection check
  (only `test` and `black-box-api-test` are).
- GitHub Issues bug-tracking setup (severity/component labels, issue
  template) named in `architecture.md`'s CI/CD section, never created.
- Mockito self-attach / Netty macOS DNS resolver warnings — cosmetic,
  carried over since 2026-08-10, still not addressed.

Next:

- Get the user's call on k8s first-slice scope and Terraform in/out-of-
  scope, then start whichever (or both) they greenlight.
- Real 2-replica spike validation once someone wants that closed out.
- `api/bruno/` collections — small, standalone, could slot in anytime.
- Promote `frontend-test` to a required check once it's had a few more
  clean runs (mirrors how `black-box-api-test` was promoted this
  session).
