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

## Open

- (carried over from `status/claude_chat_2026-09-02.md`, still accurate as
  of this session's start)
  - Postgres/Redis/Kafka HA passes are otherwise fully closed
    (infrastructure + application + follow-up corrections) — no further
    stages planned unless a new gap surfaces.

## Next

- Nothing committed yet this session — `docs/cross-project-lessons.md`,
  `docs/postgres-ha-scope.md`, `docs/testing-strategy-ha-supplement.md`,
  `load-tests/postgres-app-primary-failure-test.sh`, and
  `load-tests/kafka-controller-failover-rto-test.py` are all modified,
  awaiting a commit decision.
- The identical hardcoded-`patroni-2` pattern found in 4 sibling scripts
  (`postgres-consul-nonleader-agent-loss-test.sh`,
  `postgres-consul-partition-test.sh`, `postgres-consul-quorum-loss-test.sh`,
  `postgres-primary-failure-test.sh`) — deliberately not fixed this
  session, flagged for a future follow-up if those scripts are revisited.
- Docker Compose stack is currently up, **including the Kafka debug-
  logging overlay** (`docker-compose.kafka-debug.yml`, TRACE-level
  controller logging on all 3 brokers) rather than the normal dev
  config — worth knowing if picking this back up; bring it back with a
  plain `docker compose up -d` (no `-f docker-compose.kafka-debug.yml`)
  to revert to standard logging.
