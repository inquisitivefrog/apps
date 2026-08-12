# grid-meter-app — Pinned versions

Checked current as of **August 2026**. All entries are current stable
releases — no alphas/betas/RCs, nothing past its support window. Re-verify
before reuse if it's been more than a few months since this was last
updated.

| Component | Version | Notes |
|---|---|---|
| Java | 25 (LTS) | Current LTS since Sept 2025, supported into the 2030s. Don't use 26 — that's the interim non-LTS release. |
| Spring Boot | 4.1.0 | Built on Spring Framework 7. Requires Java 17+. |
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
| React Router | 8.3.0 | v8 dropped the separate `react-router-dom` package — install `react-router` directly, `BrowserRouter` included in the main export. |
| MUI (`@mui/material`) | 9.3.1 | Verified current on npm Aug 2026. Jumped v7→v9 directly (no v8 line). `@mui/icons-material` tracks the same major. |
| Emotion (`@emotion/react`/`@emotion/styled`) | 11.14.x | Required peer deps for MUI's default styling engine. |
| TanStack Query | 5.101.4 | |
| Vite | 8.2.1 | Paired with `@vitejs/plugin-react` 6.0.5 (uses Oxc, not Babel, for Fast Refresh). |
| TypeScript | 7.0.2 | Current stable (Go-rewrite line). Very recent GA as of this pinning — if it causes editor/tooling friction, falling back to the last 6.x stable is a documented, defensible deviation. |

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
