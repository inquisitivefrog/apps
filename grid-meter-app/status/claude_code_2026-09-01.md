# Session status — 2026-09-01 (Claude Code)

Backfilled retroactively on 2026-09-02 (no status doc was written at the
time) from git history — grouped by topic, not strictly chronological.
Closed out the app-vs-infrastructure gap across all three HA passes
(Postgres, Redis, Kafka confirmed clean by construction), completed
Postgres Stage 7, verified the Patroni bootstrap hook against a real
cold bootstrap, fixed Kafka's Scenario 1 RTO measurement, and wrote the
idempotency-key design doc that the rest of the following session
implements.

## Done — app-vs-infrastructure gap resolved for all three HA passes

- **Kafka confirmed already clean**: checked `load-tests/kafka-ha-demo.sh`
  directly — every scenario logs in for a real JWT and sends readings via
  authenticated `POST /api/v1/readings` through Traefik, exercising the
  app's actual Spring Kafka producer end to end. No remediation needed.
- **Redis cut over** (Stage 6, Steps 1–3): app's Lettuce client was a
  fixed `spring.data.redis.host/port` pointing at the `redis` container
  by name, with no Sentinel awareness — confirmed via live config check,
  not assumed. Cut over to `spring.data.redis.sentinel.master/nodes`
  (Spring Boot 4.x renamed `RedisProperties` to `DataRedisProperties` —
  verified against the real jar, not memory). Hit and fixed a real,
  previously-known-but-unfixed bug along the way: adding the Sentinels
  to `api`'s `depends_on` tripped the "docker compose start instead of
  --force-recreate crashes Sentinels" bug flagged as low-priority weeks
  earlier — now actually tripped by everyday use, fixed at the root
  (`rm -f /tmp/sentinel.conf` before `touch`, not a per-script
  workaround).
- **Redis Stage 6 completed**: re-ran the primary-kill scenario through
  the app's real endpoints (new `redis-app-primary-failure-test.sh`),
  3/3 clean across different topology permutations, zero HTTP failures.
  Confirmed the async Redis cache write (decoupled from the request/
  response by design) survives the failover every time. A genuine
  mechanism found via direct log inspection: Lettuce's
  `ConnectionWatchdog` doesn't immediately re-resolve the master via
  Sentinel on connection loss — it retries the dead address first for
  several seconds — yet the cache write still caught up with zero loss,
  most plausibly because Spring Kafka's own consumer retry covers the
  gap. Also found and fixed a `set -euo pipefail` + `grep -c` interaction
  bug borrowed incorrectly from a different script (killed the script
  silently at its first readiness check).
- **Standing lesson closed out**: checked the premise across all three
  passes rather than assuming it generalized from Postgres alone — held
  for Postgres and Redis (each had a real, independent gap), did not
  hold for Kafka (already covered by construction). Worth recording as
  its own point: "check everywhere" and "assume everywhere" would have
  produced the same three checkmarks, but only one was actually earned.

## Done — Postgres Stage 7: app cutover, standalone container retired, real failover verified

- **Cutover** (Steps 1–2): pointed `SPRING_DATASOURCE_URL` at Traefik's
  `:55432` entrypoint. Needed more than a one-line change: the
  `gridmeter` role/database never existed on the Patroni cluster (fixed
  live, declared in `patroni.yml` for next bootstrap — not yet verified
  working, see below); the `postgres-primary` Consul registration wasn't
  durable across a fresh Consul bootstrap (added a one-shot
  `postgres-primary-registrar` service, idempotent on every
  `docker compose up`, verified against a fully-wiped Consul); added
  `PrimaryFailoverSQLExceptionOverride` (HikariCP's
  `exceptionOverrideClassName`) to force immediate evict-and-retry on a
  Postgres `25006` read-only-transaction error.
- **Retirement + real failure scenario** (Steps 3–4): removed the
  standalone `postgres` container/volume. New
  `postgres-app-primary-failure-test.sh` generates real continuous app
  traffic while killing the current leader, 3/3 clean across all
  topology permutations — HikariCP recovered automatically every time,
  1–2 failed requests out of 28–42 per run, self-healing within a
  single-digit-second window.
- **A genuine finding, not fixed here**: one run's database had one more
  reading row than the client counted as successful — a write committed
  server-side with its response lost. Real argument for an idempotency
  key on `POST /readings`. This is what `docs/idempotency-scope.md`
  (below) exists to close.
- A real script bug found while building the test: an unrelated cosmetic
  edit had stripped the `|| echo "000"` guard that was also keeping
  `set -e` (inherited into a backgrounded loop) from silently killing the
  traffic generator on the first real connection-refused during
  failover — caught by noticing one run's request count was implausibly
  low, not by the script's own still-clean-looking summary.
- This closes all 7 stages of the Postgres/Patroni/Consul HA pass.

## Done — Patroni bootstrap-hook verification: it was broken, now fixed

- Stage 7 had declared `bootstrap.users`/`post_bootstrap` config to fix
  the missing role/database but explicitly flagged it as never exercised
  against a real from-scratch bootstrap. Verified directly per explicit
  request — an unfired hook is exactly the kind of unverified claim this
  project doesn't let stand.
- Testing it required tearing down more than expected: each Patroni
  node's data actually lives on a Docker-managed anonymous volume
  (inherited from the `postgres:18.4` base image), not purely in the
  writable layer as `patroni.yml`'s own comment claimed —
  `docker compose rm -f -v` didn't actually delete the old volumes (now
  dangling), though the recreated container still got a genuinely fresh
  one regardless. Consul's own KV tree for the cluster also had to be
  cleared explicitly, or Patroni would try to rejoin as a replica rather
  than bootstrap fresh.
- With both genuinely wiped: **`bootstrap.users` is dead configuration
  in Patroni 4.1.5** — confirmed directly against Patroni's own
  `bootstrap.py` source. `post_bootstrap()` explicitly no-ops on a
  `users` key with a logged error; the role was never created, the
  hook's own `CREATE DATABASE ... OWNER gridmeter` failed, and Patroni
  treats a failing `post_bootstrap` as fatal — it renamed the freshly-
  initialized data directory to `.failed` and aborted the whole
  bootstrap.
- **Fixed**: role and database now created inside `post_bootstrap`
  itself via `psql`'s multiple `-c` flags (not a shell `&&` — Patroni
  execs via `shlex.split()` with no shell, confirmed against source).
  Re-verified against a second genuine cold bootstrap: clean,
  `patroni-1` self-bootstrapped as Leader at t+2s with the role/database
  already present before either replica joined.
- Held to source-level root cause plus one failing + one passing full
  run, not this project's usual 3-run bar — a deterministic code-path
  check, where root-causing against real source is stronger evidence
  than additional black-box repetitions.

## Done — correcting two unverified explanations under explicit pushback

- The fresh-bootstrap write-up had asserted specific mechanisms for two
  secondary findings ("Flyway ran: no", "replicas joined: no") without
  actually testing those explanations — caught and required to be
  investigated properly, not accepted as plausible-sounding.
- **Replicas**: confirmed they did converge (the run's own final state
  showed both streaming), so the original 60s poll just gave up too
  early. Two new controlled tests (single fresh replica reset, then both
  simultaneously, matching the original scenario exactly) both converged
  in 3s against an already-stable Consul — directly refuting a
  "two-simultaneous-bootstraps-contend" explanation. Recorded as
  measured-but-not-root-caused rather than forced into an explanation
  the data doesn't support.
- **Flyway**: reproduced the same restart-and-immediately-check sequence
  and found a later log line (written after Flyway completes) visible
  with zero lag — directly contradicting the "docker log buffering
  hadn't caught up" hypothesis. The migration itself is independently
  confirmed real; only why that one check missed it remains genuinely
  unresolved, not fixed by relabeling it a buffering race.
- Neither open question changes the actual finding (the `post_bootstrap`
  fix works, confirmed independent of both).

## Done — Kafka Scenario 1 fixed: real partition targeting, real RTO measured

- `kafka-ha-demo.sh`'s Scenario 1 stopped `kafka-2` unconditionally
  regardless of whether it led any partition the test's traffic used —
  with 3 partitions spread across 3 brokers, a fixed choice risked
  silently testing nothing. It also never measured real RTO, just a
  fixed 5s sleep.
- Now determines the actual target partition via an offset diff around a
  canary write, kills that partition's real current leader, measures RTO
  by polling concurrently with sending traffic.
- **Three real bugs found getting there**: `cluster_state()` hardcoded
  its query target to `kafka-1` — the first run that finally killed the
  actual leader (which happened to be `kafka-1`) queried a dead container
  on every poll, a false "no leader elected" indistinguishable from a
  real failure; Scenario 2's durability check queried the standalone
  `postgres` container, retired earlier that same session, silently
  corrupting its data-loss accounting; fixing that by hardcoding
  `patroni-1` would have reintroduced the exact same bug in a new
  location (caught by Chat before shipping) — routed through Traefik's
  `:55432` entrypoint instead, which introduced its own small bug (TCP
  needs password auth, unlike the local-socket connection), fixed with
  `PGPASSWORD`.
- Real RTO across 3 valid runs, each a genuinely different leader/
  partition combination: **3.7s, 14.0s, 15.5s** — no fixed pattern,
  reported honestly. This is the number the following session's Kafka
  controller-failover investigation retested and ultimately found was
  itself mostly a test-harness JVM-spawn-cost artifact.

## Done — `docs/idempotency-scope.md` written (design only, not yet implemented)

- New doc (Claude Chat) designing an idempotency-key fix for the Stage 7
  finding above: a write that committed server-side with its response
  lost, which a naive client retry would turn into a silent duplicate.
  Deliberately scoped narrower than the retired outbox pattern — this
  protects against duplication from an ordinary transient network
  hiccup, not data loss during a rare bounded outage.
- One factual error caught before it became an implementation directive:
  the proposed `V5__add_idempotency_key_to_readings.sql` collides with
  an already-existing `V5` (the now-retired outbox pattern's own
  migration) — checked the actual migration directory rather than
  assumed. Corrected to `V7`.
- Not implemented this session — that's the following session's main
  thread of work.

## Done — doc review and consolidation

- Reviewed and accepted a Chat consolidation of the Kafka/Redis
  write-ups, catching one real correction along the way: the Kafka RTO-
  variance claim said "two of three runs killed the same broker" — direct
  transcript check found all three killed the same broker, corrected to
  the stronger, more precise finding (two of three also hit the identical
  partition, ruling out "different broker/partition" by construction).
- A real script-bug finding (the `grep -c`/`set -e` interaction from
  Redis Stage 6) got dropped entirely in the same consolidation pass —
  restored, alongside two new lessons from this session (editing a
  script while it's still running; a chaos script's observation point
  getting invalidated by the fault it injects or by unrelated work
  elsewhere).
- The `grep -c`/`set -e` lesson was later found dropped a *second* time
  in a further Chat pass, after already being restored once — restored
  again, confirmed it hadn't just been relocated elsewhere first.

## Next steps (as of end of this session)

- Implement `docs/idempotency-scope.md`'s design (the following
  session's main work).
- Re-execute Postgres Stage 7 after all the intervening Patroni
  bootstrap-hook changes, since the underlying infrastructure had been
  torn down and rebuilt multiple times since it was first verified (done
  same evening, `eb99fba` — 3/3 clean, Run 3 reproduced the same
  phantom-success pattern, confirming the gap was still live).
- `redis-quorum-loss.sh`'s minor restore-step bug still not fixed — low
  priority, carried over again.
