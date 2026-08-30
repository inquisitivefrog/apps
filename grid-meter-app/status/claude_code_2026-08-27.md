# grid-meter-app — Status: 2026-08-27 (Claude Code)

Direct continuation of the same conversation as `status/claude_code_2026-08-26.md`
— the session ran long enough to cross midnight, so this file picks up exactly
where that one's final "Next" list left off, split into its own dated file per
the project's per-day naming convention rather than left folded into 08-26's
record.

Done today:

- **Empirical Kafka-outage-durability test.** User asked how many messages
  JMeter can send in the time Kafka takes to recover from a stop/restart, and
  whether they're durably stored in Postgres afterward. Ran `steady-state`
  (20 threads, 150s) with a precisely-timed 46s Kafka outage (`docker compose
  stop/start kafka`) mid-run, all inside one self-contained background script
  (`kafka-outage-test.sh`) rather than separate sequential tool calls — a
  first attempt using separate Bash calls failed silently: unexpected latency
  between tool-call round trips meant the outage landed 52s *after* the
  JMeter run had already finished, so it measured nothing (0% error rate,
  but only because Kafka was up the entire time). The corrected, single-script
  run: 88 `POST /readings` requests sent during the 46s outage window,
  **zero HTTP errors** — `ReadingService.ingest()`'s Postgres check
  (`meterRepository.existsById()`) is unaffected by Kafka being down, and
  `kafkaTemplate.send()` is fire-and-forget (no `.get()`). But not free: a
  handful of in-flight requests each blocked the calling Tomcat thread for up
  to ~49.8s — the Kafka producer stalling inside `send()` itself while unable
  to fetch fresh cluster metadata, bounded by the client's default
  `max.block.ms` (60000ms), undeclared in `application.yml` at the time — the
  same "undeclared default" shape as the earlier HikariCP `connection-timeout`
  finding. All blocked requests resolved successfully once Kafka came back,
  comfortably under the 60s ceiling. Durability: confirmed 100% via an exact
  row-count reconciliation — Postgres `readings` grew by +9248 across the
  whole run, matching the real `POST /readings` sample count exactly (9261
  total JMeter samples minus 13 setup/provisioning calls — 1 login, 10 meter
  creates, 1 CSV reset, 1 pool-verify — that don't touch the `readings`
  table). Zero loss, zero duplicates, even across the outage.

- **Declared Kafka producer's `max.block.ms` explicitly in
  `application.yml`**, per user request, mirroring the HikariCP treatment:
  written down at its existing default value (60000ms) with a comment
  explaining what it actually bounds (how long `ingest()`'s `send()` call can
  hang the calling thread during a broker outage) and citing the empirical
  ~49.8s observation above as the reason it's worth knowing this ceiling
  exists rather than discovering it by accident during a real outage.
  Rebuilt and restarted the `api` container (`docker compose up -d --build
  api`); confirmed clean startup (`Started GridMeterApiApplication` in the
  logs, `/actuator/health` → `{"status":"UP"}`, no errors). **Not yet
  committed** — `api/src/main/resources/application.yml`.

- **Split `status/claude_code_2026-08-26.md` into two files** so each
  calendar day's work has its own dated record — moved the Kafka-outage
  finding and the stale/superseded parts of that file's "Next" list (the
  since-completed "commit the native-retry migration" item) out into this
  file, leaving 08-26's file ending at its true end-of-day state.

- **`docs/resilience-scope.md` and `docs/multi-tenancy-scope.md` landed from
  Claude Chat** (read in full, each summarized back to the user). The
  former confirms the `max.block.ms` move above was exactly right (declare
  near current value, don't shorten until a circuit breaker + outbox
  exist) and flags a correction to something said earlier in that
  conversation (Actuator has no built-in Kafka health indicator). The
  latter confirms **observability-only tenancy** (2026-08-27): add a
  minimal `Customer` entity, propagate `customerId` through logs/traces
  only, no API access-control change — and corrects an earlier suggestion
  that `customerId` become a raw Prometheus label (cardinality risk;
  Loki/Tempo are the right home).

- **Implemented `docs/multi-tenancy-scope.md`'s data model and
  propagation, per user request ("yes please start implementing").**
  - New `Customer` entity (`id`, `name`, `createdAt`/`updatedAt`) +
    `CustomerRepository`, mirroring the existing `Meter`/`User` pattern.
    `Customer.DEFAULT_ID` is a public constant for the seeded default row.
  - `V4__create_customers_table.sql`: creates `customers`, seeds the
    default customer, adds `customer_id` (NOT NULL FK) to both `users` and
    `meters`, backfilling existing rows to the default customer first.
  - `Meter.customerId` / `User.customerId`: flat UUID FK fields, not JPA
    relations — same convention already used for `Reading.meterId`.
  - **JWT claim**: `JwtService.generateToken(username, customerId)` embeds
    `customerId`; `AuthService.login()` now does one Postgres lookup (via
    `UserRepository`) at login time to resolve it, so no per-request DB
    lookup is needed afterward — the whole point of putting it in the
    token per the doc's own reasoning.
  - **`AuthenticatedUser`** (new record: `username`, `customerId`) is the
    principal `JwtAuthenticationFilter` now attaches to the
    `Authentication`, resolvable via `@AuthenticationPrincipal` in
    controllers — `MeterController.create()` uses it to set the new
    meter's `customerId` from the caller's own claim, not from the request
    body (a client shouldn't be able to assign an arbitrary customer).
    `MeterResponse` gained a `customerId` field (additive; confirmed the
    frontend's `Meter` TS interface doesn't reject unknown JSON fields, so
    no frontend change needed).
  - **Logs and traces, not Prometheus** (the doc's explicit correction):
    `JwtAuthenticationFilter` puts `customerId` into MDC for the request's
    duration (cleared in a `finally`, since Tomcat threads are pooled) and
    calls `Span.current().setAttribute("customerId", ...)` for Tempo.
    Added `logging.pattern.level: "%5p [customerId=%X{customerId:-}]"` to
    `application.yml` so the MDC value actually reaches stdout → Alloy →
    Loki, not just live in-JVM.
  - **Tests**: updated `JwtServiceTest` (new `generateToken` signature,
    added an `extractCustomerId` round-trip test), `AuthComponentTest`
    (seeded users now get `customerId`; added
    `login_embedsTheUsersOwnCustomerIdInTheToken`, which seeds a *second*
    real `Customer` row via `CustomerRepository` to prove it's not
    hardcoded to the default), `MeterComponentTest`/`ReadingComponentTest`
    (`meterService.create()`'s new `customerId` parameter). Added a new
    `JwtAuthenticationFilterTest` (3 tests, Mockito) that asserts the MDC
    value is actually present *during* `chain.doFilter()` (not just that
    the code compiles) and cleared after, plus that the attached principal
    carries the right `customerId` — this is the one that would have
    caught it if the MDC put/remove were silently no-ops.
  - **Verified, not just compiled**: full `mvn test` (58 tests, up from
    55) and `mvn verify`'s black-box `*ApiIT` tier (16 tests) both green.
    Rebuilt the real `api` container and ran the migration against the
    actual accumulated dev Postgres (892 real meters, not a fresh
    Testcontainers instance) — all backfilled to the default customer
    cleanly. Live end-to-end smoke test: logged in as `demo`, decoded the
    JWT to confirm the `customerId` claim, created a meter through the
    real HTTP API, confirmed the response carried the same `customerId`.
  - **Explicitly deferred** (per the doc's own "explicitly deferred"
    section, genuinely out of scope, not a gap): enforced API-level tenant
    isolation, multiple users per customer, a subscription-tier field.

- **`docs/multi-tenancy-scope.md` updated again from Claude Chat**,
  pushing back on the previous entry: the two "testing implications" items
  (≥2 seeded customers, a regression proving `GET /meters`/`readings`
  span all customers today) aren't optional follow-on work — they're the
  verification that proves this pass didn't silently change access
  behavior, explicitly invoking this same project's HikariCP and
  Kafka-outage investigations as precedent for "verify real behavior,
  don't just assume it." Agreed with the reasoning and closed both out:
  - `MeterComponentTest`: added `createOtherCustomer()` (seeds a real
    second `Customer` row) and
    `search_returnsMetersAcrossAllCustomers_documentingCurrentNonIsolation`
    — creates a meter under the default customer and one under a distinct
    customer sharing a unique location, asserts `search()` returns both.
  - `ReadingComponentTest`: same pattern —
    `search_returnsReadingsAcrossAllCustomers_documentingCurrentNonIsolation`,
    using two meters under two different customers and a distinctive
    value bracket (not `meterId`) to isolate the two new rows from the
    rest of the test dataset while proving the search has no meterId
    filter applied.
  - **Found and fixed a real, pre-existing latent test bug while doing
    this** (not something the new tests introduced, something they
    exposed): `ReadingComponentTest`'s `awaitPersisted()` helper calls
    Awaitility's `.until(() -> readingService.findById(readingId), r -> r
    != null)` without `.ignoreExceptions()`. `findById()` throws
    `ResourceNotFoundException` (not null) before the Kafka consumer has
    caught up, and Awaitility does NOT catch exceptions from the polled
    supplier by default — so the very first poll that loses the race
    against consumer lag fails the test immediately instead of retrying
    for the full 10s window. This had been latent since the helper was
    first written (it "worked" purely because the consumer was normally
    fast enough to win on the first poll); the new cross-customer test
    ingests two readings back-to-back, which reliably lost that race under
    full-suite load (reproduced 2/2 times before the fix, confirmed gone
    3/3 times after adding `.ignoreExceptions()`). Fixed and reverified.
  - **Verified**: `mvn test` — 60 tests (up from 58), 3 consecutive clean
    full-suite runs. `mvn verify`'s black-box `*ApiIT` tier — 16/16 green
    against the real deployed stack. Not committed — same file list as
    above plus `MeterComponentTest.java`/`ReadingComponentTest.java`
    changes.

- **Committed and pushed both, as two separate commits** since they're
  unrelated changes: `a46b5af` (Kafka `max.block.ms`) and `aa9cea3`
  (multi-tenancy). `application.yml` was touched by both, so
  `logging.pattern.level` was temporarily removed/re-added between the two
  commits to split the file's diff cleanly rather than mixing both changes
  into one commit. CI (`grid-meter-app CI`, all 3 required checks) —
  `success` in 2m32s.
- **Incidental finding while checking that CI run**: the load-test
  workflow's nightly `schedule` trigger fired for real for the first time
  (run `33097903198`, `event: schedule`, 2026-08-27T17:20:31Z,
  `conclusion: success`, 4m4s) — resolving a long-standing open item that
  had only ever been exercised via manual `workflow_dispatch` before today.

- **Relabeled the existing 4 alert rules in
  `observability/alerting/rules.yml` as incident alerts.** Added
  `alert_class: incident` to each rule's existing `labels:` block (`api-down`,
  `high-error-rate`, `edge-5xx-rate`, `tomcat-threads-saturated`) —
  `observability-taxonomy.md` didn't pin down a specific label key, so
  picked one that reuses the file's own existing `labels:` mechanism
  (alongside `severity`) rather than a title-string prefix or a separate
  rule group/folder, and sets up a clean `alert_class: trend` counterpart
  for the not-yet-built trend-alert task. Verified live, not just via file
  diff: restarted `grafana` to force a provisioning reload (no errors),
  then confirmed all 4 rules actually carry the new label via Grafana's
  provisioning API (`/api/v1/provisioning/alert-rules`). **Committed and
  pushed** as `2a07bc5`; CI (`grid-meter-app CI`, all 3 required checks) —
  `success` in 2m26s.

- **k8s observability follow-up slice, built and validated end-to-end
  against a real `kind` cluster** (`k8s/deploy-observability.sh`, new).
  Design (per user correction mid-session — an initial "two separate
  Prometheus/Grafana pairs" answer was wrong; the actual decision was one
  unified pair): `kube-prometheus-stack` (Helm, the one piece of this
  project's k8s manifests using it) installed into `default` namespace,
  its bundled Prometheus scraping both cluster/node metrics (bundled) and
  the app itself (`servicemonitor-api.yaml` for `api`,
  `additionalScrapeConfigs` for `traefik`, to avoid hand-editing the
  vendored Traefik manifests further), its bundled Grafana getting the
  app's existing dashboard/alert-rules/Loki+Tempo-datasources layered in
  rather than running a second redundant Grafana. Alertmanager disabled
  (alerting is Grafana-managed, same as Compose). Loki/Tempo/Alloy
  deployed as plain YAML alongside it. ConfigMaps for the dashboard,
  alert rules, and Tempo config are generated at deploy time directly
  from the same `observability/` source files Compose mounts, so the two
  environments share one source of truth rather than duplicating
  YAML/JSON.

  - **`observability/alloy-k8s.river`** (new, separate from the
    Compose-only `alloy.river`): Compose discovers containers via the
    Docker socket, which doesn't exist in a kind cluster (containerd, not
    dockerd, manages the node). Uses `loki.source.kubernetes` instead —
    reads pod logs straight from the Kubernetes API (the same path
    `kubectl logs` uses), needing only RBAC, no hostPath mount — which is
    also why it runs as a single-replica Deployment, not a DaemonSet: log
    collection is centralized via API calls, not node-local, and the
    cluster is single-node anyway.
  - **Real bugs found validating this live, not just applying manifests
    and trusting them**:
    1. River's comment syntax is `//`, not `#` — my own header comment in
       `alloy-k8s.river` used shell-style `#` and crash-looped the Alloy
       pod with a parse error on every restart.
    2. `ServiceMonitor.spec.selector` matches a Service's
       `metadata.labels`, not its `spec.selector` (a separate field
       despite the easy-to-conflate naming) — `api.yaml`'s Service had no
       `metadata.labels` at all, so the target silently never appeared in
       Prometheus, no error anywhere.
    3. `hostPort: 80` + the default `RollingUpdate` strategy deadlock a
       single-node cluster — the new Traefik pod can never schedule
       before the old one releases the only eligible node's port
       (`FailedScheduling: didn't have free ports`). Fixed with
       `strategy: {type: Recreate}`.
    4. The chart's default Grafana (13.2.0) doesn't match this project's
       pin (13.0.2) and crash-looped independently of resource
       contention — 13.2.0's newer "apiserver" bootstrap (registering
       `dashboard.grafana.app`/`folder.grafana.app`/etc. as separate
       multi-second steps) pushed real boot time past the chart's default
       liveness budget. Confirmed via exit code 137 and reproduced
       identically with Compose fully stopped, ruling out contention
       before concluding it was a real version/timing issue. Fixed by
       pinning `13.0.2` plus extending liveness
       `initialDelaySeconds`/`failureThreshold`.
    5. A second, different restart (exit code 1, not 137) on a truly cold
       `kind create cluster` run: Grafana got as far as provisioning
       alerts and dashboards before `"Database locked... SQLITE_BUSY"` —
       the two sidecar containers polling Grafana's own provisioning-reload
       API concurrently with Grafana's own boot-time provisioning, both
       hitting the embedded SQLite DB at once — got interrupted by the
       liveness probe's SIGTERM before the retry finished, then converged
       to stable on the very next restart with no intervention. Left as a
       documented, honest, self-healing characteristic rather than chased
       to zero restarts; `deploy-observability.sh`'s Helm `--wait --timeout`
       bumped from 5m to 8m so a genuinely cold run doesn't get reported
       as failed while this plays out.
    6. **A third, ongoing issue caught by live monitoring, not a
       deploy-time check**: `context deadline exceeded` readiness-probe
       failures during otherwise-stable operation (10+ minutes in, ruling
       out a cold-start explanation). Root-caused via direct cgroup
       measurement (`kubectl exec ... cat /sys/fs/cgroup/memory.current`):
       268402688 / 268435456 — 99.99% of the 256Mi limit, in real use, no
       OOMKilled event yet but `GOMEMLIMIT=230MiB` forcing heavier GC as
       it approached that soft cap. **Deliberately did not borrow
       Compose's 768Mi Grafana limit as precedent** — that number fixes a
       different, unrelated problem (a real memory leak in
       `load-tests/screenshot-daemon.js` repeatedly opening fresh
       Playwright sessions, fixed architecturally by reusing one
       persistent session; see `status/claude_code_2026-08-24.md`) that
       has no equivalent workload in this k8s cluster. Bumped to 512Mi
       instead, sized from the direct measurement; also loosened
       `readinessProbe.timeoutSeconds` from the chart's fragile 1s
       default to 5s. Re-verified under continued real load (sidecars in
       WATCH mode + 4 alert rules evaluating every 10s) rather than
       assumed sufficient: settled at 43-44% of the new limit across
       6+ minutes of uptime (231MB→236MB, clearly plateauing, not
       climbing), 0 restarts.
    7. **A fourth, more subtle bug, caught only by directly querying live
       metric values rather than trusting the rules compiled and
       applied**: all 4 alert rules were firing continuously (every ~30s,
       confirmed via Grafana's own logs) with every pod healthy — 2 of
       the 4 (`api-down`, `edge-5xx-rate`) had a real structural cause,
       the other 2 (`high-error-rate`, `tomcat-threads-saturated`) were
       transient early-evaluation-window false starts that had already
       self-resolved by the time they were checked (confirmed back to
       `0`/`0.5%`, both well under threshold). The two structural ones:
       `api-down`'s query filters `job="grid-meter-api"`, but Prometheus
       Operator's default job-naming derives `job` from the discovered
       Service's name (`api`), not the ServiceMonitor's own name — zero
       matching series, confirmed via `/api/v1/targets`. `edge-5xx-rate`
       filters `service="api@docker"` (Traefik's Docker-provider naming),
       but the k8s CRD provider names services like
       `default-grid-meter-<hash>@kubernetescrd` — also zero matching
       series, confirmed via a direct query against the live metric.
       **Fixed at scrape time via relabeling, not by editing the rule to
       match whichever environment's default happened to differ**:
       `servicemonitor-api.yaml` now has a `relabelings` entry forcing
       `job` to the canonical `grid-meter-api` (matching what Compose
       already emits natively); both `k8s/kube-prometheus-stack-values.yaml`'s
       `additionalScrapeConfigs` for Traefik and `observability/prometheus.yml`'s
       Compose equivalent now carry a `metric_relabel_configs`/regex
       relabel toward a new shared canonical value, `grid-meter-api-edge`,
       since Traefik's k8s-generated hash isn't guaranteed stable across
       an IngressRoute recreation — a literal-string fix would've been
       fragile in a way the Compose side's fixed name never was. One
       alert-rule definition now works unchanged in both environments,
       which matters more given `docs/cloud-deployment-scope.md` already
       commits to Traefik staying constant across future cloud targets —
       this exact bug would otherwise resurface per cloud. Re-verified
       live after the fix: `job`/`service` labels correctly normalized in
       Prometheus, `api-down`/`edge-5xx-rate` queries now find real
       matching series, and all 4 rules confirmed back to
       `inactive`/`health: ok` via Grafana's rules API.
  - **Verified live, end to end, on a from-scratch cluster rebuild** (not
    just the already-live, already-patched cluster): tore down and
    recreated the `kind` cluster, re-ran `deploy.sh` then
    `deploy-observability.sh` from the fixed files. Prometheus:
    `grid-meter-api` and `traefik` targets both `up`. Loki: log streams
    present for `api`/`frontend`/`postgres`/`kafka`/`redis`/`traefik`/
    `tempo`/`alloy`, plus cluster-internal pods (`kindnet`,
    `local-path-provisioner`) Compose's Docker-socket-based Alloy never
    had visibility into. Grafana: `Grid Meter API — Overview` provisioned
    alongside `kube-prometheus-stack`'s own bundled cluster dashboards in
    the same instance; all 4 alert rules present with `alert_class:
    incident` labels intact and no longer false-firing.
  - **Committed** as `9fea221` (13 files) — not yet pushed. `kind` cluster
    torn down afterward (`./k8s/teardown.sh`) to free Docker Desktop VM
    resources; nothing running now (`kind get clusters` empty, `docker ps`
    empty).

- **`docs/cross-project-lessons.md` updated from Claude Chat**, folding
  today's k8s findings into portable lessons for the other monorepo apps:
  River's `//` comment syntax, the `ServiceMonitor` selector trap,
  `hostPort`+`RollingUpdate` deadlocking a single-node cluster, verifying
  a Helm chart's own bundled sub-chart versions (not just the outer
  chart's), not borrowing a resource limit from an unrelated precedent,
  and normalizing alert-rule labels at scrape time rather than hardcoding
  either environment's snapshot. Read in full and checked against what
  actually happened this session — accurate, no corrections needed.

- **Session closed out.** k8s observability follow-up slice committed
  (`9fea221`) and pushed; CI (`grid-meter-app CI`, all 3 required checks)
  — `success` in 2m51s. `kind` cluster torn down
  (`./k8s/teardown.sh`) — confirmed empty (`kind get clusters`, `docker ps`
  both show nothing running). Docker Compose stack is also stopped (taken
  down earlier this session to free resources for the `kind` work, never
  brought back up) — a future session picking this up needs `docker
  compose up -d` (or `--build` if `api`/`frontend` source changed) before
  the app is reachable at `http://localhost` again.

- **Implemented `docs/ha-scope.md`: Kafka moved to a real 3-broker KRaft
  cluster** (`docker-compose.yml`'s `kafka-1`/`kafka-2`/`kafka-3`, shared
  `CLUSTER_ID`, combined broker+controller roles per the doc's quorum
  reasoning). `readings` topic: replicas 1→3, `min.insync.replicas=2`
  declared explicitly — both moved to properties
  (`readings-topic-replicas`/`readings-topic-min-insync-replicas`) rather
  than hardcoded, since the real values are structurally unsatisfiable
  against any single-broker Testcontainers Kafka.
  - **Found and fixed a real gap this surfaced**: 4 separate test classes
    each run their own independent single-broker Testcontainers Kafka
    (`ComponentTestSupport`, `GridMeterApiApplicationTests`,
    `ReadingApiComponentTest`, `ApiSecurityComponentTest`,
    `MeterApiComponentTest` — 5 total setups) and each needed the same
    override added individually; missed 3 of them on the first pass
    (`InvalidReplicationFactorException`, silently swallowed by
    `KafkaAdmin` — logged as `ERROR` but non-fatal, so all 60 tests kept
    passing throughout, using whatever topic config happened to exist
    from an earlier context). Root-caused via a temporary debug print
    correlated against a full-suite log, not guessed — confirmed exactly
    which contexts received which property values before fixing each one.
    Also found the `-Dtest='!ClassName'` Surefire exclusion I tried
    mid-investigation silently didn't work — bash's `!` history expansion
    inside double-quotes corrupted the argument.
  - **Verified live against the real 3-broker cluster**: `kafka-topics.sh
    --describe` confirms `ReplicationFactor=3`, full ISR across all 3
    brokers on every partition. Stopped `kafka-2` mid-run: `POST
    /readings` still returned `201` immediately, zero impact — a direct,
    measurable contrast to the single-broker outage tested earlier this
    project (~49.8s blocked per request, from the Kafka-outage-durability
    investigation). Full test suite (60 tests) green, zero
    topic-creation errors, after fixing all 5 independent test setups.
  - **Committed** as `26c50e8` (8 files) — not yet pushed.
  - **Explicitly deferred, not done this pass** (session running low on
    budget): a dedicated `load-tests/kafka-ha-demo.sh` covering the
    3 scenarios `docs/ha-scope.md` itself frames as the point of this
    work (tolerate-one-broker, two-broker quorum loss, rolling
    maintenance) — only did an ad hoc single-broker-kill check above, not
    the "genuinely different, well-scoped test suite" the doc calls for.
    Also deferred: the k8s side (`k8s/kafka.yaml` is still single-broker),
    matching this session's established precedent of doing Compose first
    and treating k8s as its own follow-up slice (see the observability
    slice earlier today). Redis/Postgres HA remain explicitly out of
    scope per the doc's own "Kafka only, this pass" framing.

- **Built and ran `load-tests/kafka-ha-demo.sh`** covering `docs/ha-scope.md`'s
  three scenarios. Scenarios 1 (tolerate one broker loss, 20/20 succeeded)
  and 3 (rolling maintenance, 30/30 succeeded across all 3 sequential
  restarts) passed cleanly. Scenario 2 (two-broker quorum loss) surfaced a
  real finding instead of a clean pass: all 10 requests returned `201`
  and a direct Postgres query confirmed all 10 landed, despite the
  cluster being below the 2-of-3 majority it needs — root-caused to
  `kafkaTemplate.send()` only blocking on metadata fetch (`max.block.ms`,
  declared) while actual delivery retries run in the background under an
  **undeclared** `delivery.timeout.ms` (120000ms default), which
  comfortably absorbed the ~15-20s outage window used. Documented in
  `load-tests/README.md` as two concrete follow-ups, not a clean result:
  re-run with a longer (2+ min) quorum-loss window to actually see it
  fail, and/or declare `delivery.timeout.ms` explicitly. **Committed** as
  `8f2d2f3`.

- **CI broke on push, found and fixed same-day.** `26c50e8`/`8f2d2f3`
  renamed Compose's `kafka` service to `kafka-1`/`kafka-2`/`kafka-3`, but
  3 other places still referenced the old bare name directly:
  `scripts/run-black-box-api-tests.sh`, `load-tests/chaos-demo.sh`'s
  `LINKS` array, and `.github/workflows/grid-meter-app-load-test.yml` —
  all broke with `no such service: kafka` the moment they ran fresh
  rather than against an already-up local stack. `chaos-demo.sh`'s
  single-Kafka-outage scenario also updated: killing one of three brokers
  is now expected to be a non-event, not the outage it demonstrated with
  a single broker. Verified: black-box Failsafe suite (16 tests) run
  directly against the real 3-broker stack, not just applied and
  trusted. **Committed and pushed** as `207dc83`; both main CI and the
  scheduled `grid-meter-app Load Test` workflow confirmed `success`.

- **Re-ran `kafka-ha-demo.sh`'s scenario 2 with the outage extended to
  150s (past `delivery.timeout.ms`'s undeclared 120s default) — confirmed
  real, permanent data loss, not a hypothesis.** All 10 readings sent
  during the outage were lost forever (0 landed during, 0 more after
  recovery), while every one of the 10 `POST /readings` calls still
  returned `201` throughout. The api container's own logs named the exact
  mechanism: `TimeoutException: Expiring N record(s) for
  readings-0:120001 ms has passed since batch creation`.
  `ReadingService.ingest()` never checks `kafkaTemplate.send()`'s returned
  `Future`, so the failure has no path back to the caller and isn't
  otherwise logged as actionable — a real silent-data-loss bug. Script
  updated to measure durability directly (Postgres row counts
  before/during/after the outage) rather than trust HTTP status codes,
  which this investigation showed are not evidence of anything for this
  specific failure mode. **Committed and pushed** as `87f5061`.

- **Fixed the silent-data-loss bug: declared `delivery.timeout.ms`
  explicitly, added a `whenComplete` callback (Micrometer counter +
  ERROR log with recovery context), a new `alert_class: incident` alert
  rule, and a Mockito unit test.** Verified live end-to-end against the
  rebuilt api container: `reading_delivery_failures_total` went 0.0 →
  10.0, all 10 ERROR logs carried the correct meterId/readingTimestamp/
  value, and the new "Reading delivery failures" rule correctly reached
  `pending`. Full suite (62 tests) green. **Committed and pushed** as
  `8b7ce23` (declare + callback) and `4566221` (counter + alert + test);
  CI green on both.
  - **The one thing that actually matters here, stated plainly so it
    isn't mistaken for "fixed" later**: this verification proved the
    *observability* pipeline works — it did not stop the data loss from
    happening. The reading is still permanently gone once
    `delivery.timeout.ms` expires during a quorum-loss outage. The real
    fix for that remains the outbox pattern in `docs/resilience-scope.md`,
    not built yet.
  - **Gap closed with a direct, continuously-observed re-test** (per
    explicit user request — "better to find an issue now rather than
    later" — rather than leave the earlier inference as good enough).
    Triggered a fresh quorum-loss failure (stop `kafka-2`/`kafka-3`, send
    10 readings) and polled the rule's actual state every 15s
    uninterrupted through the whole window. Full timestamped transcript:
    counter jumped 10.0→20.0 at exactly +120s (matching
    `delivery.timeout.ms`'s 120000ms precisely); state reached `pending`
    at +150s; reached **`firing` at +180s — exactly 30s after `pending`
    began, matching the rule's `for: 30s` to the second**; held `firing`
    across 5 more consecutive 15s checks through +240s. Normal → Pending
    → Firing now directly confirmed, not inferred. Brokers restored
    afterward, cluster healthy.
  - **k8s side explicitly still open, not dropped**: this was tested
    against Compose only. `k8s/kafka.yaml` is still single-broker and
    never got the 3-broker cluster, the relabeling fixes, or this new
    alert rule. Already tracked below, restated here so it doesn't
    quietly fall off the list now that the Compose side feels "done."

- **Moved to `docs/resilience-scope.md` per a Claude Chat staged plan**
  (Stage A → B → C → D → E, plus the Kafka health indicator as an
  independent parallel item). Completed so far:
  - **Stage A (outbox write path, no reconciler)**: new `reading_outbox`
    table (`V5` migration), `ReadingOutbox`/`ReadingOutboxRepository`.
    `ReadingService.ingest()`'s existing failure callback now writes here
    instead of only logging/counting — the data survives a
    `delivery.timeout.ms` expiry, though it isn't queryable via `GET
    /readings` yet (no reconciler — that's Stage D). `kafka-ha-demo.sh`'s
    scenario 2 updated to check the outbox alongside the readings table,
    distinguishing "genuinely lost" from "captured, not yet visible."
    Verified live: re-ran the 150s quorum-loss scenario, all 10 readings
    now land correctly in `reading_outbox`. **Committed and pushed** as
    `5d82fd2`; also promoted a one-off diagnostic (the pending→firing
    watcher) into a reusable `load-tests/watch-alert-rule.sh`.
  - **Kafka health indicator** (independent item, done in parallel):
    `ReadingsKafkaHealthIndicator`. Found a real Spring Boot 4 API move
    while building it — health classes live in a new `spring-boot-health`
    module (`org.springframework.boot.health.contributor`), not
    `spring-boot-actuator` — via jar inspection, not assumed. Deliberately
    does not build on `KafkaAdmin.clusterId()`: its real source shows it
    caches the cluster id after the first success and swallows exceptions,
    which would make a polled health indicator silently stop reflecting
    live state. Builds a fresh `Admin` client per check instead. Verified
    live: stopped all 3 brokers, `/actuator/health`'s aggregate status
    flipped UP→DOWN, recovered to UP on restart. Also confirmed a real,
    separate gap while doing this — no Docker healthcheck or Traefik
    `loadbalancer.healthcheck` label exists for `api` at all; Traefik
    currently routes with no active check whatsoever. Flagged, not fixed.
    **Committed and pushed** as `b0cd179`.
  - **Not started yet**: Stage B (sustained-outage load test at `--scale
    api=2`, measuring real outbox growth), Stage C (set bound values from
    B's data), Stage D (reconciler, built correctly for 2 replicas from
    the start with `SELECT ... FOR UPDATE SKIP LOCKED`, plus 503-on-bound
    shedding), Stage E (2-replica end-to-end verification). Circuit
    breaker build order still pending a check of the `resilience4j-
    spring-boot4` BOM gap.

Next:

- k8s Kafka HA follow-up slice (`k8s/kafka.yaml` → 3-broker StatefulSet,
  plus the relabeling fixes and the new "Reading delivery failures"
  alert) — not started, mirrors all the Compose work above.
- Consider also declaring Kafka's `retries` / `buffer.memory` explicitly
  — `max.block.ms` and `delivery.timeout.ms` are both now declared; these
  two remain undeclared defaults for now.
- Wait for user direction on the remaining 4 new `docs/` files (ha-scope,
  testing-strategy-ha-supplement, observability-taxonomy,
  cloud-deployment-scope) — still conferring with Claude Chat, nothing to
  do here yet.
- **Discuss and design trend alerts as a separate task** — capacity-
  climbing-over-time alerts (the writer-node/blue-green-upgrade-planning use
  case), distinct in shape from the existing threshold-crossing incident
  alerts. Not started; needs its own scoping discussion first.
- Decide data-tier HA expansion scope — Kafka first, or Kafka+Redis, or all
  three including Postgres+Patroni/Consul — not decided yet.
- Whenever picking this back up: this file plus `status/claude_code_2026-08-26.md`
  and `status/claude_code_2026-08-24.md` cover current repo state; no other
  session context needed. Environment starts cold (Compose stopped, no
  `kind` cluster) — see the close-out note above.
