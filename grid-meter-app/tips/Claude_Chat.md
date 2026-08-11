let’s continue the Claude Code partnership to build a java app.  Do you recall anything or need a refresher?

I have a MacBook Air with 24GB RAM and 20 GPUs.  I have a repository at https://github.com/inquisitivefrog/apps.   The app in question is called grid-meter-app and here is the CLAUDE.md.  We installed all tools chosen and services will be accessed using Docker Desktop for Mac.
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % pwd
/Users/tim/Documents/workspace/java/apps/grid-meter-app
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % cat CLAUDE.md 
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

## Current status (update every session)
Last updated: 2026-08-07

Done: docs, Docker Compose scaffolding, GitHub Actions/Issues, api/ Spring Boot
scaffold (compiles clean, Kafka/Redis/Flyway wired).

Open: Docker Desktop socket bug (github.com/inquisitivefrog/apps/issues/N) blocks
Testcontainers-based tests; docker compose up not yet runtime-validated; frontend/
not started.

Next: validate docker compose up end-to-end, then frontend scaffold.

(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % cat docker-compose.yml 
services:
  traefik:
    image: traefik:v3.7.10
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --api.dashboard=true
    ports:
      - "80:80"
      - "8080:8080" # Traefik dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - grid-meter

  frontend:
    build:
      context: ./frontend
    labels:
      - traefik.enable=true
      - traefik.http.routers.frontend.rule=PathPrefix(`/`)
      - traefik.http.routers.frontend.priority=1
      - traefik.http.services.frontend.loadbalancer.server.port=80
    networks:
      - grid-meter

  api:
    build:
      context: ./api
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/gridmeter
      SPRING_DATASOURCE_USERNAME: gridmeter
      SPRING_DATASOURCE_PASSWORD: gridmeter
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      SPRING_REDIS_HOST: redis
      SPRING_REDIS_PORT: 6379
      JAVA_TOOL_OPTIONS: -Xmx384m
    depends_on:
      - postgres
      - kafka
      - redis
    labels:
      - traefik.enable=true
      - traefik.http.routers.api.rule=PathPrefix(`/api`)
      - traefik.http.routers.api.priority=10
      - traefik.http.services.api.loadbalancer.server.port=8080
    deploy:
      resources:
        limits:
          memory: 512m
    networks:
      - grid-meter
    # Run multiple replicas with: docker compose up --scale api=2
    # Traefik's Docker provider auto-discovers and load balances across them.

  postgres:
    image: postgres:18.4
    environment:
      POSTGRES_DB: gridmeter
      POSTGRES_USER: gridmeter
      POSTGRES_PASSWORD: gridmeter
    volumes:
      - postgres-data:/var/lib/postgresql
    deploy:
      resources:
        limits:
          memory: 512m
    networks:
      - grid-meter

  redis:
    image: redis:8.10
    deploy:
      resources:
        limits:
          memory: 128m
    networks:
      - grid-meter

  kafka:
    image: apache/kafka:4.3.1
    environment:
      # Single-node KRaft mode — no ZooKeeper.
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    deploy:
      resources:
        limits:
          memory: 768m
    networks:
      - grid-meter

  prometheus:
    image: prom/prometheus:v3.11.2
    volumes:
      - ./observability/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    labels:
      - traefik.enable=true
      - traefik.http.routers.prometheus.rule=PathPrefix(`/prometheus`)
      - traefik.http.services.prometheus.loadbalancer.server.port=9090
    deploy:
      resources:
        limits:
          memory: 256m
    networks:
      - grid-meter

  loki:
    image: grafana/loki:3.7.4
    command: -config.file=/etc/loki/local-config.yaml
    deploy:
      resources:
        limits:
          memory: 256m
    networks:
      - grid-meter

  tempo:
    image: grafana/tempo:2.10.0
    command: -config.file=/etc/tempo/tempo.yml
    volumes:
      - ./observability/tempo.yml:/etc/tempo/tempo.yml:ro
    deploy:
      resources:
        limits:
          memory: 256m
    networks:
      - grid-meter

  grafana:
    image: grafana/grafana:13.0.2
    environment:
      GF_AUTH_ANONYMOUS_ENABLED: "true"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Admin
    volumes:
      - ./observability/grafana-datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro
      - grafana-data:/var/lib/grafana
    labels:
      - traefik.enable=true
      - traefik.http.routers.grafana.rule=PathPrefix(`/grafana`)
      - traefik.http.services.grafana.loadbalancer.server.port=3000
    deploy:
      resources:
        limits:
          memory: 256m
    networks:
      - grid-meter

networks:
  grid-meter:

volumes:
  postgres-data:
  grafana-data:
(⎈|N/A:N/A)tim@Timothys-MacBook-Air grid-meter-app % 


