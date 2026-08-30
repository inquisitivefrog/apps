# grid-meter-app — High-availability scope: PostgreSQL (Patroni)

## Why this doc exists

`docs/ha-scope.md` deferred Postgres explicitly and separately from
Redis, calling out that it's "the hard layer regardless of consensus-store
choice" and instructing that it get its own scope decision rather than
being bundled in as if it were the same size of change as Kafka or
Redis. This is that doc.

**Do not start work from this doc until `docs/redis-ha-scope.md`'s pass
is fully closed out**, per the explicit instruction to proceed in steps.
This doc is written now, in initial form, so it's ready when that time
comes — not as a signal to begin.

**This doc will need real revision once Redis testing is actually
underway and closed out.** Some of what's below is necessarily
provisional: Postgres/Patroni's actual failure modes won't be fully known
until tested the same disciplined way Kafka and (upcoming) Redis were —
config assumed sound, then verified, then very possibly found wanting.
Treat this as a starting scope and test plan, not a finished
specification.

## Why Postgres is structurally the hardest of the three layers

Worth restating plainly, since it changes how cautious this pass needs
to be relative to Kafka and Redis:

- **Kafka**: any broker can become leader for a partition; leadership is
  per-partition and highly dynamic. Multi-writer-capable at the cluster
  level.
- **Redis (via Sentinel)**: single primary, but replica promotion is a
  well-trodden, single-purpose mechanism Sentinel exists specifically to
  do, with no separate coordination layer required.
- **Postgres**: single-primary, and unlike Redis, there is no
  Postgres-native automatic-failover mechanism at all. Patroni is a
  wrapper that requires an **external, separately-operated consensus
  store** (etcd, Consul, or ZooKeeper) to coordinate leader election —
  meaning this pass introduces a new piece of distributed infrastructure
  with its own quorum, its own failure modes, and its own operational
  health to reason about, on top of Postgres itself. A bug or
  misconfiguration in the consensus store can cause a Postgres HA failure
  even if Postgres and Patroni are both configured correctly.

This is not a reason to avoid the work — it's a reason to expect this
pass to take real, dedicated time, likely more than either Kafka or
Redis, and to resist the temptation to treat it as "Redis, but for
Postgres" — the mechanisms are genuinely different in kind, not just in
which technology is being failed over.

## Consensus store choice: Consul, per `ha-scope.md`'s existing decision

`ha-scope.md` already decided this: **Consul**, not etcd, specifically
because it reuses prior Consul-with-Docker experience rather than
requiring etcd learned from scratch, and because Patroni supports it as a
first-class backend, not a fallback. **ZooKeeper is explicitly ruled
out** — reintroducing it here would undo the exact reasoning that moved
Kafka to KRaft mode to avoid a separate ZooKeeper JVM in the first place.
This doc does not reopen that decision; it's inherited as-is.

**Lighter alternatives, already named in `ha-scope.md`, worth
re-confirming are still not preferred before implementation starts**:
`repmgr` (more manual, no external consensus store) and
`pg_auto_failover` (built-in monitor node instead of an external store).
Both remain real options if Patroni+Consul's operational weight turns
out to be more than this pass can absorb — but per `ha-scope.md`,
Patroni+Consul is the chosen path because it reuses real prior
experience. Don't switch away from it without an explicit reason
surfacing during testing.

## Topology

- 1 Postgres primary + at least 1 streaming replica
- Patroni running alongside each Postgres instance, coordinating via
  Consul
- Consul itself needs its own quorum — **3 Consul server agents**,
  applying the exact same "3, not 2" reasoning `ha-scope.md` already
  established for Kafka's controller quorum. Do not deploy 2 Consul
  agents; that reproduces the "replication without safe automatic
  failover" gap `ha-scope.md` already explained is structurally
  insufficient.

**Topology question needing explicit decision, same as the Redis
doc's equivalent question**: 1 replica or 2? A single replica means zero
margin — if it's down when the primary fails, there is nothing to
promote, an outcome worse than "no HA" in one respect (false confidence).
Recommend deciding intended fault tolerance explicitly before building,
not defaulting to 1 by assumption.

## Durability equivalent of `acks=all` / `min-replicas-to-write`: synchronous replication

**This is the same recurring lesson from Kafka and Redis, and it applies
here too — expect it to be undeclared until checked.** Postgres
streaming replication is **asynchronous by default**. A transaction can
be committed and acknowledged to the client before any replica has
received it. If the primary fails immediately after, that committed
transaction can be lost even with a healthy replica present and even
with Patroni correctly promoting it — the replica simply never received
the WAL records for it.

- **`synchronous_standby_names`** (Postgres primary config) is the
  direct structural analog of Kafka's `acks=all` / Redis's
  `min-replicas-to-write`: it forces the primary to wait for at least
  one standby to confirm receipt (or, depending on mode, actual replay)
  before acknowledging a commit to the client.
- **This has a real, honest cost, worth stating up front rather than
  discovering under load**: synchronous replication adds latency to
  every write (bounded by the slowest required standby's round-trip
  time), and if the required number of synchronous standbys becomes
  unavailable, by default **Postgres will block writes entirely** rather
  than silently falling back to async — a very different failure mode
  from Kafka or Redis, and one worth deliberately testing rather than
  assuming.
- **Action before any failover testing begins**: check whether
  `synchronous_standby_names` (and the related `synchronous_commit`
  level) is declared anywhere in this project's Postgres config today.
  Given the pattern found in every single durability-adjacent Kafka
  config and the likely-similar Redis finding, the working assumption
  going in should be that this is **currently undeclared and running
  fully asynchronous**, not that it's already handled.

## The failure mode Kafka and Redis don't really have: split-brain via a non-dead old primary

**This is the sharpest new risk in this doc relative to the other two,
and deserves the most caution.** Kafka's KRaft controller and Redis
Sentinel both have relatively fast, centralized mechanisms to prevent two
nodes from both believing they're the writable leader/primary
simultaneously. Postgres has a materially worse version of this risk:

- If the old primary becomes unreachable to Patroni/Consul (network
  partition, brief hang) but is **not actually dead** — still running,
  still capable of accepting client connections — and Patroni promotes
  the replica because it believes the primary is down, you can end up
  with **two nodes both accepting writes simultaneously**: a true
  split-brain, not just a stale-read risk. This is materially worse than
  the Kafka unclean-election finding, where the wrong node became leader
  but there was still only one leader at a time — here, there can be two
  simultaneous writers producing genuinely irreconcilable data.
- **Fencing (sometimes called STONITH — "shoot the other node in the
  head")** is the standard mitigation: a mechanism that guarantees the
  demoted primary can no longer accept writes, typically by cutting its
  network access, its ability to write to shared storage, or forcibly
  killing the process — not just asking it nicely to step down. Patroni
  supports fencing via configurable callbacks, but it is **not automatic
  out of the box** and needs to be explicitly configured against this
  project's actual environment (Docker Compose networking).
- **Action before failover testing begins**: explicitly decide and
  document what fencing mechanism (if any) will be used for this pass.
  Testing failover *without* a real fencing mechanism in place and
  without deliberately testing the "old primary comes back while still
  briefly able to accept connections" scenario would repeat exactly the
  kind of unverified-durability-guarantee gap the Kafka and (expected)
  Redis investigations both found — except the consequence here is worse
  (concurrent writes, not just a wrong-but-singular leader).

## Testing strategy — staged, mirroring the Redis doc's structure

Same discipline as `docs/redis-ha-scope.md`: **do not proceed to a stage
before the previous one has a clean, verified result.** Given this
layer's added complexity (external consensus store, synchronous
replication's block-on-unavailable behavior, real split-brain risk),
expect this pass to need more stages, not fewer, and expect findings from
Redis's pass to change some of the specifics below before this actually
starts.

### Stage 0 — Confirm Consul quorum works in isolation, before Postgres/Patroni touch it at all

Stand up the 3-agent Consul cluster alone. Kill 1 agent, confirm the
remaining 2 still form a majority and the cluster stays healthy. Kill 2,
confirm it correctly loses quorum and refuses to elect/serve writes
requiring consensus. This isolates Consul's own quorum behavior as a
known-good baseline *before* Patroni's behavior on top of it becomes a
variable too — don't let a Consul-layer problem get misdiagnosed as a
Patroni or Postgres problem later.

### Stage 1 — Config audit

Grep the current Postgres config
(`docker-compose.yml`, `application.yml`'s `spring.datasource.*`, any
`postgresql.conf`) for every durability/replication-relevant setting:

- `synchronous_standby_names` / `synchronous_commit`
- `wal_level` (must be `replica` or higher for streaming replication —
  confirm it isn't left at a lower default)
- `max_wal_senders` / `max_replication_slots`
- HikariCP's existing `connection-timeout` (already 5s, per `ha-scope.md`
  — re-examine once real Patroni failover RTO is measurable, per that
  doc's own still-open note)

**Report findings before moving to Stage 2**, same as the Redis doc.

### Stage 2 — Stand up the full topology, no chaos testing yet

Primary + replica + Patroni + the (already-verified, per Stage 0) Consul
cluster. At rest, with no failures introduced, confirm:

- `patronictl list` shows the expected roles and replication state
- A committed write on the primary is confirmed present on the replica
  via direct query, not inferred from `pg_stat_replication`'s lag numbers
  alone
- **Enable Patroni's and Postgres's verbose logging now**, before any
  failure is introduced — same hard-learned lesson from Kafka's Run 1
  gap, repeated here deliberately because it's cheap insurance and was
  expensive to skip the first time.

### Stage 3 — Single replica failure, expected-safe case

Kill the replica only. Confirm the primary keeps serving, Patroni
correctly reports the degraded-but-functional state, and (if
`synchronous_standby_names` is configured) confirm whether writes now
block as expected — this is the moment to verify that documented
block-on-unavailable behavior actually happens, rather than assuming the
config does what its name implies.

### Stage 4 — Primary failure, the real test

Kill the primary while under real write load, using the same
marker-write methodology as Kafka and Redis (send a distinguishable,
acknowledged write immediately before killing the primary).

**Explicitly check, not assume:**
- Did Patroni correctly promote the replica, and how long did it take
  (real RTO number, not the configured ceiling)?
- Does the promoted primary actually have the last acknowledged write?
- **The split-brain check, this layer's most important one**: once the
  old primary comes back online, does Patroni correctly demote it to a
  replica before it can accept any client writes, or is there a real
  window where both nodes could accept writes? Test this deliberately,
  don't just observe the happy path.
- Run this stage more than once, even if the first run looks clean — the
  Kafka investigation's central lesson (a second, unlabeled failure path
  existed alongside the labeled, expected one) argues strongly for not
  trusting a single clean result here, in the layer with the worst
  failure-mode consequences of the three.

### Stage 5 — Consensus-store degradation while Postgres is otherwise healthy

A scenario Kafka and Redis don't really have: degrade or partition
Consul (not Postgres or Patroni directly) while the primary/replica are
both healthy. Confirm Patroni fails safe — refusing to make a failover
decision it can't safely make, per Stage 0's Consul-quorum baseline —
rather than doing something to Postgres based on stale or
partially-available consensus-store state.

### Stage 6 — Quorum-loss equivalent: kill 2 of 3 Consul agents while Postgres is under real load

Direct analog of Kafka's and Redis's quorum-loss scenarios. Confirm the
system fails safe rather than allowing any ambiguous promotion decision.

## What NOT to do in this pass

- **Do not skip Stage 0.** Testing Patroni's behavior against a
  not-yet-verified Consul cluster risks misattributing a Consul-layer
  problem to Patroni or Postgres.
- **Do not skip the split-brain/fencing check** to save time. This is the
  one failure mode in this entire multi-pass HA effort (Kafka, Redis,
  Postgres) with a genuinely worse consequence than data loss or
  temporary unavailability — concurrent writers producing irreconcilable
  data.
- **Do not reconsider ZooKeeper** as the consensus store "since it's
  already familiar from prior Cassandra/Spark work." `ha-scope.md`
  already ruled this out explicitly; re-litigating it here would undo
  settled reasoning without new information.
- **Do not begin this doc's work before `docs/redis-ha-scope.md` is
  closed out**, per the explicit instruction to proceed in steps.

## Resource budget — needs real re-measurement, not the earlier estimate

`ha-scope.md` estimated a full 3× expansion of all three data-tier layers
(including Postgres+Patroni+Consul) at ~8.2–8.9 GiB total, **exceeding**
the current 7.748 GiB Docker Desktop VM ceiling — meaning this pass, more
than Kafka or Redis, will likely require raising the VM allocation (e.g.
to 12–16 GiB) before Stage 2 can even be attempted. Confirm actual
measured usage after Redis's pass closes out (not before), since Redis's
real footprint will be known by then rather than estimated, and this
doc's own resource math should be revised with that real number before
committing to a Postgres implementation start date.

## Deliverables expected from this pass

1. Stage 0 and Stage 1 findings, reported before proceeding further
2. Explicit topology and fencing-mechanism decisions, documented here
   before Stage 2 begins
3. A results doc analogous to `docs/testing-strategy-ha-supplement.md`,
   capturing what Stages 2–6 actually found — expect this to require at
   least one significant revision pass, the same way the Kafka doc did,
   given this layer's added complexity
