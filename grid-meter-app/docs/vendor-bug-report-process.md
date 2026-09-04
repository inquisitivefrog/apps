# Vendor bug-report process — recall doc

Short version, for picking this back up after a few days away: **the
evidence lives in `load-tests/vendor-bug-reports/`, the narrative lives in
`docs/`, and this file is the map between them.**

## Why this exists

Moving this project's testing from a single-instance-per-service
configuration to a real HA configuration (3 instances of each service)
surfaced cases where a clustering technology may not behave the way its own
documentation says it should. The first one found was Kafka: unclean leader
election happening despite `unclean.leader.election.enable=false` being
confirmed live, via a code path that doesn't even log with an `UNCLEAN`
label. See `docs/testing-strategy-ha-supplement.md` for the full account.
There's no reason to assume Kafka is the only technology this happens with —
Redis/Sentinel and whichever PostgreSQL clustering package gets selected are
both explicitly expected candidates once their own HA testing starts (see
`docs/ha-scope.md`), which is why the evidence structure is organized
per-technology from the start rather than assuming it stays Kafka-specific.

## Where things live

- **`load-tests/vendor-bug-reports/`** — the evidence archive: one
  subdirectory per suspect technology (`kafka/`, `redis/`, `postgres/`, ...),
  each with a `NOTES.md` run index and a `runs/` directory of raw captured
  evidence (logs, config dumps, JMX counters, script transcripts). Full
  layout convention is documented in
  `load-tests/vendor-bug-reports/README.md` — read that file, not this one,
  for the actual directory-structure rules.
- **`docs/testing-strategy-ha-supplement.md`** (and any future sibling doc
  for Redis/Postgres findings) — the authoritative narrative: the theory,
  the evidence chain, what's ruled out and why, current root-cause status.
  This is where the actual thinking lives. `NOTES.md` files in the evidence
  archive only index runs and link back here — they don't duplicate the
  analysis.
- **Per-technology environment snapshots** — e.g.
  `load-tests/vendor-bug-reports/kafka/docker-compose.kafka-debug.yml` is a
  frozen copy of the exact debug-overlay config used to capture that
  technology's evidence, alongside a version table (Docker, Compose, the
  technology itself, host OS) in that technology's `NOTES.md`. A vendor bug
  report needs exact reproduction conditions, not "whatever the repo looked
  like at the time."

## Resuming after time away — the actual recall steps

1. Open `load-tests/vendor-bug-reports/<technology>/NOTES.md` first. It has
   the filing status (has a ticket been opened yet?), the working theory in
   one paragraph, and a run-by-run table of what's already been captured.
2. Follow its link to the `docs/` narrative doc for the full reasoning
   before assuming you remember it correctly — these investigations involve
   enough nuance (see: the `UNCLEAN`-label-vs-actually-unsafe distinction in
   the Kafka finding) that re-deriving from memory risks getting it wrong.
3. If continuing the investigation, the reproduction scripts live in
   `load-tests/` (e.g. `kafka-unclean-election-dynamic-override.sh` for the
   Kafka finding) and already know to save new evidence into the right
   `runs/` subdirectory automatically — check the script's own header
   comment for prerequisites (e.g. bringing up a debug-logging overlay
   first) before running it.
4. Update the technology's `NOTES.md` run table after any run worth
   keeping, and update the `docs/` narrative doc if the finding changes —
   don't let the two drift out of sync.

## Current status (as of 2026-09-04)

| Technology | Status | Filing status |
|---|---|---|
| Kafka | Active — mechanism confirmed twice (broker-fencing-triggered ELR promotion, unlabeled, not gated by config) | JIRA account requested, pending approval |
| Redis / Sentinel | HA testing closed (all 6 stages, `docs/redis-ha-scope.md`) — no vendor-bug candidate surfaced | N/A |
| PostgreSQL clustering | HA testing closed (Patroni + Consul, all 7 stages, `docs/postgres-ha-scope.md`) — no vendor-bug candidate surfaced | N/A |
