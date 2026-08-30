# Session status — 2026-08-29 (Claude Code)

Very large session — three separate HA investigations (Kafka, Redis,
Postgres) plus a recurring Docker-disk crisis resolved for good. Grouped
by topic below, not strictly chronological.

## Done — Docker disk crisis (3rd occurrence), root-caused and fixed permanently

- **Crisis recap**: Docker Desktop's engine got stuck in a shutdown loop
  after the host disk filled to ~126Mi free, cascading into a full tool
  outage. Resolved by force-quitting Docker Desktop and deleting
  `Docker.raw` outright (explicit user sign-off — wipes all local Docker
  data, not just this project's). Reclaimed the disk; stack rebuilt
  clean from checked-in config.
- **Root cause found and fixed, not just patched around**: Docker's
  default `json-file` logging driver has no size cap — every container's
  stdout/stderr accumulates forever until the container is removed.
  Compounded by this project's own testing (high-request-volume load
  tests, TRACE-level Kafka debug logging) and `Docker.raw`'s sparse file
  only shrinking on manual `docker system prune`. Fixed: `docker-compose.yml`
  now has a shared `x-logging` anchor (`max-size: 10m`, `max-file: 3`) on
  every service. `scripts/check-disk-headroom.sh` added — a real
  enforcement gate (warn <30GB, hard-stop <15GB) sourced by every
  load-test/chaos script, forcing a decision before a run proceeds
  rather than silently degrading until a reboot.
- **Separately identified and cleaned**: 82GB of throwaway Xcode UI-test
  simulator clones (`~/Library/Developer/XCTestDevices`, deleted), 4
  cold UTM VMs explicitly **kept** at the user's request (a Linux build
  node for their C++ apps — saved as a standing memory not to re-flag
  these). `docker system prune` alone reclaimed ~49GB one-time
  (`Docker.raw` compacted 57GB→6.4GB).

## Done — Kafka unclean-election investigation: root cause confirmed, mechanism understood, evidence archived

- **Finding 1 (fixed)**: `application.yml`'s Kafka producer never
  declared `acks`, silently inheriting client default `1`. Declared
  `acks: all` explicitly, re-verified.
- **Finding 2 — root cause CONFIRMED, 3/3 reproductions, both suspected
  upstream tickets ruled out on their own terms**:
  - KAFKA-19148 (originally cited): **wrong ticket** — already resolved
    in 4.1.0, different mechanism (partition-reassignment race, never
    triggered here). Retracted.
  - KAFKA-19552 (candidate): **ruled out** — real, open ticket, but
    opposite polarity (its bug is unclean election *failing to fire*
    when wanted; ours is it firing when it shouldn't) and a structural
    mismatch (it assumes separate broker/controller processes; this
    project's nodes are combined).
  - **Actual mechanism, found via TRACE-level internal logs (the debug
    overlay built this session, `docker-compose.kafka-debug.yml` +
    `observability/kafka-debug-log4j2.yaml`)**: two distinct
    promotion-from-ELR (KIP-966) code paths exist. Path 1 (the periodic
    `electUnclean` task) is correctly labeled `UNCLEAN partition change`
    in Kafka's own logs. **Path 2 — broker-fencing-triggered immediate
    reassignment — is not.** It logs at plain `DEBUG` with no `UNCLEAN`
    label, and is **not gated by `unclean.leader.election.enable`** even
    under a confirmed-live dynamic override. Confirmed identically 3
    times independently (different broker/partition combinations each
    run) — meets this project's 3-iteration bar for a correctness
    finding.
  - `docker-compose.yml` now declares `unclean.leader.election.enable=false`
    explicitly (was previously true only via Kafka's own undeclared
    default).
  - Full evidence in `load-tests/vendor-bug-reports/kafka/` (runs,
    TRACE logs, a frozen debug-compose snapshot). Bug report is
    describable and ready to file; **blocked on JIRA account approval**,
    not on evidence-gathering.
- **`kafka-ha-demo.sh` Scenario 3 fixed**: a fixed `sleep 8` was assumed
  to represent ISR-rejoin time. Measured directly, twice: real rejoin
  time is **13–30 seconds**. The "zero downtime" result itself still
  held (0 failures both times) — but for a stronger reason than
  originally claimed: `min.insync.replicas=2` tolerates a broker
  genuinely still mid-rejoin, not just one already caught up. Script now
  measures and reports the real number instead of assuming it.
  `load-tests/README.md` corrected/strengthened to match.

## Done — Redis Sentinel HA investigation: all 5 stages complete

Full plan in `docs/redis-ha-scope.md`, full evidence in
`load-tests/vendor-bug-reports/redis/`.

- **Stage 1** (config audit): `min-replicas-to-write=0` live — the direct
  structural twin of Kafka's undeclared `acks=1`.
- **Stage 2** (topology): 1 primary + 2 replicas + 3 Sentinels built.
  `min-replicas-to-write 1`/`min-replicas-max-lag 10` declared explicitly
  on the primary, closing Stage 1's gap. Debug logging enabled before any
  failure testing.
- **Stage 3** (single-replica loss): run as two independent sub-tests
  (one per replica, not assumed symmetric). Both PASS.
- **Stage 4** (primary failure) — **two real, distinct defects found**:
  - **Finding A**: the primary's `docker-compose` command had no
    `--replicaof`, so it always booted believing it was still primary
    after any restart, regardless of what Sentinel decided while it was
    down — a real, confirmed ~10s split-brain window (tied exactly to
    `failover-timeout`). **Fixed** with `scripts/redis-entrypoint.sh`:
    all 3 data nodes now ask Sentinel who the real master is before
    starting. Re-verified 3/3 clean: demotion now happens in ~0.3s.
  - **Finding B**: total failover non-completion, traced to Sentinel's
    own `-failover-abort-no-good-slave` event — a race in this
    project's own test script (a fixed sleep after topology reset raced
    Sentinel's replica-discovery poll), not a Sentinel defect. Fixed via
    active polling. Re-verified 8/8 clean.
- **Stage 5** (quorum-loss): kill 2 of 3 Sentinels, then also kill the
  primary — **zero unsafe promotions across 3 runs**. No fix needed here
  (unlike A/B) — Sentinel's own quorum-authorization mechanism held
  correctly every time. One more instance of the fixed-sleep pattern
  caught and fixed in the test script along the way (a stale quorum
  check reading ~3s early).
- **Minor known follow-up, not yet fixed**: `redis-quorum-loss.sh`'s
  restore step uses `docker compose start` instead of `--force-recreate`
  on the Sentinels, which can hit a `Duplicate master name` crash on
  restart (found post-hoc, fixed manually that one time). Low priority —
  doesn't affect any reported finding.

## Done — standing principles promoted (CLAUDE.md + docs/testing-strategy.md)

- **Undeclared-durability-default pattern** — now 7 confirmed instances
  across this whole effort (HikariCP `connection-timeout`, Kafka
  `max.block.ms`/`delivery.timeout.ms`/`acks`/
  `unclean.leader.election.enable`, Redis `min-replicas-to-write`,
  Postgres `synchronous_standby_names`). Standing principle in
  `CLAUDE.md`.
- **Fixed-sleep-races-unbounded-readiness pattern** — found 3+ times
  across Kafka and Redis test scripts (one produced a false result, one
  masked the real explanation for a true result, others caught while
  building). New "Test-infrastructure lesson" section in
  `docs/testing-strategy.md`; also a standing `CLAUDE.md` bullet.

## Done — Postgres/Patroni/Consul HA investigation: Stage 0 + Stage 1 complete, Stage 2 IN PROGRESS

Full plan in `docs/postgres-ha-scope.md`, full evidence in
`load-tests/vendor-bug-reports/postgres/`. Consul 1.20.1 and Patroni
4.1.5 pinned in `docs/tech-stack-versions.md` (exact versions provided
directly by the user from HashiCorp's/Patroni's own release pages, not
guessed).

- **Resource re-measurement** (per the doc's own instruction, now that
  Redis is closed out): real baseline ~3.42 GiB / ~4.33 GiB headroom
  under the 7.749 GiB VM ceiling — the original "8.2–8.9 GiB, exceeds
  ceiling" estimate looks pessimistic given how much lighter Redis's
  real footprint came in. Explicitly NOT treated as fully resolved —
  Postgres+Patroni+Consul's own real footprint still needs measuring
  post-Stage-2, same discipline.
- **Stage 0** (Consul quorum in isolation) — **PASS, 3/3 clean**, but
  only after finding and fixing **3 real bugs on day one** in new
  infrastructure: (1) a readiness check confusing "alive" (gossip) with
  "voting member" (raft) — Consul's autopilot stabilization delay meant
  one run's effective quorum was smaller than intended; (2) a missing
  abort-guard on the setup loop, so a genuine `-retry-join` race
  silently produced a misleading result instead of failing loud; (3)
  neither `timeout` nor `gtimeout` exists in this environment — a
  write-refusal check was silently a no-op (exit 127). Claude Chat
  specifically asked Claude Code to verify with certainty that none of
  the 3 counted clean passes predated fix #1 — confirmed directly
  against the saved transcripts (all 3 explicitly show `3/3 voters`
  before proceeding); also audited the whole project for other latent
  `timeout`/`gtimeout` dependencies — none found.
- **Stage 1** (config audit) — complete. `synchronous_standby_names`
  confirmed empty/undeclared via live `psql SHOW` (not just repo grep,
  which also found nothing). The other 3 checked settings
  (`wal_level`, `max_wal_senders`, `max_replication_slots`) are
  undeclared too, but their Postgres defaults are already adequate at
  this project's scale.
- **Stage 2** (topology) — **IN PROGRESS, stopped for the night
  mid-build**. Decided: 2 replicas (primary + 2 = 3 total nodes,
  matching Kafka/Redis). Decided: custom Dockerfile (`patroni/Dockerfile`)
  pip-installing Patroni onto `postgres:18.4`, since no official image
  preserves that exact pin. **Two real bugs found and fixed getting
  `patroni-1` alone to bootstrap**: (1) `patroni[consul]` doesn't bundle
  a Postgres driver — added `psycopg[binary]`; (2) the `bootstrap`
  section has **no environment-variable equivalent at all** (confirmed
  against Patroni's own `ENVIRONMENT.rst`, not assumed) — added
  `patroni/patroni.yml` (mounted into all 3 nodes) supplying just that
  section; everything node-specific stays in env vars, which override
  it. **Confirmed working**: `patroni-1` alone bootstrapped a brand-new
  cluster, registered in Consul, elected itself leader, and logged
  `Enabled synchronous replication` — closing Stage 1's found gap via
  `synchronous_mode: true`, the correct Patroni-native mechanism.
  **`patroni-2`/`patroni-3` have not been brought up yet.**

## Next steps on resume

0. **Two real gaps surfaced by Claude Chat's parallel `docs/postgres-ha-scope.md`
   update tonight, neither addressed yet**:
   - **`synchronous_standby_names` mode not decided** — `patroni.yml`
     only sets the coarse `synchronous_mode: true`; the specific
     standby-selection mode (named standby vs. priority list vs. quorum
     `ANY n (...)`) still needs an explicit choice, ideally before
     `patroni-2`/`patroni-3` join (harmless so far since only `patroni-1`
     has bootstrapped — no replicas exist yet for a mode to apply to).
   - **Client write-routing (Traefik + Consul Catalog) completely
     unaddressed** — Traefik's default Consul Catalog behavior
     load-balances across *every* healthy instance of a service, not
     just the primary; needs either Patroni tagging its own Consul
     registration by role or using Patroni's `/primary` REST endpoint as
     the backing health check. Not yet spiked. Testing has so far
     bypassed this entirely (direct `docker compose exec`/`psql` against
     whichever node is primary) — this will matter for real once Stage 4
     failover testing needs to verify the *client's* write path, not
     just which node Patroni currently considers primary.
1. `docker compose up -d patroni-2 patroni-3`, confirm all 3 join as one
   Patroni cluster (`patronictl list` or the REST API), confirm a
   replica actually streams and catches up, confirm a write is present
   on a replica via direct query (not `pg_stat_replication` lag alone) —
   the rest of Stage 2's own checklist, not yet done.
2. `patroni/`, the `docker-compose.yml` Patroni/Consul additions, and
   the Stage 0/1 evidence are **not yet committed** this session —
   decide what to commit once Stage 2 is further along, or commit the
   in-progress state as-is if picking this up much later.
3. Consider pinning `psycopg`'s exact version explicitly in the
   Dockerfile (currently `psycopg[binary]` unpinned) — noted in
   `load-tests/vendor-bug-reports/postgres/NOTES.md` as a loose end.
4. Once Stage 2 is fully verified: Stage 3 (single-replica loss) through
   Stage 6 (Consul quorum-loss under real Postgres load) per
   `docs/postgres-ha-scope.md` — expect the fencing/split-brain decision
   (Stage 4's "sharpest new risk" note) to need an explicit choice before
   that stage, same pattern as the replica-count and Dockerfile-approach
   decisions this session.
5. Fix `redis-quorum-loss.sh`'s minor restore-step bug (`start` →
   `--force-recreate` on the Sentinels) — low priority, noted but not
   done.
6. All commits from earlier in the session (Kafka investigation, Redis
   investigation + testing-strategy.md/CLAUDE.md updates) were made and
   pushed to `origin/main` already — only the Postgres/Patroni/Consul
   work from tonight remains uncommitted.

## Open / not started (carried over, still accurate)

- Circuit breaker build-order decision (Resilience4j vs. deferring).
- k8s Kafka HA follow-up slice (`k8s/kafka.yaml` → 3-broker StatefulSet).
- `docs/cloud-deployment-scope.md`, `docs/multi-tenancy-scope.md` —
  Claude-Chat-authored, awaiting direction.
- Trend-alert design (scoped separately, not started).
- Stage 5 (Postgres consensus-store degradation) and Stage 6
  (Postgres quorum-loss under load) — not started, gated behind Stage
  2–4 per the doc's own staging discipline.

## Environment note for next session

All Docker containers were **stopped** (not removed) at the end of this
session per the user's request to wind down for the night — a plain
`docker compose up -d` (plus `patroni-2`/`patroni-3` explicitly, since
they were never started) should resume cleanly with no rebuild needed,
except the Patroni image which already exists locally from tonight's
build.
