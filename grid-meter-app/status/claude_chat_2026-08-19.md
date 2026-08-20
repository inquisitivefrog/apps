# grid-meter-app — Status: 2026-08-19 (Claude Chat)

Primarily a scoping/decision + review session, with some live troubleshooting.
Two Claude Code commits landed as a result, both pushed to `origin/main`.

Done:

- **Terraform scoping decision**: marked explicitly out-of-scope rather than
  left as a dangling "maybe someday" — no real cloud target exists in this
  project (Compose/`kind` are both local), so there's nothing honest for it
  to provision. Doc language drafted for `architecture.md`'s Deployment
  model section.

- **k8s/`kind` first-slice scope decision**: went with full in-cluster
  (api, frontend, postgres, kafka, redis as plain-YAML Deployments/
  Services, plus Traefik IngressRoute) rather than the earlier
  acknowledge-data-tier-as-out-of-cluster option from the 2026-08-18 log.
  Reasoning: a self-contained `kind create cluster` + `kubectl apply -f
  k8s/` demo is a stronger interview story than depending on the host's
  Compose stack also being up. Observability (`kube-prometheus-stack`,
  in-cluster Alloy/Loki/Tempo) stays explicitly deferred to a follow-up
  slice. Wrote up a full handoff brief (concrete manifest scope, doc-edit
  text, deferred-items list) for Claude Code to work from directly —
  relayed by the user.

- **Docker Desktop troubleshooting** (blocking issue, not project-related
  but blocked all `kind` work until resolved): Docker Engine stuck on
  "Engine stopped" with an "upgrade to 4.8.7" prompt and a highlighted
  "Upgrade Plan" button. Diagnosed as a stale Docker Desktop install (the
  4.8.x version number is from ~2022) rather than an actual licensing
  gate — Docker Personal's free tier is gated by company size/revenue, not
  by `kind` usage, and the "Upgrade Plan" button is a standing upsell
  shown to personal accounts too, not a real blocker. Fix: full reinstall
  via a fresh installer download (not the in-app updater) + sign-in with a
  free personal Docker ID. Resolved — user landed on 4.87.0.

- **`kind` cluster recovery after the Docker Desktop reinstall**: the
  existing `grid-meter` cluster's control-plane container didn't survive
  the Docker Desktop restart cleanly (`kind get kubeconfig` failed —
  container present but not running). Rather than trying to resurrect it,
  did a clean `kind delete cluster` + `kind create cluster` recreate.
  Verified healthy via `kubectl cluster-info dump`: node `Ready`, all
  `kube-system` pods `Running` with 0 restarts.

- **Reviewed `k8s/kind-config.yaml`** once Claude Code added it: confirmed
  it's the standard, low-risk `kind` + ingress-controller pattern
  (single control-plane node, `ingress-ready=true` label, host port 80 →
  container port 80) — matches `kind`'s own documented ingress-nginx
  recipe, adapted for Traefik. Approved as-is. Flagged one open question:
  only port 80 is mapped, not 443 — fine if HTTP-only is the deliberate
  choice (matches Compose), just worth confirming it's intentional rather
  than an oversight.

- **Reviewed live UI validation screenshots** against the fresh in-cluster
  deploy: `/actuator/prometheus` and `/actuator/health` both reachable
  unauthenticated through Traefik as designed; `/login` and `/meters`
  working end-to-end including a real create-through-UI round trip
  (`SN-KIND-UI-1` / `kind-ui-validation-site`, clearly test data). Confirms
  api ↔ Postgres ↔ frontend ↔ Traefik wired correctly in-cluster. Also
  reviewed the full URL reference sheet Code had assembled (frontend
  routes, API routes, unauthenticated ops endpoints) — good raw material
  for `k8s/README.md`.

- **Flagged a validation gap**: the meters flow only proves direct
  Postgres connectivity, not the readings ingestion path (API → Kafka →
  consumer → Postgres/Redis), which is architecturally distinct. Walked
  the user through why the Readings page can't be used for this (by
  design — read-only, no create/edit affordance, matching the immutability
  rule and `ReadingsPage.test.tsx`'s explicit assertion of that), and gave
  Bruno-run and curl-based alternatives (login → token → `POST
  /api/v1/readings`) to exercise the Kafka path directly and confirm the
  reading surfaces back through the read path in the UI.

- **Two commits confirmed landed and pushed** (per user report, both on
  `origin/main`, working tree clean):
  - `5c07d1f` — docs: `architecture.md` updates, decision-doc tightening,
    new `identity.md`
  - `27a080e` — the k8s slice itself: manifests, scripts, status log

Open:

- **Readings/Kafka path not yet confirmed validated** — last item
  discussed this session (how to POST a reading via Bruno/curl since the
  UI won't do it); no confirmation yet that it was actually run against
  the in-cluster stack or that the reading surfaced back through
  `GET /readings`.
- **`k8s/README.md` content unconfirmed** — the URL reference sheet shown
  this session is good raw material for it, but not verified whether it's
  actually been written into the repo (commit `27a080e`'s "scripts" and
  "status log" description doesn't explicitly mention it).
- **Port 443 / HTTPS** — `kind-config.yaml` only maps port 80. Worth an
  explicit one-line confirmation in `k8s/README.md` that this is
  deliberate (HTTP-only, matching Compose) rather than a gap.
- **Observability stack (`kube-prometheus-stack`, in-cluster Alloy/Loki/
  Tempo)** — explicitly deferred to a follow-up slice per this session's
  scope decision, not started.
- Everything else still open from `status/claude_code_2026-08-18.md`
  (real 2-replica spike load-test validation, `frontend-test` CI job not
  yet a required check, GitHub Issues bug-tracking setup) — untouched
  this session, still valid.

Next:

- Confirm the readings/Kafka path (POST a reading via Bruno or curl,
  verify it appears via `GET /readings` and in the UI) to close out full
  data-tier validation for the k8s slice.
- Confirm/finish `k8s/README.md` (prereqs, apply order, how to reach the
  app, teardown, the HTTP-only note) if not already done in `27a080e`.
- Once the slice is fully validated end-to-end, decide on scope/timing for
  the observability follow-up slice.
