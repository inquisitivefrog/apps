# Session status — 2026-09-04 (Claude Code)

**Status: open, kept running through the day rather than closed at a single
stopping point** — this file will be updated as the session continues; treat
it as current-through-last-edit, not a final EOD summary yet.

## Done

- **Full CLAUDE.md/docs/status/ review, per user request.** Delegated to
  three parallel research agents (docs were too large to read directly)
  and synthesized their findings. Found several real doc-drift gaps:
  `observability-taxonomy.md` still called the circuit breaker "unbuilt"
  after it shipped; `vendor-bug-report-process.md`'s status table still
  showed Redis/Postgres HA work as "Not started" after both closed;
  `architecture.md`/`identity.md` still described Terraform/TLS as
  out-of-scope after `cloud-deployment-scope.md` reversed both decisions
  on 2026-08-27. Fixed all four (commit `60b7476`). Also flagged (not
  yet acted on, Chat's call): the "chaos-tested infrastructure ≠
  protected application" methodology finding wasn't in CLAUDE.md's
  standing-lessons section — the user/Chat added it directly to
  CLAUDE.md shortly after.

- **Built the full Playwright E2E tier from scratch, in five batches,
  each live-verified against the real stack before moving on — commit
  `849cc1f`:**
  - **Batch 1 (scaffolding)**: `e2e/` at the repo root (sibling to
    `api/`/`frontend/`, per a quick structural check-in), `@playwright/test`
    pinned to the live-verified current stable (`1.62.1`), Chromium-only
    with cross-browser expansion noted as deliberate future scope, a
    throwaway smoke spec run and deleted to prove the harness works.
  - **Batch 2a (app journeys)**: login/logout, meter create-edit-delete
    (`E2E-`-prefixed, API-cleaned-up in `afterEach`), readings
    search/filter/pagination (own self-contained seed fixture — a
    meter plus 12 readings via the real `POST /readings` +
    `Idempotency-Key` contract, polled until the async Kafka-ingest
    path actually landed them, not fire-and-forget), and the readings
    page's no-create/edit-affordance negative assertion. **Found and
    fixed a real bug in the test itself, not the app**: `navigate()`
    updates the URL before React Router's route swap finishes
    rendering, so asserting on the URL alone could interact with the
    outgoing page's stale fields — root-caused via direct network-request
    logging, not guesswork, and named as the same "proxy signal ≠ real
    condition" pattern `testing-strategy.md` already warns about.
  - **Batch 2b (observability UIs)**: `ui-services.ts` fixture,
    Grafana (found live: no login at all — anonymous Admin via
    `GF_AUTH_ANONYMOUS_ENABLED`, a deliberate dev-only posture, not a
    bug) and Consul (found live: UI wasn't host-reachable at all —
    added the `8500:8500` port mapping to `docker-compose.yml` after
    confirming the port was free and deciding, per Chat, that exposing
    it beats dropping the check). Screenshots added per explicit user
    request.
  - **Batch 2c (CLI connectivity checks)**: `cli-services.ts` fixture.
    Live-verified every access path rather than assuming: Redis has no
    `requirepass` and no host-published port at all (exec-only, checked
    via Sentinel discovery); Postgres's `:55432` Traefik entrypoint is
    still current (confirmed live); Kafka's bootstrap port isn't
    published (exec-only); Consul's CLI check (`consul members` +
    `consul operator raft list-peers`) is deliberately separate from
    2b's UI check.
  - **Resource-measurement pass** (before scoping CI): peak aggregate
    Docker memory ~3.6–3.7 GiB, peak host-native Chromium/Playwright
    memory ~1 GiB (a separate pool from Docker Desktop's VM on this Mac
    — explicitly flagged as NOT the same comparison a GitHub-hosted
    runner's shared pool would need), combined ~4.6 GiB against a
    live-confirmed 7 GB standard-runner ceiling. Peak Docker-container
    CPU alone (270–293%) already exceeds a standard runner's 2-vCPU
    ceiling — flagged as the more likely blocker than memory.

- **Phase 3: self-hosted E2E CI, genuinely proven green, not just
  reviewed — commits `ca2a4b2`, `98ca5d9`, `64c005e`.** Registered this
  Mac as a self-hosted GitHub Actions runner (user ran the actual
  `config.sh`/`svc.sh` commands themselves after Claude Code's own
  attempt was correctly blocked by the auto-mode classifier as a
  standing, security-relevant change). New workflow
  (`.github/workflows/grid-meter-app-e2e.yml`, non-blocking, push-
  triggered, `--workers=2`, 20-min timeout), backed by
  `scripts/preflight-ci-check.sh` (Docker running + ports free, mirrors
  `check-disk-headroom.sh`'s pattern) and
  `scripts/wait-for-patroni-convergence.sh`. **The 112s-vs-26s Patroni
  convergence question was answered empirically, not assumed**: tried
  connecting to the replica `cli-postgres.spec.ts` targets at the exact
  moment `/actuator/health` goes green — connection refused. Traced
  further: a replica only accepts connections once its own state
  reaches `streaming`. Found and fixed two real, non-obvious
  self-hosted-macOS gotchas getting the runner actually green: (1) the
  launchd service's non-interactive session can't unlock the macOS
  keychain, so Docker's default credential helper fails even on
  anonymous public-image pulls — fixed with a separate `DOCKER_CONFIG`
  scoped to just this runner; (2) that fix alone wasn't enough for
  images not yet locally cached (buildkit only skips the
  keychain-dependent check for cache hits) — fixed by pre-pulling all
  16 base images this project uses. Documented both as durability
  warnings (workflow YAML + `preflight-ci-check.sh` header) so a future
  runner rebuild (`svc.sh install`, `docker system prune -a`) doesn't
  silently reintroduce either failure mode from scratch. **4 consecutive
  real green runs** on the actual runner, confirmed via `gh run
  view --log` that the real 11-test suite ran and passed each time
  (not just a green job shell).

- **Fixed `scripts/run-black-box-api-tests.sh`'s "no such service:
  postgres" CI failure (separate thread, doesn't touch the E2E track) —
  commit `8315625`.** Root cause: the standalone `postgres` Compose
  service was retired after the Postgres HA cutover, but this script
  never got updated. Deliberately did *not* apply the suggested
  `kafka-ha-demo.sh`-style Traefik/`PGPASSWORD` fix pattern, since this
  script never queries Postgres at all — it only needs to bring up the
  right containers, and `api`'s own `depends_on` already covers the
  full Patroni/Consul/registrar chain, so the actual fix was just
  removing the dead service name (more robust than hand-duplicating
  that list, which is itself proof of how this bug happened). Verified
  live: 18/18 Failsafe tests pass (`ReadingApiIT` 10, `MeterApiIT` 8).
  A fresh repo-wide sweep (prompted by Chat's question about whether
  the 2026-09-03 sweep's scope had a gap) found exactly one more real
  instance — `load-tests/chaos-demo.sh` — and confirmed every other
  grep hit was a false positive (`-U postgres` the superuser name,
  `postgres-primary-registrar`/`postgres-primary` both real, still-
  existing entities). Fixed `chaos-demo.sh` too, per Chat's explicit
  decision: reframed `postgres` → `patroni-1` in its `LINKS` array as a
  single-node-loss "should be a non-event" case, matching `kafka-1`'s
  existing framing under the 3-node HA cluster, rather than silently
  keeping total-outage wording for what's now the boring/expected case.
  Verified two ways: a full real run of the script end-to-end, and an
  isolated direct test (continuous authenticated requests against the
  API while only `patroni-1` was stopped/started) to confirm the
  "non-event" claim is actually true — **40/40 requests returned 200**,
  isolated from the other four outages' noise. Screenshots from the
  verification run committed too, matching this project's existing
  convention of keeping chaos-demo screenshots as evidence, not
  disposable output.

- Deleted `grid-meter-app/CI_Pipeline`, a confirmed-accidental paste of
  an earlier chat message that was never meant to be a project file
  (was never git-tracked, so no commit needed for the deletion).

- **Kafka `external_confirm_s` root-cause follow-up: both of Chat's
  ordered candidates (ISR catch-up lag, then GC-pause noise) tested
  directly and refuted — not committed yet, awaiting review.**
  Candidate 1 refuted against the archived 20260903T175404Z pass's raw
  `controller.log` slices: the target partition's ISR/leader handoff
  happens instantly (~0.14s) via the *dying* broker's own graceful
  SIGTERM-triggered shutdown, identically in both conditions — no
  separate re-sync for the new controller to wait on. Found a more
  precise breakdown along the way: controller activation itself is a
  roughly *constant* ~2.3–2.5s across all 3 archived trials (not the
  source of the 4.0–15.15s spread); the real variable component is the
  gap *after* activation (1.5s–12.8s archived). Candidate 2 required a
  fresh live trial (archived trials' GC logs don't survive — no
  persistent Kafka volume) — new script
  `load-tests/kafka-external-confirm-gc-check.py`, reproduced the same
  shape (2.394s activation, 14.087s `external_confirm_s`, 11.693s
  post-activation gap) and found **zero GC events** in that entire
  window on the new controller, with the instrument itself verified
  working first (real GC entries exist from JVM startup moments
  earlier). Real mechanism remains genuinely unknown — reported
  plainly rather than forced, per this task's own explicit standard.
  One unchased lead named for later: AdminClient-side retry/backoff
  inside the single `kafka-topics.sh --describe` call itself could
  produce this shape without any JVM- or partition-level explanation —
  not investigated, would be a third, unscoped cycle beyond what was
  asked. `docs/testing-strategy-ha-supplement.md`'s "still neither has
  been tested" note fully rewritten with this account.

- **Third, bounded round on the same Kafka investigation (Chat
  greenlit it, given how closely the lead matched this thread's own
  already-proven bug pattern): the "unchased lead" turned out not to
  be client-side retries, but led to precisely localizing the real
  mechanism instead.** Enabled `org.apache.kafka.clients` DEBUG logging
  for the `kafka-topics.sh --describe` call itself (existing capability
  via `KAFKA_LOG4J_OPTS`, no source change) and correlated every
  request/response pair against two fresh controller-kill trials, live.
  Found: every request type resolves in single-digit milliseconds
  *except* `ListPartitionReassignments` sent to the new controller,
  which stalls for many seconds — 18.6s in trial 1 (83% of that trial's
  22.5s total), 10.5s in trial 2 against a different new controller
  (74% of that trial's 14.3s total). Not a retry loop at all — one
  outstanding request the newly-active controller itself doesn't
  answer promptly. New script
  `load-tests/kafka-external-confirm-adminclient-check.py`; both runs'
  full transcripts properly archived under `load-tests/results/`
  (moved there from `/tmp/`, where they first landed — didn't repeat
  this investigation's own already-documented archival-gap mistake).
  *Why* that one request type specifically stalls (a KRaft-controller-
  internal question) is one level deeper than this bounded round
  covers — stopped there per Chat's explicit scope, not chased further.
  `docs/testing-strategy-ha-supplement.md` updated again: status is now
  "three candidates tested, first two refuted, third reframed into a
  precise, reproducible, named bottleneck" rather than "still unknown."
  Not committed yet.

- **Diagnosed and closed the CI pre-flight-conflict Chat flagged from
  two failure screenshots — confirmed as the check working as designed,
  not a bug, then improved it anyway.** Mac was already clean by the
  time this was checked (today's diagnostic stacks had already been
  torn down). Re-triggered the E2E workflow to confirm green — and in
  the process, **almost caused a real collision myself**: ran a manual
  `docker compose up -d traefik` without checking whether the just-
  triggered CI run was already using the same stack. It was (mid
  "Wait for Patroni HA convergence"). Caught it via `gh run view`
  before doing anything destructive, backed off immediately, and let
  the CI job finish untouched — it completed successfully (11/11 real
  tests passed, confirmed via log, not just a green checkmark) despite
  the near-miss. Worth remembering: check a just-triggered run's live
  status before touching the same stack manually, not just before
  running `docker compose down`. Improved
  `scripts/preflight-ci-check.sh` per Chat's request: conflicts now
  cross-reference `docker ps` to report the actual owning container and
  its uptime (macOS's `lsof` always attributes Docker Desktop's
  published ports to Docker Desktop's own proxy process, never the
  real container — confirmed live this was genuinely uninformative
  before), tested against both a real conflict (3 containers, 5 ports)
  and a clean state. Added a note to `CLAUDE.md`'s CI section — which
  turned out to itself be stale (still said "no CI pipeline exists
  yet" despite three workflows now existing) — fixing that plus adding
  the dual-duty-runner tradeoff Chat asked for. Not committed yet.

## Open / Next

- **Nothing currently blocked.** Both today's threads (E2E track
  Phases 1–3, and the postgres-reference fix + its sweep follow-on)
  are closed per Chat's own confirmation.
- **Not yet promoted to a required/blocking check**: the new
  `grid-meter-app-e2e.yml` workflow is intentionally non-blocking for
  now (matches `testing-strategy.md`'s existing precedent for
  new/possibly-flaky tiers) — promote later once proven stable over
  more real runs, not a decision made yet.
- **A possible future addition, explicitly not built now**: a genuine
  full-Patroni-cluster-outage scenario (all 3 nodes down at once) as
  its own distinctly-named case in `chaos-demo.sh`, separate from the
  single-node-loss `LINKS` loop. Flagged, not scoped or requested yet.
- **Peak Docker-container CPU (270–293%) already exceeds a standard
  GitHub-hosted runner's 2-vCPU ceiling** — not relevant to the
  self-hosted runner actually in use, but worth remembering if this
  workflow's `runs-on` target is ever reconsidered.
- The Mac's Docker stack is currently **down** (no containers running)
  as of this file's last edit — several manual verification runs
  happened during the session and the stack wasn't brought back up
  afterward. `docker compose up --build -d` from `grid-meter-app/` to
  resume.
- Working tree is clean; everything through commit `8315625` is pushed
  to `main`.
