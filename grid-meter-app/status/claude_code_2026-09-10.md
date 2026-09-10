# grid-meter-app — Status: 2026-09-10 (Claude Code)

Direct continuation of `status/claude_code_2026-09-09.md`'s k8s Redis
Sentinel HA work — Claude Chat reviewed the finished write-up and pushed
back twice, each time surfacing something real rather than being a
formality. Closed out both rounds, then closed the slice out fully per
Chat's own checklist, then a user question surfaced a real doc-hygiene
gap in an unrelated but adjacent doc. The day then moved into GitHub
Actions education/manual-trigger work, a real sustained-load-testing
investigation, and — once Claude Chat wrote
`docs/testing-expansion-scope.md` in a separate thread — building and
live-verifying the first two items (§1.1, §1.3) of its 11-item plan before
pausing for the day.

## Done — Chat round 1: is Bug 1 new or pre-existing, and what's the real mechanism?

- Claude Chat (relayed by the user) pushed back on the prior day's
  write-up: don't assume the stale-`get-master-addr-by-name` bug is new
  just because it was found right after a parameterization change — test
  it. Also asked whether the real mechanism was "a single Sentinel's own
  internal state lags" (as documented) or a genuine quorum-vs-single-
  responder race (different Sentinels disagreeing, not just one being
  slow).
- **Confirmed pre-existing, empirically, not by reading the diff.**
  Swapped the exact pre-parameterization script
  (`git show 2632bd5:.../redis-entrypoint.sh`) into the live Compose bind
  mount as a negative control and re-ran the identical Stage 4
  reproduction: it hit the same mechanism, confirmed via the entrypoint's
  own boot log (`sentinel-1 reports current master is redis:6379 (attempt
  1)` — byte-identical shape to the original finding, since that version
  has no flags-checking at all). Restored the fixed script and
  force-recreated the Compose tier immediately after, confirmed healthy.
- **Confirmed the sharper mechanism via direct log cross-reference,
  not assumed.** Checked all 3 Sentinels' own logs from the original
  bug reproduction: the elected failover *leader* (sentinel-1, which has
  to actually drive the reconfiguration) reached its own `+switch-master`
  **6.25 seconds after** the two followers (which just observe the
  promotion) reached theirs. The original script always queries
  sentinel-1 first and trusts the first non-empty answer with no
  cross-check — a genuine quorum-vs-single-responder gap, not merely "the
  answer lags." The already-shipped fix (per-Sentinel flags gate, tries
  each host in order, skips dirty ones) incidentally closes this too,
  since it'll skip a lagging leader in favor of an already-settled
  follower.
- Updated `docs/k8s-redis-ha-scope.md` with the sharper root cause and the
  negative-control evidence. Committed and pushed as `197c1a8`.

## Done — Chat round 2: prove the fix, not just the diagnosis

- Chat's second pass (after seeing the actual current file, confirming
  the flags-gate fix is real and structurally sound — the earlier
  quoted "no flags check" loop turned out to be a stale pasted snapshot
  from mid-negative-control-test) asked for one more explicit thing: run
  the *exact* Stage 4 primary-kill scenario against the fully-fixed
  script, checked the same way the original bug was found (role + live
  write-attempt polling, not "no errors observed").
- Ran it. **`SPLIT-BRAIN: NO`, demoted at `t+0.13s`** — the cleanest
  result of the whole investigation. The entrypoint's own captured boot
  log shows it identified the real master correctly on the very first
  attempt with clean flags and started as a replica immediately, with no
  window at all where it claimed to be master.
- **A separate, honest finding from that same run**: its own setup phase
  (unrelated to the kill test) hit real contention — all 3 Sentinels
  stayed dirty for the entire 60-attempt budget during the cold-bootstrap
  reset, so the default node fell through to its already-documented
  no-fallback bare-start path. Not a bug (loud, not silent, by design;
  correct by construction here) — but a real, now-live-observed data
  point about how often that fallback actually gets exercised under this
  Mac's real contention (kind + Compose + CI running simultaneously).
- Updated the doc, committed and pushed as `78c70b7`.

## Done — closing the slice per Chat's checklist

- **`docs/ha-scope.md`'s "Revisit triggers"**: trimmed the big "done"
  bullet to a short closed pointer (full detail already lives in
  `docs/k8s-redis-ha-scope.md`), and added a new, separate,
  forward-looking note specifically about the contention-driven fallback
  finding — kept visible rather than left only in the investigation's own
  narrative, per Chat's explicit ask. Mirrored as a one-line comment
  directly next to `scripts/redis-entrypoint.sh`'s `max_attempts=60`.
- **`k8s/README.md`**: already correct from the prior day, verified.
- **Fresh end-to-end re-verification**: given how much manual Compose
  swapping happened during the investigation, didn't just re-apply onto
  the existing (21-hour-old, heavily-poked) `kind` cluster — tore it down
  and did a genuinely clean `kind create cluster` + `./k8s/deploy.sh` +
  full functional check (login → create meter → ingest reading →
  confirmed async landing → confirmed the Redis cache key on the
  Sentinel-reported primary, correctly identified by hostname from a real
  cold bootstrap). Clean throughout; test data cleaned up.
- Committed and pushed as `48e479f`.

## Done — vendor-bug-report-process.md hygiene, prompted by a direct user question

- User asked whether `docs/vendor-bug-report-process.md` needed updating.
  Checked rather than assumed: its status table's conclusion for Redis
  was still accurate (all 3 bugs found are in this project's own
  `scripts/redis-entrypoint.sh`, confirmed not a Redis/Sentinel defect —
  no change to the "no vendor-bug candidate" verdict needed), but the
  date was stale and the investigation wasn't mentioned at all.
- **The real gap**: `load-tests/vendor-bug-reports/redis/NOTES.md` hadn't
  been touched since the original 2026-09-02 investigation, even though
  this session's work generated roughly 15 new evidence run directories
  under `redis/runs/` — a genuine violation of the process doc's own
  stated discipline ("update NOTES.md after any run worth keeping...
  don't let the two drift out of sync"). Added a full run index for the
  k8s follow-up, pointing at `docs/k8s-redis-ha-scope.md` as the
  authoritative narrative per the file's existing "index, don't
  duplicate" convention.
- Committed and pushed as `9e8aa32`.

## Done — GitHub Actions: manual triggers and CI/CD education

- User asked whether existing pipelines can be run on demand (not an
  expert with GitHub Actions). Explained `workflow_dispatch` and
  demonstrated it concretely against this project's own workflows via
  `gh workflow run`, then walked through checking run status with
  `gh run view <id> --json status,conclusion,jobs` — writing stdout to a
  file first, since piping straight into a JSON parser sometimes pulled in
  stray `gh` debug-log lines and broke parsing.
- Triggered and verified `grid-meter-app-e2e.yml` per explicit request —
  it had been failing repeatedly on the self-hosted runner due to a port
  conflict with a `kind` cluster left running on this same Mac (this
  project's self-hosted-runner tradeoff, documented in `CLAUDE.md`'s CI
  section). Confirmed clean once the conflicting stack was torn down.
- Answered a follow-up question (GitHub Actions and CD): yes, the same
  platform can do push-and-deploy, not just build-and-test — this
  project's own workflows are CI-only by design, so explained the
  distinction and what an Environments-gated CD workflow would add.
- Triggered the remaining dispatchable workflows (CI, load-test) once
  each, per request, checking each run's final status the same
  write-to-file-first way.

## Done — load-test workflow: a real stale-service-reference bug, found twice

- The load-test workflow failed outright: `docker compose up -d --build
  traefik api postgres kafka-1 kafka-2 kafka-3 redis` → `no such service:
  postgres`. Root cause: the standalone `postgres` container was retired
  when Postgres HA Stage 7 cut over to Patroni — the same stale-reference
  shape already fixed elsewhere in this project. Fixed by removing the
  dead name; verified `api`'s own `depends_on` in `docker-compose.yml`
  already pulls in everything needed (patroni-1/2/3,
  postgres-primary-registrar, kafka-1/2/3, redis, sentinel-1/2/3).
- Per this project's "a declared-complete sweep still misses instances"
  lesson, grepped the whole repo rather than trusting the one fix was the
  only one — found and fixed an identical stale example command in
  `load-tests/README.md`. Re-triggered the workflow; confirmed the fix
  held (run succeeded end to end).
- Committed and pushed as `8815b95`.

## Done — a real question about sustained/soak load testing, investigated honestly

- User recalled a genuine past incident — an unclosed Java object
  accumulating over a weekend-long run until it exhausted server
  resources — and asked whether this project has equivalent sustained
  load-test coverage. Investigated rather than reassured: `soak.jmx`
  existed but had never actually been run anywhere near leak-detection
  timescale, and the JWT's 60-minute TTL with no refresh token would hard
  -fail any real extended run with a 401 burst at the one-hour mark — a
  blocking gap, not a minor one.
- Follow-up questions (does JMeter genuinely represent concurrent clients
  hammering the app, and are Grafana dashboards snapshotted periodically
  to detect drift) were answered by checking the actual `.jmx` thread-group
  structure (yes, genuinely concurrent) and confirming no dashboard
  -snapshotting mechanism existed at all.
- These findings fed directly into Claude Chat's `docs/testing-expansion
  -scope.md` (written in a separate Chat thread — see
  `status/claude_chat_2026-09-10-testing-expansion.md` for that side of
  the work in full).

## Done — reviewed testing-expansion-scope.md, resolved 5 open decisions, started the build

- Reviewed Claude Chat's new `docs/testing-expansion-scope.md` in full.
  Verified one factual claim against the live codebase rather than taking
  it on faith (confirmed `PostgresUnavailableComponentTest` really is
  already in the CI-required `mvn test` tier, closing one doc claim as
  anticipated rather than assumed).
- Elicited explicit sign-off on the doc's 5 flagged open decisions from
  the user: soak leak framing (volume-based/accelerated, not time-based),
  HA-regression failure policy (auto-file a GitHub Issue, non-blocking),
  seed-customer naming (synthetic company names), UI load-test timing
  (build alongside Part 3), and JFR timing (defer until the heap-trend
  metric actually signals a leak). Recorded all 5 resolutions directly in
  the doc.
- Set up an 11-item task list (#7–17) matching the doc's stated build
  order. Committed the doc plus its resolved decisions as `7fd2dcd`.

## Done — built and live-verified §1.1 (soak.jmx re-auth) and §1.3 (heap-after-GC trend alert)

- **§1.1**: added a concurrent "token refresh" Thread Group to `soak.jmx`
  that re-runs the shared `common/login.jmx` fragment on an interval,
  overwriting the same `accessToken` JMeter Property every request reads
  live via `${__P(accessToken)}` — no per-thread token-passing needed.
  Caught a real bug before it mattered: `TestPlan.serialize_threadgroups`
  was still `true`, which would have run the new group sequentially
  *after* soak load finished rather than alongside it, silently defeating
  the entire point — fixed by flipping it to `false`. Also hit and fixed
  an XML well-formedness error from a raw `<!-- -->` comment containing a
  literal `--` (invalid per the XML spec); removed it since the
  explanation already lived redundantly in a `stringProp` comment.
  **Functionally verified**, not just XML-validated: brought up the full
  stack and ran a 60-second accelerated soak (15s re-auth interval, 5
  threads). The token-refresh group fired exactly 3 logins at 15s/30s/45s
  as configured, running genuinely concurrently with soak load, and all
  1,395 `POST /readings` samples across the run succeeded (0% errors) —
  the shared-property refresh never disrupted live traffic.
- **§1.3**: added a new Prometheus alert rule,
  `observability/alerting/rules.yml`'s `heap-after-gc-trend`, following
  `observability-taxonomy.md`'s existing resource-capacity-trend category
  (a projected-exhaustion slope, not a hard threshold — never pages
  anyone). Verified the actual GC pool label against the live running JVM
  rather than assumed: this app's small `-Xmx384m` heap gets Serial GC
  under JVM ergonomics, not G1 as initially assumed — confirmed via a real
  `curl /actuator/prometheus` (`gc="Copy"`, pool id `"Tenured Gen"`, not
  `"G1 Old Gen"`), another instance of this project's standing
  verify-the-live-system pattern. The rule itself uses Micrometer's
  collector-agnostic `jvm_gc_live_data_size_bytes`/
  `jvm_gc_max_data_size_bytes` (old-gen size after a full/major GC), so it
  doesn't need revisiting if the heap size or collector choice changes
  later. Verified end to end against a real Grafana instance, not just
  YAML-valid: provisioned cleanly (no error in Grafana's provisioning
  logs), then polled until it left its initial `NoData` startup state and
  settled into `Normal` (0% projected slope — correctly reading "no major
  GC has happened yet" as no signal, not an error).
- One incidental scare along the way, resolved without incident: bringing
  the stack up for testing found a partial stack already running
  (consul/kafka/patroni, but not all instances) that hadn't been started
  this session. Checked for an in-progress self-hosted GitHub Actions run
  before touching anything, per this project's standing caution about
  colliding with CI-owned Docker state on this dual-duty Mac; found none,
  rechecked once more rather than trusting the first read, and confirmed
  it was a same-day E2E workflow's teardown still settling — the stack
  cleared on its own moments later.
- Committed both changes together as `2dbc21f`.

## A durable lesson saved this session

- Confirmed directly by the user: Claude Chat has no live repo access —
  it only sees whatever the user has manually pasted or shared, which can
  go stale mid-investigation. When Chat's feedback cites file contents
  that contradict the live repo, the default hypothesis should be "the
  pasted copy is stale," not "Chat is wrong" or "Code made an error" —
  saved to the `user-workflow-tool-split` memory for future sessions.

## Commits today

`197c1a8`, `78c70b7`, `48e479f`, `9e8aa32`, `8815b95`, `7fd2dcd` — all
pushed to `origin/main`. `2dbc21f` (§1.1 + §1.3) is committed locally but
was **not yet pushed** as of this status update — Chat's own status file
for this thread (`claude_chat_2026-09-10-testing-expansion.md`) states it
was pushed, but that's stale; pushing it is part of this same update.

## Open / Next

- **Paused mid-build-order by explicit request**, at task #9 (§1.2
  validation: a longer accelerated volume-based soak run, now that §1.1's
  re-auth and §1.3's heap-trend detection are both built and verified).
  Not started yet.
- Tasks #10–17 (Part 3's seed migration/blast-radius demo, Part 2's HA
  regression promotion, §1.5 static analysis, §4.1's Nginx load profile)
  are queued but untouched.
- The `kind` cluster was torn down earlier today per explicit request and
  has not been recreated since. The Docker Compose stack was brought up
  twice more for §1.1/§1.3 verification and torn down cleanly both times
  — nothing is running now.
- Carried-over, untouched threads from earlier sessions remain open:
  cloud-deployment (Terraform) scope decision, circuit-breaker
  concurrent-load test.
