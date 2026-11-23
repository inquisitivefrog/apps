# 2026-11-18 — kind capacity: load shedding, router-level SLI, OOM fixes, alert email

## Done

- **Load shedding at the edge.** Traefik `inFlightReq` caps `/api` at 300 concurrent requests
  (`k8s/ingressroute.yaml`) and answers the rest with an immediate 429. `allowEmptyServices` makes
  a missing api backend return 503 instead of falling through to the frontend as a 405.
- **Availability SLI moved to Traefik's router metric** (`traefik_router_requests_total`,
  `addRoutersLabels`). It counts served, 5xx, shed 429s and "no healthy backend" 503s. Before, a
  total api outage (199,508 503s) showed as 100% availability. Burn-rate alerts, the edge error
  alert, the SLOs dashboard and the Golden Signals shed series all read it. New alert "Edge is
  shedding load"; SHED series fixed red.
- **Resource fixes, each from a measured OOMKill or CPU starvation:** api 1Gi, Traefik 512Mi,
  Tempo 1Gi, CPU requests/limits on api/Traefik/Alloy/Tempo, Loki capped at 1 core (it had peaked
  at 4.9 cores and halved api throughput).
- **Undeclared defaults declared:** Redis command timeout 2s (Lettuce default 60s turned a Redis
  OOM into an api outage via the liveness probe); Kafka heap `-Xmx512m` (image default 1G exceeded
  the 768Mi container limit), kind and Compose.
- Redis/Sentinel no longer at `--loglevel debug`; trace sampling 10% on kind (Compose 100%).
- **Load tests:** every run starts by clearing Redis idempotency keys
  (`clear-idempotency-keys.sh`; ~1.7M leftover keys had OOMKilled all 3 Redis pods). All profiles
  pause `backoff429Ms` (default 1000ms) after a 429.
- **Capacity measured** (`load-tests/README.md`, "Capacity and load shedding on kind"):
  - 100 threads: 2,649/s, p95 56ms. 300 threads: 3,368/s, p95 197ms, 0 errors = measured capacity.
  - 600 threads, no backoff: retry storm, ~14,900 shed/s, successful throughput fell to ~790/s.
  - 600 threads, 1s backoff: ~4,650 successful/s, ~300 shed/s, p95 149ms, no restarts.
- **Alert email:** Grafana emails alerts via Gmail SMTP when the gitignored
  `grid-meter-app/.alert-email.env` exists (`observability/alerting-email/notifications.yml`,
  `deploy-observability.sh`). `info` alerts are muted. Verified end to end with real alerts.
  A contact point with no integrations crash-loops Grafana's provisioning; a mute timing is the
  working way to "show but don't notify".
- Committed and pushed `77f03fe` to `aws-freetier`. GitHub-hosted CI passed. Self-hosted E2E
  failed its pre-flight check because the kind cluster held port 80 (expected; tests never ran).
- aws-core Claude Code plugin moved to the untracked `.claude/settings.local.json`.
- Incident (my mistake): `docker system prune` deleted the stopped datastore-dev kind cluster.
  Backups verified complete; recovery is stage 3 below.

## Current live state (as of session end)

- kind cluster `grid-meter` **stopped** (`docker stop grid-meter-control-plane`), not deleted.
  `docker start grid-meter-control-plane` brings it back. Postgres has no PV, so seeded users
  may be gone; `run.sh` reseeds them.
- No AWS account: green-elephant was disabled by AWS today. No AWS deploy work planned.

## Open / Next

1. Why the Kafka/Redis/Sentinel StatefulSets restarted all pods at once instead of one by one.
2. JVM old-gen heap rule false-alarms after api restarts (6h `predict_linear` over a fresh heap).
3. Grafana bundled Elasticsearch plugin install error (unused plugin).
4. Re-run 600 threads to confirm Tempo at 1Gi survives.
5. Compose Grafana alert email (optional); tail sampling in Alloy (optional, later).
6. Log-pipeline alert; Alloy as a DaemonSet reading node log files.
7. datastore-dev rebuild, stage 3.
8. Multi-tenancy + HMAC pseudonyms + Vault: four decisions pending, scope doc first.
9. Branch: `aws-freetier` vs `main` undecided.
