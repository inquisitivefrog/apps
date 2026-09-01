# PostgreSQL clustering — HA investigation

**Authoritative narrative and plan**: `docs/postgres-ha-scope.md`. This file
tracks status/progress against that plan's staged approach, not a duplicate
of its reasoning. Clustering solution: Patroni + Consul (decided in
`docs/ha-scope.md`, inherited as-is — see that doc's reasoning).

**Status (2026-09-01): Stages 0–6 complete — this closes out the entire
staged Postgres/Patroni/Consul HA pass. See "Stage 6" near the end of
this file for the final stage's results.**

## Stage 0 — Confirm Consul quorum works in isolation (complete, PASS 3/3)

Script: `load-tests/consul-quorum-loss.sh`. Two sub-tests per run:

- **Sub-test A** — kill the *current leader* specifically (not just any
  follower — the more rigorous test), leaving 2 of 3 agents. Confirm the
  survivors elect a new leader and the cluster stays fully functional (a
  real `consul kv put`/`get`, not inferred from `consul members` alone).
- **Sub-test B** — kill a second agent, leaving only 1 of 3. Confirm the
  cluster correctly loses quorum (no leader reported) and refuses writes
  requiring consensus, rather than silently continuing degraded.

**Three real bugs found and fixed before trusting any result** — this is
Consul, day one, and the same lesson categories from Kafka/Redis showed
up again immediately:

1. **Insufficiently precise readiness check.** First run checked "3 agents
   alive + a leader exists" before starting, which is not the same as "all
   3 are actual raft voters." Consul's autopilot has a stabilization delay
   before promoting a freshly-(re)joined server to full voting status —
   the first run's baseline showed one agent `Voter: false`, meaning when
   the leader was killed, only 1 of the *effective* 2 voters remained
   alive, not 2 — quorum was lost one step earlier than the test intended,
   producing a misleading "no new leader elected" result that looked like
   a Consul defect but was actually an imprecise setup check. Fixed by
   polling `consul operator raft list-peers` for actual voter status, not
   `consul members`'s gossip-layer "alive" alone.
2. **Missing abort-guard on the fixed setup loop.** A second run's initial
   readiness poll exhausted its full timeout without ever reaching "3/3
   alive + 3/3 voters" (one agent never joined the raft configuration at
   all that run — plausibly `-retry-join`'s own backoff interval outracing
   the poll, the same DNS/join-timing family of bug hit repeatedly this
   session with Kafka and Redis), but the script had no check for whether
   the loop actually succeeded before continuing — it silently proceeded
   into a broken 2-node baseline and produced a scary-looking false
   "quorum lost" result for what was actually a setup race. Fixed: abort
   cleanly with a clear diagnostic if readiness isn't reached, same
   pattern already used elsewhere in this project's scripts. Also widened
   the poll ceiling 30s → 60s, since real cluster-formation time varied a
   lot across runs (2s, 4s, 15s all observed).
3. **`timeout` command doesn't exist in this environment** (neither GNU
   `timeout` nor macOS's `gtimeout`) — a write-refusal check silently
   failed with exit 127 instead of testing anything real. Didn't produce
   a false PASS only by coincidence (a different check failed that run
   too). Removed the wrapper; confirmed empirically that a quorum-less
   Consul agent fails fast with a 500 error rather than hanging, so no
   external timeout is actually needed.

**Result after both fixes, 3/3 clean runs**: leader-kill correctly
triggers a new election among the 2 survivors (2-4s observed), the 2-node
cluster stays fully read/write functional, and killing a second agent
(down to 1 of 3) is correctly detected as quorum loss with writes refused
(`500 No cluster leader`), never silently degraded.

This establishes the known-good Consul baseline Stage 0 exists to
provide — Patroni's own behavior on top of Consul is now a variable that
can be tested in Stage 1+ without risk of misattributing a Consul-layer
problem to Patroni or Postgres.

## Stage 1 — Config audit (complete)

Live-verified via `psql SHOW` against the running (pre-HA) `postgres`
instance, not just repo grep (repo grep: zero matches for any setting):

| Setting | Live value | Declared anywhere? |
|---|---|---|
| `synchronous_standby_names` | **empty/undeclared** | No |
| `synchronous_commit` | `on` | No — Postgres default; meaningless with no standby list configured |
| `wal_level` | `replica` | No — but already at the minimum required for streaming replication |
| `max_wal_senders` | `10` | No — default already adequate for this project's scale |
| `max_replication_slots` | `10` | No — same |

**The one real gap**: `synchronous_standby_names` empty means fully
**asynchronous** replication — the 7th confirmed instance of the
undeclared-durability-default pattern (see `CLAUDE.md`). The other three
undeclared settings have adequate defaults already, not fixes needed.
HikariCP's `connection-timeout` (5s) stays as-is per `docs/postgres-ha-scope.md`'s
own note — re-examine once real Patroni failover RTO is measurable in
Stage 4.

## Stage 2 — Topology (complete)

Built a **separate, isolated** 3-node Patroni+Consul cluster
(`patroni-1/2/3` in `docker-compose.yml`) — deliberately not touching the
app's real `postgres` service or its data, since Postgres is this app's
actual system of record (unlike Redis). 2 replicas confirmed (primary + 2
= 3 total nodes, matching the Kafka/Redis pattern). Custom
`patroni/Dockerfile` built (no official image preserves the pinned
`postgres:18.4`) — Patroni 4.1.5, pinned via
[Patroni's own release notes](https://patroni.readthedocs.io/en/latest/releases.html#releases).

**Two real bugs found and fixed getting `patroni-1` alone to bootstrap**:

1. `patroni[consul]` doesn't bundle a Postgres driver — failed outright
   with `FATAL: Patroni requires psycopg2>=2.5.4 ...`. Fixed: added
   `psycopg[binary]` to the Dockerfile's pip install.
2. The `bootstrap` section (how a brand-new cluster self-initializes) has
   **no environment-variable equivalent at all** — confirmed directly
   against Patroni's own `ENVIRONMENT.rst`, not assumed, after `patroni-1`
   sat indefinitely logging "waiting for leader to bootstrap" with no
   config telling it self-initialization was even an option. Fixed: added
   `patroni/patroni.yml` (mounted into all 3 nodes) supplying just the
   `bootstrap` section; everything node-specific stays in env vars, which
   override the file.

**Full topology confirmed working**: all 3 nodes joined (`patroni-1`
Leader, `patroni-2`/`patroni-3` streaming, 0 lag), a committed write on
the leader confirmed present on both replicas via direct `SELECT`, and
verbose logging enabled on all 3 nodes (Postgres GUCs pushed live via
`patronictl edit-config`, Patroni's own log level to `DEBUG` via a live
reload) before any failure testing began — no container restart needed
to get any of this.

**The 8th confirmed instance of the undeclared-durability-default
pattern, a sharper sub-shape than the first seven**: setting
`synchronous_mode: true` alone (closing Stage 1's found gap) silently
resolved the still-open `synchronous_standby_names` *mode* question
(named standby vs. priority list vs. quorum) via Patroni's own default
— single named-standby, pinned to whichever replica registered first.
This wasn't merely unconfigured; it was a decision this project's own
doc had explicitly flagged in writing as "not yet decided," and it got
closed by a vendor default anyway. **Resolved**: switched to quorum
`ANY 1 (*)` (confirmed with the user), live-verified via
`SHOW synchronous_standby_names` → `ANY 1 ("patroni-2","patroni-3")`,
and declared directly in `patroni.yml`'s bootstrap section so a future
fresh bootstrap doesn't reopen the same gap (this cluster has no
persistent volume by design, so it re-bootstraps from that file, not
from whatever's live in Consul's DCS, if ever fully recreated).

**Design note on Consul connectivity**: each `patroni-N` points at a
*different* Consul agent (`patroni-1`→`consul-1`, etc.), not all 3 at the
same one — this project doesn't run a per-node local Consul client-agent
tier (the standard production resilience pattern), so pointing every
Patroni node at one shared agent would mean that agent's failure alone
breaks all 3 nodes' DCS connectivity, confounding Stage 5's actual intent
(testing genuine Consul quorum loss, not one agent being down). Spreading
across agents means an individual agent hiccup only affects 1 of 3 nodes.

**Also resolved this stage**: the Traefik + Consul Catalog client-write-
routing spike (`load-tests/postgres-traefik-routing-register.sh`) —
registers a `postgres-primary` Consul service per node, health-checked
against each node's own Patroni `/primary` REST endpoint rather than
Patroni's own `register_service` feature (a documented upstream issue,
patroni/patroni#2517, describes that mechanism's service tag getting
stuck stale after a Consul communication hiccup). Verified live across
2 independent failover directions — exactly one node ever reported
"passing" at any polled instant.

## Stage 3 — Single replica failure, expected-safe case (complete, PASS, 3/3 across 2 sub-tests)

Script: `load-tests/postgres-replica-failure-test.sh` (parameterized by
target node, reused for both sub-tests). Kills `patroni-3` then
`patroni-2` independently — kept as two sub-tests even under quorum mode
(where both are *expected* to behave identically) specifically to verify
that symmetry empirically rather than assume it from the config's name,
matching Redis's own precedent of not assuming replica interchangeability.

**Both sub-tests clean and symmetric**: primary kept serving throughout
each (5/5 writes succeeded, ~90–100ms each — real numbers, not inferred),
`synchronous_standby_names` correctly dropped the killed node within
`loop_wait`'s bound (~1–7s observed), the killed replica rejoined cleanly
and caught up, and all marker rows confirmed present on both the primary
and the rejoined replica via direct query. Killing `patroni-2` and
`patroni-3` produced identical outcomes — the actual finding this stage
was designed to produce, not just two passing runs.

**A real bug found and fixed along the way**: the marker-write script's
first attempt used `date +%s%3N` for write timestamps, which silently
misparses on this Mac's BSD `date` (`%3N`'s width modifier is GNU-only;
bare `%N` works). The resulting bash arithmetic error silently truncated
the write loop after its first iteration while the script's own summary
line still printed "5/5 succeeded" — caught and fixed before the result
was trusted. See `docs/cross-project-lessons.md`'s "Shell scripting and
OS-tooling pitfalls" section for the full portable lesson.

## Stage 4 — Primary failure (complete, PASS, 3/3, each run killing a different node)

Script: `load-tests/postgres-primary-failure-test.sh`. Dynamically
detects the current leader so it can run repeatedly as roles rotate.

| Run | Old primary | New primary | RTO | Write survived | Client routing followed | Self-demotion | Split-brain |
|---|---|---|---|---|---|---|---|
| 1 | `patroni-3` | `patroni-1` | 1676ms | Yes | Yes (~11s) | 310ms | No |
| 2 | `patroni-1` | `patroni-2` | 1793ms | Yes | Yes (~10s) | 345ms | No |
| 3 | `patroni-2` | `patroni-3` | 1972ms | Yes | Yes (~15s) | 315ms | No |

Zero split-brain across all 3 runs — by the time a restarted node was
even reachable for a query, it already correctly reported itself as a
replica. Client-observed failover (Traefik + Consul Catalog, not just
internal Patroni state) confirmed following every failover. **Honest
caveat**: the measurement probe polls roughly every ~300ms, so this
confirms no *observable* split-brain window at that granularity, not an
absolute guarantee at any resolution.

**Two real script bugs found and fixed**: a CIDR-notation string-
comparison bug (`inet_server_addr()::text` returns `"172.18.0.21/32"`,
not a bare IP), and a `set -e`/command-substitution crash — an unguarded
write-check sibling to a correctly-guarded read-check one line above it.
Traced precisely and recorded in `docs/cross-project-lessons.md`'s Build
tooling section as a general `set -e` discipline note, not promoted to a
fourth standing pattern (confirmed to be platform-agnostic, unlike the
GNU-vs-BSD findings — a plain asymmetric-oversight bug, not a fact about
differing tool behavior).

## Stage 5 — Consensus-store degradation (complete, both sub-scenarios reported separately)

Expanded into two genuinely different sub-scenarios per this project's
own discipline against conflating them — Stage 4 tested a node that
actually died and restarted (sub-second self-demotion); this stage tests
the doc's actually-named worst case: a primary that's never dead, just
cut off from consensus.

### Sub-scenario A — partition the primary from Consul, Postgres never touched

Script: `load-tests/postgres-consul-partition-test.sh`. Live config
confirmed first (`ttl: 30`, `loop_wait: 10`, `retry_timeout: 10` — all
explicitly declared already, not undeclared defaults this time).

| Run | Partitioned primary | Self-demoted at | New leader elected at | Gap | Split-brain |
|---|---|---|---|---|---|
| 1 | `patroni-2` | 15423ms | 36511ms | +21088ms | No |
| 2 | `patroni-3` | 19362ms | 28659ms | +9297ms | No |
| 3 | `patroni-1` | 19534ms | 27544ms | +8010ms | No |

Zero split-brain across all 3 runs, but the self-demotion magnitude
(15–20s, TTL/retry-driven) is materially larger than Stage 4's
restart-based ~310–345ms, with a real ~8–21s window where nobody accepts
writes at all (an availability gap, not a data-safety one).

**A real methodology bug found and fixed, worth flagging as its own
portable chaos-testing lesson**: the first attempt used only an
`/etc/hosts` blackhole and saw zero reaction for a full 60s — which
looked like, but was not, a complete absence of self-protection.
Confirmed via direct log inspection: Patroni's Consul client was reusing
an already-open, pooled connection the blackhole never touched — only
*new* connection attempts were blocked. Fixed by also restarting the
target Consul agent immediately after applying the blackhole, forcing
the existing connection closed. General lesson: a DNS/hosts-file-level
fault injection only blocks new connections, not ones a target process
already holds open.

### Sub-scenario B — kill a non-leader, non-primary-paired Consul agent

Script: `load-tests/postgres-consul-nonleader-agent-loss-test.sh`.
Dynamically picks a safe target (avoids both the Consul raft leader and
whichever agent the current primary is paired with).

Confirmed non-event: primary completely unaffected throughout (writes
kept succeeding, `pg_is_in_recovery()` never changed), cluster timeline
never changed (no election). **One minor, real nuance**: the replica
paired with the killed agent temporarily disappeared from
`patronictl list`'s Consul-derived view, restored within ~3-4s of the
agent returning — confirmed via direct query that its actual replication
state was never affected, a Consul-*reporting* gap only, the same
underlying caution as Stage 0's "alive vs. voting member" distinction.

Two real script bugs found in the first draft (wrong `awk` field index
for the raft-leader check, wrong field index for the cluster timeline)
— fixed and re-verified before trusting the result.

## Environment

| Component | Version |
|---|---|
| Consul | 1.20.1 (`hashicorp/consul` image) — confirmed via [HashiCorp's own install page](https://developer.hashicorp.com/consul/docs/fundamentals/install#precompiled-binaries) |
| Patroni | 4.1.5 (custom image on `postgres:18.4`) — pinned via [Patroni's own release notes](https://patroni.readthedocs.io/en/latest/releases.html#releases) |
| psycopg | latest via `psycopg[binary]` (not separately version-pinned — worth pinning explicitly if this topology becomes permanent, matching this project's declare-versions-explicitly convention) |
| Docker Client/Server (Desktop) | 29.7.2 |
| Docker Compose | 5.4.0 |
| Host OS | macOS 26.5.2, arm64 (Apple Silicon) |

## Stage 6 — Quorum-loss equivalent: kill 2 of 3 Consul agents under real load (complete, PASS, 3/3, each run leaving a different agent up)

Script: `load-tests/postgres-consul-quorum-loss-test.sh`, parameterized
by which single Consul agent survives.

**A real prerequisite finding surfaced while scoping this stage**: Consul
refuses `consistent=1` reads (which Patroni's own Consul client uses)
outright without a raft quorum — meaning `patronictl list`, the tool
every earlier stage leaned on, was expected to fail on *every* node
during this stage's failure mode, not just report stale data. This
stage's safety check therefore polls each of the 3 nodes' own
`pg_is_in_recovery()` directly via `psql`, bypassing Consul-derived
state entirely — the same discipline as Stage 0's "alive vs. voting
member" and Stage 5's "Consul-reported visibility vs. actual replication
state," now a third time in this investigation.

**The 9th confirmed instance of the undeclared-durability/quorum-default
pattern, found verifying the note above**: `PATRONI_CONSUL_CONSISTENCY`
was completely undeclared anywhere in this project, despite governing
exactly the read-consistency property this stage's safety depends on.
Live behavior already matched the safe value (`consistent`, confirmed
via Stage 5's own log inspection) — declared explicitly in
`docker-compose.yml` to stop relying on that being a coincidence,
applied via a rolling recreate (replicas first, leader last, one real
expected failover), verified unchanged on all 3 nodes afterward.

**Re-tested (2026-09-01) after the first pass, adding two things the
original 3 runs didn't cover**, per direct follow-up: (a) Traefik's
client-routing behavior during total Consul quorum loss, checked as its
own clearly-labeled observation, never folded into the Postgres/Patroni
safety verdict; (b) the specific 1-of-3 → 2-of-3 recovery transition,
isolated via a staggered restore (bring back one killed agent, confirm
exactly one node gets cleanly elected, *then* restore the second) rather
than restoring both agents together and only checking the eventual
full-health end state. The table below is the final, complete result;
the original 3-run pass without these two checks is superseded by it.

| Run | Surviving agent | Primary | Self-demoted at | Unsafe promotion | 2-of-3 recovery |
|---|---|---|---|---|---|
| 1 | `consul-3` | `patroni-2` | 3000ms | No | 1 node cleanly elected, 10000ms |
| 2 | `consul-1` | `patroni-3` | 10000ms | No | 1 node cleanly elected, 37000ms |
| 3 | `consul-2` | `patroni-2` | 10000ms | No | 1 node cleanly elected, 7000ms |

**The critical safety property held in all 3 runs**: Consul correctly
refused the consistent operation immediately (real `500`s each time),
and neither non-leader node ever reported itself primary at any point
across any full 60-second window, confirmed via direct query on all 3
nodes independently. The system fails safe — unavailable for writes,
never ambiguous about who's primary — exactly as this stage exists to
verify, not merely assumed from Stage 0's Consul-only baseline.

**The 2-of-3 recovery transition was also clean in all 3 runs — exactly
one node elected, never zero-then-ambiguous, never two at once** — but
the *time* to reach that clean election varied widely (7s to 37s), with
no clear causal pattern identified (self-demotion time didn't correlate
with recovery time in any consistent way across the 3 runs). Reported
honestly as real variance rather than forcing a tidy explanation that
the data doesn't actually support.

**A genuinely useful finding for understanding Traefik + Consul
Catalog's actual behavior under this failure mode, confirmed 3/3
identically**: Traefik kept routing every client connection to the
*same* node for the entire ~59-second quorum-loss window in every run —
even after that node had already self-demoted and was no longer really
primary. This is not a Traefik bug and not unsafe (a write sent there
would just fail against a read-only replica, not corrupt anything) —
it's a direct, mechanical consequence of how the whole routing spike
works: Traefik relies on Consul Catalog's health-check status, and
Consul itself cannot process *any* health-check state changes without a
raft quorum to write them into. Once quorum is lost, Consul Catalog's
last-known-good answer is simply frozen, and Traefik has no way to know
it's stale. This is a different specific mechanism from Stage 5's
"Patroni reuses a stale pooled connection" finding, but the same general
shape: a health/routing signal derived from Consul is not the same thing
as the real state of the component being routed to, and the gap between
them widens for as long as Consul itself can't be consulted at all.

**Three real script bugs found and fixed across both passes, worth
recording precisely**:
1. A self-inflicted mistake, not a code bug: piping a live,
   state-mutating script through `head -30` triggered a `SIGPIPE` that
   killed it before its own cleanup ran, leaving 2 Consul agents
   stopped. Caught and restored immediately. Lesson: never truncate
   output from a script that mutates real infrastructure state via a
   pipe that can close early.
2. An unreproduced timing anomaly in the first pass: a first version
   driving the monitoring loop's `while` condition directly off
   `date +%s%N` nanosecond arithmetic exited after only ~2.5s instead of
   the intended 60s — isolated repros of the identical pattern did not
   reproduce it. Worked around by redesigning the loop to use the
   `SECONDS` builtin for loop control instead, trading sub-second timing
   precision for robustness.
3. **The same class of bug recurred in the *new* staggered-restore
   loop during the re-test, even though it already used the `SECONDS`
   builtin** — one run's 2-of-3 recovery check silently stopped after a
   single iteration with no error. This time the actual mechanism was
   identified: the underlying shell command had exceeded the tool
   environment's foreground-execution window and been force-migrated to
   run in the background mid-script, and that migration itself appears
   to disrupt the running script's loop execution. Confirmed by
   re-running the identical scenario launched as a background command
   from the very start (no mid-run migration) — it completed cleanly
   with a normal result (7000ms). The underlying cluster had, in fact,
   converged correctly on its own during the failed observation (checked
   directly afterward) — this was lost visibility into a real, safe
   outcome, not a masked unsafe one. **Portable lesson for future
   sessions**: launch any script expected to run long enough to risk a
   foreground timeout as a background command from the start, rather
   than letting it be migrated mid-execution.

This closes out all 6 stages of the staged Postgres/Patroni/Consul HA
pass.

## Resource budget — re-measured against the real full topology (belated, closed)

One item from the doc's own plan was left unaddressed through Stages
2-6 and the addendum: re-confirm the VM-ceiling concern with real
`docker stats` numbers once the full 3-Consul + 3-Patroni topology was
actually up, not the original pre-Stage-2 estimate. Nothing in the later
stages happened to force a look back at it, so it just sat stale.

Caught on a direct re-test request and closed with real numbers, full
stack up and idle: Consul (3 agents) ~135 MiB, Patroni-supervised
Postgres (3 nodes) ~279 MiB — Postgres HA layer total ~414 MiB. Full
20-container stack (both the Patroni cluster and the standalone
`postgres` container the app still actually points at, running side by
side, pre-cutover) totals ~3.57 GiB, ~4.18 GiB of headroom under the
7.749 GiB Docker Desktop VM ceiling. Post-cutover (standalone `postgres`
retired) that's ~3.53 GiB, ~4.22 GiB headroom. `ha-scope.md`'s original
"~8.2-8.9 GiB, exceeds the ceiling" estimate is confirmed substantially
overstated, same direction as Redis's own estimate-vs-real gap. No VM
allocation increase needed. Full writeup in
`docs/postgres-ha-scope.md`'s "Resource budget — finally re-measured
against the real full topology" section.

## Stage 7 — Application-level cutover and validation (complete, 3/3 clean)

Six clean chaos-testing stages had validated the Patroni/Consul topology
in isolation, but `SPRING_DATASOURCE_URL` still pointed at the
standalone `postgres` container the whole time -- none of that
protection was actually in the app's request path. Closed in four steps:

1. **Cutover**: pointed `SPRING_DATASOURCE_URL` at Traefik's `:55432`
   entrypoint. Needed more than a one-line change: the `gridmeter`
   role/database never existed on the Patroni cluster (fixed live +
   declared in `patroni.yml` for future bootstraps), the routing
   registration was still the manual, explicitly-"not yet durable" spike
   script (fixed with a new one-shot `postgres-primary-registrar`
   compose service, verified against a genuine cold Consul teardown, not
   just a restart), and HikariCP needed
   `PrimaryFailoverSQLExceptionOverride` added to evict pooled
   connections on Postgres' `25006` read-only-transaction SQLState so a
   connection to a freshly-demoted node doesn't keep getting handed out.
2. **Functional check**: real login, meter create, reading ingest via
   Kafka, and search all confirmed working, with the row directly
   verified present on `patroni-2` and absent from the standalone
   container.
3. **Retired the standalone `postgres` container**, its compose service,
   and its `postgres-data` volume, after Step 4 confirmed cutover was
   solid. One snag: `docker compose rm -f postgres` silently no-opped
   once the service definition was already removed from the compose
   file; the container needed stopping directly via plain `docker`
   commands instead.
4. **Re-ran a primary-kill scenario through the app's real endpoints**
   (`load-tests/postgres-app-primary-failure-test.sh`), 3/3 clean:

   | Run | Old leader → new | Infra RTO | Requests | Failed | Self-healed |
   |---|---|---|---|---|---|
   | 1 | patroni-2 → patroni-3 | 1806ms | 42 | 1 | Yes |
   | 2 | patroni-2 → patroni-3 | 1806ms | 28 | 2 (client-reported) | Yes |
   | 3 | patroni-3 → patroni-1 | 1632ms | 42 | 1 | Yes |

   HikariCP recovered automatically every time, no restart needed.
   Total impact: 1-2 failed requests out of 28-42, within a single-digit
   second window.

**A genuine finding, not a bug**: Run 2's DB had 27 reading rows for its
test meter, but the client only counted 26 successes -- one write
committed server-side with its response lost, almost certainly from the
connection being severed mid-response by the container stopping. Real
implication: `POST /api/v1/readings` has no idempotency key, so a naive
client retry on this exact failure shape risks a duplicate write. Not
fixed here (out of scope), but a concrete, evidence-backed argument for
one if this app's ingestion contract is ever hardened.

**A real script bug found and fixed while building the test**: an early
version's background traffic-generator loop silently died after ~2s
instead of running the full ~24s window (7 requests logged instead of
~30-40), while the outer script's summary still looked clean. Root
cause: fixing an unrelated cosmetic bug (a doubled `"000000"` status
code) removed the loop's `|| echo "000"` guard without recognizing it
was also what kept `set -e` (inherited into the `&`-backgrounded
subshell) from killing the loop the instant `curl` hit a real
connection-refused during the failover window. Caught by noticing one
run's request count was implausibly low for its duration; that run was
discarded and re-run after restoring the guard.

Full writeup: `docs/postgres-ha-scope.md`'s "Stage 7 results" section.
This closes all 7 stages of the staged Postgres/Patroni/Consul HA pass.
