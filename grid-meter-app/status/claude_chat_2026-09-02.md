# grid-meter-app — Status: 2026-09-02 (Claude Chat)

Long session, mostly Claude Chat reviewing/correcting Claude Code's work
across several threads: Postgres bootstrap-hook follow-up, a fabricated
Stage 6 table caught and fixed, the self-demotion timing investigation
(source-verified), the idempotency companion-work gap (found twice),
and a multi-round Kafka RTO investigation that went through two of its
own self-corrections before landing on a trustworthy number. **Today's
reviewed changes have been committed and pushed**, per the user's
standing workflow: review/approval happens here turn by turn, and a
commit+push is requested afterward — this log doesn't get separate
confirmation once that happens, so absence of an explicit "pushed"
note in a future log shouldn't be read as "not pushed," only as "not
independently confirmed from this side."

## Done

- **Postgres Stage 7 bootstrap-hook follow-up — real bug found and
  fixed, not just re-verified.** The `bootstrap.users`/`post_bootstrap`
  fix declared in Stage 7 was untested against a real cold bootstrap.
  Testing it surfaced: a stale `patroni.yml` comment claiming no
  persistent volume exists (false — Docker-managed anonymous volume),
  stale Consul KV state that would have prevented a real bootstrap from
  ever triggering, and the actual root cause — `bootstrap.users` is dead
  configuration as of Patroni 4.0+, confirmed against Patroni's own
  source (not docs). Fixed via `post_bootstrap` + `psql`'s multiple
  `-c` flags (Patroni execs commands with no shell — a bare `&&` would
  have silently failed too). Re-verified clean against a second real
  cold bootstrap. `docs/postgres-ha-scope.md` updated.
- **Stage 6's original results table found to not match its own cited
  raw evidence** — leader/timing figures (`12326ms` etc.) didn't appear
  anywhere in the transcripts they were supposedly drawn from. Corrected
  to the real numbers; traced back to how the number was originally
  reported, not introduced during doc-writing. Raised as a broader
  concern: no number in any HA doc this project has produced has ever
  been independently re-derived from raw evidence before today.
- **Self-demotion timing investigation, fully resolved.** Paired-agent
  hypothesis retested with proper controls: refuted at the originally
  claimed magnitude, but a real, smaller, consistently-replicated effect
  survives. Escalated to a source read of Patroni 4.1.5's Consul DCS
  retry/backoff logic, plus an empirical scaling test
  (`loop_wait`/`retry_timeout` dropped from 10/10 to 3/3 and back) —
  produced a clean, predictive formula: self-demotion lands at ~90–103%
  of `loop_wait + retry_timeout`. Real operational finding along the
  way: a tight `retry_timeout` buys faster detection at the cost of
  false-positive self-demotion margin during normal post-disruption
  latency. One data row's console-reconstructed provenance (after a
  mid-run crash) was flagged as under-disclosed, then verified directly
  against raw `.log` files and found trustworthy — footnoted honestly
  either way. `docs/postgres-ha-scope.md` updated in full.
- **Redis Stage 6 doc contradiction found and fixed** — header said
  "done," the line directly beneath it still said "Not yet started."
  Same category as the Postgres Stage 7 header staleness found earlier
  this week.
- **Idempotency companion-work gap — found twice, now closed
  exhaustively.** First pass (JMeter, Bruno) was declared complete and
  wasn't: a repo-wide grep (not scoped to `load-tests/`) found 6 more
  scripts POSTing directly to `/readings` with no header
  (`kafka-ha-demo.sh`, `kafka-acks-gap-repro.sh`,
  `kafka-leader-failover-rto.sh`, `postgres-app-primary-failure-test.sh`,
  `redis-app-primary-failure-test.sh`, `scripts/verify-bruno-collection.sh`).
  All fixed; a second, unrelated bug found only by actually running the
  fix (`verify-bruno-collection.sh` had no wait for the async
  Kafka→Postgres write before asserting `GET`). `docs/idempotency-scope.md`'s
  prior "no companion work remains outstanding" claim struck through
  (a second time) with the full account. New `cross-project-lessons.md`
  entry: a breaking API-contract audit needs a repo-wide grep for
  literal call sites, not a check against the documented/remembered
  client list.
- **Kafka RTO variance investigation — closed after three rounds of
  self-correction, each one caught by pushing back rather than
  accepting a plausible-sounding number:**
  1. Controller-failover hypothesis built and tested: internal RTO
     landed in an ~identical ~0.6s band regardless of condition —
     hypothesis refuted.
  2. Found that both the retest script and the original
     `kafka-ha-demo.sh` measured RTO via a `kafka-topics.sh --describe`
     polling loop whose real per-call cost (~0.96s, JVM startup) was
     never accounted for — meaning the original `3.7s/14.0s/15.5s`
     figures likely never measured a real Kafka mechanism at all.
     Rebuilt around a live log-tail instead.
  3. Production port (`kafka-partition-rto.py`) then measured `~0.1s`
     in real runs — 5x below the "corrected" `~0.6s` band. Investigated
     rather than dismissed as variance: found the investigation script
     itself had a bug (`kill_dt` captured before tail-setup and a
     `sleep(0.3)`, `kill_wall_time` captured correctly but unused for
     the primary metric). Fixed, re-measured.
  4. The fix's own explanation was then itself an overclaim
     ("~250ms accounts for essentially the entire gap" — that 250ms
     was measured on a *different* script's setup phase). Caught,
     re-measured directly at the actual two capture points: `0.471–0.483s`
     across 6 trials, closing the arithmetic for real this time.
     **Final, cross-validated result**: controller-killed
     `0.138–0.167s`, non-controller-killed `0.106–0.143s` (n=6 each,
     still overlapping — conclusion unchanged, now at the right scale),
     matching all 3 real `kafka-ha-demo.sh` production runs. Secondary
     finding (external metadata visibility, not internal decision time,
     may carry a real controller-correlated cost) upgraded from
     single-sample to 3-times-replicated (9-of-9 clean separation).
     `docs/testing-strategy-ha-supplement.md` and `docs/testing-strategy.md`
     (new standing lesson: a polling loop's own per-call cost can
     dominate the measurement it's taking) both updated.
- **Fix carried back into production**: `kafka-ha-demo.sh` Scenario 1
  now uses the validated log-tail measurement instead of the polling
  loop. Hard fail-fast guard added (checks `org.apache.kafka.controller`
  is at DEBUG/TRACE before any disruptive action; stricter than the
  existing unclean-election scripts' best-effort precedent, since here
  the log read is the primary mechanism, not bonus evidence). **Decision
  made**: require the debug overlay as a documented prerequisite
  (option 2), not a permanent stock-config logging change — this script
  is expected to run rarely enough that the recurring overlay-up cost
  doesn't dominate.
- **Two more real bugs found only by running the production fix to
  completion**: a negative RTO (signal-file write ordering vs. Kafka's
  SIGTERM-triggered controlled shutdown relinquishing leadership mid-`stop`),
  and a stale `RTO_MS` variable reference left over from a rename.
  Both fixed.
- **`docs/api-and-data-model.md` brought current and live-verified**:
  added the `Customer` entity, `customerId` on `Meter`/`User`, the
  `idempotencyKey` column, and a new Multi-tenancy section — then
  checked column-for-column against the real running schema (`\d+`
  output for all 5 tables plus `flyway_schema_history`). Everything
  matched; the one real addition was the seeded "Default Customer" row,
  which no design doc would have specified in advance.
- **Traffic-flow PDF produced**, combining the original observability
  diagram (still accurate, confirmed) with a new data-tier diagram
  (Traefik's dual role, Kafka/Postgres-HA/Redis-HA fan-out) and a
  traffic-type breakdown.

## Open

- **`CLAUDE.md`'s undeclared-default tally** still needs bumping to 9
  (`PATRONI_CONSUL_CONSISTENCY`) — flagged previously, not yet
  confirmed done.
- **A possible fourth `set -e`/command-substitution occurrence** was
  mentioned in passing during today's work but not yet written up with
  full mechanism detail the way the first two instances were.
- **Kafka RTO investigation's own archival gap, disclosed not fixed**:
  re-running the corrected script a second time overwrote the first
  corrected pass's raw log files (same fixed filenames). Pass 1's
  numbers survive only in the doc's prose, not as separately archived
  evidence. Named honestly in the doc; not corrected.
- Postgres/Redis/Kafka's earlier flagged "nice to have, not blocking"
  items (App RTO variance mechanism, GC-pause/ISR-lag as a fallback
  explanation if needed) remain untouched — today's work resolved the
  Kafka RTO question specifically, not these adjacent ones.

## Next

1. Bump `CLAUDE.md`'s undeclared-default count to 9.
2. Confirm whether the possible 4th `set -e` instance is real and
   write it up with the same precision as the first two, or drop it if
   it doesn't hold up under the same scrutiny everything else today got.
3. Decide whether to close the Kafka RTO archival gap (re-run once more
   with distinct filenames per pass) or accept the current disclosed
   state as sufficient.
4. Postgres/Redis/Kafka HA passes are otherwise fully closed
   (infrastructure + application + this session's follow-up
   corrections) — no further stages planned unless a new gap surfaces.
