# grid-meter-app — k8s (`kind`) demo

First slice, per `docs/k8s-terraform-decisions-2026-08-19.md`: everything the
app needs runs in-cluster (api, frontend, postgres, kafka, redis, Traefik),
so this is fully self-contained — no dependency on the host's Docker
Compose stack. Observability (`kube-prometheus-stack`, in-cluster
Alloy/Loki/Tempo) is a follow-up slice on top of this — see "Observability
follow-up slice" below — deployed via a separate script since it needs
Helm, which the first slice doesn't.

## Prerequisites

- Docker Desktop running
- `kind` (`brew install kind`) and `kubectl` (`brew install kubectl`)
- `api/` and `frontend/` build cleanly (`docker compose build api frontend`
  works, if you want to sanity-check first)

## Deploy

```
./k8s/deploy.sh
```

This builds `grid-meter-api:kind` / `grid-meter-frontend:kind` from the same
Dockerfiles Compose uses, creates the `grid-meter` `kind` cluster (or reuses
it if already up), loads both images into it (`kind` can't pull images that
only exist in the host's local Docker — no registry is involved), and
applies every manifest in dependency order. See "Apply order" below for why
that order matters and what running the `kubectl apply` steps by hand looks
like.

Once it finishes, the app is reachable at **http://localhost** — same URL
as `docker compose up`, via `kind-config.yaml`'s port mapping (see below),
not a port-forward you need to keep running in a separate terminal.

## Apply order (why it matters)

1. **`traefik-crds.yaml`, then `traefik-rbac.yaml`** — `IngressRoute` is a
   Traefik-defined Custom Resource, not a built-in Kubernetes kind. The API
   server has to know about it (the CRD) before anything can reference it,
   which is why `ingressroute.yaml` has to apply *after* this, not as part
   of one blind `kubectl apply -f k8s/` directory sweep — files in that
   directory aren't guaranteed to apply in a dependency-safe order (`kubectl
   apply -f DIR` goes alphabetically, and `ingressroute.yaml` sorts before
   `traefik-crds.yaml`).
2. **`traefik.yaml`** — the controller itself, so it's up and watching for
   `IngressRoute` objects by the time one exists.
3. **`configmap.yaml`, `secret.yaml`** — referenced by every Deployment
   below via `configMapKeyRef`/`secretKeyRef`.
4. **`postgres.yaml`, `kafka.yaml`, `redis.yaml`** — the data tier `api`
   depends on. Not strictly required to apply before `api.yaml` (Kubernetes
   Services resolve by DNS name regardless of pod readiness, and `api`'s
   Deployment has a readiness probe that will just fail until Postgres is
   actually reachable), but applying data tier first means fewer
   crash-loop restarts while everything settles.
5. **`api.yaml`, `frontend.yaml`**.
6. **`ingressroute.yaml`** — now that the CRD (step 1) and the controller
   (step 2) both exist.

`deploy.sh` runs exactly this sequence. `kind-config.yaml` is deliberately
never part of any `kubectl apply` — it's a `kind create cluster --config`
input, not a Kubernetes manifest (`kubectl apply -f k8s/` would error on it
if you ran that as a raw directory sweep, since `kind: Cluster` isn't a real
API kind).

## How the app is reached: `kind` port mapping, not `kubectl port-forward`

`kind-config.yaml` maps the kind node's port 80 to the host's port 80
(`extraPortMappings`), and `traefik.yaml`'s Deployment binds `hostPort: 80`
with a `nodeSelector`/`toleration` pair that lands its pod on that exact
node (the `ingress-ready=true` label kind's own docs use for the same
pattern with ingress-nginx). Net effect: `http://localhost/...` reaches
Traefik directly, matching Docker Compose's URL exactly, with no
`kubectl port-forward` command to leave running in a spare terminal for the
whole demo.

## Vendored Traefik manifests

`traefik-crds.yaml` and `traefik-rbac.yaml` are Traefik's own official
install manifests for the v3.7 line (matching the version already pinned in
`docs/tech-stack-versions.md`), fetched via
`scripts/fetch-traefik-k8s-manifests.sh` and committed here rather than
referenced by URL — so `kubectl apply -f k8s/...` doesn't depend on live
internet access at demo time. Re-run that script only if the Traefik
version pin changes.

## Secret management: what's real here vs. what a production setup needs

`secret.yaml`'s values are hardcoded plaintext, committed to git — fine at
this project's dev-only scope (the exact same values are already
hardcoded in `docker-compose.yml`), but worth being explicit that this is
**not** how a real deployment would inject credentials. A production setup
would keep the DB password and JWT signing key out of git entirely, using
one of: a cloud provider's secret manager (e.g. AWS Secrets Manager, GCP
Secret Manager) synced in via the External Secrets Operator; Sealed
Secrets (encrypts the value so the *encrypted* form is what's safe to
commit); or HashiCorp Vault with the Vault Agent Injector. Any of those
swaps `secret.yaml` for a reference to an external source instead of
inline `stringData` — worth naming in an interview as the actual answer
to "how would you do this for real," even though this project doesn't
implement it.

## Deliberate simplifications

- **No PersistentVolumeClaim for postgres/kafka** — ephemeral, writing to
  the container's own filesystem layer. `kind` clusters are themselves
  ephemeral, so this isn't modeling real data durability either way; not a
  silent gap, a deliberate scope cut for this slice (see
  `docs/k8s-terraform-decisions-2026-08-19.md`).
- **Everything in the `default` namespace** — the vendored
  `traefik-rbac.yaml`'s `ClusterRoleBinding` hardcodes
  `namespace: default` for the Traefik `ServiceAccount`; using a custom
  namespace would mean patching a vendored third-party file. One less
  concept to explain in an interview walkthrough, too.
- **No Traefik dashboard exposed** — Compose exposes it on `:8080`
  separately from the `web` entrypoint; this slice's `IngressRoute` only
  covers `/` and `/api`/`/actuator`, matching the app itself. Skipped here
  as out of scope for "the app is reachable," not a placeholder for a
  future add.

## Teardown

```
./k8s/teardown.sh
```

Deletes the `grid-meter` `kind` cluster and only that — `kind delete
cluster` doesn't touch the separate `docker-compose.yml` stack if that's
also running.

## Observability follow-up slice

```
./k8s/deploy-observability.sh
```

Run after `./k8s/deploy.sh` (assumes the first-slice app is already up).
Needs `helm` (`brew install helm`) in addition to the first slice's
prerequisites — the only piece of this project's k8s manifests installed
via Helm, per `CLAUDE.md`'s "Helm reserved for `kube-prometheus-stack`
only" rule.

### Design: one unified Prometheus + Grafana, not two

`kube-prometheus-stack`'s bundled Prometheus scrapes **both** cluster/node
metrics (node-exporter, kube-state-metrics, the API server — all bundled by
the chart) **and** the app itself (`api` via `servicemonitor-api.yaml`,
`traefik` via a static `additionalScrapeConfigs` entry, since the vendored
`traefik-rbac.yaml` stays hand-edited as little as possible). Its bundled
Grafana is the **only** Grafana in the cluster — the app's existing
dashboard, alert rules, and Loki/Tempo datasources are layered into it
rather than running a second, separate Grafana+Prometheus pair. Two
independent stacks would be simpler to reason about in isolation, but
means two redundant Prometheus/Grafana pairs competing for the same tight
~7.75GiB Docker Desktop VM budget — not worth it for a single-tenant demo
cluster.

Alertmanager is disabled (`alertmanager.enabled: false`) — this project's
alerting is Grafana-managed (`observability/alerting/rules.yml`, the same
Grafana-native `apiVersion: 1` rule format reused verbatim here), not
Prometheus-rule-file-plus-Alertmanager, so it has no job to do.

Installed into the `default` namespace, not the usual `monitoring`
convention — consistent with this project's existing "everything in
`default`" simplification for the app's own manifests, and it avoids
cross-namespace `extraConfigmapMounts`/`ServiceMonitor` matching for no
real benefit here.

### Reusing the same source files as Compose, not duplicating them

`deploy-observability.sh` generates ConfigMaps directly from
`observability/tempo.yml`, `observability/alerting/rules.yml`, and
`observability/dashboards/grid-meter-overview.json` at deploy time
(`kubectl create configmap --from-file=...`), so k8s and Compose share one
source of truth instead of two YAML/JSON copies drifting apart. The
dashboard ConfigMap is labeled `grafana_dashboard: "1"` for the chart's
sidecar to auto-discover; alert rules use `grafana.extraConfigmapMounts`
instead, since this chart version's grafana subchart has a
`sidecar.dashboards` and `sidecar.datasources` but **no** `sidecar.alerts`
(confirmed via `helm show values`, not assumed) — `extraConfigmapMounts`
statically mounts the same file Compose's volume mount points at.

Loki/Tempo datasources are added via `grafana.additionalDataSources` in
`kube-prometheus-stack-values.yaml` (a plain Helm values list, no
ConfigMap needed); the Prometheus datasource is auto-configured by the
chart itself.

`observability/alloy-k8s.river` is a **separate** file from `alloy.river`
(the Compose config), not a variant applied via templating — Compose
discovers containers via the Docker socket (`discovery.docker`), which has
no equivalent in a kind cluster (no Docker socket exposed to pods,
containerd not dockerd manages the node). The k8s version uses
`loki.source.kubernetes`, which reads pod logs straight from the
Kubernetes API server — the same path `kubectl logs` uses — needing only
RBAC (`alloy.yaml`'s ClusterRole/ClusterRoleBinding for `pods`,
`pods/log`), no hostPath mount onto `/var/log/pods`. That's also why it
runs as a single-replica Deployment rather than a DaemonSet: log
collection isn't node-local here, it's centralized via API calls, and this
project's `kind` cluster is single-node anyway.

### Real bugs found validating this against a live cluster (not just applying and trusting it)

- **River's comment syntax is `//`, not `#`.** `alloy-k8s.river`'s
  explanatory header comment used `#` (shell/YAML style) and crash-looped
  the Alloy pod with a parse error on every restart — River is
  HCL-derived, not shell-like, despite superficially resembling both.
- **`ServiceMonitor.spec.selector` matches a Service's `metadata.labels`,
  not its `spec.selector`.** `api.yaml`'s Service had a `spec.selector:
  {app: api}` (for pod routing) but no `metadata.labels` at all —
  `servicemonitor-api.yaml`'s `matchLabels: {app: api}` silently matched
  nothing, no error anywhere, the target just never appeared in
  Prometheus's target list. Fixed by adding the same label to
  `metadata.labels`, which is a genuinely separate field from
  `spec.selector` despite the easy-to-assume-they're-linked naming.
- **`hostPort` + the default `RollingUpdate` strategy deadlock a
  single-node cluster.** `traefik.yaml`'s pod binds `hostPort: 80`,
  exclusive per node; `kind-config.yaml`'s `ingress-ready` label only
  lands on one node. The default rolling-update strategy tries to schedule
  the *new* pod before killing the *old* one, which can never succeed when
  both want the same host port on the only eligible node (`kubectl
  describe pod` showed `FailedScheduling: didn't have free ports for the
  requested pod ports`) — this would recur on every future change to
  `traefik.yaml`'s pod template, not just the one that surfaced it. Fixed
  with `strategy: {type: Recreate}`.
- **The chart's default Grafana version (13.2.0) doesn't match this
  project's pin (13.0.2, `docs/tech-stack-versions.md`) and crash-looped
  independently of resource contention.** 13.2.0's newer "apiserver"
  bootstrap path (registering `dashboard.grafana.app`,
  `folder.grafana.app`, `playlist.grafana.app`, etc. as separate
  multi-second steps) pushed real boot time well past the chart's default
  liveness-probe budget (60s delay + 10×10s failures ≈ 160s) — confirmed
  via `kubectl describe pod`'s exit code 137 and reproduced identically
  with the Compose stack fully stopped, ruling out resource contention as
  the cause before concluding it was a real version/timing issue. Fixed by
  pinning `grafana.image.tag: 13.0.2` (restoring version parity with
  Compose, which was already worth doing anyway) plus extending the
  liveness probe's `initialDelaySeconds`/`failureThreshold` as
  defense-in-depth for this specific laptop-shared-CPU environment.

### An honest, self-healing characteristic left as-is, not chased away

A truly cold `kind create cluster` run (fresh image pulls, nothing cached
— re-tested deliberately after the fixes above, tearing the cluster down
and rebuilding from scratch rather than trusting the already-live,
already-patched cluster) hit one further restart: Grafana got as far as
`"finished to provision alerting"` and `"starting to provision
dashboards"` before `"Database locked, sleeping then retrying (5)
(SQLITE_BUSY)"` — the sidecar containers polling Grafana's own
provisioning-reload API concurrently with Grafana's own boot-time
provisioning, both hitting the embedded SQLite DB at once — got
interrupted by the liveness probe's SIGTERM before the retry could
finish, then converged to a stable `3/3` on the very next restart with no
further intervention. `deploy-observability.sh`'s Helm `--wait --timeout`
was bumped from 5m to 8m so a genuinely cold run doesn't get reported as
failed while this plays out, but the restart itself was left as a
documented, real, self-healing characteristic of a cold multi-container
boot rather than tuned away — it doesn't block the deploy, and chasing it
to zero restarts would mean guessing at SQLite lock-retry internals for a
demo cluster that already recovers on its own.

### Verified live, not just deployed

`kubectl port-forward` to Prometheus, Loki, and Grafana, after generating
real traffic against the app:

- Prometheus: `serviceMonitor/default/grid-meter-api/0` and the static
  `traefik` job both `up`.
- Loki: log streams present for `api` (2, one per replica), `frontend`,
  `postgres`, `kafka`, `redis`, `tempo`, `alloy` — plus cluster-internal
  pods (`kindnet`, `local-path-provisioner`) Compose's Docker-socket-based
  Alloy config never had a way to see, a real (if secondary) benefit of
  the Kubernetes-API-based discovery approach.
- Grafana: `Grid Meter API — Overview` (the app dashboard) provisioned
  alongside `kube-prometheus-stack`'s own bundled cluster dashboards
  (Kubernetes namespace/pod/node views, Node Exporter, CoreDNS, etcd) in
  the same instance; all 4 alert rules present with their
  `alert_class: incident` labels intact; Loki and Tempo datasources
  resolve correctly; the dashboard JSON's only datasource reference
  (`uid: prometheus`) matches the chart's auto-configured Prometheus
  datasource UID exactly.

### Resource budget

Per-container memory limits in `kube-prometheus-stack-values.yaml` mirror
the same budget-conscious approach as `docker-compose.yml` and the first
k8s slice: Prometheus 512Mi, Grafana 256Mi, the Prometheus Operator 256Mi,
kube-state-metrics 128Mi, node-exporter 64Mi; `loki.yaml`/`tempo.yaml`/
`alloy.yaml` reuse the exact same limits as their Compose counterparts
(256Mi/256Mi/128Mi). No Alertmanager, per the design note above.

### Deliberate simplifications (this slice)

- **No CPU limits, memory only** — matches every other resource block in
  this project's k8s manifests and `docker-compose.yml`.
- **Grafana access is `kubectl port-forward` only**, not wired into the
  existing `IngressRoute` — this slice's `IngressRoute` only covers `/`
  and `/api`, matching the app itself; adding a third path would mean
  either fighting `traefik.yaml`'s existing routes or introducing path
  rewriting, neither of which earns its keep for a demo. A production
  setup would put this behind real authentication anyway, not an
  `IngressRoute` tweak.
