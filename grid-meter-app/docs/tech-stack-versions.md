# grid-meter-app — Pinned versions

Checked current as of **August 2026**. All entries are current stable
releases — no alphas/betas/RCs, nothing past its support window. Re-verify
before reuse if it's been more than a few months since this was last
updated.

| Component | Version | Notes |
|---|---|---|
| Java | 25 (LTS) | Current LTS since Sept 2025, supported into the 2030s. Don't use 26 — that's the interim non-LTS release. |
| Spring Boot | 4.1.0 | Built on Spring Framework 7. Requires Java 17+. |
| Node.js | 24 (LTS) | Active LTS, confirmed via nodejs.org release schedule Aug 2026 (supersedes v22 Maintenance LTS; v26 is the current non-LTS line, entered "Current" status May 2026). Pinned in CI (`actions/setup-node@v7`, `node-version: "24"`). The local dev machine may run a different Node (e.g. an odd-numbered "Current" release like 25.x) without issue day-to-day, but jsdom's `engines` field (used by the frontend test tier) is picky about exact ranges — if `npm install` prints an `EBADENGINE` warning for jsdom, that's this mismatch, not a real problem; treat Node 24 as the version of record and reach for it if anything actually breaks. |
| React | 19.2.8 | |
| Traefik | 3.7.x | |
| Apache Kafka | 4.3.x | KRaft-only line — no ZooKeeper. |
| PostgreSQL | 18.4 | v19 is still in beta — do not use for this project. |
| Redis | 8.10 | Open source again under AGPLv3 as of the 8.0 line, after the 2024 RSAL/SSPL relicensing. |
| Grafana | 13.0.2 | |
| Loki | 3.7.6 | |
| Alloy | v1.18.1 | Replaces Promtail (removed upstream as of Loki 3.7.3). Unified agent for logs/metrics/traces; config in River language, not YAML. |
| Tomcat | Managed by Spring Boot | Don't pin manually — let the Spring Boot 4.1 parent POM manage the embedded Tomcat version. |
| JJWT (`io.jsonwebtoken`) | 0.13.0 | Verified current on Maven Central Aug 2026. Not part of any Spring BOM — pinned explicitly, same as Awaitility below. Use `jjwt-api`/`jjwt-impl`/`jjwt-jackson`, not the legacy single `jjwt` artifact. |
| Spring Security | Managed by Spring Boot | `spring-boot-starter-security`, parent-POM-managed like every other starter — resolves to 7.1.0 under Boot 4.1.0. |
| Testcontainers | 2.0.5 | Major-version bump from the 1.x line — required to negotiate the Docker daemon API version properly after a Docker Desktop update raised the minimum accepted version (see the 2026-08-10 status log). Artifact IDs changed with the bump: `testcontainers-junit-jupiter`, `testcontainers-postgresql`, `testcontainers-kafka`, not the old bare `junit-jupiter`/`postgresql`/`kafka`. |
| Awaitility | 4.3.0 | Polls for async state (Kafka → consumer → Postgres/Redis) in component tests instead of `Thread.sleep`. Not part of any Spring BOM — pinned explicitly. |
| REST Assured | 5.5.2 | JVM-native black-box HTTP test DSL — see `docs/testing-strategy.md`'s "API tooling" section for the shared-base-class two-tier design (embedded `*ApiComponentTest` via Surefire + black-box `*ApiIT` via Failsafe). |
| Groovy (`groovy`/`groovy-xml`/`groovy-json`) | 4.0.32 | Pinned as direct test-scope dependencies to win Maven's nearest-wins mediation over rest-assured 5.5.2's transitive pull of Groovy 5.0.6, which rest-assured doesn't support yet ([rest-assured/rest-assured#1846](https://github.com/rest-assured/rest-assured/issues/1846)) — symptom was a `NullPointerException` in Groovy's `ClosureMetaClass` on GET/PUT calls. |
| `maven-failsafe-plugin` | 3.5.6 | Managed by `spring-boot-starter-parent`; just needed activating (an execution binding `integration-test`/`verify` to the `*ApiIT` classes) to run the black-box tier separately from Surefire's `*ApiComponentTest`. |
| Apache JMeter | 5.6.3 | Confirmed still current stable Aug 2026 (last real release Jan 2024). Runs natively on the host (`brew install jmeter`), not containerized — see `architecture.md`'s resource budget notes. Test plans in `load-tests/`. **Must run under Java 21, not this project's pinned Java 25** — JMeter 5.6.3's bundled Groovy/ASM (used for the JSR223 scripts in `load-tests/common/`) fails with `Unsupported class file major version 69` under Java 25, discovered via an actual failed CI run, not assumed. Homebrew's own formula hardcodes `JAVA_HOME` to `openjdk@21` for this exact reason, which is why it never reproduced locally; `grid-meter-app-load-test.yml`'s `setup-java` step is pinned to 21 to match. |
| Bruno CLI (`@usebruno/cli`) | 4.0.0 | `npm install -g @usebruno/cli`, host-native like JMeter above — not a project dependency, so not in any `package.json`. Runs `api/bruno/`'s collection headlessly (`bru run --env local`) for local verification; the Bruno *app* (GUI) is the primary intended way to use the collection interactively, per `docs/testing-strategy.md`. |
| React Router | 8.3.0 | v8 dropped the separate `react-router-dom` package — install `react-router` directly, `BrowserRouter` included in the main export. |
| MUI (`@mui/material`) | 9.3.1 | Verified current on npm Aug 2026. Jumped v7→v9 directly (no v8 line). `@mui/icons-material` tracks the same major. |
| Emotion (`@emotion/react`/`@emotion/styled`) | 11.14.x | Required peer deps for MUI's default styling engine. |
| TanStack Query | 5.101.4 | |
| Vite | 8.2.1 | Paired with `@vitejs/plugin-react` 6.0.5 (uses Oxc, not Babel, for Fast Refresh). |
| TypeScript | 7.0.2 | Current stable (Go-rewrite line). Very recent GA as of this pinning — if it causes editor/tooling friction, falling back to the last 6.x stable is a documented, defensible deviation. |
| Vitest | 4.1.10 | Frontend unit/component test runner. Wired into `vite.config.ts`'s `test` block rather than a separate config file, reusing the same Vite plugins. |
| React Testing Library (`@testing-library/react`) | 16.3.2 | |
| `@testing-library/jest-dom` | 7.0.1 | Adds DOM matchers (`toBeInTheDocument`, etc.) to Vitest's `expect`, imported in `src/setupTests.ts`. |
| `@testing-library/user-event` | 14.6.4 | |
| jsdom | 30.0.1 | Vitest's `test.environment`. `engines` wants Node `^22.22.2 \|\| ^24.15.0 \|\| >=26.0.0` — see the Node.js row above for why this can print a harmless `EBADENGINE` warning locally. |
| `netty-resolver-dns-native-macos` | 4.2.15.Final (managed transitively) | Test-scope only, classifier `osx-aarch_64` (matches this project's pinned arm64 MacBook Air). Silences a Netty warning ("Can not find ... MacOSDnsServerAddressStreamProvider ... fallback to system defaults") that only fires when the JVM runs directly on macOS — i.e. only during `mvn test` on this dev machine. The real app always runs inside a Linux container (Compose/`kind`), so this dependency has no effect there and doesn't belong outside test scope. |
| `maven-dependency-plugin` | Managed by `spring-boot-starter-parent` | Its `properties` goal resolves `mockito-core`'s jar path into a build property, used by `maven-surefire-plugin`'s `argLine` to load Mockito as a real `-javaagent` instead of letting its inline-mock-maker self-attach at runtime (a JDK-deprecated pattern Mockito itself warns about on every test run otherwise). |

## Deliberately excluded

| Component | Reason |
|---|---|
| HAProxy | Redundant with Traefik, which handles both routing and load balancing. Dropped to avoid overlapping edge tools. |
| Envoy | Earns its place in service-mesh setups (Istio/Linkerd); out of scope for a single-app project. |
| OpenSearch | Considered for both search-over-app-data (unnecessary — Postgres indexes cover it) and log aggregation (Loki chosen instead, for RAM footprint and native Grafana integration). |
| Zookeeper | Removed by Kafka's KRaft mode (default since Kafka 4.0). |

## Update checklist

Before reusing this table on a future date:

1. Re-check each project's release page / `endoflife.date` entry.
2. Confirm no version below has reached end-of-life.
3. Confirm no version above is a beta/RC (check `postgresql.org`,
   `spring.io/blog`, etc. directly rather than relying on cached knowledge).
