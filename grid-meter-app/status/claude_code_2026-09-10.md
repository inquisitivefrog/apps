# grid-meter-app — Status: 2026-09-10 (Claude Code)

Direct continuation of `status/claude_code_2026-09-09.md`'s k8s Redis
Sentinel HA work — Claude Chat reviewed the finished write-up and pushed
back twice, each time surfacing something real rather than being a
formality. Closed out both rounds, then closed the slice out fully per
Chat's own checklist, then a user question surfaced a real doc-hygiene
gap in an unrelated but adjacent doc.

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

## A durable lesson saved this session

- Confirmed directly by the user: Claude Chat has no live repo access —
  it only sees whatever the user has manually pasted or shared, which can
  go stale mid-investigation. When Chat's feedback cites file contents
  that contradict the live repo, the default hypothesis should be "the
  pasted copy is stale," not "Chat is wrong" or "Code made an error" —
  saved to the `user-workflow-tool-split` memory for future sessions.

## Commits today

`197c1a8`, `78c70b7`, `48e479f`, `9e8aa32` — all pushed to `origin/main`.

## Open / Next

- Nothing outstanding from this slice — Chat's full closing checklist is
  satisfied, docs are current, evidence is indexed.
- The `kind` cluster is currently up and healthy (freshly recreated
  today); the Compose stack is down.
- Carried-over, untouched threads from earlier sessions remain open:
  cloud-deployment (Terraform) scope decision, circuit-breaker
  concurrent-load test.
