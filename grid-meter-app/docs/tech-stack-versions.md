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
| Grafana | 13.0.0 | |
| Loki | 3.7.4 | |
| Tomcat | Managed by Spring Boot | Don't pin manually — let the Spring Boot 4.1 parent POM manage the embedded Tomcat version. |

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
