# Session status — 2026-08-31 (Claude Code)

Backfilled retroactively on 2026-09-02 (no status doc was written at the
time) from git history — grouped by topic, not strictly chronological.
Entirely the Postgres/Patroni/Consul HA investigation: Stages 2 through 6
of `docs/postgres-ha-scope.md`, continuing from Stage 0/1 done the
previous session.

## Done — Stage 2 (topology): synchronous-replication mode resolved

- Found Patroni's `synchronous_mode: true` default had silently picked
  single named-standby mode (pinned to `patroni-2`) for a decision the
  doc had explicitly flagged as not yet made — the 8th instance of this
  project's undeclared-durability-default pattern, and a sharper one: a
  documented open question got closed by a vendor default before anyone
  chose, not just unconfigured silence.
- Resolved to quorum `ANY 1(*)` (confirmed with the user), live-verified
  via `SHOW synchronous_standby_names` and `patronictl list`, declared
  directly in `patroni.yml`'s bootstrap section so a fresh cluster build
  doesn't reopen the gap.

## Done — Client write-routing spike (Traefik + Consul Catalog)

- Resolved the doc's stated hard requirement before Stage 4: verify a
  client can actually be routed to whichever node is currently primary,
  not just that Patroni promotes correctly internally.
- Deliberately did not use Patroni's own `register_service` Consul
  feature (a documented upstream issue, patroni/patroni#2517, describes
  its service tag getting stuck stale after a Consul hiccup). Instead,
  Consul actively polls each node's own Patroni REST API (`/primary`)
  via a manually registered `postgres-primary` service; Traefik's Consul
  Catalog provider routes a new `:55432` TCP entrypoint to whichever
  instance passes.
- Verified live across two independent failover directions — exactly one
  node ever reported passing, real connections followed the real primary
  each time, zero flapping on the demoted node.

## Done — Stage 3 (single-replica loss): both sub-tests clean

- Killed `patroni-2` and `patroni-3` independently — both symmetric under
  quorum `ANY 1(*)` as predicted, no blocking, clean degrade-and-recover,
  marker rows verified via direct query on both primary and rejoined
  replica.
- **Fencing decision resolved**: rely on Patroni's built-in self-demotion
  rather than bespoke Docker-socket fencing (real watchdog support isn't
  available on Docker Desktop for Mac) — Stage 4 to measure the actual
  self-demotion window rather than assume it's safe.
- **`sync_mode_strict` decision resolved**: left unset, based on real
  measured numbers under both settings (bounded 126ms–6.4s fallback to
  async vs. an indefinite, `statement_timeout`-immune 82.8s hang), not
  documentation alone.
- **Real bug found and fixed**: `date +%3N` silently misparses on this
  Mac's BSD-derived `date` (bare `%N` works, GNU's field-width modifier
  doesn't) — found because the resulting bash arithmetic error silently
  truncated a write-verification loop after one iteration while the
  script's own summary still reported full success. Same idiom found and
  fixed in `kafka-acks-gap-repro.sh` and `capture-connection-reset.sh`; a
  repo-wide audit for other GNU-only flags found nothing further.
  **Promoted to a third named standing pattern** (GNU-vs-BSD tooling
  assumptions) in `CLAUDE.md`/`docs/testing-strategy.md`, alongside the
  undeclared-default and fixed-sleep patterns — this being the second
  independent hit from the same root cause.

## Done — Stage 4 (primary failure): fencing decision confirmed

- Kills the current primary under real write load, measures real
  promotion RTO, confirms the last acknowledged write survives, verifies
  client-observed failover through Traefik + Consul Catalog, precisely
  measures the split-brain window on rejoin.
- 3/3 clean runs, each killing a different node as primary. Self-demotion
  measured at a consistent ~310–345ms, zero observed split-brain across
  all 3 — stated precisely as "no split-brain window at this measurement
  granularity," not an absolute guarantee.
- A `set -e`/command-substitution bug (an unguarded write-check sibling
  to a correctly-guarded read check) found while building the script —
  recorded in `docs/cross-project-lessons.md`, confirmed related to but
  distinct from that same morning's disk-headroom-guard crash (platform-
  agnostic asymmetric oversight vs. a platform-specific tooling
  difference), so not promoted to a fourth named pattern.

## Done — Stage 5 (Consul degradation): two genuinely different sub-scenarios

- **Sub-scenario A** (partition the primary from its own paired Consul
  agent, Postgres itself never touched): a real methodology bug found
  and fixed first — an `/etc/hosts` blackhole alone has no effect on
  Patroni's already-open, pooled Consul connection; the script also
  restarts the target agent to force that connection closed. 3/3 clean
  after the fix. Self-demotion took 15–20s here — TTL/retry-driven, not
  the fast local-restart check Stage 4 measured — with a real ~8–21s
  availability gap before a new primary took over.
- **Sub-scenario B** (kill a non-leader, non-primary-paired Consul
  agent): confirmed a non-event, with one nuance — a Consul-reporting
  visibility gap for the replica paired with the killed agent, distinct
  from its actual (unaffected) replication state.
- Fencing decision's conditional acceptance updated to be understood as
  accepting Sub-scenario A's larger availability-gap magnitude, not the
  sub-second number Stage 4 alone would have suggested.
- Evidence archive (`NOTES.md`) brought current for Stages 1–5,
  previously stale at Stage 0 with a contradicting "IN PROGRESS" tail;
  raw run transcripts backfilled for every Stage 3/4/5 run, including
  invalid ones (a stale pooled-Consul-connection bug, an `awk`
  field-index bug), matching this project's precedent of keeping the
  real kinks archived alongside clean results.

## Done — Stage 6 (Consul quorum-loss under real load): fail-safe confirmed, twice

- Kills 2 of 3 Consul agents (below raft majority) while Postgres is
  under real load. Methodology note: Patroni's own Consul reads use
  `consistent=1`, which Consul refuses outright without quorum, so
  `patronictl` is expected to fail on every node during this exact
  window — the script polls each node's own `pg_is_in_recovery()`
  directly instead.
- **9th confirmed instance of the undeclared-durability-default
  pattern**: `PATRONI_CONSUL_CONSISTENCY` was completely undeclared
  despite governing whether Patroni's cluster-state reads could return
  stale data during exactly this scenario. Live-verified via DEBUG log
  inspection that the undeclared default already matched the safe value
  this stage's result depended on; declared explicitly to stop relying
  on that being a coincidence.
- First pass, 3/3 clean (each run leaving a different agent up): Consul
  correctly refused writes without quorum every time, no unsafe
  promotion. Two real script bugs found: a self-inflicted `SIGPIPE` from
  piping a state-mutating script through `head` (killed cleanup mid-run,
  manually recovered), and an unreproduced `date +%s%N`-driven loop-exit
  anomaly worked around via bash's `SECONDS` builtin.
- **Re-run a second time** to close two gaps: Traefik's client-routing
  behavior during quorum loss (never observed in the first pass), and
  whether the 1-of-3→2-of-3 recovery transition was watched directly
  rather than inferred from an eventual healthy end-state. Traefik froze
  on stale routing for the full ~59s outage in all 3 re-runs (expected —
  Consul can't push any routing update without quorum). Recovery was
  clean in all 3 (exactly one node elected, never ambiguous) but timing
  varied widely (7s, 37s, 7s) — reported honestly as unexplained
  variance rather than smoothed into a misleading average.
- **The early-exit loop anomaly from the first pass was root-caused on
  the re-run**, not just re-mitigated: the same shape recurred even with
  the `SECONDS` fix in place, traced to a Bash tool call exceeding its
  foreground timeout and being migrated to background mid-script, which
  itself disrupts a running script's loop execution — confirmed by
  re-running the identical scenario launched as background from the
  start, which then completed cleanly. Recorded as a portable lesson in
  `docs/cross-project-lessons.md`: launch any long-running script as
  background from the start, don't let it be migrated mid-run.

## Done — other fixes and closures

- **Resource-budget re-measurement gap closed**: Stage 2's write-up had
  said "not yet re-measured against the full topology" and nothing in
  Stages 3–6 forced another look, so the gap sat open through the whole
  investigation until caught on direct re-test. Real numbers: Postgres
  HA layer (Consul + Patroni, 3+3 containers) ~414 MiB; full stack
  ~3.53–3.57 GiB, ~4.2 GiB headroom under the 7.749 GiB VM ceiling — the
  original "~8.2–8.9 GiB, exceeds the ceiling" estimate confirmed
  substantially overstated, same direction as Redis's own estimate-vs-
  real gap.
- **CI fix**: `check-disk-headroom.sh`'s `df -g /System/Volumes/Data` is
  macOS-only — no such path and no `-g` flag on Linux, so the nightly
  load-test GitHub Actions workflow failed outright on two consecutive
  scheduled runs (2026-08-30, 2026-08-31) with zero output. Because the
  script is *sourced*, not executed, its failing pipeline tripped the
  calling script's own `set -euo pipefail` before the script's intended
  graceful fallback ever ran. Fixed by guarding both `df` attempts with
  `|| true` and adding a real Linux/GNU `df` fallback, verified in an
  actual Ubuntu container.
- Stage 6's closing addendum connects the root-caused early-exit anomaly
  back to the original (mitigated-but-unexplained) Stage 6 finding,
  recording the reversal explicitly rather than editing the original
  note away — matching this project's standing practice for corrected
  findings.

## Next steps (as of end of this session)

- Stage 7 (app-level cutover) not yet started — the app was still
  pointed at the standalone `postgres` container throughout all of
  Stages 2–6, an explicitly-named open gap.
- `bootstrap.users`/`post_bootstrap` hook declared but not yet verified
  against a real from-scratch bootstrap (done the following session,
  2026-09-01 — it was broken).
- `redis-quorum-loss.sh`'s minor restore-step bug (`start` vs.
  `--force-recreate` on Sentinels) still not fixed — low priority, noted
  from the prior session.
