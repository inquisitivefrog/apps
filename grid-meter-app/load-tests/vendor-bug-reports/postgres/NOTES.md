# PostgreSQL clustering — HA investigation

**Authoritative narrative and plan**: `docs/postgres-ha-scope.md`. This file
tracks status/progress against that plan's staged approach, not a duplicate
of its reasoning. Clustering solution: Patroni + Consul (decided in
`docs/ha-scope.md`, inherited as-is — see that doc's reasoning).

**Status (2026-08-30): Stage 0 complete (PASS, 3/3 clean) and Stage 1
(config audit) complete. Stage 2 (topology) IN PROGRESS, stopped for the
night mid-build — `patroni-1` alone successfully bootstrapped; `patroni-2`
and `patroni-3` not yet brought up. See "Stage 2 progress" below for exact
resume point.**

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

## Stage 2 — Topology (IN PROGRESS — resume point below)

Building a **separate, isolated** 3-node Patroni+Consul cluster
(`patroni-1/2/3` in `docker-compose.yml`) — deliberately not touching the
app's real `postgres` service or its data, since Postgres is this app's
actual system of record (unlike Redis). 2 replicas decided (primary + 2 =
3 total nodes, matching the Kafka/Redis pattern). Custom
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

**Confirmed working**: `patroni-1` alone bootstrapped a brand-new
cluster, registered correctly in Consul, elected itself leader (sole
member), and logged `Enabled synchronous replication` — closing Stage 1's
found gap as part of building the real topology, via
`synchronous_mode: true` in `patroni.yml`'s bootstrap config (the correct
Patroni-native mechanism — Patroni manages `synchronous_standby_names`
dynamically itself once this is set, rather than a static value that
wouldn't track topology changes).

**Design note on Consul connectivity**: each `patroni-N` points at a
*different* Consul agent (`patroni-1`→`consul-1`, etc.), not all 3 at the
same one — this project doesn't run a per-node local Consul client-agent
tier (the standard production resilience pattern), so pointing every
Patroni node at one shared agent would mean that agent's failure alone
breaks all 3 nodes' DCS connectivity, confounding Stage 5's actual intent
(testing genuine Consul quorum loss, not one agent being down). Spreading
across agents means an individual agent hiccup only affects 1 of 3 nodes.

**Exact resume point**: `patroni-2` and `patroni-3` have not been brought
up yet. Next step is `docker compose up -d patroni-2 patroni-3`, then
confirm all 3 join as one cluster (`patronictl -c /etc/patroni.yml list`
or the REST API), confirm a replica actually streams and catches up, and
confirm a write is present on a replica via direct query — per Stage 2's
own checklist, not yet done.

## Environment additions this stage

| Component | Version |
|---|---|
| Patroni | 4.1.5 (custom image on `postgres:18.4`) |
| psycopg | latest via `psycopg[binary]` (not separately version-pinned yet — worth pinning explicitly if this becomes permanent, matching this project's declare-versions-explicitly convention) |

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

## Environment

| Component | Version |
|---|---|
| Consul | 1.20.1 (`hashicorp/consul` image) — confirmed via [HashiCorp's own install page](https://developer.hashicorp.com/consul/docs/fundamentals/install#precompiled-binaries) |
| Docker Client/Server (Desktop) | 29.7.2 |
| Docker Compose | 5.4.0 |
| Host OS | macOS 26.5.2, arm64 (Apple Silicon) |

## Next: Stage 1 (config audit)

Not yet started. Per `docs/postgres-ha-scope.md`: grep the current
Postgres config (`docker-compose.yml`, `application.yml`'s
`spring.datasource.*`, any `postgresql.conf`) for every durability/
replication-relevant setting (`synchronous_standby_names`/
`synchronous_commit`, `wal_level`, `max_wal_senders`/
`max_replication_slots`, HikariCP's `connection-timeout`). Given the
pattern confirmed in six separate Kafka/Redis configs already (see
`CLAUDE.md`), the working assumption going in should be that these are
also currently undeclared and defaulting to "no real guarantee," not that
they're already handled.
