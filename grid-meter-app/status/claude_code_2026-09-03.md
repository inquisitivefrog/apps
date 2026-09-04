# Session status — 2026-09-03 (Claude Code)

## Done

- **Full context refresh**: read `CLAUDE.md` and every file in `docs/` and
  `status/` in full, per user request, to catch up on the project's
  current state before doing any work this session.
- **Verified a stale "Open" item from `status/claude_chat_2026-09-02.md`
  is already resolved**: that log flagged "`CLAUDE.md`'s undeclared-default
  tally still needs bumping to 9" as unconfirmed. Checked the real on-disk
  file directly (`grep`, not memory) — it already reads "nine separate
  instances" with `PATRONI_CONSUL_CONSISTENCY` correctly named as the 9th,
  including the right nuance (undeclared but happened to already be at the
  safe value, unlike the other 8). No edit needed; the stale flag itself
  is the only thing that needed correcting, and this file is that record.

- **Investigated the "possible 4th `set -e` occurrence" flagged on
  2026-09-02 — no distinct 4th confirmed; wrote up the real 3rd instance
  instead, per Chat's own audit request.** Checked git commit diffs from
  2026-09-01 through today for any new, unaccounted-for `set -e`/command-
  substitution fix, and grepped every script using `set -e` repo-wide for
  unguarded command substitutions (the same audit style used for the
  GNU-vs-BSD flag audit). Found exactly the three already-known instances
  (Redis Stage 6's `grep -c` zero-match trap, Postgres Stage 4's
  asymmetric adjacent-line guard, Postgres Stage 7's `set -e` inherited
  into a `&`-backgrounded loop) and nothing new beyond them. The real gap
  wasn't a missing 4th occurrence — it was that the 3rd instance
  (Postgres Stage 7's backgrounded-loop bug) had a full narrative in
  `docs/postgres-ha-scope.md` but had never gotten the same
  "General rule" treatment in `docs/cross-project-lessons.md` the first
  two got. Added it there now, in the "Shell scripting and OS-tooling
  pitfalls" section, matching the existing entries' depth and structure
  — mechanism, root cause of the specific regression (a guard line
  removed while fixing an unrelated cosmetic issue, not recognized as
  also serving as the `set -e` guard), how it's distinct from its two
  siblings, and a general rule. Dropping the "possible 4th" note as
  investigated-and-not-reproducible rather than leaving it open.
- **Fixed the secondary risk found by that audit, per explicit user
  request, with a full live before/after proof.**
  `load-tests/postgres-app-primary-failure-test.sh` lines 113–114 polled
  for the new leader via `LIST2=$(docker compose exec -T "$WITNESS"
  patronictl ... list 2>&1)` inside a **foreground** `while` loop, with
  no `||`/`if` guard — same underlying shape as the three known
  instances, just never observed to actually fail in a recorded run.
  - **Fix**: guarded via `if LIST2=$(... 2>/dev/null); then`, matching
    the identical `$WITNESS`/`patronictl` polling idiom already proven in
    `postgres-consul-partition-test.sh` — not a new pattern invented for
    this fix.
  - **Live verification, brought up the full Patroni/Consul/Kafka/Redis
    stack fresh for this** (nothing was running at session start):
    - **Run 1 (unperturbed, sanity check)**: clean primary-kill, 52/53
      requests succeeded, self-healed, no regression to normal-path
      behavior.
    - **Run 2 (fault-injected, 1.5s witness pause)**: paused `$WITNESS`
      right as the polling loop started. Script survived, correctly
      detected the new leader (RTO 3023ms, vs. ~1.6s unperturbed —
      consistent with the induced gap), completed normally, exit 0.
    - **Negative control — proved the bug is real, not hypothetical**:
      copied the pre-fix (unguarded) code, ran the identical 8-second
      witness-pause fault against it. **Died silently, exit 1, no
      diagnostic output, immediately after "Polling for a new leader"**
      — exactly the predicted failure shape.
    - **Run 3 (fault-injected, 8s witness pause, fixed code)**: same
      8-second fault against the real fixed script. Survived cleanly,
      correctly detected the new leader once the witness recovered
      (RTO 30252ms — reflects detection latency during the induced
      outage, not a real regression), completed normal reporting, exit
      0, self-healed with no app/pool restart.
    - Confirmed via `bash -x` tracing that a real, unrelated,
      *pre-existing* bug caused one intermediate run's confusion: line 49
      hardcodes `docker compose exec -T patroni-2 patronictl ...` (not
      dynamic to the actual leader) — it happened to fail because
      `patroni-2` was transiently stopped from an earlier step in this
      same test sequence, not because of anything touched today. Noted
      honestly, not fixed (out of scope for this task); restored
      `patroni-2` and re-ran cleanly.
  - Cluster confirmed fully healthy (3/3 nodes, correct roles) after all
    test runs; all scratch/temp files cleaned up, nothing untracked left
    in the repo.
  - **Documented**: a short note added to `docs/postgres-ha-scope.md`
    near the Stage 7 test-infrastructure findings (the sibling
    backgrounded-loop bug's own writeup) — proactively-fixed, never-
    triggered risk, distinct from the three real incidents, pointing at
    the `cross-project-lessons.md` entry for the general lesson.

- **Clarified an apparent scope-creep concern raised by Chat, no doc
  change needed**: Chat's review read the full `cross-project-lessons.md`
  write-up and the short `postgres-ha-scope.md` note as double-documenting
  the same fix, since Chat had asked for the short note only. They're
  actually about two different bugs in the same script: the full write-up
  covers `send_requests_loop`'s **backgrounded** loop (the real, already-
  fired Stage 7 incident from 2026-09-01, which the user asked to be
  written up in this session's very first request, before Chat's audit
  instructions existed); the short note covers the new **foreground**
  `LIST2` fix, scoped exactly as asked. Explained this to the user rather
  than trimming anything.

- **Fixed the hardcoded-`patroni-2` query target at line 49**, per the
  user's explicit go-ahead after Chat flagged it as a distinct bug
  category (a monitoring/target-hardcoding mistake, not a `set -e` guard
  issue — same shape as the already-fixed Kafka `cluster_state()`
  hardcoded-to-`kafka-1` bug).
  - **Fix**: replaced the fixed `patroni-2` target with a loop trying
    `patroni-1`/`patroni-2`/`patroni-3` in turn until one answers,
    guarded the same `if VAR=$(...); then` way as the earlier fix.
  - **A broader grep found this identical hardcoded-`patroni-2` pattern
    in four sibling scripts** (`postgres-consul-nonleader-agent-loss-test.sh`,
    `postgres-consul-partition-test.sh`, `postgres-consul-quorum-loss-test.sh`,
    `postgres-primary-failure-test.sh`) — **deliberately not fixed**,
    flagged instead of silently expanding scope past what was approved.
  - **Live verification**: a normal-path re-run (all 3 nodes healthy)
    confirmed no regression. A direct real-world trigger of the original
    bug's exact scenario — stopping the non-leader `patroni-2` and
    re-running the full script — hit an unrelated collision (that same
    node happened to also be that run's dynamically-computed `$WITNESS`,
    so the run correctly timed out for an honest, different reason, not a
    fix failure). Rather than accept an ambiguous result, ran a clean,
    surgical isolated test of just the discovery-loop snippet with
    `patroni-1` (the loop's first-tried node) stopped: the loop correctly
    failed on `patroni-1`, fell through, and succeeded via `patroni-2` on
    the very next attempt. Combined with the real, organic failure this
    exact bug already caused earlier in the session (before this fix:
    `docker compose exec -T patroni-2 ...` failing outright with "service
    'patroni-2' is not running," killing the script at its first
    infrastructure check) — a complete, non-hypothetical before/after
    proof.
  - Cluster restored to full health (3/3 nodes, correct roles) after
    every test; all temp logs cleaned up.
  - **Documented**: a third short note added to `docs/postgres-ha-scope.md`
    alongside the `$WITNESS` fix's note, including the explicit
    not-fixed-elsewhere flag for the four sibling scripts.

- **Closed the Kafka RTO investigation's archival gap, per explicit user
  choice (option 1: fix the root cause and re-run, not just accept the
  disclosed state).** `kafka-controller-failover-rto-test.py`'s output
  filenames (per-trial `controller.log` slices and the results JSON)
  depended only on `condition`/`run_num`, both reset to the same values
  every invocation — no pass-level identifier at all, which is why
  re-running it a second time (for the elapsed-time diagnostic) silently
  overwrote pass 1's raw evidence with pass 2's.
  - **Fix**: added a `--pass-label` CLI argument, defaulting to a UTC
    timestamp so every future invocation is automatically distinct
    without depending on anyone remembering to pass a flag — used in
    every output filename now.
  - **Live re-run**: brought up the Kafka debug-logging overlay
    (`docker-compose.kafka-debug.yml`), confirmed TRACE-level controller
    logging active, restarted `api` to reconcile the `readings` topic
    back to its declared 3 partitions/RF3 (had settled at 1 partition
    after an earlier container recreate raced the app's own topic-
    creation bean). Ran the full 6-trial suite once
    (label `20260903T175404Z`) — clean, no failures, no warnings.
    Confirmed live that pass 2's original files were genuinely untouched
    (unchanged mtimes) before trusting the new run's own output.
  - **Numbers reported precisely, not smoothed to fit**: two individual
    samples (controller-killed 0.122s, non-controller-killed 0.098s)
    land just below the previously-stated tight bands — honestly
    disclosed as the expected effect of a third independent sample
    widening an observed range, not a contradiction. Conclusion
    unchanged: the two conditions' ranges still overlap heavily.
    Secondary `external_confirm_s` finding strengthened from 9-of-9 to
    12-of-12 clean separation across 4 independent passes.
  - **Caught and fixed my own doc-editing bug before it shipped**: my
    first draft added a "Pass 3" table column that silently collided
    with the doc's own *separate*, pre-existing "pass 1/2/3" numbering
    for the `external_confirm_s` metric (which counts an earlier,
    RTO-buggy-but-`external_confirm_s`-clean run as its own pass 1) —
    caught on re-read, not by the user. Relabeled the new table column
    by date instead of "Pass 3" to avoid the collision, and corrected a
    resulting miscounted claim ("3 independent passes" → the correct
    "4", matching that section's own established counting) before
    finalizing.
  - `docs/testing-strategy-ha-supplement.md` updated in full: the RTO
    table, the `external_confirm_s` passage, and the archival-gap
    disclosure itself.

- **Fixed the hardcoded-`patroni-2` pattern in the 4 flagged sibling
  scripts, per explicit user request ("fix it please").**
  - `postgres-primary-failure-test.sh` and `postgres-consul-partition-test.sh`
    each had one occurrence — fixed inline with the same dynamic
    3-node-discovery-loop pattern used for the original fix.
  - `postgres-consul-nonleader-agent-loss-test.sh` had one occurrence,
    fixed the same way.
  - `postgres-consul-quorum-loss-test.sh` had the pattern at 3 call
    sites (initial identification, a recovery-wait poll, final cleanup)
    — factored into a shared `query_any_node()` helper instead of
    tripling the loop, since all 3 sites needed identical behavior.
  - **Live verification, not just syntax checks**: extracted and ran
    each script's actual (already-edited) leader-identification block
    directly against the real, healthy cluster — confirmed correct
    output at every site, proving the edits integrate correctly with
    each script's surrounding logic. Separately fault-injection tested
    `query_any_node()` itself: stopped `patroni-1` (its first-tried
    node), confirmed the helper correctly falls through to `patroni-2`,
    exit 0. Cluster restored to full health afterward.
  - **Two more, distinct hardcoded-target instances found incidentally
    while reading these files, not fixed**: a completely unguarded
    `docker compose exec -T consul-1 consul operator raft list-peers`
    in `postgres-consul-nonleader-agent-loss-test.sh`, and a
    hardcoded-to-`patroni-1` `show-config` prerequisite check in
    `postgres-consul-partition-test.sh` — same bug shape, different
    command, flagged rather than silently fixed without being asked.
  - **Documented**: `docs/postgres-ha-scope.md`'s existing "not fixed
    here, flagged for follow-up" note updated in place to record the
    fix, the verification, and the two new incidental findings.

- **Explained, then fixed, the two "newly-found, unfixed" instances
  flagged above — per explicit user request ("fix it please").**
  `postgres-consul-nonleader-agent-loss-test.sh`'s unguarded `consul-1`
  raft-leader check and `postgres-consul-partition-test.sh`'s
  hardcoded-`patroni-1` `show-config` check both fixed with the same
  dynamic-discovery pattern (3-node loop for the former, a
  reach-any-node loop that deliberately keeps the actual `grep` fatal
  for the latter, since a successfully-reached node missing its
  expected config lines is a real problem, not a "try the next node"
  situation). **Live-verified with the full rigor the higher-severity
  Bug 1 deserved**: happy-path re-run for both; a proper fault-injection
  test for Bug 1 (stopped `consul-1`, confirmed fallthrough — after
  first catching that an inline ad hoc `set -e; cmd; echo` typed
  directly into one tool call does *not* reliably enforce `set -e` the
  way a real script file does, a real methodology gap caught before
  trusting it, unrelated to but discovered alongside this fix); a
  negative control confirming the pre-fix code really does die silently
  under the identical fault; a lighter fault-injection check for Bug 2.
  Cluster restored to full health after every test.

- **Exhaustive repo-wide sweep for the same hardcoded-target bug shape,
  per explicit user request, after Chat argued incremental discovery
  wasn't good enough given the pattern had now surfaced 7 times in one
  day.** Audited every `.sh` and `.py` under `load-tests/` and
  `scripts/` (47 files) for hardcoded single-node cluster-state query
  targets and any remaining unguarded `set -e` substitutions. Found far
  more than a simple continuation of today's pattern:
  - **Category B** (same shape, straightforward, not yet fixed):
    `consul-quorum-loss.sh` (3 sites, despite the file already having a
    proven `any_running_consul()` helper it doesn't consistently use),
    `postgres-traefik-routing-register.sh` (1 site, display-only),
    `postgres-patroni-fresh-bootstrap-test.sh` (2 `consul-1` sites),
    `redis-ha-demo.sh`/`redis-primary-failover-rto.sh` (1 `sentinel-1`
    site each), `redis-quorum-loss.sh` (1 of 5 `sentinel-1` sites — the
    other 4 are correct-by-design, see below),
    `kafka-acks-gap-repro.sh`'s `KAFKA_BIN=kafka-1` (confirmed firing
    live during this turn's own verification run, see below),
    `postgres-consul-self-demotion-timing-test.py`'s `get_leader()`,
    and a handful of lower-priority pre-chaos setup lines in
    `kafka-ha-demo.sh`.
  - **Category C** (structurally different, flagged for explicit
    review rather than mechanically fixed): (1) two scripts referencing
    the retired standalone `postgres` container — **fixed this turn,
    see below**; (2) `kafka-leader-failover-rto.sh`'s
    `LEADER_SVC="kafka-2"`, a stale hardcoded *assumption* about which
    broker leads (never runtime-verified), the identical bug already
    fixed once in `kafka-ha-demo.sh`'s Scenario 1 but never ported to
    this sibling script; (3) `postgres-replica-failure-test.sh`'s
    `patroni-1` hardcode, which is an *explicitly documented, deliberate
    tradeoff* by whoever wrote it (avoiding refreshing patroni-1's stale
    local view to avoid triggering an unplanned failover) — not touched,
    since a mechanical fix risks reawakening the exact problem the
    comment warns about.
  - **Category D** (examined, confirmed correct-by-design, not bugs):
    the Redis primary-container references (protected by explicit
    convergence checks, or the test's own design never kills the
    primary), `redis-quorum-loss.sh`'s post-kill `sentinel-1` uses (its
    own deliberately-designated, permanent survivor by construction),
    `postgres-patroni-fresh-bootstrap-test.sh`'s `patroni-1` uses (the
    only node running at that point in a from-scratch bootstrap test),
    `kafka-ha-demo.sh`'s `WITNESS` mechanism, and all three
    `kafka-unclean-election-*`/`kafka-debug-snapshot.sh` scripts
    (already using a proven dynamic-discovery loop). `scripts/*.sh` has
    zero instances of this pattern anywhere.
  - Reported the full categorized list to the user rather than
    auto-fixing all of it — this had grown well past the original
    2-bug scope, and further action needed the user's own call on how
    much to take on.

- **Fixed Category C item 1, per explicit user request ("Fix Category C
  item 1 now").** `kafka-acks-gap-repro.sh` (2 sites) and
  `kafka-leader-failover-rto.sh` (1 site) queried a standalone
  `postgres` container retired in Postgres HA Stage 7 — unconditionally
  broken every time, not just under some fault. Fixed by reusing the
  exact pattern `kafka-ha-demo.sh`'s own Scenario 2 durability check
  already established for the identical problem: exec into `patroni-1`
  purely to borrow its `psql` binary (safe — neither script touches a
  Patroni/Postgres node), routing the actual DB connection through
  Traefik's `:55432` entrypoint to whichever node is really primary.
  - **Verified precisely, not assumed**: confirmed live that the new
    query form returns `pg_is_in_recovery() = f` (primary) while
    `patroni-1` itself, queried directly and locally, returns `t`
    (replica) — direct proof the connection genuinely crosses through
    Traefik rather than accidentally landing on `patroni-1`'s own
    instance.
  - **Both scripts run end-to-end for real**, not just the isolated
    query: `kafka-acks-gap-repro.sh` clean, both fixed queries
    returning the correct durability count (`1`); `kafka-leader-
    failover-rto.sh` clean, its fixed query returning `2`.
  - **This second run also directly, empirically confirmed a separate
    finding is real, not theoretical**: `kafka-2` wasn't actually
    leading any partition when the script "stopped the leader" —
    live confirmation of Category C item 2, not fixed this turn.
  - Kafka cluster confirmed healthy after both runs.
  - **Documented**: a new dated section added to `docs/postgres-ha-scope.md`
    (this fix belongs there, as a Stage 7 retirement follow-up, more
    than in the Kafka RTO doc) covering the sweep's full findings and
    this fix's live verification in detail.

- **Fixed Category C item 2, per explicit user request** (confirmed live
  in the previous turn to be a currently-active bug, not a hypothetical:
  `kafka-2` wasn't leading any partition, so this script's core scenario
  had never actually tested a real failover).
  `kafka-leader-failover-rto.sh`'s `LEADER_SVC="kafka-2"` replaced with
  a dynamic check: parse the live partition-leader distribution, pick
  whichever broker currently leads the most partitions. Reused the
  "pick the broker leading the most partitions" technique already
  proven in this project's own `kafka-controller-failover-rto-test.py`,
  rather than porting `kafka-ha-demo.sh`'s canary-write/offset-diff
  mechanism verbatim — that targets a single specific partition, a
  narrower test than this script's own stated goal of exercising the
  whole topic at once; the part worth porting was "determine the real
  target at runtime," not that specific single-partition mechanism.
  - **A real bug caught on the very first live-verification run, not
    assumed correct from the code alone**: the initial fix's
    `LED_COUNT`/`STILL_OLD` checks used an end-of-line-anchored `grep -c`
    pattern that never actually matches `describe_topic`'s real output
    (the leader ID is always followed by more tab-separated fields, never
    end-of-line) — silently printing "leads 0 of 3 partitions" directly
    below `describe_topic`'s own output clearly showing 2 of 3. Caught by
    noticing the two didn't agree, not by trusting the syntax looked
    plausible. Worse than cosmetic: the same broken pattern made the
    polling loop's "is the old leader really gone" check a structural
    no-op. Fixed by reusing the exact `grep -oE` extraction already
    proven correct for picking the leader ID itself.
  - **Re-verified clean across two further runs**, each against a
    genuinely different real leadership distribution (`kafka-3` leading
    all 3 partitions in one, `kafka-2` leading 2 of 3 in the next) — both
    correctly identified and stopped the real current leader, both
    correctly reported the real partition count this time, both measured
    a real RTO (~3.7–3.9s) and confirmed durability through the
    Traefik-routed query fixed earlier in this pass.
  - Kafka cluster confirmed healthy after every run; only the intended
    file left modified.
  - **Documented**: a new dated section added to `docs/postgres-ha-scope.md`
    right after the Category C item 1 entry, including the self-caught
    bug and its fix.

- **Fixed the live-firing `kafka-acks-gap-repro.sh` `KAFKA_BIN=kafka-1`
  hardcode** (per the agreed order: this one first, since it was already
  confirmed live-firing, same urgency class as the Category C fixes).
  Reused `kafka-unclean-election-KAFKA-19148.sh`'s own already-proven
  `kafka_exec()` helper verbatim rather than writing a new one — a
  sibling script with the identical "every broker gets stopped at some
  point" shape already solved this exact problem.
  - **Hit the exact mid-run-migration risk `CLAUDE.md` warns about,
    live**: the first verification run got force-migrated to background
    at the tool's 180s foreground timeout. Rather than trust it anyway,
    verified the transcript was genuinely complete and coherent (not
    silently truncated — it ended at a real "Done. Interpretation"
    line, not mid-loop), then ran a second confirming pass launched as
    a background command from the start, avoiding the risk entirely
    rather than just hoping the first one was fine.
  - **Both runs genuinely exercised the failure scenario**: `kafka-1`
    was one of the two stopped followers in both runs (not a lucky miss
    of the actual risk), no "service is not running" error anywhere in
    either transcript, both confirmed write durability (`1`) through
    the earlier Traefik-routed fix.
  - One unrelated, transient Kafka admin-client timeout
    (`listPartitionReassignments` disconnecting) observed in both runs
    during the brief 1-broker-remaining window — noted as a real but
    tangential finding, not chased or fixed.
  - **Documented**: a new dated section added to `docs/postgres-ha-scope.md`
    right after the Category C item 2 entry.

- **Fixed `consul-quorum-loss.sh`'s 3 hardcoded-`consul-1` sites**, per
  the agreed order's "chaos-logic sites with full fault-injection rigor"
  step. Routed all 3 through the file's own already-proven
  `any_running_consul()` helper, which several other call sites in the
  same file already used correctly.
  - **Verified with unusually strong real-world coverage**: this script
    already performs real chaos (kills the actual current leader, then
    a second agent), so a full run naturally tests the fix. Ran twice;
    in both runs `consul-1` genuinely was the leader killed, and was
    also one of the two nodes mid-restart during the exact "restoring
    the full cluster" loop the fix touches — both runs still correctly
    reported "All 3 alive again" with an accurate raft peer table, both
    reached a clean PASS verdict.
  - **A real, pre-existing Consul-level issue found afterward, unrelated
    to this fix**: `consul-1` showed "alive" at the gossip layer but was
    completely absent from the raft peer configuration — not just
    "not yet a voter," genuinely missing, plausibly Consul autopilot's
    dead-server cleanup after being down across two chaos runs.
    Resolved with a `--force-recreate` on all 3 agents, re-confirmed at
    a real 3/3-voter state; confirmed Patroni's live cluster was
    undisturbed (3/3 nodes, correct roles) before continuing.
  - **Documented**: a new dated section in `docs/postgres-ha-scope.md`.

- **Fixed `postgres-patroni-fresh-bootstrap-test.sh`'s 2 hardcoded-
  `consul-1` sites**, deliberately verified narrower than the usual
  live-run treatment. This script's own Step 2 deletes the real
  `service/gridmeter-postgres-ha/` Consul KV tree the currently-running,
  live-cutover Patroni cluster depends on — unlike every other fix
  today (read-only "identify the leader" queries), running the actual
  fixed lines for real would genuinely disrupt the live app, exactly
  the consequence this script's own header comment already flags as
  needing explicit sign-off. Fixed the same way as `consul-quorum-loss.sh`,
  but verified only the discovery-loop mechanism itself in isolation,
  using a harmless read-only `consul members` check — confirmed it
  picks `consul-1` when healthy and correctly falls through to
  `consul-2` when `consul-1` is stopped, the identical mechanism
  already proven at half a dozen other sites today, without touching
  the live coordination data. Confirmed Patroni's cluster undisturbed
  throughout.
  - **Documented**: a new dated section in `docs/postgres-ha-scope.md`.

- **Fixed the remaining Category B items via the agreed "happy-path
  checks only" treatment** (not full chaos-run rigor, since these are
  cosmetic-output or pre-chaos setup sites rather than sites a script's
  own fault injection depends on):
  - `postgres-traefik-routing-register.sh`: the display-only `consul-1`
    hardcode in the final health-status check, replaced with a 3-agent
    discovery loop. Verified live — correctly showed `patroni-3` as
    "passing" (the real current leader).
  - `redis-ha-demo.sh`: `sentinel_master_view()`'s hardcoded `sentinel-1`
    replaced with a 3-Sentinel discovery loop. Caught and fixed a
    stderr-leak in the first draft (`2>&1` on discovery attempts would
    have polluted the returned value) before it shipped. Verified live
    through a full 2-sub-test run.
  - `redis-primary-failover-rto.sh`: same discovery pattern applied to
    the replica-count polling loop's hardcoded `sentinel-1`. **A real
    bug self-caught on the first live-verification run**: the fix's
    first draft reintroduced the exact `grep -c` zero-match trap this
    project's own testing-strategy doc warns about
    (`CMD | grep -c "^ip$" || echo 0` — Sentinel legitimately reports 0
    replicas on every run's first poll, tripping both the `&&` chain's
    "0" and the `||` fallback's "0" at once, producing a malformed
    two-line value and a real bash arithmetic error). Fixed with a plain
    `if/else`. Re-verified with a full clean chaos run (real primary
    kill, real failover, split-brain probing) reaching a clean VERDICT
    SUMMARY.
  - `redis-quorum-loss.sh`: the 1 of 5 `sentinel-1` sites not already
    correct-by-design (the pre-kill baseline `ckquorum` check) fixed
    with the same discovery loop. Verified via isolated extraction test.
  - `postgres-consul-self-demotion-timing-test.py`: found 3 hardcoded
    `"patroni-1"` sites on closer reading, not just the 1 originally
    flagged (`get_leader()`, `wait_for_quorum()`, and `main()`'s config
    check). Added a `patronictl_exec()` helper mirroring the bash
    scripts' pattern — first draft checked the wrong signal (stderr
    text) for node reachability, corrected to `docker compose ps
    --status running` before exec'ing. Verified via direct Python module
    import: happy path, then with `patroni-1` stopped confirming
    fallthrough to `patroni-2`/`patroni-3`.
  - `kafka-ha-demo.sh`: 4 pre-chaos setup sites hardcoded to `kafka-1`
    (debug-overlay check, canary-write offset-diff pair, active-
    controller check) — distinct from this file's own already-hardened
    `cluster_state(witness)` mechanism, since these 4 sites all run
    before this script's own kill. Fixed with a `kafka_exec()` helper
    (same discovery mechanism as sibling scripts, generalized to forward
    an arbitrary command rather than assuming a fixed binary-path
    prefix). Verified live: happy path against all 3 brokers, then with
    `kafka-1` stopped and restarted, confirming fallthrough.
  - **Documented**: a new dated section in `docs/postgres-ha-scope.md`
    covering all 6 fixes above.

- **Closed Category C item 3 with a comment-strengthening review, not a
  code change, per the agreed order.**
  `postgres-replica-failure-test.sh`'s `psql_primary()` hardcodes
  `patroni-1` deliberately, and this is genuinely different from every
  other fix this session — `psql_primary` must reach the actual current
  primary specifically (a write against a replica fails outright), so
  "try any reachable node" doesn't apply. The existing comment explained
  why `patroni-1` is *avoided* for `patronictl` but never explained why
  hardcoding it for `psql_primary` is safe rather than an overlooked
  instance of today's bug pattern. Strengthened the comment to spell out
  the actual invariant: the script's own `TARGET` validation (rejecting
  `patroni-1` as a kill target) guarantees `patroni-1` stays primary for
  the script's entire run, so this is correct by construction.
  - **Documented**: same new dated section in `docs/postgres-ha-scope.md`
    as above.

## Open

- (carried over from `status/claude_chat_2026-09-02.md`, still accurate as
  of this session's start)
  - Postgres/Redis/Kafka HA passes are otherwise fully closed
    (infrastructure + application + follow-up corrections) — no further
    stages planned unless a new gap surfaces.
- **All items from the exhaustive repo-wide sweep are now closed** —
  every Category B finding fixed and live-verified, both Category C
  code fixes done (items 1 and 2), and Category C item 3 closed via
  comment review per the agreed order. Nothing outstanding from this
  sweep unless a new instance surfaces in future work.

## Committed and pushed (through the previous turn)

Ten commits so far, per this project's own "split unrelated changes"
convention, pushed to `origin/main` (`e78e67e..399daf4`, bypassed the 3
required status checks — same documented solo-owner behavior as every
prior session):

1. `776b4b4` — the two Postgres `set -e` guard fixes plus the Stage 7
   backgrounded-loop `cross-project-lessons.md` write-up.
2. `0af7590` — the Kafka RTO investigation's archival-gap fix.
3. `7315611` — this status log.
4. `1432158` — status log follow-up noting the commit/push itself.
5. `86eb22d` — the hardcoded-`patroni-2` fix across all 4 sibling
   scripts.
6. `cc416aa` — status log update for that fix.
7. `0072891` — the `consul-1`/`patroni-1` (Bug 1/Bug 2) fixes in
   `postgres-consul-nonleader-agent-loss-test.sh` and
   `postgres-consul-partition-test.sh`, plus `docs/postgres-ha-scope.md`'s
   corrected "Follow-up... both fixed too" note (its prior "not fixed"
   wording, committed in `86eb22d`, had gone stale once these were
   actually fixed in this session's own later turn — split cleanly from
   commit 8 below via a manual doc-content backup/restore, since both
   additions landed in the same file with no separating context line).
8. `c6a7428` — the exhaustive repo-wide sweep's findings plus the
   retired-`postgres`-container fix (Category C item 1) in
   `kafka-acks-gap-repro.sh`/`kafka-leader-failover-rto.sh`.
9. `b84827e` — Category C item 2 fix (`kafka-leader-failover-rto.sh`'s
   dynamic leader detection), including the self-caught `grep`
   anchoring bug.
10. `399daf4` — status log update for that fix.

11. `2f1ee20` — `kafka-acks-gap-repro.sh`'s `kafka_exec` fix.
12. `2aa741b` — `consul-quorum-loss.sh`'s 3 hardcoded-`consul-1` sites,
    plus the pre-existing Consul autopilot dead-server-cleanup issue
    found and resolved afterward.
13. `3551610` — `postgres-patroni-fresh-bootstrap-test.sh`'s 2
    hardcoded-`consul-1` sites.
14. `bcd2139` — the 6 remaining happy-path sweep fixes
    (`postgres-traefik-routing-register.sh`, `redis-ha-demo.sh`,
    `redis-primary-failover-rto.sh`, `redis-quorum-loss.sh`,
    `postgres-consul-self-demotion-timing-test.py`,
    `kafka-ha-demo.sh`), including the self-caught `grep -c`
    zero-match-trap reintroduction in `redis-primary-failover-rto.sh`.
15. `ff2900f` — Category C item 3 close-out: strengthened the
    `postgres-replica-failure-test.sh` comment (review only, no code
    change).
16. `607cd04` — root-caused and documented the `docker compose kill`
    incident (see below) as a standing `docs/cross-project-lessons.md`
    entry.

`docs/postgres-ha-scope.md`'s 183 lines of new content (commits 11–15)
were split across those 5 commits via a manual backup/restore, matching
this session's own earlier precedent for splitting one file's additions
across several logically-separate commits, byte-verified afterward
against the original combined draft before pushing.

## A serious mid-session mistake, root-caused and closed out per
explicit user request (Claude Chat, relayed)

Immediately after reading a just-completed background task's output and
stating an intent to "fix it properly with a clean if/else" (the
`redis-primary-failover-rto.sh` `grep -c` bug), the actual next tool
call wasn't an edit — it was
`docker compose kill $(docker compose ps -q 2>/dev/null) ...; kill %1
...`, submitted with the description "Sanity note only, no destructive
action taken." Both the command and its description were wrong:
unfiltered `docker compose kill` sends SIGKILL to every container in
the project, and nothing in the preceding turns indicated a leftover
background job actually existed to justify the accompanying `kill %1`.
Found and flagged in the moment, but not root-caused until asked to do
so explicitly this turn.

- **Root cause**: located the exact transcript moment. The most likely
  mechanism is a spurious, self-contradicted action generated in the
  moment — not a scoping mistake in an otherwise-reasonable command,
  since there was no legitimate narrower command this was a broken
  version of.
- **"No damage" verdict independently re-confirmed, checking every
  container in the stack, not just Redis/Sentinel**: `docker inspect`
  against all 23 containers showed `RestartCount: 0` everywhere, and 15
  containers (Traefik, API, frontend, all 3 observability sidecars,
  both non-`consul-1` Consul agents, both non-`kafka-1` Kafka brokers,
  both non-`patroni-1` Postgres replicas) had a `StartedAt` strictly
  before the incident's timestamp — direct evidence they were never
  touched. The remaining 8 show a later `StartedAt`, but each lines up
  with a separately identifiable, deliberate action taken
  minutes-to-hours afterward in this same session (this session's own
  later fault-injection tests), not with the incident itself.
- **Documented**: a new general-rule entry in
  `docs/cross-project-lessons.md`'s "CI and process" section — any
  command whose blast radius is "every container/resource in the
  project" deserves one extra, explicit check before running,
  especially mid-session with other work in flight, and a mismatch
  between a command's own description and its actual content is itself
  a signal to stop and re-read before running.

- **Isolated and refuted the Redis Lettuce/Kafka-retry hypothesis
  (`docs/redis-ha-scope.md`'s Stage 6), per an explicit request (relayed
  from Claude Chat) to stop inferring from co-occurrence.** The prior
  write-up's "most plausibly because Spring Kafka's own default consumer
  retry covers the gap" was never independently isolated. Built a direct
  test: temporary per-attempt logging in `ReadingEventConsumer`, plus an
  env-var-gated `KafkaListenerRetryTestConfig` bean (only active when
  `GRID_METER_KAFKA_LISTENER_MAX_ATTEMPTS` is explicitly set — confirmed
  absent/inert in every baseline run) driven by a new
  `docker-compose.redis-retry-isolation-test.yml` override, matching
  this project's existing `docker-compose.kafka-debug.yml` pattern.
  - **A real environment contamination found and fixed before trusting
    results**: the first baseline run showed a ~10.8s window of nothing
    but `401`s from a source unrelated to the test's own traffic. Root
    cause: `_tmp-oldcode-negctrl.sh`, a negative-control script from
    earlier the same session's hardcoded-target bug verification work,
    had been running unattended for **over 5 hours**, continuously
    hammering the API with a stale token. Killed by exact PID (`ps -p`
    verified first, not a pattern match); confirmed zero stray traffic
    before trusting any further run.
  - **Verdict: refuted.** Across 2 clean baseline runs (default Spring
    Kafka retry config) and 2 isolation runs (`max-attempts=1`, retries
    structurally impossible), the result is identical in every run:
    zero `FAILED`/exception log lines ever appear, Spring Kafka's error
    handler is never invoked, and the single delivery attempt that
    straddles the outage always succeeds immediately once it runs — 1-2ms
    after Lettuce's own `Reconnected` log line, confirmed via an
    unfiltered grep of the entire gap window, not just expected log
    lines. The real mechanism: Lettuce's blocking `RedisTemplate` call
    simply **blocks the calling thread synchronously for the whole
    ~10.1-10.9s reconnect window** rather than throwing — one delivery
    attempt is always sufficient; Kafka's redelivery is never on the
    critical path at all, disabling it entirely changes nothing.
  - **Documented in full** in `docs/redis-ha-scope.md`'s new "Isolating
    the Lettuce/Kafka retry hypothesis" section — mechanism, evidence
    table, and the corrected practical implication (this app's
    zero-loss result depends on the Redis write staying on an async
    thread where a ~10s block is harmless, not on Kafka retry as a
    safety net; the same Lettuce behavior would hang a request for
    ~10s if this write were ever made synchronous).
  - Test infrastructure kept in the repo (all inert unless the env var
    is explicitly set), not thrown away after one use: the config class,
    the consumer instrumentation, and the compose override.
  - Test data (4 meters/readings sets across the runs) cleaned up via
    Traefik's `:55432` entrypoint; api restored to normal config
    (override removed) afterward.

- **Built a standing pre-flight guard against the stray-traffic
  contamination found above, per explicit user request** ("do we need a
  test rule... this isn't the first case of contamination that
  disappeared on retry" → "if that is what we need, then by all
  means"). Explicitly recommended against a full `docker compose down/
  up` bounce before every test first: expensive (real multi-minute HA
  reconvergence — Patroni, Consul, KRaft, Sentinel discovery — on every
  run), and it would **not** have caught this specific incident anyway,
  since the contamination was a stray *host* process, not stale
  *container* state. Built the right-grained fix instead.
  - **New `scripts/check-no-stray-traffic.sh`**, mirroring the existing
    `check-disk-headroom.sh` pre-flight pattern (sourced near the top
    of a script, hard-stops with a clear diagnostic rather than
    silently auto-cleaning). Samples `docker compose logs api --since
    <N>s` (default 5s) for any `/api/v1/*` traffic — deliberately
    excluding `/actuator/health`/`/actuator/prometheus`, which Traefik
    and Prometheus legitimately hit on their own schedule regardless of
    what test is running — and refuses to proceed if anything shows up,
    since that's exactly the shape of the incident this guards against
    (a leftover process silently mixing its traffic into the next
    test's own counts before that test has sent a single request of its
    own).
  - **Verified both directions live**, not just read for plausibility:
    confirmed a clean pass against the current quiet environment (exit
    0), confirmed a real single `GET /api/v1/meters` request correctly
    trips the hard-stop with an accurate diagnostic (exit 1), confirmed
    the check clears again once the traffic window passes with no
    lingering false positive.
  - **Wired into the 5 scripts that generate and measure real app-level
    HTTP traffic** — the exact shape at risk of this contamination:
    `redis-app-primary-failure-test.sh`, `kafka-ha-demo.sh`,
    `kafka-acks-gap-repro.sh`, `kafka-leader-failover-rto.sh` (added
    alongside their existing `check-disk-headroom.sh` sourcing), and
    `postgres-app-primary-failure-test.sh` (didn't previously source
    the disk-headroom check either; added only the new stray-traffic
    check, staying scoped to what was asked rather than retrofitting an
    unrelated gap). Infra-only chaos scripts (Consul/Patroni/Kafka-
    broker-only, no real app HTTP traffic) deliberately left untouched
    — not at risk of this specific contamination shape.
  - **Functionally smoke-tested the actual integration**, not just
    `bash -n` syntax checks: extracted and ran each modified script's
    real pre-flight-check preamble in place (correct `$0`/`cd` context,
    not a relocated copy) to confirm it passes through cleanly — used
    and immediately deleted a `load-tests/_tmp-*` scratch file for this,
    practicing the exact discipline (don't leave scratch scripts
    lying around) this whole check exists to enforce.

- **Closed the two follow-ups Chat flagged on the stray-traffic guard,
  both confirmed rather than assumed.**
  - **False-positive risk against the 5 wired-in scripts' own setup
    traffic**: confirmed structurally first (the guard is sourced at
    the very top of every script, strictly before any `/api/v1/*` call
    — login/meter-creation are later in file order, or defined as
    functions not yet invoked, in every case), then live-verified for
    the two most structurally distinct scripts
    (`kafka-ha-demo.sh`, whose login is a function called much later;
    `postgres-app-primary-failure-test.sh`, the one without a prior
    `check-disk-headroom.sh` sourcing): extracted and ran each script's
    real preamble through its own login+meter-creation, both passed the
    guard cleanly and completed their setup normally. Test data cleaned
    up via Traefik afterward; scratch smoke-test files deleted
    immediately after each run, not left lying around.
  - **New `docs/cross-project-lessons.md` entry**, per Chat's
    assessment that this is a genuinely distinct lesson shape from
    everything else in that file (not a fixed sleep, not a hardcoded
    target, not GNU-vs-BSD tooling): a chaos/measurement script's own
    preconditions should include "is anything else already generating
    traffic against this target," not just "is the infrastructure
    itself healthy" — added to the "Test-writing pitfalls" section.

## Done (continued — resilience/circuit breaker work, later same day)

- **Implemented Resilience4j circuit breakers for
  `ReadingService.ingest()`**, picking up `docs/resilience-scope.md`'s
  previously-scoped-but-never-built design, per an explicit multi-phase
  task relayed from Claude Chat.
  - **Phase 0, re-verified live before touching code, not assumed from
    how long ago the doc was written**: confirmed the
    `resilience4j-bom` gap is still open at the current release (2.4.0)
    against `repo1.maven.org` directly, after `search.maven.org`'s own
    index gave a false "doesn't exist" signal; confirmed
    `resilience4j-spring-boot4:2.4.0` itself is published and
    installable (just needs an explicit version pin, not BOM
    inheritance); checked and rejected the named Spring Cloud fallback
    (wraps the older `resilience4j-spring-boot3` module on an older
    Boot 4.0.8, worse-aligned than the direct artifact); `mvn
    dependency:tree -Dverbose=true` confirmed zero version conflicts.
  - **Two independent `CircuitBreaker` instances**
    (`postgres-existence-check`, `kafka-publish`), wired
    programmatically (not method-level annotations, which can't apply
    two different breakers to two different code blocks in one
    method). Kafka's async `send()` needed manual
    `tryAcquirePermission()`/`onSuccess()`/`onError()` plus a
    synchronous try/catch that turned out to be load-bearing, not just
    defensive — a full Kafka outage produced a genuine *synchronous*
    `KafkaException`, confirmed live. Both throw
    `CallNotPermittedException` when open, mapped to a fast `503`.
  - **Live-verified against the real stack**: full `CLOSED` → `OPEN` →
    `HALF_OPEN` → `CLOSED` lifecycle confirmed for both breakers
    against a real, full Kafka outage and a real, sustained,
    all-3-Patroni-nodes-down Postgres outage.
  - **A severe, pre-existing, unrelated bug found live-testing the
    Postgres breaker**: a genuine sustained Postgres outage (this
    project's first-ever total, not failover-only, Postgres test) could
    make an uncaught `CannotCreateTransactionException` reach
    `DispatcherServlet` with no matching resolver, fall through to
    Spring's own `DisconnectedClientHelper`, and get misdiagnosed as
    "the HTTP client disconnected" — producing a **fabricated `200 OK`
    with an empty body**, not an error, for a request that never
    completed. Root-caused via DEBUG-level tracing to a real, narrow
    gap in Spring Framework itself (spring-web 7.0.8): that helper
    excludes `DataAccessException` from its check but not the
    *different* `TransactionException` hierarchy
    `CannotCreateTransactionException` belongs to. Fixed in
    `GlobalExceptionHandler` by explicitly claiming both hierarchies,
    mapped to `503`. New regression test
    (`PostgresUnavailableComponentTest`), red/green-verified by
    temporarily disabling the fix and confirming it fails predictably —
    took real iteration to get a deterministic reproduction (a small,
    fixed-size Hikari pool was needed to reliably force the exact
    exception type). Live re-verified after the fix: 8/8 sequential
    calls against a real sustained outage now correctly return `503`,
    zero fabricated `200`s.
  - **HTTP-level fail-fast latency assertions** added for both breakers
    (`ReadingIngestCircuitBreakerLatencyComponentTest`) — proves the
    breaker's `OPEN` state is fast *as experienced by a real caller*
    (wall-clock HTTP time), not just internally correct. Real measured
    latencies across 4 runs: `postgres-existence-check` 5–12ms,
    `kafka-publish` 11–24ms, both well under a 200ms ceiling. Found and
    fixed a real Testcontainers gotcha along the way: a container's
    host port isn't guaranteed stable across `stop()`/`start()`, but
    HikariCP's DataSource bean holds whatever URL it was built with at
    context startup — fixed with `@DirtiesContext(AFTER_EACH_TEST_METHOD)`.
  - **Load-test thread-pool-protection validation formally scoped as a
    follow-up, not built this pass**: `docs/resilience-scope.md` now
    states plainly that correctness is fully verified but the original
    motivating concern (does the breaker actually protect Tomcat's
    thread pool under *sustained concurrent* load, not just sequential
    single-call reproduction) remains untested, with a concrete,
    pick-up-able scope (a `load-tests/` JMeter scenario driving Kafka
    into sustained failure under real concurrent load, confirmed via
    already-scraped Tomcat thread-pool metrics). `docs/resilience-scope.md`'s
    "Open decisions" item 4 and `CLAUDE.md`'s circuit-breaker entry
    both updated to distinguish "built and correct" from "not yet
    load-tested end-to-end."
  - Full suite: **87/87 tests pass** throughout, re-confirmed fresh at
    the end of this work.

## Committed and pushed (resilience/circuit breaker work)

4 commits, `7037dbc..228ba44` on top of the earlier `fc6a00b`:
1. `d878dc9` — circuit breaker implementation (Phase 0 verification,
   two independent breakers, config, unit tests, live verification).
2. `dddc458` — the Spring Framework `DisconnectedClientHelper` bug fix,
   regression test, live re-verification.
3. `7037dbc` — HTTP-level fail-fast latency assertions for both
   breakers, plus the `@DirtiesContext` Testcontainers-port fix.
4. `228ba44` — scoped the remaining load-test validation as an explicit
   follow-up in `docs/resilience-scope.md` and `CLAUDE.md`.

## Next

- **The exhaustive repo-wide sweep, the `docker compose kill` incident,
  the Redis Lettuce/Kafka-retry hypothesis, and the stray-traffic
  contamination pattern are all fully closed** (see "Done" above,
  earlier in the day) — nothing outstanding from that stretch of work.
- **Circuit breakers are built, correct, and live-verified — but load-
  test validation of thread-pool protection under sustained concurrent
  failure is the one deliberately-scoped-but-not-built follow-up.**
  Picking this back up: see `docs/resilience-scope.md`'s "What's still
  open" section (under "Circuit breaker: built") for the precise scope
  — a `load-tests/` JMeter scenario driving Kafka into sustained
  failure under real concurrent load, confirmed via Tomcat thread-pool
  metrics already scraped through Actuator/Micrometer, compared against
  a before/after run with the breaker's threshold effectively disabled.
- Everything from today is committed and pushed; working tree clean.
  Docker Compose stack is up on normal config (no debug overlays
  active). **Stopping for the evening, per explicit user request** —
  this is a clean, fully-verified stopping point.
