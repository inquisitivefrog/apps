# grid-meter-app — k8s (`kind`) demo

First slice, per `docs/k8s-terraform-decisions-2026-08-19.md`: everything the
app needs runs in-cluster (api, frontend, postgres, kafka, redis, Traefik),
so this is fully self-contained — no dependency on the host's Docker
Compose stack. Observability (`kube-prometheus-stack`, in-cluster
Alloy/Loki/Tempo) is a deferred follow-up slice, not part of this pass.

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
