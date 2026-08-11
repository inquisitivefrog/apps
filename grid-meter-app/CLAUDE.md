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

## Current status (update every session)
Last updated: 2026-08-10

Done:
- docs, Docker Compose scaffolding, GitHub Actions/Issues, api/ Spring Boot scaffold
  (compiles clean, Kafka/Redis/Flyway wired).
- docker compose up validated end-to-end — all 11 services healthy (traefik,
  frontend, api, postgres, redis, kafka, prometheus, loki, tempo, grafana, alloy).
- Traefik routing confirmed correct: api at /api/v1 (controllers already mapped
  with full prefix, no stripping needed), grafana at /grafana (sub-path aware via
  GF_SERVER_ROOT_URL + GF_SERVER_SERVE_FROM_SUB_PATH).
- Full observability stack wired and verified with real data in all three signals:
  - Metrics: Prometheus scraping api's /actuator/prometheus, confirmed via
    Grafana Metrics Drilldown (195 metrics).
  - Logs: Alloy (not Promtail — removed upstream as of Loki 3.7.3) tails
    container stdout via Docker socket, ships to Loki. Tomcat access logging
    enabled on api (server.tomcat.accesslog) so HTTP requests are visible, not
    just app startup noise. Verified via real LogQL queries in Grafana Explore.
  - Traces: spring-boot-starter-opentelemetry wired, exporting to Tempo via
    OTLP/HTTP (tempo:4318/v1/traces). Verified — real traces visible in Grafana
    Explore for grid-meter-api, correct spans/durations.
- Fixed a genuine Spring Boot 4.1.0 config quirk: management.otlp.metrics.export.
  enabled=false only takes effect as a Docker Compose environment variable
  (MANAGEMENT_OTLP_METRICS_EXPORT_ENABLED), not when set in application.yml —
  confirmed via A/B test, not assumption. Documented with comments in both files
  pointing to each other so it isn't silently "fixed" back the wrong way.
- netshoot toolbox added (docker compose --profile debug up -d toolbox) for
  ad-hoc network debugging, replacing one-off docker run --rm curlimages/curl
  calls.
- **Docker Desktop / Testcontainers blocker resolved.** Root cause: Docker
  Desktop was updated (after ~7 months idle) to 4.85.0 / Engine 29.6.2, which
  raised the daemon's minimum accepted API version to 1.40. Testcontainers
  1.21.3's bundled docker-java (3.4.2) hardcodes/falls back to API 1.32,
  causing every Testcontainers-backed test to fail at the Docker handshake
  step with BadRequestException (empty-JSON daemon response) — confirmed as a
  known, currently-open upstream bug (testcontainers-java #11235, #11240),
  not a local misconfiguration. Fixed by upgrading to Testcontainers 2.0.5,
  which negotiates the API version properly instead of hardcoding it. This
  was a major-version bump requiring artifact ID renames (junit-jupiter →
  testcontainers-junit-jupiter, postgresql → testcontainers-postgresql,
  kafka → testcontainers-kafka) — a bare version bump alone would NOT have
  worked. Verified: mvn test now runs a real Testcontainers-backed
  GridMeterApiApplicationTests against live Postgres and Kafka containers,
  BUILD SUCCESS.
- Explicit dependencies added to api/pom.xml for logging (logback-classic),
  JSON (jackson-databind), and testing (junit-jupiter, mockito-core) — all
  were already present transitively via Spring Boot starters, but made
  explicit per project preference for discoverability across codebases.
  Verified via mvn dependency:tree — no version conflicts introduced.
- Frontend stack decided (not yet scaffolded): Vite + React + TanStack Query.
  Vite chosen as current standard over Create React App (CRA is unmaintained
  upstream). TanStack Query chosen for its fit with the app's actual shape —
  paginated REST endpoints, Redis-backed caching, upcoming mutations — not
  because it's trendy. Routing and styling approach still undecided.

Open:
- frontend/ still a placeholder (Dockerfile + bare package.json only, no real
  React app). Routing (single view vs React Router) and styling (plain CSS /
  Tailwind / component library) undecided.
- Minor cosmetic warnings surfaced during the Testcontainers fix, none
  blocking: Mockito self-attach deprecation warning (future JDK may require
  it configured as a proper -javaagent), Netty macOS DNS resolver warning
  (io.netty:netty-resolver-dns-native-macos not on classpath — harmless for
  single-node local tests).

Next:
- Scaffold frontend (Vite + React + TanStack Query) — likely handed to Claude
  Code once routing/styling decisions are made, since it's file-generation-
  heavy work rather than a design decision.
- Write real Testcontainers-backed component tests now that the blocker is
  resolved (per docs/testing-strategy.md's planned layering) — using
  Testcontainers 2.0.x package paths (e.g. org.testcontainers.kafka.
  KafkaContainer) from the start, not the pre-2.0 paths.
- Consider addressing Mockito/Netty warnings before they become real breaks
  on a future JDK bump (not urgent).

Note: when reusing/updating docker-compose.yml image tags or Maven
dependencies going forward, verify versions and artifact IDs actually exist/
are current before pinning (hit this repeatedly this session — nonexistent
image tags, a deprecated log-shipping agent, wrong Spring Boot property
names, and a major-version Testcontainers bump that silently needed artifact
renames beyond the version number) — search/verify rather than trust a
plausible-looking version string or property path.


