# Redis / Sentinel — HA investigation

**Authoritative narrative and plan**: `docs/redis-ha-scope.md`. This file
tracks status/progress against that plan's staged approach, not a duplicate
of its reasoning.

**Status (2026-08-30): All 5 stages complete.** Finding A (old-primary
split-brain window) FIXED and re-verified 3/3 clean. Finding B (failover
non-completion) RESOLVED — a race in this project's own test script, not
a Redis/Sentinel defect, fixed and re-verified 8/8 clean. Stage 5
(quorum-loss) PASSED 3/3 clean with no fix needed. This pass's remaining
deliverable is the results narrative in `docs/redis-ha-scope.md`.

## Stage 1 — Config audit (complete)

Checked live via `redis-cli CONFIG GET` against the running (pre-HA, single
instance) Redis container — not just a repo grep:

| Setting | Live value found | Declared anywhere in the repo? |
|---|---|---|
| `appendonly` | `no` | No — Redis default |
| `save` | `3600 1 300 100 60 10000` | No — Redis default |
| `min-replicas-to-write` | `0` | No — Redis default |
| `min-replicas-max-lag` | `10` | No — Redis default |
| `repl-backlog-size` | `1048576` | No — Redis default |
| `repl-timeout` | `60` | No — Redis default |

**Confirmed the doc's core hypothesis**: `min-replicas-to-write=0` is the
direct structural twin of Kafka's undeclared `acks=1` (Finding 1 in
`docs/testing-strategy-ha-supplement.md`) — the seventh instance of the
undeclared-load-bearing-default pattern found this project (sixth was this
same setting, now promoted to a standing principle in `CLAUDE.md`).

## Stage 2 — Topology stood up (complete)

Built in `docker-compose.yml`: 1 primary (`redis`) + 2 replicas
(`redis-replica-1`, `redis-replica-2`) + 3 Sentinels (`sentinel-1/2/3`,
quorum 2). Replica count (2, not 1) was an explicit decision — see
`docs/redis-ha-scope.md`'s topology question.

**Fixed as part of standing up the topology** (not deferred): declared
`min-replicas-to-write 1` and `min-replicas-max-lag 10` explicitly on the
primary. `1`, not `2` (the full replica count), mirrors Kafka's own
`replication-factor=3`/`min.insync.replicas=2` pattern — tolerate one node
loss without losing durability, not require unanimity from every replica.

**Two real issues found and fixed while standing this up** (both are
genuine environment/config findings, not just "followed the doc"):

1. **Sentinel refuses hostnames by default.** `sentinel monitor mymaster
   redis 6379 2` failed at config-parse time with `Can't resolve instance
   hostname` — Redis Sentinel does not resolve DNS hostnames for a monitored
   master unless `resolve-hostnames yes` is explicitly set (and
   `announce-hostnames yes` so Sentinels announce the master by hostname,
   not a Docker-internal IP that changes on container recreation — matching
   this project's existing hostname-based approach for Kafka's advertised
   listeners). Not a startup-ordering race — `redis` was already fully up
   when this failed; adding `depends_on` alone did not fix it.
2. Added `depends_on: [redis]` on the replicas and Sentinels anyway, as
   correct practice independent of the above — matches the DNS-registration
   race already noted elsewhere in `docker-compose.yml` for `api`/`kafka`,
   even though it wasn't the actual cause of the Sentinel failure this time.

**Verified (all via direct commands against the live containers, not
inferred from status output)**:
- `redis-cli CONFIG GET min-replicas-to-write` / `min-replicas-max-lag` on
  the primary — confirmed live at `1` / `10`.
- `redis-cli INFO replication` on the primary — `connected_slaves:2`, both
  `state=online`, `lag=0`.
- `redis-cli -p 26379 sentinel master mymaster` on **all 3** Sentinels —
  identical `runid`, confirming all 3 are genuinely monitoring the same
  master instance, not divergent views.
- `redis-cli -p 26379 sentinel ckquorum mymaster` — `OK 3 usable Sentinels.
  Quorum and failover authorization can be reached`.
- A real write to the primary (`SET stage2-marker <timestamp>`), confirmed
  present on **both** replicas via direct `GET` — not inferred from
  replication-offset numbers, per the doc's explicit instruction.
- `loglevel debug` confirmed live on all 6 containers (primary, both
  replicas, all 3 Sentinels) — enabled **before** any failure testing, the
  direct lesson from Kafka's Run 1 gap (no TRACE evidence existed for the
  first unsafe reproduction because debug logging wasn't in place yet).

## Stage 3 — Single-replica failure, expected-safe case (complete, PASS)

Run as **two independent sub-tests** (kill replica-1, verify, restore; then
kill replica-2, verify, restore) rather than assuming the replicas are
interchangeable just because their config is identical — this project's
standing methodology after the Kafka investigation is to verify symmetry
empirically, not assume it. See
[`runs/20260829-205629-stage3/run-transcript.txt`](runs/20260829-205629-stage3/run-transcript.txt)
for the full transcript. Script: `load-tests/redis-ha-demo.sh`.

**Result: both replicas behaved identically — the hypothesized symmetry
held.** For each:
- Sentinel's view of the master stayed flagged plain `master` throughout —
  no failover attempted, no stuck `s_down`/`o_down` escalation.
- The primary kept accepting writes (`SET` returned `OK`) with
  `connected_slaves` dropped to 1, confirming `min-replicas-to-write=1` was
  satisfied by the one remaining replica rather than blocking writes.
- The killed replica rejoined cleanly on restart: `lag` returned to `0`,
  and the distinguishing marker write made *while it was down* was
  confirmed present via direct `GET` once it caught back up — not inferred
  from replication-offset numbers.

No surprises this stage — the boring, safe case behaved exactly as
`docs/redis-ha-scope.md` predicted it should. Worth noting precisely
because Stage 4 (real primary failure, replica promotion, split-brain
check) is where an asymmetry between the two replicas would actually
matter (Sentinel's promotion-candidate selection is identity-sensitive,
unlike the pure-count `min-replicas-to-write` check exercised here).

## Stage 4 — Primary failure, the real test (complete — real finding, not just a clean pass)

Run **three times** per this project's standing bar for a correctness/
behavioral finding, not stopped after the first clean-looking result — this
paid off directly: the three runs showed three different things. Script:
`load-tests/redis-primary-failover-rto.sh`. Each run resets to the
canonical topology (`--force-recreate` on all 6 containers) before starting,
so re-running is safe and self-contained.

| Run | Dir | Failover completed? | RTO | Marker survived (direct `GET`)? | Old-primary behavior on restart |
|---|---|---|---|---|---|
| 1 | [`20260829-210333-stage4`](runs/20260829-210333-stage4/) | **No** — 3 consecutive Sentinel epochs (~45s) failed to complete | N/A | N/A | Only recovered via manual restart; never a real failover |
| 2 | [`20260829-210710-stage4`](runs/20260829-210710-stage4/) | Yes, ~150ms after `+odown` | ~7s | Yes | **Accepted writes as `master` for ~10s** before correction |
| 3 | [`20260829-211102-stage4`](runs/20260829-211102-stage4/) | Yes | ~7s | Yes | Claimed `master` for the same ~10s, but writes correctly `NOREPLICAS`-rejected throughout |

### Finding A (runs 2 and 3, confirmed twice, mechanistically understood): a real split-brain window on old-primary restart, caused by this project's own config, not a Sentinel defect

**Root cause**: the `redis` service's `docker-compose.yml` command has no
`--replicaof` and nothing else that persists a failover decision. On *any*
restart it boots fresh believing it is master, with zero memory of what
happened while it was down — Sentinel only corrects this after it notices
and issues `+convert-to-slave`, which took **exactly 10.008s** in run 3
(`role-change...master` at `04:11:22.008` → `+convert-to-slave` at
`04:11:32.016`) — matching `failover-timeout=10000ms` almost to the
millisecond, in both runs 2 and 3. This is deterministic, not timing noise.

**Whether that window produces an actual accepted write depends on
transient, unreliable state**: run 2's restarted primary saw enough
apparent connected replicas to satisfy `min-replicas-to-write=1` and
accepted writes (`OK`) for the full ~10s window — a genuine two-writers
split-brain, the exact scenario `docs/redis-ha-scope.md` names as the
sharpest risk in this pass. Run 3's restarted primary saw zero connected
replicas and correctly rejected every write (`NOREPLICAS`) for the same
window, with no config difference between the two runs. **`min-replicas-
to-write` is not a reliable safety net against this** — it happened to
save run 3 and did not save run 2.

**This is a real, actionable gap in this project's own environment
config**, not an upstream Sentinel bug report candidate — the fix is a
proper reconciliation step on primary restart (query Sentinel for the
current master before deciding a container's own role), which none of the
3 data nodes currently have. Worth scoping as a follow-up fix before this
topology is treated as production-safe for the demo.

### Finding A — FIXED and re-verified 3/3 clean (2026-08-30)

Per `docs/redis-ha-scope.md`'s decision ("fix Finding A now, before Stage
5... re-run Stage 4 to confirm the fix holds, a clean pass required, not
just one"): added `scripts/redis-entrypoint.sh`, a Sentinel-aware
entrypoint used by all 3 data nodes (`redis`, `redis-replica-1`,
`redis-replica-2`). Before starting `redis-server`, it asks all 3
Sentinels who the current master actually is and starts as a replica of
whatever Sentinel reports if that isn't itself — no longer trusting
`docker-compose.yml`'s static role assignment to still be true after a
restart. A `FALLBACK_REPLICAOF_HOST`/`PORT` env var on the replica
services preserves their old static assumption if Sentinel is genuinely
unreachable, rather than risking an unintended second primary in that
edge case.

**Re-verification: 3 clean runs, per this project's 3-iteration bar for a
correctness fix**, not stopped after the first:

| Run | Demoted at (was ~10-11s before the fix) | Real failover? | Marker survived? |
|---|---|---|---|
| 1 | **t+0.26s** | Yes | Yes |
| 2 | **t+0.29s** | Yes | Yes |
| 3 | **t+0.30s** | Yes | Yes |

The old primary now self-identifies as a replica of the new master
**before Redis itself even starts accepting connections** — not after
Sentinel's own ~10s reconciliation delay. Zero split-brain window observed
across all 3 runs. `min-replicas-to-write`'s role in this (previously an
unreliable coincidental safety net, see the original Finding A writeup
above) is now moot — there's no window left for it to matter in.

All 3 runs promoted `redis-replica-2` specifically, not `redis-replica-1`
— consistent but not yet investigated; likely a replication-offset or
connection-order tiebreak in Sentinel's replica-priority selection,
tangential to the fix being verified here.

### Finding B — RESOLVED (2026-08-30): a race in this project's own test script, not a Redis/Sentinel defect

Original symptom (run 1): Sentinel elected a leader twice (epoch 1, then
epoch 2), but **neither elected leader ever completed a promotion** —
both epochs expired at their `failover-timeout` boundary with no
`+switch-master` — the entire ~45s window filled with continuous `Failed
to resolve hostname 'redis'`. The cluster only "recovered" because the
test script manually restarted the killed primary. This run's own
"split-brain: yes" auto-verdict was wrong — a naive role+write check that
couldn't distinguish "a real second master" from "the only master ever,
just restarted"; corrected in the script's verdict logic afterward.

**Investigated properly rather than left as "partially understood" (per
explicit instruction to retry with no need to hurry).** Re-ran the script
deliberately until it recurred — happened on the very first retry — this
time with the log-capture timestamp bug already fixed, so **all 3
Sentinels' full logs were captured**, including the actual elected
leader's own perspective (`sentinel-1` was itself the leader in this
recurrence). The real cause was sitting in that log the whole time, and it
had nothing to do with DNS resolution, which was a red herring — routine
background reconnection noise to the dead primary, coincidentally
constant throughout every occurrence:

```
+elected-leader master mymaster redis 6379
+failover-state-select-slave master mymaster redis 6379
-failover-abort-no-good-slave master mymaster redis 6379
```

**Sentinel explicitly aborted because it had zero known replicas to
select from** — not "timed out trying," but a clean, self-documented
abort. Confirmed why: the `+slave` discovery events for *both* replicas
only appeared *after* the old primary rebooted at the end of the run —
meaning Sentinel had never completed even one successful discovery poll
(Sentinel only learns about replicas by polling the primary's own `INFO
replication` output) before the primary was killed. The test script's
`--force-recreate` + fixed `sleep 8` reset step was racing Sentinel's own
discovery cycle, not reliably waiting for it.

**Measured empirically rather than guessed**: a fresh reset's discovery
normally completes in **~2-4 seconds** — comfortably inside the old 8s
sleep most of the time, which is exactly why this was rare (1 clear
occurrence in ~9 runs before the fix) rather than constant. A longer fixed
sleep would have reduced but not eliminated the race under contention
(repeated `--force-recreate` cycles in the same session, host scheduling
jitter) — the correct fix is polling for the actual condition, not
guessing a bigger number.

**A second, related race surfaced immediately while fixing the first**:
Sentinel discovering a replica (via its own `INFO` polling) is a
*different* readiness signal than the **primary itself** considering that
replica "good" for `min-replicas-to-write` (gated by `min-replicas-max-lag`
health-check cadence, a separate mechanism). Confirmed directly — a
marker write attempted right after Sentinel's discovery alone returned
`NOREPLICAS Not enough good replicas to write`, aborting that run cleanly
rather than testing against a false premise.

**Fix**: `load-tests/redis-primary-failover-rto.sh`'s reset step now
actively polls both conditions (`sentinel replicas mymaster` reports 2,
then the primary's own `min_slaves_good_slaves >= 1`) with generous
timeouts, instead of a fixed sleep, aborting cleanly with a clear message
if either doesn't converge rather than proceeding on an unverified
assumption.

**Re-verified: 8/8 clean runs after the fix** (5 runs closing this
specific race, plus the 3 runs already run for Finding A's fix above,
all using the corrected reset logic) — zero recurrences of
`-failover-abort-no-good-slave`, zero `NOREPLICAS` aborts. Finding B is
closed: it was never a Sentinel or Redis defect, just an unverified
readiness assumption in this project's own test harness — the same
"declare/verify explicitly, don't assume" lesson this whole investigation
keeps re-teaching, this time applied to test setup rather than production
config.

## Environment

| Component | Version |
|---|---|
| Redis | 8.10.1 (`redis:8.10` image) |
| Docker Client/Server (Desktop) | 29.7.2 |
| Docker Compose | 5.4.0 |
| Host OS | macOS 26.5.2, arm64 (Apple Silicon) |

## Stage 5 — Quorum-loss equivalent (complete, PASS, 3/3 clean)

Script: `load-tests/redis-quorum-loss.sh`. Two sub-tests per run, matching
the doc's exact scenario:

- **Sub-test A** — kill 2 of 3 Sentinels while the primary stays healthy.
  Expected: nothing changes.
- **Sub-test B** — the real test — with only 1 Sentinel left, *also* kill
  the primary. A lone Sentinel lacks the majority (2 of 3) required to
  authorize a failover. Expected: it does **not** unilaterally promote a
  replica anyway.

**One real bug caught in the script itself before trusting results**: the
first attempt checked `sentinel ckquorum` only 3 seconds after killing 2
Sentinels and got a stale `OK 3 usable Sentinels` — Sentinel's own
peer-liveness detection isn't instant, the same lesson as Finding B's
discovery race. Fixed by polling for the actual `NOQUORUM` state instead
of guessing a sleep duration; empirically takes 5-6 seconds.

**Result, 3/3 clean runs**:
- Sub-test A: primary kept accepting writes normally (`SET` → `OK`,
  `role` stayed `master`) — quorum loss alone changed nothing observable
  on the data side.
- Sentinel-1 correctly detected quorum loss every run (`NOQUORUM 1 usable
  Sentinels... Not enough available Sentinels to reach the majority and
  authorize a failover`), consistently at t+5s or t+6s.
- Sub-test B: **zero unsafe promotions across all 3 runs** — with the
  primary genuinely down and only 1 of 3 Sentinels alive, neither replica
  was ever promoted. The system correctly stayed leaderless/unavailable
  rather than allowing a minority-authorized failover. This is the
  "prove it fails safe, not just that it usually behaves" bar from the
  Kafka quorum-loss test, and Redis/Sentinel met it cleanly here — no
  further fix needed, unlike Findings A and B.

## Next: Stage 5's own deliverable

All 5 stages of `docs/redis-ha-scope.md`'s plan are now complete. Per that
doc's "Deliverables expected from this pass," a results narrative
(analogous to `docs/testing-strategy-ha-supplement.md`) capturing the full
account — Findings A and B, both root-caused, fixed, and re-verified, plus
Stage 5's clean pass — is the remaining item, most naturally owned by
`docs/redis-ha-scope.md` itself rather than duplicated here.
