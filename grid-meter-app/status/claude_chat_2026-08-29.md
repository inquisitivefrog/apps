# grid-meter-app — Status: 2026-08-29 (Claude Chat)

Continuation of the multi-node HA effort — Kafka and Redis passes are
both fully closed (see `docs/testing-strategy-ha-supplement.md` and
`docs/redis-ha-scope.md`'s "Outcome" sections). This session opened and
began the Postgres/Patroni pass per `docs/postgres-ha-scope.md`.

## Done

- **Postgres Stage 0 (Consul quorum in isolation)**: PASS, 3/3 clean.
  Found and fixed 3 real bugs on day one, all recognizable instances of
  bug *categories* already established during Kafka/Redis testing
  (readiness-check timing confusion, missing abort-guards, a fail-open
  tooling dependency) — not repeats of the same bugs, new instances of
  the same lesson shapes in genuinely new infrastructure. Verified with
  certainty (not assumed) that none of the 3 counted clean passes
  predate the timing-check fix — checked actual saved transcripts by
  name rather than trusting the tally. Full evidence:
  `load-tests/vendor-bug-reports/postgres/NOTES.md`.
- **Postgres Stage 1 (config audit)**: confirmed `synchronous_standby_names`
  is undeclared/empty — the **7th** confirmed instance of the
  undeclared-durability-default pattern across this project's whole HA
  effort (Hikari, `max.block.ms`, `delivery.timeout.ms`, `acks`,
  `unclean.leader.election.enable`, Redis's `min-replicas-to-write`, now
  this). The other three checked settings (`wal_level`,
  `max_wal_senders`, `max_replication_slots`) are also undeclared but
  correctly *not* treated as failures — their defaults are already
  adequate at this project's scale.
- **Topology decision confirmed**: 1 primary + 2 replicas (not 1), same
  reasoning as Redis's resolved equivalent question — 1 replica gives
  zero margin after a single promotion.
- **Patroni deployment model written up in full** (`docs/postgres-ha-scope.md`,
  new section): process topology (Patroni supervises Postgres directly,
  not a separate sidecar — 1:1 with Postgres node count), image choice
  (recommended: purpose-built `patroni[consul]` image over Zalando's
  Spilo, for the same minimal-scope reasons already applied elsewhere),
  node discovery (solved cleanly via Consul service registration — no
  static IP list needed, closing the IP chicken-and-egg problem
  discussed earlier in this project's planning), and client
  write-routing (flagged as a **real open risk, not a settled
  mechanism** — Traefik's Consul Catalog TCP routing is confirmed
  technically capable, but its default behavior load-balances across
  *all* healthy instances of a service, not just the primary; needs
  either Consul tag-based routing or a primary-only health check before
  Stage 2, not assumed to "just work").
- **Resource budget re-measured**: ~3.42 GiB baseline, ~4.33 GiB headroom
  — `ha-scope.md`'s original "~8.2–8.9 GiB, exceeds ceiling" estimate now
  looks overly pessimistic given Redis's real (lighter than estimated)
  footprint. **Not yet fully resolved** — needs one more re-measurement
  once Stage 2 actually stands up the full Postgres+Patroni+Consul
  topology together.
- **Consul 1.20.1 pinned** in `docs/tech-stack-versions.md`.
- `docs/postgres-ha-scope.md` fully updated to reflect all of the above —
  Stage 0 and Stage 1 results embedded, topology and Patroni-deployment
  decisions written up, resource-budget section revised. Not yet
  reviewed/approved by the user — was mid-review when this session
  ended.
- `docs/testing-strategy.md` and `CLAUDE.md` also updated this broader
  effort (prior session) with the fixed-sleep-vs-active-polling standing
  lesson (3 confirmed instances: 2 Redis, 1 Kafka) — unrelated to
  tonight's Postgres work specifically, but worth knowing both docs
  changed recently if diffing against an older checkout.

## Open

- **Client write-routing verification** (Traefik Consul Catalog +
  Patroni primary/replica role tagging) — flagged as needing a spike or
  early-Stage-2 check before assuming it works; not yet attempted.
- **`synchronous_standby_names` mode** (named standby vs. priority list
  vs. quorum `ANY n (...)`) — explicitly not yet decided; flagged as
  part of Stage 1's fix, not yet done.
- **Postgres image choice** (purpose-built vs. Spilo) — recommended but
  not yet confirmed/committed to.
- **Resource budget** — re-measured once already (Stage 0, Consul-only),
  needs a second re-measurement once the full topology exists (Stage 2).
- Stages 2–6 of `docs/postgres-ha-scope.md`'s test plan — not started.
  Given this pass's own doc explicitly expects "more stages, not fewer"
  than Kafka/Redis due to added complexity (external consensus store,
  synchronous-replication block-on-unavailable behavior, real
  split-brain risk worse than anything found in Redis), budget real time
  here — don't assume this pass moves at the same pace the Redis pass
  did once real failure testing starts.
- `docs/postgres-ha-scope.md`'s latest edits (this session) have not yet
  been read back by the user — start next session by confirming the doc
  reads correctly before Claude Code proceeds to Stage 2.

## Next

1. User reviews tonight's `docs/postgres-ha-scope.md` updates.
2. Resolve the two still-open Stage 1 sub-decisions (`synchronous_standby_names`
   mode, Postgres image choice) before Stage 2 building starts.
3. Spike/verify the Traefik + Consul Catalog primary-routing mechanism
   specifically — this is the one piece of the deployment model with a
   confirmed real gap between "technically possible" and "known to work
   correctly here."
4. Proceed to Stage 2 (stand up the full topology, verify logging live
   before any failure testing — same sequencing discipline as Kafka and
   Redis) once the above are settled.
