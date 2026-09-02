# grid-meter-app — High-availability scope: Redis (Sentinel)

**Status (2026-09-02): all 6 stages complete — infrastructure (1–5) and
application (6) both validated.** The app's Redis client is now
Sentinel-aware (`spring.data.redis.sentinel.master`/`.nodes`); a
primary-kill scenario re-run through the app's real endpoints came back
3/3 clean with zero HTTP-level impact. This Redis pass is fully closed,
matching the Postgres pass's own infrastructure-plus-application
closure. See "Stage 6 results" below for the full account, including a
previously-deferred bug that stopped being low-priority once real
cutover work depended on it.

## Why this doc exists

`docs/ha-scope.md` scoped this project's HA work to Kafka first and
explicitly deferred Redis, with a named revisit trigger: "once Kafka's
multi-broker pass is built, tested, and its own status log closed out."
That trigger has now fired — Kafka HA is built, tested (including a real
`acks` gap and a genuine upstream Kafka bug, both found and documented in
`docs/testing-strategy-ha-supplement.md`), and closed out. This doc opens
the Redis scope decision explicitly, rather than letting it default in
silently.

**This is a deliberately smaller, more cautious doc than `ha-scope.md`
was at the start of the Kafka pass**, for one direct reason: the Kafka
investigation took far more effort and turned up far more surprises
(an undeclared `acks` default, a Traefik health-check gap, a real
upstream KRaft bug with two distinct promotion code paths) than the
original scope doc anticipated. This doc is written to front-load those
lessons rather than relearn them from scratch, and to proceed in
deliberately small, verifiable steps rather than building the full
Sentinel topology and testing it all at once.

**Scope of this doc**: Redis only. Postgres/Patroni is explicitly a
separate, later doc — per `ha-scope.md`'s own instruction not to bundle
Postgres in with Redis "as if it were the same size of change." Do not
start Postgres HA work from this doc.

## What's being built

Per `ha-scope.md`'s "Deferred layers" section: **1 Redis primary + 2
replicas** (not 3 functionally-interchangeable instances — Redis
replication is single-writer, so the topology is asymmetric by design:
one primary accepts all writes, the other two are read-only followers
that replicate from it and are eligible for promotion), coordinated by
**Redis Sentinel** (typically 3 Sentinel processes, lightweight,
~16–32MB each) for automatic failover detection and promotion.

**Terminology note**: current Redis documentation and this doc both use
**"primary/replica"** — "master/slave" is the older terminology, now
retired from Redis's own docs. That said, **the term "master" survives
literally in Sentinel's config directive and CLI**: the config line is
`sentinel monitor <name> <ip> <port> <quorum>` (naming what's monitored,
historically "master"), and the live admin commands are `SENTINEL MASTER
<name>` and `SENTINEL REPLICAS <name>` — not `SENTINEL PRIMARY`. Don't
be thrown by the mismatch between this doc's "primary" language and
literal `MASTER` keywords appearing in actual Sentinel commands and
output — they refer to the same thing.

**Topology decision needed before implementation starts**: is 2 replicas
(1 primary + 2 replicas, as scoped above) the right number, or would 1
replica suffice for this project's demo purposes? `ha-scope.md`'s own
quorum reasoning ("3, not 2") applies to the *Sentinel* count, not
necessarily the data-node count — worth deciding explicitly rather than
assuming the two numbers must match. 1 primary + 1 replica + 3 Sentinels
gives automatic failover but only one failure of margin on the data side
(if the sole replica is down when the primary fails, there is nothing to
promote). 1 primary + 2 replicas gives one full spare even after a
promotion has already consumed one replica. Recommend confirming intended
fault tolerance explicitly before fixing the topology.

## Redis Sentinel quorum mechanics — distinct from Kafka's, don't assume they're the same shape

**This is worth stating explicitly, because it's a real and easy-to-miss
difference from the Kafka quorum reasoning already documented in
`ha-scope.md`.** Kafka's KRaft quorum is a single mechanism: majority of
controller voters agrees on one thing (who's the leader). Sentinel splits
this into two distinct, sequential decisions, each with its own
threshold:

1. **Quorum (`sentinel monitor <name> <ip> <port> <quorum>`)** — the
   number of Sentinels that must independently agree a primary is down
   (moving it from `SDOWN`, subjectively down per one Sentinel's own
   observation, to `ODOWN`, objectively down per enough Sentinels
   agreeing) before failover is even considered. This is a *detection*
   threshold, not an *authorization* threshold.
2. **Failover authorization — majority of *all known* Sentinels**,
   separate from and not necessarily equal to the configured `quorum`
   value above. Once a Sentinel decides to start a failover, it needs to
   be voted the leader for that failover epoch by a majority of every
   Sentinel in the deployment (not just the `quorum` count) before it's
   allowed to actually promote a replica.

**Why this distinction matters concretely**: it's possible to configure
`quorum` low (e.g. 2 in a 5-Sentinel deployment) while the actual
failover-authorization step still requires a true majority (3 of 5) —
these are not the same number, and conflating them was a real, named risk
during Kafka's investigation (config-checked-but-not-actually-enforced —
see `acks` and the config precedence discussion in
`testing-strategy-ha-supplement.md`). **Do not assume the `quorum` config
value is Sentinel's full quorum story** — verify both thresholds
explicitly, the same way the Kafka investigation verified `acks` and
`min.insync.replicas` were both required for durability rather than
either alone.

## Durability equivalent of `acks=all`: `min-replicas-to-write` / `min-replicas-max-lag`

**This is the single most important lesson to carry forward from the
Kafka investigation, and the most likely place for an equivalent gap to
exist.** Kafka's `acks=1` default silently allowed an acknowledged write
to exist on only one broker — `min.insync.replicas=2` was configured but
never enforced, because the producer-side half of that contract was
undeclared. Redis has the direct structural analog:

- **By default, Redis replication is asynchronous.** A write can be
  acknowledged to the client before any replica has received it. If the
  primary fails immediately after acknowledging, that write can be lost
  even with a replica present and even with Sentinel correctly promoting
  that replica — the replica simply never had the write to begin with.
- **`min-replicas-to-write N` / `min-replicas-max-lag N`** is the
  primary-side safeguard: refuse writes if fewer than `N` replicas are
  connected and within `max-lag` seconds of caught-up. This is
  structurally the same role `min.insync.replicas` plays for Kafka — a
  broker/primary-side check that only means something if actually
  configured, and does **not** exist by default.
- **Action before any failover testing begins**: check whether
  `min-replicas-to-write`/`min-replicas-max-lag` are declared anywhere in
  this project's Redis config today. Given the pattern found repeatedly
  in the Kafka work (HikariCP timeout, `max.block.ms`,
  `delivery.timeout.ms`, `acks`, `unclean.leader.election.enable` — every
  one of them an undeclared load-bearing default), the working assumption
  going in should be that this is **also currently undeclared and
  defaulting to "no durability guarantee,"** not that it's already
  handled. Verify by grep, the same way each Kafka config was verified,
  rather than assuming Redis is fine because nobody's looked yet.

## Stage 1 results (2026-08-28): confirmed — every durability-relevant setting is an undeclared default

**Confirmed via live `redis-cli CONFIG GET` against the running
container, not just a config-file grep** — same "check the actual
running system, not just what's declared" discipline used throughout the
Kafka investigation:

| Setting | Live value | Declared anywhere? |
|---|---|---|
| `appendonly` | `no` | No — Redis default |
| `save` | `3600 1 300 100 60 10000` | No — Redis default |
| `min-replicas-to-write` | `0` | No — Redis default |
| `min-replicas-max-lag` | `10` | No — Redis default |
| `repl-backlog-size` | `1048576` | No — Redis default |
| `repl-timeout` | `60` | No — Redis default |

No `redis.conf` exists anywhere in the project; the `redis:` service in
`docker-compose.yml` has no command override, no config mount, and no
relevant environment variables. Redis is running on pure image defaults.

**The doc's core hypothesis is confirmed exactly**: `min-replicas-to-write=0`
is the direct structural twin of Kafka's undeclared `acks=1` — once a
replica exists, the primary will accept and acknowledge writes with zero
enforcement that any replica is connected or caught up.

**Standing pattern, worth naming explicitly now that it's 6 for 6 across
this entire HA effort**: the HikariCP timeout, `max.block.ms`,
`delivery.timeout.ms`, `acks`, `unclean.leader.election.enable`, and now
`min-replicas-to-write` have *all* turned out to be undeclared defaults
when actually checked. This is no longer a per-config coincidence — it's
a reliable prior about this project's starting state, worth carrying
into every remaining stage here and into the Postgres pass: assume any
durability/quorum-relevant setting is undeclared until verified live,
rather than checking case-by-case as if each one might reasonably already
be handled.

**Proceeding to Stage 2 next**, per the doc's own staging discipline
(stop and report before continuing).

## Decision confirmed (2026-08-28): `min-replicas-to-write 1` / `min-replicas-max-lag 10`

Set on the primary during Stage 2, closing the exact gap Stage 1 found.
Worth recording the reasoning precisely, since two things about it are
easy to get wrong by loose analogy to the Kafka work:

**Counting convention differs from Kafka's — same-looking numbers mean
different things.** Redis's `min-replicas-to-write N` counts **replica
nodes only**; the primary is never included in that count, since it
trivially always has its own most recent write. Kafka's
`min.insync.replicas N`, by contrast, counts the **leader plus followers
together** — the leader is itself a member of the ISR set. So on this
project's two topologies: Kafka's `min.insync.replicas=2` on a 3-broker
cluster (RF=3) means "leader + 1 follower," tolerating exactly 1 follower
loss. Redis's `min-replicas-to-write=1` on a 1 primary + 2 replica
topology means "at least 1 of the 2 replicas," which is the correct
structural analog — both settings tolerate exactly one non-primary/
non-leader node being down while still enforcing that at least one real
copy exists elsewhere. **`min-replicas-to-write=2` would not be the
equivalent of Kafka's `min.insync.replicas=2`** — it would require *both*
replicas connected, tolerating zero replica loss, a stricter bar than the
matching-looking Kafka number implies. Confirmed `1` is correct for this
topology's intended fault tolerance: survive one replica loss (including
a planned maintenance window) without refusing writes.

**A real gap this setting does not close, accepted deliberately rather
than overlooked**: `min-replicas-to-write` is a periodic health gate
(checked on roughly a 1-second cadence via `REPLCONF ACK`), not a
per-write synchronous guarantee the way Kafka's `acks=all` is. A write
can still be acknowledged to the client and lost if the primary dies in
the gap between health checks, even with this setting correctly
configured. Redis does have a true per-write synchronous primitive
(`WAIT numreplicas timeout`), but nothing in this app calls it, and nothing
in this pass adds a call to it. **This gap is accepted, not fixed, for a
reason specific to how this app uses Redis**: per `architecture.md`,
Redis here is explicitly a cache of the latest reading per meter, not a
source of truth, with a documented cache-miss fallback to Postgres. A
promoted replica missing the very latest write produces a stale-or-missing
cache entry, transparently resolved by the existing Postgres fallback —
not permanent data loss, unlike the readings-durability question the
outbox investigation worked through in `docs/resilience-scope.md`. The
same redo-path reasoning that closed the outbox question applies here:
Redis's data has a redo path (Postgres), so a stronger, more
availability-costly durability mechanism (`WAIT`) is not warranted for
this pass. Revisit only if Redis's role in this app ever changes to hold
data with no upstream source of truth.

## Stage 4 results (2026-08-28): a real, mechanistically-confirmed split-brain window — self-inflicted, found, and fixed

**This is a more serious finding than anything the Kafka investigation
turned up, and worth being precise about why**: Kafka's dual-path bug
elected the *wrong* node as sole leader — a correctness problem, but
still only one writer at a time. Redis's Stage 4 finding is worse in
kind: **the old primary genuinely accepted writes as primary for a real
window while the new primary was also accepting writes** — actual
concurrent writers, the exact worst-case scenario `docs/postgres-ha-scope.md`
names as more severe than anything found in the Kafka work, showing up
here first, in Redis, before Postgres/Patroni work has even started.

### Finding A: old-primary role-persistence gap (root cause: this project's own config, not Sentinel)

Confirmed across 3 runs of the marker-write methodology (send a
distinguishable write, kill the primary, check Sentinel's actions and
the actual data via direct `GET`, not status messages):

| Run | Failover completed? | RTO | Marker survived? | Old-primary behavior on restart |
|---|---|---|---|---|
| 1 | No — 3 consecutive epochs failed over ~45s, correlated with sustained hostname-resolution failures | N/A | N/A | Only "recovered" via manual restart, never a real failover |
| 2 | Yes, ~150ms after ODOWN | ~7s | Yes, confirmed via direct `GET` | Accepted writes as master for ~10s (t+0.8s→10.3s all returned OK) before Sentinel corrected it at t+11.3s |
| 3 | Yes | ~7s | Yes, confirmed via direct `GET` | Claimed role=master for the same ~10s window, but writes were correctly rejected (`NOREPLICAS`) — no accepted split-brain write this time |

**Root cause, confirmed structurally**: the `redis` service's command in
`docker-compose.yml` has no `--replicaof` and nothing else that persists
Sentinel's failover decision. Every time the old primary container
restarts for any reason, it boots fresh believing it's still primary,
with zero memory of what happened while it was down. Sentinel does
correct it — but only after `failover-timeout` (10s) elapses, confirmed
deterministic to the millisecond across repeated runs (Run 3: role-change
at 04:11:22.008 → `+convert-to-slave` at 04:11:32.016, exactly 10.008s).
**This is a real, structural window, not an edge case or timing noise.**

**The genuinely alarming part, worth stating without softening**: Run 2
and Run 3 had **no configuration difference between them**, and produced
different outcomes — Run 2 accepted a write during the split-brain
window (actual data divergence), Run 3 correctly rejected writes during
the identical window (`min-replicas-to-write` happened to catch it).
Whether the window is merely confusing (Run 3) or actually
data-diverging (Run 2) currently depends on transient replica-connection
state at the moment of restart — **not a safety net worth trusting**,
since it means this setup's current safety during the window is
coincidental, not structural. A clean demo run today says nothing about
whether the next one is safe.

**Why this counts as good news, relatively**: unlike the KRaft dual-path
finding, this is this project's own `docker-compose.yml` configuration
gap, not an upstream Sentinel defect — directly and immediately fixable
(add `--replicaof`/an equivalent restart-reconciliation mechanism so the
old primary boots already aware it should check with Sentinel/rejoin as
a replica, rather than defaulting to believing it's still primary).

**Decision (resolved 2026-08-28): Finding A fixed and re-verified before
Stage 5** — see the fix confirmation immediately below. Stage 5 is clear
to proceed.

#### Fix and re-verification (2026-08-28)

**Fix**: `scripts/redis-entrypoint.sh` — all 3 data nodes now ask Sentinel
who the current real primary is *before starting*, rather than trusting
`docker-compose.yml`'s static role assignment on every restart. This
closes the gap structurally, not just narrows it: the old primary now
knows its correct role before Redis even begins accepting connections,
rather than briefly accepting writes on stale self-belief and waiting for
Sentinel to notice and correct it after the fact. A
`FALLBACK_REPLICAOF_HOST`/`FALLBACK_REPLICAOF_PORT` env var preserves
safe behavior (a node stays a replica rather than risking becoming an
unintended second primary) if Sentinel itself is genuinely unreachable at
boot — the fix doesn't trade "wrong role on restart" for "no role if
Sentinel is down."

**Re-verification, 3/3 clean**: normal bootstrap confirmed still correct
on all 3 nodes (entrypoint logs show the right decision, quorum
reachable) before re-running the failure scenario. Stage 4 re-run 3
times:

- Demotion time: **~0.26–0.30s**, down from the original ~10–11s window
  (previously bounded by `failover-timeout`, now bounded by how fast the
  entrypoint can query Sentinel — a structurally different and much
  smaller ceiling).
- Real failover completed and the marker write confirmed present via
  direct `GET`, all 3 runs.
- **Zero split-brain across all 3 runs** — no window where two nodes
  both believed they were primary.

**Status: closed.** Same three-run discipline applied to the fix as to
the original finding, matching the standard this whole HA effort has
held to — a single clean run would not have been sufficient evidence
either way.

### Finding B: Run 1's total failover non-completion — resolved, was a test-script race, not a Redis/Sentinel defect

**Closed (2026-08-28).** Re-investigated with properly captured leader
Sentinel logs (Run 1's originals were unrecoverable — this is a fresh,
separate reproduction). The actual cause, confirmed via a clean,
self-documented log line rather than inferred from timing correlation:
`-failover-abort-no-good-slave` — Sentinel deliberately and correctly
aborted the failover because it had not yet finished discovering a
qualified replica, not a timeout or a defect.

**Root cause, precisely**: the test script's fixed `sleep 8` after
resetting topology was racing Sentinel's own replica-discovery poll,
which normally completes in ~2–4s but isn't reliably bounded under
contention. A second, related race surfaced immediately while fixing the
first: the primary's own `min-replicas-to-write` readiness is a separate
signal from Sentinel's discovery completing, and the test script had been
implicitly assuming the two move together. Both fixed by replacing the
fixed-duration sleep with active polling for the actual readiness
conditions. **Re-verified 8/8 clean.**

**Correction to the original investigation, stated plainly**: the
`Failed to resolve hostname 'redis'` errors that looked like strong
supporting evidence for a DNS-related root cause were a **complete red
herring** — ordinary background reconnection chatter to the already-dead
primary, present in every run regardless of outcome, not correlated with
failure specifically. This is worth stating for the same reason the
KAFKA-19148 misattribution was stated plainly rather than quietly
corrected: a plausible-looking, circumstantially-supported explanation
was wrong, and the process that caught it (capturing the actual log
line, not trusting the correlation) is what's worth trusting going
forward, not the intuition that got there first.

**Worth checking, not yet done**: whether other test scripts in this
project (the Kafka HA demo scripts, in particular) have similar
fixed-sleep-after-topology-change patterns that could be masking the same
class of flakiness. Not blocking — Kafka's HA work is already closed out
— but worth a quick audit given how directly this same pattern just
produced a real, if ultimately misdiagnosed, finding here.

**Full evidence, all runs, corrected verdict logic**: see
`load-tests/vendor-bug-reports/redis/NOTES.md`.

## Testing strategy — staged, not all-at-once, per your instruction

Given how much the Kafka investigation surfaced through incremental,
disciplined steps (and how much wasted effort would have resulted from
building the full picture before testing any of it), this pass is
explicitly staged. **Do not proceed to a stage before the previous one
has a clean, verified result — stop and report back at each stage
boundary**, the same discipline that caught the `acks` gap, the Traefik
interaction, and the KRaft dual-path bug before they compounded into
something harder to untangle.

### Stage 1 — Config audit (no new infrastructure yet) — **done, see results above**

Before building anything: grep the current Redis config
(`docker-compose.yml`, `application.yml`'s `spring.data.redis.*`, and any
`redis.conf` if one exists) for every durability/replication-relevant
setting. Specifically confirm, for each, whether it's declared explicitly
or silently defaulted:

- `min-replicas-to-write` / `min-replicas-max-lag`
- `appendonly` (AOF persistence — relevant to what a restarted node
  actually recovers, separate from replication)
- `save` (RDB snapshot intervals, if AOF is off)
- `repl-backlog-size` and `repl-timeout`

**Report findings before moving to Stage 2.** This mirrors exactly how
the Kafka `acks` gap was found — by checking, not assuming — and should
surface any equivalent "durability guarantee only exists on paper" issue
before a single Sentinel process is even started.

### Stage 2 — Stand up the topology, no chaos testing yet

Build the actual Sentinel deployment (primary + replica(s) + 3
Sentinels) in `docker-compose.yml`. Verify, at rest, with no failures
introduced:

- `redis-cli info replication` on the primary shows the expected number
  of connected replicas
- `redis-cli -p <sentinel-port> sentinel master <name>` on each Sentinel
  agrees on who the primary is
- A write to the primary is confirmed present on the replica via direct
  `GET`, not inferred from replication-offset numbers alone

**Enable verbose/debug-level Sentinel and Redis logging now, before any
failure is introduced** — this is a direct, hard-learned lesson from the
Kafka investigation: Run 1's data loss had no TRACE-level evidence
captured because the debug overlay wasn't in place yet, and that gap had
to be closed by re-running the entire scenario later. Do not repeat that
sequencing mistake here — get logging capability verified working in
Stage 2, before Stage 3 needs it.

### Stage 3 — Single failure, expected-safe case

Kill the replica only (primary untouched). Confirm:

- Sentinel detects it, no failover attempted (there's nothing to fail
  over to/from — the primary is fine)
- Primary continues accepting writes throughout
- Replica rejoins and catches up cleanly on restart

This is the Redis equivalent of Kafka's rolling-maintenance scenario —
establish the safe, boring case works before testing the dangerous one.

### Stage 4 — Primary failure, the real test — **done, see results above (Finding A and Finding B both found and fixed)**

Kill the primary while under real write load (mirroring the marker-write
methodology from the Kafka investigation: send a distinguishable,
acknowledged write immediately before killing the primary, so it's
possible to check afterward whether that specific write survived, not
just whether *a* primary exists again afterward).

**Explicitly check, not assume:**
- Did Sentinel correctly promote the replica?
- Does the promoted replica actually have the last acknowledged write —
  checked via direct `GET`, not via Sentinel's own "failover complete"
  status message. (This directly mirrors the Kafka lesson: Kafka's
  controller *log labels* were shown to be an incomplete signal — Path 2's
  promotion had no `UNCLEAN` label at all despite being unsafe. Don't
  trust Sentinel's status output alone as proof of safety; check the data
  itself.)
- Measure actual failover time (Sentinel's `down-after-milliseconds` +
  its own failover-timeout — get a real number, not the configured
  ceiling).
- **Old-primary-rejoin check, directly analogous to the Kafka
  fencing/promotion investigation**: once the dead primary restarts, does
  it correctly demote itself to a replica of the new primary, or is there
  any window where it could still think it's the primary and accept
  writes? This is Redis's version of the split-brain risk `ha-scope.md`
  already names as a general concern — verify it concretely rather than
  assuming Sentinel's `reconfig` step is instant and race-free.

**Run this stage more than once**, even if the first run looks clean.
The Kafka investigation's most important finding (the second,
unlabeled promotion path) was only found because a first "clean-looking"
result (Run 2) was not treated as proof the mechanism was fully
understood — a second run under closer inspection (Run 3) found a second
code path entirely. Apply the same skepticism here: one safe-looking
failover is not the same as a verified-safe mechanism.

### Stage 5 — Quorum-loss equivalent: kill 2 of 3 Sentinels — **done, see results below (PASS, 3/3 clean)**

Mirrors Kafka's quorum-loss test. With only 1 of 3 Sentinels left, no
Sentinel can reach the majority needed to authorize a failover (per the
quorum-mechanics section above) — confirm the system fails safe (no
failover attempted, primary keeps serving if it's actually still up) or
correctly identifies it cannot safely act, rather than doing anything
export-worthy on the data side. This is the same "prove it fails safe,
not just that it usually behaves" principle from Kafka's quorum-loss
scenario.

**Results (2026-08-30)**: script `load-tests/redis-quorum-loss.sh`, two
sub-tests per run, matching the scenario above exactly:

- **Sub-test A** — kill 2 of 3 Sentinels while the primary stays healthy.
  Result: nothing changed — primary kept accepting writes normally
  throughout, confirmed via a direct `SET`/role check, not inferred.
- **Sub-test B** — the real test — with only 1 Sentinel left, *also* kill
  the primary. Result: **zero unsafe promotions across 3 independent
  runs.** With the primary genuinely down and only 1 of 3 Sentinels
  alive, neither replica was ever promoted — the system correctly stayed
  leaderless/unavailable rather than allowing a minority-authorized
  failover.

**One real bug caught in the test script itself, same family as Finding
B**: the first attempt checked `sentinel ckquorum` only 3 seconds after
killing 2 Sentinels and got a stale `OK 3 usable Sentinels` — Sentinel's
own peer-liveness detection isn't instant (confirmed: takes 5-6 seconds
in practice). Fixed by polling for the actual `NOQUORUM` state instead of
guessing a sleep duration, per the "fixed sleeps racing unbounded
readiness signals" lesson now in `docs/testing-strategy.md` — this makes
a **third** occurrence of that exact pattern within this one Redis pass
alone (a fourth across the full HA effort, counting `kafka-ha-demo.sh`).

**Unlike Findings A and B, no fix was needed for Sentinel/Redis itself
here** — the quorum-authorization mechanism held correctly on every run.
This is the "prove it fails safe" bar from Kafka's quorum-loss test, and
Redis/Sentinel met it cleanly. Full evidence:
`load-tests/vendor-bug-reports/redis/NOTES.md`.

**All 5 stages of this doc's plan are now complete.** Remaining
deliverable per "Deliverables expected from this pass" below: this
results narrative itself, now folded into this doc rather than left only
in the evidence archive's `NOTES.md`.

**Status (2026-09-02): Stage 6 complete — see results below. Redis HA
is now fully closed out, all 6 stages, matching Postgres's 7-stage
pass.** Every check above (Stages 1–5) verified Sentinel/Redis cluster
behavior directly via `redis-cli` and Sentinel's own admin commands.
None of them confirmed that the **application** — its actual Spring
Data Redis client configuration — was even using Sentinel-aware
failover at all, as opposed to a direct, fixed `host:port` connection to
a single Redis container that would have no idea a failover ever
happened. This is the same category of gap found in the Postgres pass
(`SPRING_DATASOURCE_URL` never cut over to the Patroni cluster) — found
there first, but not specific to Postgres.

## Stage 6 results (2026-09-02): PASS, 3/3 clean, plus one previously-deferred bug that stopped being low-priority the moment something real depended on it

**Step 1 confirmed, not assumed**: the app's Redis client was a fixed
connection to the `redis` container by name, with zero Sentinel
awareness — exactly the gap this stage existed to check for, not a
milder version of it.

**Cutover**: reconfigured to Sentinel-aware discovery
(`spring.data.redis.sentinel.master`/`.nodes`). Verified the exact
Spring Boot 4.x property names against the real
`spring-boot-data-redis-4.1.0.jar` rather than assumed from memory or
older documentation — Spring Boot renamed `RedisProperties` to
`DataRedisProperties` in this version line, exactly the kind of
version-specific naming drift `cross-project-lessons.md`'s "verify a
version against the real registry/artifact, don't trust a plausible
string" lesson already warns about, just hitting a property name instead
of a dependency coordinate this time.

**A previously-known, previously-deferred bug, hit for real during this
cutover — worth recording precisely for what changed, not just that it
got fixed**: Stage 5's own results (above) already found and explicitly
left as a "low-priority, not-yet-fixed loose end" that
`redis-quorum-loss.sh`'s restore step could crash Sentinels with a
`Duplicate master name` error, because `docker compose start` (unlike
`--force-recreate`) reuses a container's existing writable filesystem —
and Sentinel's own `/tmp/sentinel.conf`, containing a persisted
`sentinel monitor mymaster ...` line from before the stop, collides with
the container's command-line `--sentinel monitor ...` flag being
reapplied on top of it. This was filed as low-priority specifically
because nothing in normal operation depended on Sentinels surviving a
plain `start` — until cutting the app over to a Sentinel-aware client
meant adding `sentinel-1`/`sentinel-2`/`sentinel-3` to the API's
`depends_on`, which brings up existing-but-stopped Sentinel containers
via exactly that code path on every normal `docker compose up`. **Not a
new bug introduced by this stage — a real, latent risk since Stage 4/5
that simply had nothing exercising it until now.** Fixed at the root,
not just at the one call site that happened to trigger it: all 3
Sentinel commands in `docker-compose.yml` now run `rm -f
/tmp/sentinel.conf && touch /tmp/sentinel.conf && exec redis-server
...`, so every start gets a clean config regardless of whether the
container was freshly created or merely restarted.
`redis-quorum-loss.sh`'s own restore step still uses `start` rather than
`--force-recreate`, but the underlying crash condition it could hit is
now closed structurally, not patched per call site.

### Primary-kill re-run through the app's real endpoints — 3/3 clean

| Run | Old → new master | Infra RTO | Requests | HTTP failures | Cache caught up |
|---|---|---|---|---|---|
| 1 | `redis` → `redis-replica-2` | 7.2s | 87 | 0 | Yes |
| 2 | `redis` → `redis-replica-2` | 6.3s | 86 | 0 | Yes |
| 3 | `redis` → `redis-replica-1` | 6.7s | 83 | 0 | Yes |

**Zero HTTP-level failures in every run — architecturally expected, not
a surprising result to take at face value without explaining why.** This
app's write path persists to Postgres and publishes to Kafka entirely
independently of Redis (per `architecture.md`'s data flow); the cache
write happens later, in an async Kafka consumer. So the real question
this stage needed to answer wasn't "does ingestion survive a Redis
outage" (architecturally, it always would) but "does the async cache
write itself survive the failover" — confirmed directly against
whichever node Sentinel actually promoted, not inferred, in all 3 runs.

**A genuinely interesting mechanism, confirmed via direct log
inspection rather than assumed from how Sentinel failover is supposed
to work**: Lettuce's `ConnectionWatchdog` does not immediately re-resolve
the master via Sentinel once the old primary dies — it first retries the
same dead address for several seconds before falling back to asking
Sentinel for the new one. The cache write still caught up with zero lost
updates in every run regardless, most plausibly because Spring Kafka's
own default consumer retry covers the gap until Lettuce reconnects — a
"most plausibly," not a certainty, since the two mechanisms weren't
independently isolated to confirm this explanation over an alternative
one. **Worth stating precisely why this isn't a designed safety net**:
the connection-pool layer (Lettuce) and the service-discovery layer
(Sentinel) don't necessarily fail over in lockstep, and the only reason
that gap didn't matter here is that Kafka's consumer retry happened to
sit underneath it. If this app's cache write path were ever changed to
not have an independent retry mechanism backing it, this same Lettuce
behavior could produce a real, silent gap instead of a harmless one —
worth remembering as a general shape (a client library's own reconnect
timing and a coordinator's promotion timing are two separate clocks,
not one) rather than a Redis-specific curiosity.

Full evidence: `load-tests/vendor-bug-reports/redis/NOTES.md`.

**Stage 6: done. This closes the Redis HA pass — infrastructure
(Stages 1–5) and application (Stage 6) both now validated, matching the
Postgres pass's own infrastructure-plus-application closure.**

**Follow-up, found later (2026-09-02): this stage's own cutover commit
(`1cbf040`) silently broke every component test's Redis connectivity,
unnoticed until unrelated idempotency work needed a clean full-suite
run.** Once `spring.data.redis.sentinel.master` became non-null, Spring
Boot's autoconfiguration always builds a Sentinel-mode connection,
overriding `ComponentTestSupport`'s attempt to point tests at the
standalone Testcontainers Redis instead — every component test's Redis
write had been failing against a nonexistent `localhost:26379` Sentinel
since this commit landed, with nothing catching it in the meantime.
Fixed via a `!test`-profile gate in `application.yml`; confirmed live
afterward that production Sentinel behavior was completely undisturbed
by the fix. See `docs/idempotency-scope.md`'s "Implementation results"
section for the full account. Worth naming precisely: this is the same
category of gap `docs/ha-scope.md`'s standing lesson already
tracks — a change made for one real purpose silently breaking something
else with no visibility into the dependency — just surfacing in the
test suite this time instead of production traffic.

### Stage 6 — Application-level cutover and validation: confirm the app's real Redis client survives a Sentinel-driven failover — **done, see results above**

**Completed — see "Stage 6 results" above for what was actually found.
The steps below are the original plan, preserved for the record of what
was intended and executed, not a currently-open task list.**

**Step 1 — Check the live config first, don't assume.** Confirm exactly
how the app currently connects to Redis — likely
`spring.data.redis.host`/`port` pointing at a single fixed container
(the pre-Sentinel setup), or possibly already reconfigured toward
Sentinel awareness by an unrelated change since this pass began. Check
the actual running config (`docker compose exec api env | grep -i
redis`, or the equivalent in `application.yml`/`docker-compose.yml`),
not a memory of what it was set to originally.

**Step 2 — Cutover, if Step 1 confirms it's needed.** Reconfigure the
app's Redis client to be Sentinel-aware — for Spring Data Redis with
Lettuce (the default), this means a `RedisSentinelConfiguration`
pointing at all 3 Sentinel nodes and the configured master name, not a
direct host/port to whichever container happens to be primary today.
This is architecturally different from the Postgres cutover (a
TCP-proxy entrypoint) — here the client itself talks to Sentinel to
discover the current master, so there's no separate routing layer to
point at the way Traefik's `:55432` entrypoint served that role for
Postgres. Confirm this distinction rather than assuming the same
proxy-based pattern transfers.

**Step 3 — Basic functional check.** Exercise whatever the app actually
does with Redis in normal operation (per `architecture.md`'s data flow —
Redis as a cache of the latest reading per meter, written by the Service
layer on ingest, read back by the dashboard) against the Sentinel-aware
connection. Confirm both the write and the read path work, not just
that the API starts cleanly.

**Step 4 — Re-run a representative failure scenario through the app
itself.** Stage 4's primary-failure scenario (Findings A and B, both
already fixed and re-verified at the infrastructure level) is the right
candidate. Generate real load against the app's actual ingest endpoint
while killing the Redis primary, and check:
- Does the app's Lettuce/Jedis client transparently reconnect to the
  newly-promoted primary once Sentinel completes failover, or does it
  need an application restart — a real, specific risk direct
  `redis-cli` testing can't surface, since it doesn't hold a persistent
  client-side connection pool the way the app's Redis client does.
- What does a real request actually experience during Sentinel's
  failover window (already measured at the infrastructure level in
  Stage 4) — does the app-level read/write silently succeed via
  automatic reconnect, error out and require a caller retry, or hang?
- Does anything in the app's own Redis client configuration
  (connection/command timeouts, retry policy) need tuning now that a
  real Sentinel failover mechanism exists underneath it — the same kind
  of re-tuning question `docs/ha-scope.md` already flagged for Postgres's
  HikariCP `connection-timeout`.

**Step 5 — Hold this to the same 3-run bar** applied to Stage 4 and
Stage 5 above.

**Step 6 — Document findings with the same discipline as every other
stage in this doc**: real numbers, explicit confirmed-not-assumed
checks, and honest reporting of anything unexpected.

## What NOT to do in this pass

- **Do not build Redis Cluster (sharding).** That's a capacity mechanism
  (`autoscaling-scope.md` already rules this out for a different reason —
  it changes the caching semantics entirely), not a failover mechanism.
  Sentinel is the correct tool for this scope; cluster mode is a
  different, unrelated feature.
- **Do not start Postgres/Patroni work from this doc.** Per `ha-scope.md`,
  that's its own scope decision, materially more complex (single-primary
  architecture, external consensus-store dependency), and should get its
  own doc once Redis is fully closed out — matching exactly the request
  to proceed in steps.
- **Do not skip Stage 1** because "Kafka's gaps don't necessarily apply
  to Redis." They might not — but the entire pattern across five separate
  Kafka configs was "assumed fine, wasn't," and the cost of checking is a
  few `grep` commands versus the cost of discovering a durability gap
  after Sentinel is already built and tested against a false assumption.

## Resource budget check

Per `ha-scope.md`'s original numbers, current usage was estimated at
~1.94 GiB against the 7.748 GiB Docker Desktop VM ceiling. **Correction
(confirmed live via `docker stats` during Stage 1, 2026-08-28): actual
current usage is ~3.33 GiB**, not ~1.94 GiB — the VM ceiling figure
itself checks out exactly (confirmed via Traefik's uncapped container
reporting the true VM limit), but the earlier usage estimate was measured
at a different, lighter moment (before the 3-broker Kafka cluster's own
footprint, ~1.8 GiB combined, was accounted for under today's testing
conditions). **Real current headroom is ~4.4 GiB, not ~5.8 GiB.** Still
comfortably enough for Sentinel + a replica (3 lightweight Sentinel
processes, ~16–32MB each, plus one additional Redis replica process),
so the "moderate step up from Kafka, not a hard one" conclusion holds —
just don't cite the original ~5.8 GiB figure going forward. Re-confirm
actual measured usage again after Stage 2's topology is stood up, per
the same discipline that caught this correction.

## Deliverables expected from this pass

1. Stage 1 findings (config audit), reported before proceeding
2. Stage 2 topology in `docker-compose.yml`, with logging verified before
   Stage 3 begins
3. A results doc analogous to `docs/testing-strategy-ha-supplement.md` —
   either a new `docs/redis-ha-testing-results.md` or a clearly-dated
   section appended here — capturing what Stages 3–5 actually found,
   including any surprises, using the same "state what was tested, what
   was found, what's confirmed vs. inferred" discipline as the Kafka doc
4. Stage 6 (application-level cutover and validation) — **done**. Found
   the app's Redis client had zero Sentinel awareness, cut it over to
   Sentinel-aware discovery, hit and root-caused the previously-deferred
   `/tmp/sentinel.conf` bug along the way, and re-verified 3/3 clean
   through the app's real endpoints. See Stage 6's results above.
