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
a named set to acknowledge. **Status (2026-08-30): resolved as quorum
`ANY 1 (*)`** — see "Sync mode decision" below for the full reasoning,
including that this mode was never explicitly chosen until Patroni's own
default (single named-standby) surfaced the question and forced a real
decision.

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

**Status (2026-08-31): resolved — confirmed working, 2/2 clean runs
across both failover directions.** No longer an open risk; this section
is now a record of what was built and verified, not an outstanding
requirement.

**Implementation, deliberately not the two options sketched above.**
Neither "Patroni updates its own Consul service tags" nor "use Patroni's
`register_service` feature as the health-check backend" was used.
Instead: a `postgres-primary` Consul service was registered manually
(one instance per node, via `load-tests/postgres-traefik-routing-register.sh`),
each backed by an **HTTP health check against that node's own Patroni
`/primary` endpoint** — Consul actively polling each node itself, rather
than depending on Patroni to successfully push or maintain any state.
**Reason for the deviation, found via research before implementation,
not discovered the hard way**: a documented upstream Patroni issue
([#2517](https://github.com/patroni/patroni/issues/2517)) describes
Patroni's own `register_service` mechanism getting its Consul service
tag stuck stale after a Consul communication hiccup — exactly the kind
of "config exists but silently stops being enforced" gap this whole HA
effort keeps finding elsewhere (undeclared durability defaults, the
`%3N` false-positive). Choosing the Consul-polls-Patroni direction
instead of the Patroni-pushes-to-Consul direction sidesteps that failure
mode structurally, not just avoids triggering it by luck. Traefik's
Consul Catalog provider then routes a new `:55432` TCP entrypoint only
to whichever instance currently reports "passing."

**Verified, not assumed, at rest and across two failover directions**:
- **At rest**: a live TCP connection through Traefik's `:55432`
  entrypoint landed on `patroni-1`'s real IP, confirmed as the genuine
  primary via `pg_is_in_recovery() = false`.
- **Run 1 (`patroni-1` → `patroni-2`)**: Consul's health check flipped
  in ~3s; `patronictl` confirmed a real promotion (timeline bumped
  2→3, not a relabeling); a live connection through Traefik
  independently landed on `patroni-2`'s real IP. `patroni-1` restored
  and correctly settled as non-passing (replica), stable with zero
  flapping over a full 60s window.
- **Run 2 (`patroni-2` → `patroni-1`, the reverse direction)** — run
  specifically because this project's own standing discipline ("run
  more than once, even if the first run looks clean," the Kafka
  dual-path lesson) treats a first clean pass as the least trustworthy
  result, not the most: identical clean outcome. Across both runs,
  **exactly one node ever showed "passing" at any polled instant —
  never zero, never two.**

**A genuinely odd finding, reported even though it didn't block
anything**: Traefik's dashboard/introspection API (`/api/version`,
`/api/tcp/routers`) returns a flat `404` on this setup despite
`--api.dashboard=true` being set. Not chased down, since direct TCP
connection behavior was the real evidence and didn't need it — but
worth a note for whoever next wants to *watch* Traefik's routing table
live rather than inferring it from connection behavior; that flag alone
doesn't expose what it's expected to here.

**Not yet committed.** `docker-compose.yml` has the new entrypoint/
provider/port; the 3 Consul services are live-registered in the running
cluster, not in any checked-in config — they would need re-registering
via `load-tests/postgres-traefik-routing-register.sh` after a fresh
Consul bootstrap. Cluster is back to its original healthy 3-node steady
state, 0 lag. Commit this before Stage 4, not during it — Stage 4's own
chaos testing shouldn't be the first thing to exercise a not-yet-durable
setup step.

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

## Fencing decision (resolved 2026-08-31): rely on Patroni's built-in self-demotion, measure the real window in Stage 4

Two real findings narrowed this from an open design question to a
choice between two concrete options:

- **Patroni already has real self-protection, with no extra config.**
  When a node loses its DCS leader lock, Patroni proactively tries to
  stop PostgreSQL locally — but Patroni's own docs are explicit this can
  fail under process crashes, slow shutdown, or resource starvation,
  which is exactly the "briefly unreachable but not actually dead"
  scenario this section worries about. Not a closed gap, but not
  nothing either.
- **Watchdog-based fencing — Patroni's own recommended hardware backstop
  for when self-demotion fails — is not realistically usable in this
  environment.** Confirmed via direct research, not assumed: Docker
  Desktop for Mac runs containers inside a HyperKit/Virtualization-
  framework VM that doesn't support the device passthrough `/dev/watchdog`
  needs — a documented, structural limitation of Docker Desktop on
  macOS, not a missing flag or a config gap
  ([docker/for-mac#5263](https://github.com/docker/for-mac/issues/5263),
  [docker/for-mac#3110](https://github.com/docker/for-mac/issues/3110)).
  This rules out the mechanism Patroni's own documentation treats as the
  standard answer to exactly this gap — it's not available to reach for
  here, at any effort level.

With the documented hardware-backstop path closed off, the real choice
was between (a) trusting Patroni's existing self-demotion behavior and
empirically measuring how wide its failure window actually is, or (b)
building bespoke Docker-socket-based fencing — mounting the Docker
socket into Patroni (or a sidecar) so a newly-promoted node can actively
stop/network-isolate the old primary's container on promotion. Option
(b) closes the gap by construction rather than by measurement, but grants
a data-tier component Docker-daemon-level control — a real blast-radius
increase — and is bespoke to this Compose setup, not a pattern Patroni's
own documentation recommends.

**Decision: option (a).** No new infrastructure. Stage 4 (below) is
deliberately designed to test whether a real writable window exists
during Patroni's self-demotion gap and how wide it is, using the same
verify-then-build discipline as the rest of this HA effort — measure
first, and only build a targeted fix (in the spirit of Redis's own
entrypoint fix for its analogous split-brain window) if measurement
actually shows a real, non-negligible gap. Unmitigated risk is accepted
only conditionally, pending that measurement — not accepted outright by
this decision alone.

**Conditional acceptance confirmed, in two parts.** Stage 4
(2026-08-31, see "Stage 4 results" below) measured the restart-based
case: self-demotion at a consistent ~310–345ms across 3 independent
runs, each killing a different node, zero observed split-brain. But
Stage 4 alone did not test the actual scenario this decision names as
the sharpest risk — a primary that's genuinely never dead, merely
partitioned from Consul. **Stage 5's Sub-scenario A (2026-09-01, see
"Stage 5 results" below) tested exactly that case**: 3/3 clean on
split-brain, but self-demotion took 15–20s there (TTL-driven, not a
fast restart check) with a real ~8–21s availability gap before a new
primary took over. The accepted risk stands as accepted — no split-brain
in either the restart case or the harder live-partition case — but it
should now be understood specifically as an acceptance of that
availability-gap magnitude for the live-partition scenario, not the
sub-second number Stage 4 alone would have suggested. The measurement-
granularity caveat from Stage 4 (no split-brain window observable at
~300ms resolution) still applies to that stage's own number; Stage 5's
15–20s numbers are well above any such resolution concern.

- **Action before failover testing begins**: ~~explicitly decide and
  document what fencing mechanism (if any) will be used for this
  pass~~ — **done, see decision above.** Testing failover *without*
  first confirming what Stage 4 actually measures during the "old
  primary comes back while still briefly able to accept connections"
  scenario would repeat exactly the kind of unverified-durability-
  guarantee gap the Kafka and Redis investigations both found — except
  the consequence here is worse (concurrent writes, not just a
  wrong-but-singular leader). **Done — see "Stage 4 results" below.**

## Testing strategy — staged, mirroring the Redis doc's structure

Same discipline as `docs/redis-ha-scope.md`: **do not proceed to a stage
before the previous one has a clean, verified result.** Given this
layer's added complexity (external consensus store, synchronous
replication's block-on-unavailable behavior, real split-brain risk),
expect this pass to need more stages, not fewer, and expect findings from
Redis's pass to change some of the specifics below before this actually
starts.

**Known gap, found 2026-09-01 — resolved same day.** Every "Full
evidence" pointer below cites `load-tests/vendor-bug-reports/postgres/NOTES.md`,
which had only covered Stage 0 (stopping at "Next: Stage 1 (config
audit)") despite being cited as the evidence source for every stage
since. Flagged rather than left implicit, per this project's own habit
of naming known gaps instead of letting a citation silently go stale.
**Backfilled the same day**: Stages 1–5 are now indexed in `NOTES.md`,
and it's confirmed current as of Stage 5. The "Full evidence" pointers
below can now be trusted to resolve to real data, not just a correctly-
named but empty destination. Keeping it current from Stage 6 onward
remains the standing expectation, not a one-time catch-up.

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

**Consequence, not yet resolved**: named-standby mode pins synchronous
duty to one specific node (`patroni-2`). This has a direct, concrete
effect on how Stage 3 needs to be designed — see the restructured Stage
3 plan and the open decision immediately below. Do not treat this as
settled just because it's live; it was never explicitly chosen, and
quorum `ANY 1 (*)` (any one of the two replicas satisfies the sync
requirement, no fixed node) remains a real, arguably more appropriate
alternative given this project's own stated reason for having 2
replicas in the first place (always a spare, per the Topology section
above).

**Resource budget**: not re-measured this session — no fresh `docker
stats` numbers were captured against the full Postgres+Patroni+Consul
topology now that it's actually up. The VM-ceiling concern named in
Stage 0's results therefore stays open per this doc's own standing
instruction; don't treat it as resolved just because the topology
itself is now running cleanly.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

## Sync mode decision (resolved 2026-08-30): quorum `ANY 1 (*)`

Was an open decision as of Stage 2; now resolved. Two real options were
on the table:

- **Named-standby (`patroni-2`), kept deliberately** — simpler to reason
  about, but makes `patroni-2` specifically load-bearing for write
  durability: if it's the node that dies, Postgres blocks writes (per
  the durability section above); if `patroni-3` dies instead, sync
  durability is unaffected. An asymmetry that would need to be
  deliberate, not stumbled into.
- **Quorum `ANY 1 (*)` — chosen.** Either replica satisfies the sync
  requirement — no single node is specially load-bearing, and losing
  either one has the identical effect on write durability. Matches this
  doc's own stated reason for provisioning 2 replicas in the first place
  ("2 replicas leaves one full spare," Topology section above) more
  directly than pinning that spare-ness to one specific named node.

**Live-verified (2026-08-30)**: cluster confirmed running as Leader +
2 Quorum Standbys, 0 lag on both, following the config change. This
collapses the Stage 3 sub-tests below back into one symmetric test, per
this section's own earlier prediction that choosing quorum mode would
do exactly that.

**Resolved (2026-08-31): `synchronous_mode_strict` left unset (the
current default), decided from real measurement of both settings, not
documentation alone.** This was flagged above as a named-but-untested
gap; it's since been tested directly — both replicas killed
simultaneously while the primary stayed up, under each setting, with
real numbers:

| `synchronous_mode_strict` | Behavior when both replicas die | Write blocking |
|---|---|---|
| unset (current default) | Patroni clears `synchronous_standby_names` to empty, falls back to async | Bounded but variable: 126ms–6.4s across 2 runs, tied to where in Patroni's `loop_wait` (10s) cycle the failure lands — not a fixed number. Once cleared, durability is fully unprotected until a replica returns. |
| `true` | Patroni keeps requiring `ANY 1 (*)` — any standby, but none exist | **Indefinite**, and critically, **not governed by `statement_timeout` at all** — confirmed by a write that hung 82.8s until a replica was manually restored to release it. A client has no clean, session-level way to bound this wait. |

**Decision: leave it unset**, for two reasons beyond the raw numbers:

1. **Strict mode's indefinite hang doesn't interact safely with this
   app's own HikariCP pool.** The 5s `connection-timeout` only bounds
   *acquiring* a connection, not waiting on a commit already in flight
   on one already acquired. Under strict mode, a double-replica outage
   would pile up Tomcat threads indefinitely — a worse operational
   failure than a brief unprotected-writes window, and one the app's
   existing timeout configuration does nothing to prevent.
2. **Matches this project's own established redo-path precedent** (the
   outbox retirement in `resilience-scope.md`): this app's readings are
   synthetic with no downstream consequence, so briefly-unprotected-but-
   available loses less than a real write outage would cost. Same
   reasoning, applied to a different durability knob.

This closes the gap named below in "What NOT to do" — the "both
replicas down while the primary stays up" scenario is no longer a named,
untested hole; it's been directly measured, and a decision made from
that measurement rather than from Postgres's documentation alone.

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

## Stage 3 results (2026-08-31): Sub-test A (kill `patroni-3`) — PASS, exactly as predicted under quorum mode

- **Primary kept serving throughout, with no blocking**: all 5 writes
  during the outage succeeded, 90–100ms each — real measured numbers,
  not inferred. (An earlier run's "5/5 succeeded" was bogus; see the
  script bug below.)
- **`synchronous_standby_names` correctly dropped `patroni-3`** after
  ~7s (bounded by Patroni's `loop_wait: 10`), degrading to `ANY 1
  ("patroni-2")` — confirmed live, not assumed.
- **`patronictl list` correctly reported the degraded state**:
  `patroni-3` shown demoted to plain Replica with `nosync: true`.
- **`patroni-3` rejoined cleanly on restart** — streaming, caught up
  (0 lag) within the polling window, `synchronous_standby_names`
  returned to naming both nodes again.
- **All 6 marker rows** (1 baseline + 5 during-outage) confirmed present
  on both the primary and the rejoined `patroni-3` via direct query, not
  inferred from lag.

**A real bug found and fixed along the way, same shape as Stage 0's
`timeout`/`gtimeout` finding**: the marker-write script's first attempt
used `date +%s%3N` for write timestamps, which silently misparses on
macOS's BSD `date` (the `%3N` width modifier is GNU-only; only bare
`%N` works here). The resulting bash arithmetic error silently
truncated the write loop after its first iteration — while the script's
own summary line still printed "5/5 succeeded." Caught and fixed before
this result was trusted; re-run produced the real, verified numbers
above. The identical `%3N` idiom also exists, unfixed, in
`load-tests/kafka-acks-gap-repro.sh` (a secondary timing print there,
not the separately-reported 3.7s Kafka RTO number, which uses a
different mechanism and is unaffected) — flagged as a follow-up, not
yet fixed. Promoted to a standing lesson in `docs/cross-project-lessons.md`
("Shell scripting and OS-tooling pitfalls") alongside the `timeout`/
`gtimeout` finding, since this is the second independent instance of the
same underlying mistake (assuming GNU coreutils behavior on macOS's BSD
userland) producing the same dangerous shape (silent wrong behavior,
reported as success).

**Not yet run: the symmetric second half (kill `patroni-2` instead).**
The plan below only requires testing one replica under quorum mode, on
the theory that both are interchangeable — but that's exactly the kind
of assumption this project's own discipline says to verify rather than
trust, the same reasoning Redis's own Stage 3 applied by testing both
replicas independently rather than assuming symmetry. Recommended before
this stage is called fully closed, not required to unblock Stage 4.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

## Stage 3 results, continued (2026-08-31): Sub-test B (kill `patroni-2`) — PASS, symmetric with Sub-test A

- **Primary kept serving throughout**: all 5 writes during the outage
  succeeded, ~91–94ms each — statistically indistinguishable from
  Sub-test A's 90–100ms.
- **`synchronous_standby_names` dropped `patroni-2` even faster this
  time** (~1s vs. Sub-test A's ~7s — both well within the `loop_wait:
  10` bound, just different points in Patroni's poll cycle), degrading
  to `ANY 1 ("patroni-3")`.
- **`patronictl list` correctly showed `patroni-2` demoted** to plain
  Replica with `nosync: true`, while `patroni-3` picked up sole Quorum
  Standby duty.
- **`patroni-2` rejoined cleanly**, caught up, and
  `synchronous_standby_names` returned to naming both nodes again.
- **All 6 marker rows confirmed present** on both the primary and the
  rejoined `patroni-2` via direct query.

**This is the actual finding Stage 3 was designed to produce, not just a
second passing run**: killing `patroni-2` and killing `patroni-3`
produced identical outcomes (no blocking, clean degrade-and-recover) —
real, empirical evidence that quorum mode behaves symmetrically, not an
assumption inherited from the config's name. Per this doc's own framing,
had the two sub-tests diverged, *that* divergence would have been the
real finding; they didn't, which is itself the confirmation.

**Stage 3: done, both sub-tests clean.** The fencing approach (see
"Fencing decision" above) and the Traefik/Consul Catalog client-write-
routing spike (see §4 of "Patroni deployment model" above) are both now
resolved. **Every precondition named for Stage 4 is satisfied — clear
to proceed.** Remaining loose end: commit the routing spike's
`docker-compose.yml` changes and registration script before Stage 4
starts, per that section's own note, so Stage 4's chaos testing isn't
also the first exercise of a not-yet-durable setup step.

### Stage 3 — Single replica failure, expected-safe case — collapsed back to one test (2026-08-30), per quorum mode being chosen; **both sub-tests done, see results above**

**Briefly restructured into two sub-tests while named-standby mode was
still live (see the sync-mode decision above); collapsed back to one
now that quorum `ANY 1 (*)` is confirmed in effect.** Under quorum mode,
killing either replica has the identical expected consequence — there's
no longer a distinguished node for the test to treat specially.

Kill either replica — **both done, see results above**: `patroni-3`
first, then `patroni-2`, confirmed symmetric. Confirm:

- The primary keeps serving writes throughout, with **no blocking** —
  the remaining replica alone satisfies `ANY 1`, so this is the
  moment to verify that symmetric, non-blocking behavior actually holds
  rather than assuming quorum mode does what its name implies.
- Patroni correctly reports the degraded-but-functional state (one
  replica down, quorum still met) while the failure is live.
- The killed replica rejoins and catches back up cleanly once
  restarted, and `patronictl list` returns to the full 3-node healthy
  state.

**Not covered by any of Stages 3–6 as staged**: both replicas down
simultaneously while the primary stays up — the scenario
`synchronous_mode_strict` governs. This was tested directly, but as its
own targeted measurement rather than as a numbered stage in this
sequence — see "Sync mode decision" above for the real numbers under
both settings and the resulting decision (leave `synchronous_mode_strict`
unset). No longer an untested gap, just not folded into the Stage 3–6
numbering.

## Stage 4 results (2026-08-31): PASS, 3/3 clean — the fencing decision's conditional acceptance is now confirmed, with an honest caveat on measurement granularity

Ran against real write load using the same marker-write methodology as
Kafka and Redis, with the client-observed failover path (Traefik +
Consul Catalog, per §4 of "Patroni deployment model") verified as part
of every run, not just Patroni's internal state. Per this project's
3-iteration bar for a correctness finding, and per this stage's own
explicit instruction not to trust a first clean run, 3 runs were
required and run — and each run happened to kill a different node, so
this ended up more comprehensive than the minimum bar: every node has
now been tested as "the primary that dies," not just one repeated case.

| Run | Old primary | New primary | RTO | Write survived | Client routing followed | Old-primary self-demotion | Split-brain |
|---|---|---|---|---|---|---|---|
| 1 | `patroni-3` | `patroni-1` | 1676ms | Yes | Yes (~11s) | 310ms | No |
| 2 | `patroni-1` | `patroni-2` | 1793ms | Yes | Yes (~10s) | 345ms | No |
| 3 | `patroni-2` | `patroni-3` | 1972ms | Yes | Yes (~15s) | 315ms | No |

**This directly answers the fencing decision's conditional risk
acceptance** (see "Fencing decision" above): Patroni's self-demotion
window measured at a consistent, narrow ~310–345ms across all 3 runs —
in every case, by the time the restarted node was even reachable for a
query at all, it already correctly reported itself as a replica; no
write ever succeeded while it still claimed to be primary. **This
measurement supports the earlier decision** (rely on self-demotion, no
bespoke Docker-socket-based fencing) rather than calling for the
targeted fix that was left as the fallback option.

**An honest caveat, stated precisely rather than claiming a
millisecond-exact zero**: the measurement probe polls roughly every
~300ms (each iteration is two sequential `docker compose exec` calls).
This confirms no *observable* split-brain window at that granularity —
it does not rule out something narrower than ~150ms that a coarser
check could miss between polls. The conditional acceptance is closed
at the resolution this project's tooling can actually measure, not
at an absolute guarantee of zero.

**Client-observed failover confirmed real, not inferred**: the
Traefik + Consul Catalog routing path (verified as a standalone spike
earlier) correctly followed every failover across all 3 runs — the
~10–15s delay each time is Consul's health-check interval plus
Traefik's provider-propagation delay, not a bug, and matches the
timing already established when that spike was first verified.

**Two real script bugs found and fixed along the way**: a CIDR-notation
string-comparison bug, and a `set -e`/command-substitution crash. The
second was initially flagged as a possible fourth standing pattern
(alongside undeclared-defaults, fixed-sleeps, and GNU-vs-BSD), but
tracing it precisely against this morning's disk-headroom-guard crash
showed the two are related but not the same mechanism: this morning's
was a genuinely platform-specific pipeline failure (`df -g` failing on
Linux, fine on macOS) — the same *shape* of lesson as GNU-vs-BSD.
Today's Stage 4 crash was a plain, platform-agnostic unguarded command
substitution (an adjacent write-check left unguarded while its sibling
read-check on the line above it was correctly guarded) — an asymmetric
oversight, not a fact about differing tool behavior. **Conclusion: does
not earn a fourth named pattern.** Recorded instead as a line in
`docs/cross-project-lessons.md`'s existing "Build tooling" section — a
general `set -e` discipline note (every command substitution needs its
own explicit guard; correctly guarding one line doesn't guarantee its
neighbor got the same treatment), not a new standing category.

**Stage 4: done.** Cluster restored to full health (3/3 nodes correct
roles) after the third run.

### Stage 4 — Primary failure, the real test — **done, see results above**

Kill the primary while under real write load, using the same
marker-write methodology as Kafka and Redis (send a distinguishable,
acknowledged write immediately before killing the primary).

**Explicitly check, not assume:**
- Did Patroni correctly promote the replica, and how long did it take
  (real RTO number, not the configured ceiling)?
- Does the promoted primary actually have the last acknowledged write?
- **The split-brain check, this layer's most important one — and now
  the specific measurement the fencing decision above depends on.**
  Once the old primary comes back online, does Patroni's self-demotion
  correctly stop it before it can accept any client writes, or is there
  a real window where both nodes could accept writes? If a window
  exists, measure it precisely (duration, and whether a write actually
  lands during it) — this number is what decides whether the accepted
  risk from the fencing decision above stays accepted or whether a
  targeted fix (e.g. a restart-time role check, in the spirit of
  Redis's own entrypoint fix for its analogous split-brain window)
  becomes necessary. Don't just observe the happy path.
- Run this stage more than once, even if the first run looks clean — the
  Kafka investigation's central lesson (a second, unlabeled failure path
  existed alongside the labeled, expected one) argues strongly for not
  trusting a single clean result here, in the layer with the worst
  failure-mode consequences of the three. This is doubly true here since
  a single clean run cannot, on its own, close out the fencing decision's
  conditional acceptance.

## Stage 5 results (2026-09-01): both sub-scenarios PASS on split-brain — but Sub-scenario A found a real, material availability gap Stage 4 could not have found

Reported separately per this section's own instruction — a clean result
in one sub-scenario says nothing about the other.

### Sub-scenario A (partition the primary from Consul, Postgres itself never touched) — 3/3 clean on split-brain, but a real ~8–21s availability gap found

| Run | Partitioned primary | Self-demoted at | New leader elected at | Gap | Split-brain |
|---|---|---|---|---|---|
| 1 | `patroni-2` | 15423ms | 36511ms | +21088ms | No |
| 2 | `patroni-3` | 19362ms | 28659ms | +9297ms | No |
| 3 | `patroni-1` | 19534ms | 27544ms | +8010ms | No |

**Zero split-brain across all 3 runs** — the old primary always
self-demoted before a new leader took over; the ordering the split-brain
check cared about held every time. But the more important finding is
the **magnitude**, exactly as this section's own reframing predicted
before the test ran: self-demotion here took **15–20 seconds** — driven
by Patroni's retry/timeout logic actually failing to confirm its lock,
not a fast local restart check — a materially larger number than Stage
4's ~310–345ms. Between the old primary stepping down and a new one
being elected, there's a real **~8–21 second window where nobody accepts
writes at all**. This is not split-brain (the opposite failure — an
availability gap, not a data-safety one), but it's a real, previously
unmeasured cost of relying on TTL-based self-demotion for the
genuinely-alive-but-partitioned case, distinct from and larger than
anything Stage 4 could have surfaced.

**A real methodology bug found and fixed along the way, worth flagging
prominently**: the first attempt used only an `/etc/hosts` blackhole and
left the primary alone for 60s with zero reaction — which looked like,
but was not, a complete absence of self-protection. Root cause:
Patroni's Consul client was reusing an already-open, pooled connection
that the blackhole never touched — only *new* connection attempts were
blocked, and Patroni was confirmed (via direct log inspection) to still
be successfully renewing its Consul session the entire time. Fixed by
also restarting the target Consul agent immediately after applying the
blackhole, forcing the existing connection closed. **This is exactly
the "verify, don't trust a surprising result" discipline this whole
project has been built around** — a first result suggesting a serious
safety gap turned out to be a test artifact, not a real finding, and was
caught before being reported as one. Worth flagging as a portable
chaos-testing lesson beyond this project: a DNS/hosts-file-level fault
injection only blocks *new* connections, not ones a target process
already holds open — if the thing under test might reuse a long-lived
connection, the injection needs to force that connection closed too, not
just block future ones.

### Sub-scenario B (kill a non-leader, non-primary-paired Consul agent) — confirmed non-event, as predicted

Primary (`patroni-3`) completely unaffected throughout — kept accepting
writes, `pg_is_in_recovery()` never changed. **One minor, real nuance,
worth recording precisely rather than glossing over**: the replica
paired with the killed agent (`patroni-1`) temporarily disappeared from
`patronictl list`'s Consul-derived view. Confirmed via direct query that
its actual replication state was never affected — this was a Consul-
*reporting* gap for that specific node, not a functional one. Visibility
restored within 3s of the agent coming back. This is the same underlying
caution as Stage 0's "alive vs. voting member" confusion: a monitoring
signal derived from Consul is not the same thing as the state of the
component Consul is reporting on, and the two can diverge without the
underlying thing actually being wrong.

### What this means for the fencing decision

**The conditional acceptance from "Fencing decision" above holds — no
split-brain was found even in the harder, genuinely-alive-but-
partitioned case this stage was specifically designed to test.** But
the acceptance should now be understood precisely: it's an acceptance of
a **~8–21 second availability gap** during this specific failure mode,
not merely "unmitigated risk" in the abstract. If that gap's length ever
becomes operationally unacceptable, the lever to pull is tuning
`ttl`/`loop_wait`/`retry_timeout` down — not building the bespoke Docker-
socket fencing that was declined — though shortening those values
trades against a real risk of false-positive failovers under normal
transient network jitter, and hasn't been tested here. Not a decision to
make now; recorded so a future session doesn't have to rediscover the
tradeoff from scratch.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

### Stage 5 — Consensus-store degradation while Postgres is otherwise healthy — expanded (2026-09-01) into two explicit sub-scenarios; **both sub-scenarios done, see results above**

**Reframing before this stage runs: this is likely the real test of this
doc's named worst case, not a lesser follow-on to Stage 4.** Stage 4
tested a node that was genuinely killed and restarted — its self-
demotion measurement (~310–345ms, see "Stage 4 results" above) answers
"how fast does a node that just came back from being dead figure out
it's a replica." It does **not** answer the scenario "The failure
mode..." section above actually names as the sharpest risk: a primary
that becomes unreachable to Consul but is **never dead at all** — still
running, still serving client connections the entire time. That
scenario's safety net is Patroni's leader-lock **TTL expiry**, not the
fast local self-demotion Stage 4 measured, and the exposure window is
however long `ttl` is actually configured for — Patroni's own shipped
default is 30 seconds, roughly two orders of magnitude wider than what
Stage 4 found. Treat this stage's finding as potentially requiring a
revisit of the "Fencing decision" conditional acceptance above, not as
a foregone confirmation of it.

**Prerequisite, before designing the actual test**: check
`ttl`/`loop_wait`/`retry_timeout` live (`patronictl show-config` or
equivalent), not by grep. Given this project's 8-for-8 record on
undeclared durability defaults, the working assumption going in should
be that these are still at Patroni's shipped defaults until verified —
and the actual `ttl` value is the number that determines how dangerous
this stage's finding will be, so it needs to be known before the test
is designed, not discovered as a side effect of running it.

**Two genuinely different scenarios bundled under "degrade or
partition" — don't conflate them, run and report both separately.**

#### Sub-scenario A (the one that matters most): partition the current primary from Consul specifically, while Postgres itself keeps running uninterrupted

Sever connectivity between the primary's own Patroni process and Consul
specifically — a surgical block (e.g. blocking Consul's port from
inside the primary's container, or a targeted network-level disconnect
scoped to just the Consul-facing path) rather than killing or restarting
anything. Postgres itself must keep running and keep accepting client
connections for the entire duration — that's the point of this
sub-scenario, and if the mechanism used ends up stopping Postgres too,
it isn't testing this case.

**Explicitly check, not assume:**
- Does the primary actually keep believing it's primary (and keep
  accepting writes) for the live duration of the partition, up to
  roughly the confirmed `ttl` value — or does something demote it
  sooner than that number would predict?
- Does the primary correctly self-demote once its lock renewal fails
  and TTL expires, measured precisely (not inferred from a status
  message) — and does this happen without a manual restart, purely from
  the TTL mechanism itself?
- **The real split-brain check**: does the rest of the cluster (which
  still has healthy Consul quorum) promote a replica *before* the
  partitioned primary's TTL expires? If so, there is a real window,
  potentially seconds wide rather than Stage 4's sub-second window,
  where two nodes could both believe they're primary and both accept
  writes. Measure this window's actual duration if it exists — don't
  just note that it exists or doesn't.
- Does the client-facing routing path (Traefik + Consul Catalog)
  correctly continue routing to whichever node Consul currently reports
  as passing throughout, the same verification standard applied in
  Stage 4?
- **Run at least 3 times**, matching this project's correctness-finding
  bar — arguably more warranted here than in Stage 4, given this
  sub-scenario is the one most likely to actually move the fencing
  decision's risk assessment rather than confirm it.

#### Sub-scenario B (a lighter baseline, not a substitute for A): kill one non-leader Consul agent, cluster keeps quorum

Kill 1 of the 3 Consul agents (not the current Consul raft leader) while
Postgres primary/replicas are both healthy and untouched. Consul's own
quorum survival here was already established in Stage 0 — this
sub-scenario isn't re-testing that. Its only purpose is confirming
Patroni doesn't notice or react at all.

**Explicitly check, not assume:**
- Postgres primary/replica roles are completely unaffected throughout —
  no promotion attempt, no self-demotion, no logged concern from
  Patroni.
- Any brief Consul client reconnection Patroni performs (if the agent
  it happened to be talking to was the one killed) resolves
  transparently, with no observable effect on Postgres.
- This sub-scenario should be close to a non-event. If it isn't — if
  Patroni reacts in any way — that's a more surprising and higher-
  priority finding than a clean pass, since it would mean sub-quorum
  Consul agent loss (a routine, expected event) has a real effect on
  the data tier, which nothing in this doc's design intends.

**Do not report these two sub-scenarios as a single "Stage 5: PASS."**
Given how different their risk profiles are, report each with its own
verdict — a clean Sub-scenario B result says nothing about Sub-scenario
A, and only Sub-scenario A's result should inform whether the fencing
decision's conditional acceptance needs revisiting.

## Stage 6 results (2026-09-01): PASS, 3/3 clean, one run per possible surviving-agent combination — the system genuinely fails safe

Ran using direct `pg_is_in_recovery()` polling on each of the 3 nodes
independently, per this stage's own methodology note above — never
`patronictl` or any other Consul-derived view, since `consistent` reads
fail cluster-wide once quorum is lost. Each run polled continuously
across a full 60-second window, not spot-checked at two points, per the
requirement to confirm the outage genuinely persists rather than just
starting and ending as expected.

| Run | Surviving agent | Primary | Self-demoted at | Unsafe promotion |
|---|---|---|---|---|
| 1 | `consul-3` | `patroni-3` | 12326ms | No |
| 2 | `consul-1` | `patroni-3` | ~15000ms | No |
| 3 | `consul-2` | `patroni-3` | ~3000ms | No |

**The critical safety property held perfectly across all 3 runs**:
Consul correctly refused the `consistent` operation immediately (real
`500`s each time), and neither non-leader node ever reported itself as
primary at any point across any full 60-second window. This confirms
the expected outcome stated before this stage ran: the system becomes
**unavailable for writes, never ambiguous about who's primary** — an
unbounded outage is the correct safe behavior here, not a defect, and
no run showed anything resembling a bounded recovery (which would have
been the alarming result, not the reassuring one).

**A real, interesting nuance found, refining Stage 5's ~15–20s
self-demotion estimate rather than contradicting it**: self-demotion
speed depends on whether the primary's own paired Consul agent is among
the two killed. Run 1 and Run 2 (the primary's own agent survived but
couldn't reach quorum) took 12.3s and ~15s — in line with Stage 5's
range. Run 3 (the primary's own agent, `consul-3`, was killed directly)
took only ~3s. The mechanism is precise: an immediate connection
failure to a dead agent is detected faster than a live-but-quorumless
agent that still accepts and processes the request before failing at
the raft layer. Worth remembering as a general shape for any future
Consul-backed HA testing in this project: "the agent is gone" and "the
agent is alive but the cluster it's part of has no quorum" are
different failure signals with different detection latencies, not
interchangeable versions of "Consul is down."

**Two real bugs found while building this stage's test, both reported
plainly rather than smoothed over:**

1. **A self-inflicted mistake, not a Patroni/Consul finding**: piping a
   live, state-mutating script's output through `head -30` triggered a
   `SIGPIPE` that killed the script before its own cleanup logic ran,
   leaving 2 Consul agents stopped. Caught and restored immediately.
   Worth a standing personal/team lesson beyond this project: never
   truncate the output of a script that mutates real infrastructure
   state via a pipe like `| head` — if the reader side closes early, the
   writer can be killed mid-mutation before any trap/cleanup handler
   fires, regardless of how carefully that handler was written.
2. **An unexplained loop bug, honestly reported as mitigated rather than
   root-caused**: an early version of the monitoring loop's condition
   used `date +%s%N`-based nanosecond arithmetic and exited after only
   ~2.5s instead of running the full 60s — isolated repro attempts of
   the identical pattern didn't reproduce it, so the actual mechanism
   remains unknown. Rather than keep chasing an unreproduced timing
   anomaly against live infrastructure, the loop was redesigned around
   bash's `SECONDS` builtin (already proven reliable elsewhere in this
   project's scripts) for loop control, decoupling correctness from
   millisecond arithmetic entirely. This trades sub-second timing
   precision for robustness — an honest, stated tradeoff, not a claimed
   fix for a bug whose cause was never actually found.

Full evidence: `load-tests/vendor-bug-reports/postgres/NOTES.md`.

**All 6 stages of this doc's plan are now complete.**

### Stage 6 — Quorum-loss equivalent: kill 2 of 3 Consul agents while Postgres is under real load — expanded (2026-09-01); **done, see results above**

Direct analog of Kafka's and Redis's quorum-loss scenarios: confirm the
system fails safe rather than allowing any ambiguous promotion decision.
But this stage has a methodology subtlety the earlier two didn't, worth
resolving before building the test, not discovered mid-run.

**Methodology note, found before running rather than the hard way**:
Patroni's own Consul reads use `consistent=1`, which Consul refuses
outright without a raft quorum. That means `patronictl list` — the tool
every earlier stage leaned on for a quick status check — will likely
**fail outright on every node** once quorum is lost, not just report
stale data. Consul-derived state is exactly the thing this failure mode
breaks, so it can't be the source of truth for this stage's safety
check. **Poll each node's own `pg_is_in_recovery()` directly via `psql`
instead** — the same discipline Stage 0 applied to "alive" vs. "voting
member" and Stage 5 applied to Consul-reported visibility vs. actual
replication state, now showing up a third time in this same
investigation.

**A real prerequisite finding, found while verifying the note above —
the 9th confirmed instance of this project's undeclared-durability/
quorum-default pattern, and a load-bearing one for the exact property
this stage exists to check.** `PATRONI_CONSUL_CONSISTENCY` (Patroni's
own config key, accepting `default`, `consistent`, or `stale`) governs
which of these two read modes Patroni actually uses against Consul —
and it was **completely undeclared anywhere in this project's config**,
not in `patroni.yml`, not as an environment variable, confirmed by
direct check rather than assumed. This matters specifically because
Stage 6's whole fail-safe premise depends on Patroni reading consistent
(quorum-backed) state rather than a stale read from a possibly-lagging
individual agent — a stale read during quorum loss could return outdated
cluster state and risk exactly the unsafe promotion decision this stage
is designed to catch. Live behavior was already confirmed via Stage 5's
log inspection to be using `consistent=1` reads — so the *behavior*
being relied on was already correct, but only as an undeclared default,
the same shape as all 8 prior instances (see `CLAUDE.md`'s standing
note). **Decision: declare `PATRONI_CONSUL_CONSISTENCY=consistent`
explicitly in `docker-compose.yml`**, matching the project's standing
"declare it, don't rely on an implicit default" principle (same
treatment as Kafka's `unclean.leader.election.enable=false`) — this
locks in the behavior already verified safe rather than leaving it
exposed to silently changing on a future Patroni upgrade or a config
refactor that happens not to preserve an implicit default. Confirmed
via Patroni's own documentation
([`ENVIRONMENT.rst`](https://patroni.readthedocs.io/en/latest/ENVIRONMENT.html)),
not assumed from memory.

**Applied and re-verified (2026-09-01), not just declared.** Rolling
recreate of all 3 nodes with `PATRONI_CONSUL_CONSISTENCY=consistent`
now explicit, confirming the declaration didn't silently change
behavior from what was already measured — including a real, clean
failover when the leader's own container was the one recreated. This is
the same "verify the fix didn't introduce its own regression" discipline
already applied everywhere else in this pass (e.g. Redis's Finding A
re-verification after its entrypoint fix). Committed in two focused
commits (`5f25c4c`, `e6e61cd`), not yet pushed. **This closes the
prerequisite work — Stage 6's actual chaos test (kill 2 of 3 Consul
agents under real load) is still pending, not yet run.**

**The correct expected outcome here is an unbounded outage, not a
bounded gap — say so explicitly before running, so a long stall isn't
misread as a hang or a bug.** Stage 5 cut off only the primary from
Consul; the rest of the cluster still had quorum and could elect a
replacement once the old primary's TTL expired, producing a bounded
~8–21s gap. Here, killing 2 of 3 Consul agents removes quorum for
*every* Patroni node, including the current primary — the same TTL
mechanism Stage 5 measured should still fire on the primary (expect a
similar ~15–20s self-demotion), but **nothing can elect a replacement,
because nothing has quorum to elect anyone.** The safe outcome is
therefore an outage lasting until Consul quorum itself is restored, not
a bounded number. A test that found a *bounded* recovery here would
actually be the more alarming result — it would mean something got
promoted without real quorum, which is the exact split-brain risk
Stage 0 already proved Consul refuses to allow.

**Explicitly check, not assume:**
- Does the current primary self-demote once its own Consul session
  fails to renew — checked via direct `pg_is_in_recovery()` polling on
  that node specifically, not via `patronictl` or any other
  Consul-derived view? Expect a magnitude similar to Stage 5's
  ~15–20s, though confirm rather than assume it transfers unchanged.
- **The actual safety check**: while quorum stays lost, does `psql`
  against every node directly ever show more than one node reporting
  `pg_is_in_recovery() = false` at the same time? This is the real
  pass/fail condition — not whether a new primary eventually appears
  (it shouldn't, until quorum returns).
- Does the outage genuinely persist for as long as quorum stays lost,
  with no promotion attempt succeeding at any point during that window —
  confirmed by continuing to poll well past where Stage 5's ~15–20s
  self-demotion number would predict any activity, not just checking
  once early and once late?
- **Traefik's client-routing path has the same Consul dependency
  identified above for `patronictl` — treat its behavior as a separate,
  clearly-labeled observation, not part of the Postgres/Patroni safety
  verdict.** The routing spike verified in Stages 4–5 works by querying
  Consul Catalog for whichever node is passing; with no Consul quorum,
  that query path is likely degraded or failing closed too (e.g.
  connection refused rather than stale-but-served traffic). If this
  happens, it's expected and says nothing about whether Postgres itself
  behaved safely — don't let a Traefik-side failure get folded into or
  confused with the actual Postgres/Patroni finding.
- **Recovery check**: once 1 of the 2 killed agents is restored (back
  to 2 of 3, quorum regained), confirm exactly one node is elected and
  the cluster converges cleanly — same standard already applied to
  Kafka's and Redis's own quorum-loss recovery checks.
- **Run at least 3 times**, matching the bar already applied to Stage
  4's fencing measurement and Stage 5's split-brain check — this stage
  is testing the same "fails safe vs. fails unsafe" category as both.

## What NOT to do in this pass

- **Do not skip Stage 0.** Testing Patroni's behavior against a
  not-yet-verified Consul cluster risks misattributing a Consul-layer
  problem to Patroni or Postgres.
- ~~Do not skip Stage 4's split-brain measurement~~ **— done, see "Stage
  4 results" above**: 3/3 clean runs, ~310–345ms self-demotion, zero
  observed split-brain, with the measurement-granularity caveat stated
  explicitly rather than overclaimed. The conditional, evidence-gated
  acceptance from "Fencing decision" above is now backed by the evidence
  it was conditioned on, not left as an assumption. This remains the one
  failure mode in this entire multi-pass HA effort (Kafka, Redis,
  Postgres) with a genuinely worse consequence than data loss or
  temporary unavailability — concurrent writers producing irreconcilable
  data — which is exactly why it wasn't skipped.
- ~~Do not treat Stage 4's clean split-brain result as already covering
  Stage 5's Sub-scenario A.~~ **Confirmed correct to have flagged this,
  not just a precaution**: the two stages found genuinely different
  numbers — Stage 4's ~310–345ms restart-based self-demotion vs. Stage
  5's 15–20s TTL-based self-demotion with a real ~8–21s availability
  gap. Both clean on split-brain, but at very different magnitudes — a
  reader relying on Stage 4 alone would have materially understated the
  real cost of this failure mode. See "Stage 5 results" above.
- **Do not reconsider ZooKeeper** as the consensus store "since it's
  already familiar from prior Cassandra/Spark work." `ha-scope.md`
  already ruled this out explicitly; re-litigating it here would undo
  settled reasoning without new information.
- **Do not begin this doc's work before `docs/redis-ha-scope.md` is
  closed out**, per the explicit instruction to proceed in steps.
- ~~Do not let "both replicas down while the primary stays up" go
  untested by accident.~~ **Resolved (2026-08-31)**: tested directly
  under both `synchronous_mode_strict` settings, with real measured
  numbers for each — see "Sync mode decision" above for the results and
  the resulting decision (leave it unset). Retained here, struck
  through, as the record that this bullet did its job rather than
  quietly dropped once satisfied.
- ~~Do not use `patronictl` (or any other Consul-derived view) as the
  safety check for Stage 6.~~ **Followed — see "Stage 6 results" above**:
  all 3 runs used direct `pg_is_in_recovery()` polling, never
  `patronictl`, per this bullet's own reasoning.
- ~~Do not expect Stage 6's outage to be bounded, and do not treat a
  long stall as a bug.~~ **Confirmed correct — see "Stage 6 results"
  above**: all 3 runs showed a genuine unbounded-until-quorum-restored
  outage with zero unsafe promotion, exactly as predicted, not a bug.

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

1. Stage 0 through Stage 6 findings, reported before proceeding
   further — **done, all six stages complete**, see the results
   sections above
2. Explicit topology and fencing-mechanism decisions, documented here
   before Stage 2 begins — topology and Patroni deployment model done;
   the synchronous-standby mode is resolved (quorum `ANY 1 (*)`, see
   "Sync mode decision" above); the fencing approach is resolved and its
   conditional acceptance confirmed by real measurement in both the
   restart case and the harder live-partition case (see "Fencing
   decision," "Stage 4 results," and "Stage 5 results" above); Stage 6
   additionally confirmed total quorum loss fails safe to an unbounded
   outage rather than any ambiguous promotion — nothing left undecided
   on this front
3. A results doc analogous to `docs/testing-strategy-ha-supplement.md`,
   capturing what Stages 4–6 actually found — **done, all three stages
   in**. This doc's own accumulated Stage 0–6 results sections serve
   that role directly rather than a separate document, consistent with
   how this doc has been maintained throughout rather than written once
   at the end.
