# grid-meter-app — Status: 2026-08-10 (Claude Chat)

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
