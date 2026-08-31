# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`grid-meter-app` currently has docs/,
`Dockerfile`s for `api/` and `frontend/`, `docker-compose.yml`, and
`observability/` configs. Treat `docs/architecture.md` and
`docs/api-and-data-model.md` as the spec to implement against, not
aspirational docs to ignore.

**When scaffolding `api/` or `frontend/` source for the first time, or making
structural choices not already pinned down in the docs (project layout,
initial dependencies, package structure), check in before committing to
them rather than deciding unilaterally.**

Note: this repo's git root is one level up, at the `apps/` workspace
(sibling Java apps live there too), not at `grid-meter-app/` itself.

## What this is

A smart-grid-meter simulation app built to demonstrate SRE/QA capability:
app lifecycle, CI/CD, load testing, and observability. Scope is
intentionally minimal (CRUD + search on meters/readings, no billing or
anomaly detection) so effort goes into infra/observability. Full detail in
@docs/architecture.md and @docs/api-and-data-model.md.

## Stack (pinned — see @docs/tech-stack-versions.md)

Java 25 (LTS) + Spring Boot 4.1.0 (Maven) · React 19.2.8 (npm) · Traefik
3.7.x (single edge tool — routing + load balancing, HAProxy deliberately
excluded) · Kafka 4.3.x (KRaft, no ZooKeeper) · PostgreSQL 18.4 (not 19 —
still beta) · Redis 8.10 · Prometheus/Grafana/Loki/Tempo for
metrics/logs/traces. Whole stack is memory-budgeted to run on a 24GB
MacBook Air — see per-container limits in `docker-compose.yml` before
adding new services. Re-verify versions against
`docs/tech-stack-versions.md`'s update checklist if it's been a while.
Logs shipped via Grafana Alloy (v1.18.1) — not Promtail, which was removed
upstream as of Loki 3.7.3.

## Architectural decisions to preserve

- **Readings are immutable** — no `PUT /readings/{id}`. Corrections are new
  readings, not edits to history. Tests should assert the PUT is rejected,
  not just that it's absent.
- **Pagination is enforced server-side** on all list/search endpoints
  (default `size=20`, max `size=100`), not merely documented — a client
  can't request an unbounded page.
- **Controller → Service → Repository** layering. Controllers stay thin
  (HTTP concerns only); Service owns Kafka producer calls and Redis writes;
  Repository is Spring Data JPA. Don't put business logic in controllers.
- API is versioned under `/api/v1`; `/actuator/health` and
  `/actuator/prometheus` are deliberately unversioned/outside the contract.
- Composite index on `(meter_id, reading_timestamp)` is the dominant query
  shape — keep new reading queries aligned with it rather than adding
  competing indexes.
- App's own k8s manifests (planned, not yet created) should be plain YAML,
  not Helm — Helm is reserved for `kube-prometheus-stack` only.
- **JWT auth gates all of `/api/v1/**`**, including `POST /readings` — no
  endpoint is left open for machine-to-machine ingestion. `/actuator/health`
  and `/actuator/prometheus` remain the sole unauthenticated routes. See
  `docs/architecture.md`'s "Authentication" section for why JWT over
  sessions, why self-issued tokens over an OAuth2 resource server, and the
  access-token-only/no-refresh-token tradeoff. Tests needing an
  authenticated request should log in via `POST /api/v1/auth/login`
  (seed credentials: `demo` / `GridMeter!Demo2026`, Flyway-seeded in
  `V3__create_users_table.sql`) rather than mocking the security layer.
- **Assume any durability/quorum-relevant setting is an undeclared
  default until verified live against the running system.** This project
  has now found eight separate instances of this same gap across its HA
  work — the HikariCP `connection-timeout`, Kafka's `max.block.ms`,
  `delivery.timeout.ms`, `acks`, `unclean.leader.election.enable`,
  Redis's `min-replicas-to-write`, and Postgres's `synchronous_standby_names`
  — every one silently defaulting to "no real guarantee" until someone
  checked the live config (not just a repo grep) and declared it
  explicitly. The 8th instance (Postgres's `synchronous_standby_names`
  *mode* — named standby vs. priority list vs. quorum) is a sharper
  variant worth distinguishing from the other seven: it wasn't merely
  unconfigured, it was a decision `docs/postgres-ha-scope.md` had
  *explicitly flagged in writing as not yet decided*, and Patroni's own
  default (single named-standby, pinned to whichever replica registered
  first) silently closed that exact open question before anyone actually
  chose — resolved to quorum `ANY 1 (*)` only after the gap was noticed
  and the decision deliberately made. Treat this as the standing prior
  for any remaining or future HA work (any new service added later), not
  a coincidence specific to Kafka — and treat an explicitly-flagged
  "not yet decided" note in a doc as no safer than total silence; both
  get silently resolved by someone else's default the moment work
  proceeds without an explicit choice. See `docs/ha-scope.md`,
  `docs/testing-strategy-ha-supplement.md`, `docs/redis-ha-scope.md`, and
  `docs/postgres-ha-scope.md` for the full investigation trail.
- **In chaos/failover test scripts, poll for the actual readiness
  condition — never assume a fixed `sleep N` reflects real convergence
  time.** The same HA testing effort found this exact bug shape three
  independent times: twice in Redis Sentinel testing (a fixed `sleep 8`
  racing Sentinel's replica-discovery poll, and a stale quorum check
  reading ~3s early) and once in `kafka-ha-demo.sh` (a fixed `sleep 8`
  assumed to represent ISR-rejoin time, when actual measured rejoin took
  13–30s — 2 to nearly 4x the assumption, every run). Two of the three
  produced a false or misdiagnosed result; the third produced a correct
  result for the wrong stated reason, hiding a stronger finding
  (`min.insync.replicas=2` providing real margin *during* a slow rejoin,
  not just after). Same sibling pattern as the undeclared-defaults lesson
  above — verify the actual condition, don't trust a plausible-looking
  assumption — applied to test infrastructure rather than production
  config. See `docs/testing-strategy.md`'s "Test-infrastructure lesson"
  section for the full account and the standing guidance for new test
  scripts.

## Dev workflow

`docker compose up` brings up the full stack (Traefik, frontend, api,
postgres, kafka, redis, prometheus, loki, tempo, grafana) with resource
limits already set per service. Scale API replicas with
`docker compose up --scale api=2` — Traefik's Docker provider
auto-discovers and load-balances across them. DB credentials are
dev-only hardcoded (`gridmeter`/`gridmeter`) in `docker-compose.yml`, not
secrets.  A `toolbox` service (nicolaka/netshoot) is available for ad-hoc network
debugging — opt-in via `docker compose --profile debug up -d toolbox`, not
started by default.

**Frontend dev loop**: `docker compose up traefik api postgres kafka redis`
(frontend container intentionally excluded — the Vite dev server replaces
it) + `npm run dev` from `frontend/`. `vite.config.ts`'s dev-server proxy
forwards `/api` to Traefik on `localhost:80`, exercising the same
`PathPrefix(/api)` routing used in production, so no CORS config is
involved either way. Full `docker compose up --build` (frontend container
included) is the path that matches production most closely — use it before
calling a frontend change done.

## Testing strategy (see @docs/testing-strategy.md)

Not yet implemented, but planned layering: JUnit 5 + Mockito (unit,
heaviest investment on the Service layer) → JUnit 5 + Testcontainers
(component, real Postgres/Kafka/Redis) → REST Assured + Bruno (API,
collections in `api/bruno/`) → JMeter `.jmx` (load, `load-tests/`, manual/
nightly only, never blocks a PR — gates are intentionally coarse: error
rate < 1%, p95 latency ceiling).

## CI

GitHub Actions workflows already exist at the `apps/` repo root
(`.github/workflows/claude-code-review.yml`, `claude.yml`) — automated
Claude Code review on PRs touching `grid-meter-app/**`, and an `@claude`
mention responder. No build/test/lint CI pipeline exists yet; one is
planned per @docs/testing-strategy.md (unit + component tests block merge,
API tests block merge after a throwaway env, load tests via
`workflow_dispatch`/nightly and never block).

## Session status log

Per-session status reports (Done/Open/Next) live in `status/` as dated
files, not appended here — keeps this file focused on standing project
instructions rather than growing indefinitely. Naming: `claude_chat_<date>.md`
for sessions run via Claude Chat, `claude_code_<date>.md` for sessions run via
Claude Code. Check the most recent file there before starting a new session.


