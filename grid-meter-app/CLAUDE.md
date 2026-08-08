# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`grid-meter-app` currently has **no application source code** — only docs,
`Dockerfile`s for `api/` and `frontend/`, `docker-compose.yml`, and
`observability/` configs. Treat `docs/architecture.md` and
`docs/api-and-data-model.md` as the spec to implement against, not
aspirational docs to ignore. This directory is also not yet committed to
git (WIP) — don't assume anything under it is tracked.

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

## Dev workflow

`docker compose up` brings up the full stack (Traefik, frontend, api,
postgres, kafka, redis, prometheus, loki, tempo, grafana) with resource
limits already set per service. Scale API replicas with
`docker compose up --scale api=2` — Traefik's Docker provider
auto-discovers and load-balances across them. DB credentials are
dev-only hardcoded (`gridmeter`/`gridmeter`) in `docker-compose.yml`, not
secrets.

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
