# Session status — 2026-08-28 (Claude Code)

## Done

- **Stage B outbox-growth test, revised for rigor then run for real.**
  Rewrote `load-tests/outbox-growth-stageB.sh` per feedback before
  running it: longer real pre-outage warmup (90s, not just JMeter's own
  internal warmup), rate/growth calculated only from the steady-state
  tail (skipping the `delivery.timeout.ms` lag before any outbox row
  exists), and a rate-independent bytes-per-row figure as the primary
  output. Ran it: 720s Kafka outage at 2 api replicas.
- **Real finding from that run**: the outbox grew 20→40 rows in the
  first ~2 minutes, then flatlined for the remaining ~10 minutes despite
  Kafka staying down. Root cause, confirmed via the actual JMeter
  response-code timeline: Traefik's active health check (added last
  session, gating on the full `/actuator/health` aggregate) took `api`
  out of rotation once the Kafka health indicator flipped that aggregate
  DOWN — after which requests got Traefik's edge `503` directly, never
  reaching `ingest()`/Kafka/the outbox at all.
- **Fixed the Traefik health-check bug** (real bug, independent of any
  outbox decision): it was taking down `GET /meters`, `GET /readings`,
  and `POST /meters` too — none of which touch Kafka. Retargeted at
  Spring Boot's `/actuator/health/readiness` probe group
  (`management.endpoint.health.probes.enabled`, new in `application.yml`),
  which by default excludes the Postgres/Kafka/Redis indicators. Verified
  live: `GET /meters` now returns `200` through a real Kafka outage;
  `/actuator/health` aggregate still correctly reports `DOWN`. Also
  widened `SecurityConfig`'s actuator matcher to `/actuator/health/**`
  so the readiness sub-path stays unauthenticated for Traefik.
- **Retired the transactional-outbox pattern (Stage A) entirely**, per
  an explicit redo-path scope decision: a lost simulated meter reading
  has no real downstream consequence (no billing, no regulatory record,
  nothing to redo), and an outbox table with no reconciler to drain it
  isn't durability — it's an ever-growing, never-queried table that
  looks like unfinished work. Removed `ReadingOutbox`/
  `ReadingOutboxRepository`, added `V6__drop_reading_outbox_table.sql`
  (a new migration, not an edit to the already-applied `V5` — verified
  live against the real dev Postgres, Flyway history intact), reverted
  `ReadingService.ingest()` to log+counter only, updated
  `ReadingServiceTest`, `kafka-ha-demo.sh`'s scenario-2 interpretation,
  and the "reading delivery failures" alert rule's annotation.
  Documented the full outcome (what was built, what Stage B found, the
  redo-path reasoning, what got retired) in `docs/resilience-scope.md`'s
  new "Outcome (2026-08-28)" section, with the now-moot open decisions
  and testing-implications bullets struck through rather than deleted.
- Full `mvn -B test` suite green after all of the above (confirmed twice
  — one transient full-suite failure from `*ApiIT` mid-restart was
  isolated and shown unrelated to any code change, then a clean re-run
  confirmed).

## What's still standing from this work (not reverted)

- `ReadingsKafkaHealthIndicator` + its component test.
- `reading_delivery_failures_total` counter, the `ERROR` log on delivery
  failure, and the "reading delivery failures" Grafana alert rule —
  the accepted, sufficient signal per the redo-path decision.
- The Traefik readiness-probe fix (independently correct regardless of
  the outbox decision).
- 3-broker Kafka HA (`ha-scope.md`, prior session) and
  `load-tests/kafka-ha-demo.sh`/`watch-alert-rule.sh` — unaffected.

## Done (continued, later same day) — alert reclassification, acks=all fix, KAFKA-19148

- **Reclassified the "Reading delivery failures" alert from incident to
  notice.** Same redo-path reasoning that retired the outbox: a
  permanently-lost simulated reading has no real consequence, so paging
  anyone about it doesn't follow either. Changed `severity: critical` /
  `alert_class: incident` → `severity: info` / `alert_class: notice` in
  `observability/alerting/rules.yml`; updated `ReadingService.java`'s
  comment, `docs/resilience-scope.md`, and `docs/observability-taxonomy.md`
  (§1 cross-reference, §3 entry, summary table). Verified live against
  the running Grafana instance. Committed as `576feb3` (first commit of
  `docs/observability-taxonomy.md`, previously untracked).
- **Cross-referenced `ha-scope.md`/`testing-strategy-ha-supplement.md`
  against the real codebase** (user asked "anything outstanding left to
  implement"). Found one genuinely important, previously-unverified gap:
  **`acks` was undeclared in `application.yml`, silently defaulting to
  the raw Kafka client's `"1"` (leader-only ack), not `"all"`** —
  confirmed by pulling `spring-boot-kafka-4.1.0`'s real sources jar
  (`KafkaProperties.Producer.acks` is `@Nullable` with no default). This
  meant `min.insync.replicas=2` (topic config) was never actually being
  enforced, since that check only fires under `acks=all`.
- **Reproduced the gap live** (`load-tests/kafka-acks-gap-repro.sh`,
  untracked, not yet committed): stopped both followers for a target
  partition, sent a write, got `201` in under a second with only the
  leader holding it. Then killing that leader too surfaced something
  worse than the hypothesis: **a follower with NO copy of the record was
  elected leader anyway** — real unclean leader election despite
  `unclean.leader.election.enable=false` being confirmed genuinely in
  effect (not an oversight — checked live via `kafka-configs.sh`). The
  write survived only by luck (no conflicting write landed on the
  data-less leader before the true leader rejoined).
- **This matches a known, currently-unresolved upstream Kafka bug**:
  **KAFKA-19148** ("Potential Unclean Leader Election in KRaft Despite
  `unclean.leader.election.enable=false`"), reported against 4.0.0/3.9.0
  in KRaft mode (this project runs 4.3.1, also KRaft) — the same
  scenario in ZooKeeper mode does not trigger it. No fix version listed.
  A related, separately-tracked issue (KAFKA-19552) is also still open.
- **Fixed the part this project *can* fix**: declared `acks: all`
  explicitly in `application.yml`, with a comment documenting the full
  finding. Re-verified live: the same under-replicated scenario now
  correctly produces `NOT_ENOUGH_REPLICAS` retries instead of a silent
  accept, and once `delivery.timeout.ms` (120s) exhausts,
  `reading_delivery_failures_total` incremented to `1.0` with the
  matching `ERROR` log — the existing observability path catches it
  correctly. Full `mvn test` suite green after the fix.
- **Measured a clean, uncofounded RTO** (`load-tests/kafka-leader-failover-rto.sh`,
  untracked): stopped only the current leader (not followers), keeping
  quorum/controller-quorum healthy the whole time — **3.7 seconds** to
  elect new leaders across all 3 partitions, first successful write only
  35ms after that, zero data loss confirmed in Postgres. This is the
  number `testing-strategy-ha-supplement.md`'s Failover/RTO test asked
  for.
- **Wrote a dedicated KAFKA-19148 tracking script**
  (`load-tests/kafka-unclean-election-KAFKA-19148.sh`, untracked): talks
  to Kafka directly via `kafka-console-producer.sh` with an explicit
  `acks=1` override, bypassing the Spring app entirely, so a
  reproduction is unambiguously a Kafka/KRaft-level issue rather than an
  artifact of this app's config. Always exits `0` (a tracking script,
  not a merge gate, matching load-tests/'s existing "never blocks a PR"
  treatment) — the printed verdict (REPRODUCED / NOT REPRODUCED THIS
  RUN) is what matters. **First run had a real script bug** (hardcoded
  `docker compose exec -T kafka-1`, which fails once kafka-1 itself is
  one of the stopped brokers — silently no-opped the marked-record
  production step, invalidating that run's "REPRODUCED" verdict). Fixed
  via a `kafka_exec` helper that dynamically execs through whichever
  broker is currently running. **Not yet re-run since the fix** — the
  disk-space incident below interrupted before a clean confirming run
  happened.

## Interrupted: host disk-space emergency (unresolved as of write time)

Mid-way through re-running the fixed KAFKA-19148 script, the host Mac
ran out of disk space entirely (`/System/Volumes/Data`: 460Gi, only
`119Mi` free at the worst point) — every Bash tool call failed with
`ENOSPC`, including trivial ones (`df -h`), since even this tool's own
output-capture file couldn't be written. Diagnosed via the user running
`df -h` / `xcrun simctl runtime list` / `du -sh` on Docker's disk image
directly (I couldn't run anything myself at that point):
- No Time Machine local snapshots to reclaim (`tmutil listlocalsnapshots /`
  was empty).
- 3 iOS Simulator runtimes installed (23.9G total: iOS 26.5, 26.2, 18.6).
  User deleted the oldest (iOS 18.6/22G86, `xcrun simctl runtime delete
  70241CB2-979B-4C8C-957F-D07B33AA679E`) — freed ~3.5GB, confirmed gone
  via `simctl runtime list` afterward (down to 2 runtimes, 15.7G).
- Docker Desktop's `Docker.raw` virtual disk is 27G — not yet addressed;
  Docker Desktop's own Settings → Resources → Advanced → "Reclaim disk
  space" is the recommended next step (safer than touching the file
  directly), not yet done.
- **While checking `docker system df -v`, the user reported Docker
  Desktop itself showing an error and turning off its engine** —
  plausibly the low-disk condition triggering Docker's own protection,
  or a manual choice to free resources while sorting out disk space.
  All Kafka/Docker-dependent work paused at this point, mid-`docker
  system df -v` (backgrounded, task id `bs2dxs958`, harmless to ignore/
  let time out).
- Current state when this file was written: `/System/Volumes/Data` at
  `3.6Gi` free (up from `119Mi`) — Bash tool access confirmed restored,
  but Docker Desktop's engine is off/pausing per the user's last message,
  and the user is about to quit this Claude Code session to `brew
  upgrade` the CLI itself.

## Resumed after disk incident: the fixed script re-run, then the KAFKA-19148 citation itself fell apart

- Disk cleanup (host maintenance, not project code): freed iOS
  DeviceSupport (16G), Xcode DerivedData (11G), unused simulator
  devices, Homebrew/npm/go-build/pip/node-gyp/golangci-lint/browser
  caches (~4G), and Docker's build cache (8.7G, sparse file so it gave
  space back to macOS immediately) — 8.4Gi → 40Gi free, without
  touching Docker volumes (confirmed those hold real data from *other*
  sibling `apps/` projects too — `ecommerce`, `mobile-app-server`'s
  MongoDB shard/replica set, `laravel-feature-lab` — left alone
  deliberately).
- Brought the compose stack up clean, re-ran the fixed
  `load-tests/kafka-unclean-election-KAFKA-19148.sh` for real: **it
  reproduced again**, cleanly this time (dynamic `kafka_exec`, no script
  bug in play) — broker 3 (no copy of the marked record) elected leader
  for partition 0 while broker 2 (the only broker holding it) was down.
  This part is solid: real, repeatable, not a script artifact.
- **But the KAFKA-19148 citation itself doesn't hold up.** Checked the
  live Kafka 4.3.1 release notes (user-provided URL) — no mention of
  19148/19552/any KRaft election fix. Checked the JIRA ticket directly,
  twice, the second time with a more rigorous verbatim-quote-demanding
  prompt specifically because an earlier pass and a separate KAFKA-19552
  source-code question had produced inconsistent AI summaries of the
  same material — both checks agreed: **KAFKA-19148 is Resolved, fix
  version 4.1.0** (this project runs 4.3.1, well past it), and its
  actual mechanism requires an in-flight **partition reassignment**
  (ISR `[1,2]`→`[3,2]` mid-reassignment) — this project's test never
  triggers a reassignment at all. **The citation is a confirmed
  misattribution, not a fluke of one imprecise fetch.**
- **KAFKA-19552** (the doc's other cited ticket) is a live lead, not yet
  confirmed: it describes the KRaft controller's election-trigger logic
  disregarding a *statically*-set broker config in favor of a *dynamic*
  override — reported in the opposite polarity (a static `true` being
  ignored) and for separate broker/controller processes (this project
  runs combined broker+controller nodes). Whether the same mechanism
  explains the *false*-being-ignored direction seen here is unconfirmed.
- **Independent, solid finding along the way**: `docker-compose.yml`
  never declares `unclean.leader.election.enable` at all (confirmed via
  `grep`) — the live broker's effective value comes from Kafka's
  built-in `DEFAULT_CONFIG`, not this project's own static config. Right
  now the effective value (`false`) is correct by coincidence, not by
  declaration — an undeclared load-bearing default, worth fixing
  regardless of how the root-cause chase below resolves.
- **In-progress experiment (interrupted, inconclusive)**: to test the
  KAFKA-19552 hypothesis directly, set
  `unclean.leader.election.enable=false` **dynamically** on the
  `readings` topic (`kafka-configs.sh ... --alter --add-config`,
  confirmed applied — synonym source became `DYNAMIC_TOPIC_CONFIG`, not
  `DEFAULT_CONFIG`), then re-ran the same stop-followers/write/
  stop-leader/restart-followers sequence to see whether a dynamic
  override (vs. the current undeclared default) changes the outcome.
  **The host rebooted again mid-run** (Docker Desktop failed to restart
  cleanly after the previous reboot) — the experiment script (a
  scratchpad path, session-specific, did not survive; reproducible from
  this description if needed) got only as far as stopping the two
  followers and was about to produce the marked record when it was
  killed. **No verdict was reached.**

## Second disk emergency: Docker Desktop's own auto-updater hung and grew `Docker.raw` 27G → 58G

After the second reboot, the user started Docker Desktop; it attempted
an auto-upgrade that hung, and `Docker.raw` grew from 27G to 58G while
stuck — host disk went from the post-cleanup 40Gi free down to **192Mi**,
then **254Mi**, critical enough that this very status-file write
initially failed with `ENOSPC`. User force-quit Docker Desktop, which
stopped further growth but did not reclaim the 58G already written (a
sparse file doesn't shrink just because the writer stopped — needs an
explicit prune/compact, and Docker's daemon isn't necessarily in a
clean state to do that safely right after a hung auto-upgrade).
**Unresolved as of this write.** Options discussed but not yet acted on:
- Try `docker system df` / `docker builder prune -f` again once the
  daemon responds cleanly post-force-quit-and-restart — worked cleanly
  last time (freed 8.7G), but untested against a daemon recovering from
  a hung auto-upgrade specifically.
- **Nuclear option**: delete `Docker.raw` entirely (Docker fully quit)
  — reclaims the full 58G instantly but wipes every local image/
  container/volume, including the sibling-project data this session
  specifically chose to protect earlier (`mobile-app-server`'s MongoDB
  shard set, `ecommerce`, `laravel-feature-lab`, this project's own
  Postgres/Grafana volumes). Explicit user sign-off required before
  ever doing this — not a call to make unilaterally.
- Worth checking whether Docker Desktop has a version pinning/
  auto-update-disable setting, to stop this from recurring on the next
  launch.

## `Docker.raw` resolution: deleted entirely, third disk emergency this session

Wi-Fi off didn't hold as the fix — after Wi-Fi was re-enabled, Docker
Desktop's engine got stuck in a shutdown loop (couldn't cleanly stop,
plausibly because the disk was too full for it to write its own
shutdown state — a genuine chicken-and-egg deadlock: can't reclaim disk
via the CLI without a responsive daemon, can't get a responsive daemon
without disk headroom). Host disk hit **126Mi**, then tool calls started
failing on the harness's *own* output-capture file (`ENOSPC` on a
`/private/tmp/.../tasks/*.output` path) — fully blocked from running
anything for several turns.

**Resolution**: user force-quit Docker Desktop (successful), then
deleted `~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw`
directly (`rm Docker.raw`) with explicit sign-off given the
consequence — **wipes every local Docker image/container/volume**, not
just this project's. User's explicit call: "i don't care about the
state of other apps. i developed those last year as experiments" —
`ecommerce`, `mobile-app-server` (MongoDB shard/replica set), and
`laravel-feature-lab`'s data is gone, deliberately, not by accident.
**Result: 58Gi free**, tools confirmed working again.

**Consequence for this project specifically**: `grid-meter-app`'s own
Postgres and Grafana volumes are gone too — next `docker compose up`
starts genuinely fresh (Flyway migrations re-run from scratch, fine for
a demo app with seed-data migrations; Grafana dashboards/alert rules
reprovision from `observability/` configs, not from volume state). The
3-broker Kafka cluster is gone too, which **simplifies** one open item:
the interrupted dynamic-config experiment's leftover
`unclean.leader.election.enable` override on the `readings` topic no
longer exists to clean up — a fresh topic will be created on next
startup with no leftover state to check for.

**Root cause note for next launch**: Docker Desktop's auto-updater
hanging (not the disk itself) is what started this cascade. Re-enabling
Wi-Fi before relaunching risks the same hang recurring — worth checking
Docker Desktop's Settings → Software Updates for a way to defer/disable
auto-update before the next launch, rather than relying on toggling
Wi-Fi again.

## Next steps on resume

1. Relaunch Docker Desktop carefully — check Settings → Software
   Updates for an auto-update opt-out before trusting it to start
   cleanly with Wi-Fi on. Re-check `df -h /System/Volumes/Data` stays
   stable (not silently climbing again) once it's up.
2. `docker compose up -d` — expect a genuinely fresh stack (empty
   Postgres, fresh Kafka cluster, fresh Grafana). Confirm Flyway
   migrations run clean and the app comes up healthy before assuming
   parity with before.
3. Declare `unclean.leader.election.enable=false` explicitly in
   `docker-compose.yml` (the undeclared-default finding — still valid
   and still worth fixing regardless of cluster state being fresh).
4. Re-run the dynamic-config experiment cleanly (now against a fresh
   topic, no leftover state) to get an actual verdict: does a *dynamic*
   `unclean.leader.election.enable=false` override change the outcome
   vs. the default? Decisive test for whether KAFKA-19552's mechanism
   (opposite polarity from its reporter, but same code path) explains
   the unclean election seen here.
5. Based on that verdict, correct `testing-strategy-ha-supplement.md`'s
   Finding 2: remove the KAFKA-19148 citation (confirmed wrong —
   Resolved in 4.1.0, wrong mechanism — verified via two independent,
   increasingly rigorous JIRA fetches plus the live 4.3.1 release
   notes), and either cite KAFKA-19552 (if the experiment confirms it)
   or state honestly that the cause is reproducible but not
   conclusively identified (if ruled out). Don't write the
   originally-proposed "sentinel test" pointing at KAFKA-19148 — that
   citation is wrong and shouldn't become permanent test infrastructure.
6. Decide what to commit: `application.yml`'s `acks: all` fix, the 3
   untracked `load-tests/*.sh` scripts, the `docker-compose.yml` default
   fix, and (pending user sign-off, same as other Claude-Chat-authored
   docs) the corrected `testing-strategy-ha-supplement.md` narrative.
7. `docs/cross-project-lessons.md` still has an unrelated pending edit
   from earlier k8s observability work (pre-dates today's Kafka work) —
   still not committed, still not this session's to resolve unprompted.

## Open / not started (carried over, still accurate)

- Circuit breaker build-order decision (Resilience4j vs. deferring) —
  gated on checking the `resilience4j-spring-boot4` BOM gap, not yet
  done.
- k8s Kafka HA follow-up slice (`k8s/kafka.yaml` → 3-broker StatefulSet)
  — still open, not started.
- Remaining `docs/*.md` files from Claude Chat awaiting direction:
  `testing-strategy-ha-supplement.md` (now has real answers to record —
  see above), `cloud-deployment-scope.md`.
- Trend-alert design (scoped as separate work earlier, not started).
