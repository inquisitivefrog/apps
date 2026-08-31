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

- **1 Postgres primary + 2 streaming replicas** (confirmed 2026-08-29,
  same reasoning as Redis's resolved topology question — see below).
- Patroni running alongside each Postgres instance, coordinating via
  Consul — see "Patroni deployment model" below for what this actually
  means concretely (not a separate sidecar container; see that section).
- Consul itself needs its own quorum — **3 Consul server agents**,
  applying the exact same "3, not 2" reasoning `ha-scope.md` already
  established for Kafka's controller quorum. Do not deploy 2 Consul
  agents; that reproduces the "replication without safe automatic
  failover" gap `ha-scope.md` already explained is structurally
  insufficient.

**Topology decision confirmed (2026-08-29): 2 replicas, not 1.** Same
reasoning as Redis's resolved equivalent question: 1 replica gives zero
margin — if it's promoted on a first failure, there is nothing left to
promote from on a second, independent failure landing before the
cluster's back to full strength. 2 replicas leaves one full spare even
immediately after a promotion has already consumed one. This is
consistent with (not merely analogous to) the "3, not 2" quorum
reasoning `ha-scope.md` established for the Consul/controller layer,
applied here to the data-node count instead.

**A decision nested inside the replica count, not automatically resolved
by picking "2"**: with 2 replicas, `synchronous_standby_names` needs an
explicit mode, not just a bare setting. Postgres supports naming a
specific standby, a priority list (first available takes precedence), or
(version-dependent) quorum-based `ANY n (...)` syntax requiring any N of
a named set to acknowledge. **Resolved 2026-08-31: quorum `ANY 1(*)`** —
see "Stage 2 results" below for the full account of how this mode got
silently decided by Patroni's own default before anyone actually chose
(a sharper instance of this project's standing undeclared-default
pattern), and "Open decision" below (now closed) for why quorum was
picked over keeping the default.

## Patroni deployment model

Three sub-decisions bundled inside "how should Patroni be deployed,"
worth pulling apart explicitly rather than assuming one default covers
all of them:

**1. Process topology — Patroni supervises Postgres; it is not a
separate sidecar process the way Sentinel is separate from Redis.**
Patroni is the **entrypoint** of each Postgres container: it calls
`initdb`, and directly starts/stops/restarts/promotes/demotes the local
`postgres` process, managing `postgresql.conf` and `pg_hba.conf` itself.
The deployment unit is **1 container = 1 Patroni process (PID 1)
supervising 1 local Postgres process**, one such container per node.
There is no independent "how many Patroni instances" question — it is
always 1:1 with the Postgres node count (primary + 2 replicas = 3
Patroni-supervised containers, per the topology above).

**2. Image choice — a real decision, not obvious, worth deciding before
Stage 2 starts building.** Two common paths:
- **Zalando's Spilo** (`registry.opensource.zalan.do/acid/spilo`) — the
  most widely-used production Patroni image, but bundles WAL-E/S3 backup
  tooling, a fixed extension set, and Kubernetes-operator-oriented
  assumptions this project doesn't need.
- **A purpose-built image**: `pip install patroni[consul]` on top of the
  official `postgres:18.4` image (matching this project's own pinned
  version). Lighter, and consistent with this project's demonstrated
  pattern of not adopting tools "because they're common" when they carry
  unneeded baggage — the same reasoning that already ruled out Helm for
  the app's own k8s manifests and HAProxy for the edge tier.

**Recommended: the purpose-built image**, for the same minimal-scope
reasons already applied elsewhere in this project. Confirm before Stage
2's `docker-compose.yml` work begins, not decided implicitly by whichever
image the first working example online happens to use.

**3. Node discovery — solved cleanly, worth stating why explicitly.**
This directly closes the IP chicken-and-egg problem discussed earlier in
this project's planning (nodes needing to know peers' addresses before
peers have addresses): each Patroni instance registers itself with
Consul under a shared `scope` (cluster name) at startup. Nodes discover
each other dynamically via Consul — no static IP list needed in advance,
the same pattern this project's Kafka brokers already use via Docker
Compose service-name DNS rather than hardcoded IPs.

**4. Client write-routing — the real open design question, needing
verification before Stage 2, not an assumption.** Only the current
primary accepts writes, and which node that is changes over time after a
failover — something has to route client traffic to whichever node is
*currently* primary. Patroni's REST API exposes `/primary` and `/replica`
endpoints specifically for this.

Given this project's committed "Traefik is the single edge tool" stance
(already used to rule out HAProxy for exactly this class of routing
need), reusing **Traefik's Consul Catalog provider with a TCP router**
is the architecturally consistent choice. **Confirmed via direct
documentation check (2026-08-29)**: Traefik's Consul Catalog provider
does support TCP routing via tags (`traefik.tcp.routers.*`), but its
**default behavior load-balances across every healthy instance of a
Consul service** — it does not automatically pick "the primary" out of a
group of otherwise-identical service instances. Making this work
correctly requires one of:
- Patroni updating its own Consul service tags by role (primary vs.
  replica) as failovers happen, with Traefik's router rule filtering on
  that tag, or
- Relying on Patroni's REST API health check itself (`/primary` returns
  `200` only from the actual primary, `503` from replicas) as the Consul
  health check backing a primary-only service definition, so only the
  current primary ever reports "passing" for that service.

**This is unverified, real risk, not a settled mechanism** — exactly the
kind of assumption ("Consul Catalog plus Traefik will just route
correctly") that has burned this project before (the Traefik/aggregate-
health-check interaction from the Kafka resilience work is the closest
precedent). **Action**: verify Patroni's Consul integration actually
exposes primary/replica role distinctly enough for one of the two
approaches above to work, as part of Stage 1 or an early Stage 2 spike —
before assuming client write-routing "just works" once Consul Catalog is
wired up.

**Status (2026-08-30): still unaddressed, now overdue against this
section's own stated timing.** Stage 2 is complete and this spike still
hasn't been run — Stage 2's own verification went entirely through
`docker compose exec`/`psql` against whichever node Patroni currently
reports as primary, never through the app or Traefik. That substitution
was fine for Stage 2's own checklist (which only needs Patroni's
internal state, not the client path), but it can't carry Stage 4, which
is explicitly about verifying failover from the client's point of view —
Patroni promoting correctly internally says nothing about whether
Traefik ever routes a client to the new primary. **Hard requirement**:
this spike lands before Stage 4 is called done, either in parallel with
Stage 3 or immediately after it — not deferred until Stage 4 testing is
already underway and needs it.

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

## Stage 0 results (2026-08-29): PASS, 3/3 clean — with three real bugs found and fixed on day one

Consul's own quorum behavior (leader-loss recovery, and correctly
refusing writes on real quorum loss) confirmed working — but getting a
trustworthy result required finding and fixing three real bugs first,
all the same lesson *categories* already established during Kafka/Redis
testing, now showing up immediately in brand-new infrastructure rather
than being specific to those two technologies:

1. **Readiness check confused "alive" (gossip layer) with "voting
   member" (raft layer).** Consul's autopilot stabilization delay meant
   one run's effective quorum was smaller than the script believed.
   Fixed by checking for the actual voting-member count, not mere
   liveness. **Verified with certainty, not assumed**: all 3 counted
   clean passes (saved transcripts `20260829-225940`, `20260829-231119`,
   `20260829-231303`) explicitly show "3/3 alive, 3/3 voters, leader=X"
   *after* the fix — the one run that predates the fix already failed
   and was correctly excluded from the tally, not a hidden
   coincidentally-clean pre-fix result.
2. **Missing abort-guard on the setup loop** — when cluster formation
   genuinely raced, the script silently continued into a broken baseline
   instead of failing cleanly. Fixed.
3. **`timeout`/`gtimeout` don't exist in this environment** — a
   write-refusal check was silently a no-op (fails open, not just
   imprecise — a distinct and arguably worse failure mode than a bad
   timing assumption, since it can mask total absence of verification).
   **Fixed by removing the dependency entirely**, not by adding a
   portability guard: Consul fails fast with a real `500` on quorum loss
   (confirmed empirically), so no external timeout wrapper is needed at
   all. Audited the rest of `load-tests/` and `scripts/` for the same
   pattern — no other real instances found (remaining grep hits were
   false positives: Kafka's own `--timeout` producer flag, comments,
   config-parameter names like `failover-timeout`).

**Resource budget re-measured** (not carried forward from the original
estimate): ~3.42 GiB real baseline, ~4.33 GiB headroom, now that Redis's
pass is closed and its real (lighter-than-estimated) footprint is known.
The original "~8.2–8.9 GiB, exceeds the VM ceiling" estimate looks overly
pessimistic in light of this — but **the VM-ceiling concern stays
explicitly open, not resolved**, per this doc's own instruction: confirm
with real `docker stats` numbers again once Stage 2 actually stands up
the full Postgres+Patroni+Consul topology, the same discipline already
applied to Kafka and Redis, before concluding whether raising the VM
allocation is actually necessary.

Also pinned **Consul 1.20.1** in `docs/tech-stack-versions.md`.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

### Stage 0 — Confirm Consul quorum works in isolation, before Postgres/Patroni touch it at all — **done, see results above**

Stand up the 3-agent Consul cluster alone. Kill 1 agent, confirm the
remaining 2 still form a majority and the cluster stays healthy. Kill 2,
confirm it correctly loses quorum and refuses to elect/serve writes
requiring consensus. This isolates Consul's own quorum behavior as a
known-good baseline *before* Patroni's behavior on top of it becomes a
variable too — don't let a Consul-layer problem get misdiagnosed as a
Patroni or Postgres problem later.

## Stage 1 results (2026-08-29): confirmed — 7th instance of the undeclared-durability-default pattern

Live-verified via `psql SHOW`, not just repo grep — same discipline as
every prior stage across this whole HA effort:

| Setting | Live value | Declared anywhere? |
|---|---|---|
| `synchronous_standby_names` | empty/undeclared | No |
| `synchronous_commit` | `on` | No — Postgres default, meaningless with no standby list configured |
| `wal_level` | `replica` | No — already at the minimum required for streaming replication |
| `max_wal_senders` | `10` | No — default already generous enough at this project's scale |
| `max_replication_slots` | `10` | No — same, default is fine |

**The one real gap, exactly matching this doc's prediction**:
`synchronous_standby_names` is empty — Postgres is running fully
asynchronous replication. Direct structural twin of Kafka's undeclared
`acks=1` and Redis's `min-replicas-to-write=0`: a committed transaction
can be acknowledged to the client before any replica has received it,
and if the primary dies immediately after, that write is gone even with
a healthy replica present. **This is the 7th confirmed instance of the
undeclared-durability-default pattern across this project's whole HA
effort** (see `CLAUDE.md`'s standing note on this).

**The other three settings are undeclared too, but correctly NOT treated
as failures** — their defaults already happen to be adequate at this
project's scale. Undeclared-but-adequate and undeclared-and-dangerous are
different findings even though both start from the same grep; conflating
them would have manufactured false findings out of settings that don't
actually need fixing.

**HikariCP's `connection-timeout` (5s) stays as-is per this doc's own
earlier note** — re-examine once real Patroni failover RTO is measurable
in Stage 4, not now.

**Next**: declare `synchronous_standby_names` explicitly, resolving the
still-open mode question from the Topology section above (named standby
vs. priority list vs. quorum `ANY n (...)`) as part of this fix, not
deferred past it.

### Stage 1 — Config audit — **done, see results above**

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

## Stage 2 results (2026-08-30): PASS — topology verified, plus the 8th instance of the undeclared-durability-default pattern, in a new shape

All three of Stage 2's own checklist items verified clean, using the
same "direct query, not inferred from a status field" discipline as
every prior stage:

- `patronictl list` shows the expected topology: `patroni-1` Leader,
  `patroni-2` Sync Standby, `patroni-3` Replica, both replicas streaming
  with 0 lag.
- A committed write on the leader confirmed present on **both**
  replicas via direct `SELECT`, not inferred from `pg_stat_replication`
  lag numbers.
- Verbose logging enabled on all 3 nodes **before** any failure testing
  (the Kafka Run-1 lesson, deliberately repeated here) — Postgres GUCs
  (`log_min_messages=info`, `log_connections`, `log_disconnections`,
  `log_checkpoints`, `log_replication_commands`) pushed live via
  `patronictl edit-config` (propagates through Consul's DCS to all 3
  nodes, no restart needed), and Patroni's own log level set to `DEBUG`
  via a live reload — confirmed actual `DEBUG` lines appearing in
  container logs, not just the config accepted.

No container was restarted or recreated to get any of this — the fresh
3-node cluster's state was never put at risk to verify it.

**A real finding, worth recording precisely as its own instance of the
project's standing pattern**: this doc's own Topology section flagged
`synchronous_standby_names`'s specific mode (named standby vs. priority
list vs. quorum `ANY n (...)`) as "not yet decided" back at Stage 1.
Setting `synchronous_mode: true` in `patroni.yml` — with no further
tuning — silently resolved that open question via Patroni's own default:
live-confirmed as `synchronous_standby_names = "patroni-2"`, single
named-standby mode. **This is the 8th confirmed instance of the
undeclared-durability-default pattern across this project's whole HA
effort, but a distinct sub-shape from the first seven**: instances 1–7
were all "nobody configured it, so a vendor default silently applied."
This one is "this project's *own documented open decision* got silently
closed by someone else's default before anyone actually chose" — a
sharper version of the same underlying lesson, since the gap was already
named in writing and still got skipped rather than merely unnoticed.

**Resolved 2026-08-31: switched to quorum `ANY 1 (*)`.** Named-standby
mode's pinning of synchronous duty to one specific node (`patroni-2`) was
the opposite of this doc's own stated reason for provisioning 2 replicas
in the first place ("2 replicas leaves one full spare," Topology section
above) — under named-standby, the "spare" (`patroni-3`) carried zero
durability weight at all, while `patroni-2` alone was load-bearing.
Applied via `patronictl edit-config -s synchronous_mode=quorum -s
synchronous_node_count=1`, live-confirmed via `SHOW
synchronous_standby_names` → `ANY 1 ("patroni-2","patroni-3")`, and both
replicas now report role `Quorum Standby` in `patronictl list` (previously
asymmetric: one `Sync Standby`, one plain `Replica`). A write immediately
after the switch was re-confirmed to succeed, not just assumed from a
clean config diff. `synchronous_mode_strict` (whether Postgres should
block writes entirely rather than fall back to async once zero
sync-eligible replicas remain) was deliberately left unset/default — a
related but separate decision, not bundled into this one; needs its own
explicit call before Stage 4 has to interpret a double-replica-loss
result.

**Resource budget**: not re-measured this session — no fresh `docker
stats` numbers were captured against the full Postgres+Patroni+Consul
topology now that it's actually up. The VM-ceiling concern named in
Stage 0's results therefore stays open per this doc's own standing
instruction; don't treat it as resolved just because the topology
itself is now running cleanly.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

## Open decision: named-standby vs. quorum `ANY 1 (*)` mode — RESOLVED 2026-08-31

**Decision: quorum `ANY 1 (*)`.** Confirmed with the user (a real
architecture pin, per this project's own check-in-before-structural-
decisions convention) rather than made unilaterally, given Stage 2 had
already shown a vendor default silently closing this exact question once
before. Either replica now satisfies the sync requirement — no single
node is specially load-bearing, and losing either one has the identical
effect on write durability, matching this doc's own stated reason for
provisioning 2 replicas ("2 replicas leaves one full spare") rather than
pinning that spare-ness to one specific named node. See "Stage 2 results"
above for the live verification.

### Stage 2 — Stand up the full topology, no chaos testing yet — **done, see results above**

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

### Stage 3 — Single replica failure, expected-safe case — two sub-tests, kept even under quorum mode

**Originally restructured (2026-08-30) around named-standby's known
asymmetry; that mode is now resolved to quorum `ANY 1 (*)` (see "Open
decision" above), which changes the *reason* for two sub-tests without
eliminating the need for them.** Under quorum mode, killing either
replica *should* have an identical, non-blocking effect — but "the config
says it's symmetric" is exactly the kind of claim this project's whole
testing discipline exists to verify rather than trust (the same "don't
assume symmetric" principle Redis's own Stage 3 already applied, and the
same "verify live, don't infer from what a setting implies" principle
that found the named-standby default in the first place). Collapsing to
one generic "kill a replica" run would mean never actually confirming
that `patroni-2` and `patroni-3` really do behave identically — an
unverified assumption of the same shape this whole doc exists to catch,
just relocated from config to test coverage. Run both sub-tests
explicitly.

- **Sub-test A — kill `patroni-3`.** Expected: no effect on write
  acceptance — 1 of 2 quorum standbys remains, satisfying `ANY 1 (*)`.
- **Sub-test B — kill `patroni-2`.** Expected: **identical** outcome to
  Sub-test A — no effect on write acceptance, for the same reason (1 of 2
  remains). Under the previous named-standby default this would have
  instead been the sub-test that blocks writes; under quorum mode it
  should not. **A real divergence between A and B's outcomes would itself
  be the finding** — evidence that Patroni's quorum-standby selection
  isn't behaving as symmetrically as `ANY 1 (*)` implies — not something
  to explain away as "well, symmetric behavior is what quorum promises."

Both sub-tests: confirm the primary keeps serving throughout, Patroni
correctly reports the degraded-but-functional 1-of-2-quorum-standbys
state, `synchronous_standby_names` live-updates to drop the dead node
from its set (worth checking directly, not assumed), and the killed
replica rejoins and catches back up cleanly once restarted, with
`synchronous_standby_names` returning to naming both nodes again.

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
- **Do not run Stage 3 as a single generic "kill a replica" test**, even
  now that quorum mode is resolved and the two replicas are *expected* to
  behave identically. That expectation is itself unverified until both
  are actually tested independently — see the Stage 3 plan above.

## Resource budget — re-measured (2026-08-29), original estimate revised, still not fully resolved

`ha-scope.md`'s original estimate (full 3× expansion of all three
data-tier layers at ~8.2–8.9 GiB, exceeding the 7.748 GiB Docker Desktop
VM ceiling) has been **revised, not confirmed**, now that Redis's pass
closed out with a real, lighter-than-estimated footprint: current
baseline is ~3.42 GiB, with ~4.33 GiB of headroom under the VM ceiling.
The original "exceeds the ceiling, will need a VM bump" conclusion now
looks overly pessimistic in light of this.

**This is not yet a resolved question.** Per this doc's own standing
discipline, re-confirm with real `docker stats` numbers once Stage 2
actually stands up the full Postgres+Patroni+Consul topology (3 Consul
agents + 3 Patroni-supervised Postgres containers) — Consul's and
Patroni's own real combined footprint could still surprise in either
direction once actually running together, the same way Redis's estimate
turned out meaningfully lighter than `ha-scope.md`'s original guess. Do
not treat the VM-ceiling concern as closed until that Stage 2 number
exists.

## Deliverables expected from this pass

1. Stage 0, Stage 1, and Stage 2 findings, reported before proceeding
   further — **done**, see the results sections above for all three
2. Explicit topology and fencing-mechanism decisions, documented here
   before Stage 2 begins — topology, Patroni deployment model, and the
   synchronous-standby mode (resolved 2026-08-31: quorum `ANY 1 (*)`,
   see "Open decision" above) are done; the fencing mechanism (see "The
   failure mode..." section above) remains undecided and needs resolving
   before Stage 4
3. A results doc analogous to `docs/testing-strategy-ha-supplement.md`,
   capturing what Stages 3–6 actually find — expect this to require at
   least one significant revision pass, the same way the Kafka doc did,
   given this layer's added complexity
