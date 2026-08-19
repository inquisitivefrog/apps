# grid-meter-app — k8s first-slice scope & Terraform decision (2026-08-19)

Decisions made in Claude Chat session, relayed via user. Both items were
blocked on user go-ahead per CLAUDE.md's check-in-before-scaffolding
convention — go-ahead given 2026-08-19.

---

## 1. Terraform: mark explicitly out-of-scope

**Decision:** out-of-scope, not deferred-with-no-plan.

**Reasoning:** everything in this project runs locally (Compose for dev,
`kind` for the k8s demo) — there's no real cloud target for Terraform to
provision. Scoping fake infra just to have a Terraform story would be
speculative structure against the project's own minimal-scope ethos.
Leaving it as a vague "maybe someday" is worse than a clean no.

### Doc change — `architecture.md`, end of "Deployment model" section

Add:

```markdown
### Terraform — explicitly out of scope

Considered as a future SRE-demo addition, but not adopted: this project's
entire deployment surface is local (Docker Compose for dev, `kind` for the
k8s demo), so there is no real cloud target for Terraform to provision.
Introducing it would mean inventing infrastructure to justify the tool
rather than the other way around — inconsistent with the project's
minimal-scope ethos elsewhere. Revisit only if a real cloud deployment
target is ever added to this project's actual scope.
```

---

## 2. k8s / `kind` first slice: full in-cluster, plain YAML

**Decision:** all five components in-cluster for slice one — api, frontend,
postgres, kafka, redis — plus Traefik IngressRoute. Observability
(Prometheus/Loki/Tempo/Grafana in-cluster) explicitly deferred to a
follow-up slice.

**Reasoning for going full in-cluster** (rather than the earlier "acknowledge
data tier as out-of-cluster for now" option): the demo's value is "clone,
`kind create cluster`, `kubectl apply -f k8s/`, walk through the manifests"
— self-contained. Requiring the laptop's Compose stack to also be running
undercuts that story and adds a confusing "which environment is this
actually" question in an interview walkthrough. `kind` already spins up and
tears down in under a minute on this hardware (per `architecture.md`'s
existing resource-budget notes), so the extra containers aren't a real cost
concern.

### Concrete scope for Claude Code

**In scope for this slice:**

- `k8s/` directory, plain YAML (no Helm — consistent with existing
  "Helm reserved for `kube-prometheus-stack` only" decision)
- Deployment + Service for: `api` (2 replicas, matching the Compose
  `--scale api=2` story), `frontend`, `postgres`, `kafka` (KRaft mode,
  matching Compose — single broker, no need for a StatefulSet at this
  scope), `redis`
- ConfigMap for non-secret env vars (mirrors `docker-compose.yml`'s
  `GRID_METER_*` passthrough pattern)
- Secret for DB credentials / JWT signing key — even though the Compose
  dev credentials are hardcoded and non-secret, model this properly in k8s
  since "how would you actually do secrets" is a reasonable interview
  question and it costs little to do right here
- Traefik IngressRoute for `/` → frontend, `/api` → api (same path-based
  split as the Compose Traefik config)
- No persistent volumes for postgres/kafka in this slice — ephemeral
  `emptyDir` or no explicit volume (defaults to container filesystem) is
  fine, since `kind` clusters are themselves ephemeral and this isn't
  modeling data durability. Note this as a deliberate simplification in
  `k8s/README.md`, not a silent gap.
- A `k8s/README.md` covering: prerequisites, `kind create cluster`, apply
  order if it matters, how to reach the app (`kubectl port-forward` to
  Traefik, or a `kind` port mapping — pick one and document it), teardown.

**Explicitly deferred to a follow-up slice (do not build now):**

- `kube-prometheus-stack` (Helm) and any in-cluster Prometheus/Grafana/Loki/
  Tempo/Alloy wiring
- Any Terraform (see decision #1 above)
- HPA / resource requests-and-limits tuning beyond what's needed to fit the
  24GB budget — copy the same per-container limits already established in
  `docker-compose.yml` rather than re-deriving them
- CI wiring to deploy to `kind` automatically (the existing CI/CD section
  in `architecture.md` mentions this as a future step; this slice is manual
  `kubectl apply` only)

### Doc change — `architecture.md`, "Deployment model" section

Replace the current one-paragraph `kind` mention with:

```markdown
- **`kind`** (Kubernetes-in-Docker) — the k8s demo for the interview. Spins
  up and tears down in under a minute on this hardware; a full multi-node
  cluster is not realistic on a laptop, and `kind` is an honest, standard
  way to demonstrate real k8s manifests without pretending otherwise.
  First slice is fully in-cluster — api, frontend, postgres, kafka, redis —
  rather than depending on the host's Compose stack for the data tier, so
  the demo is self-contained (`kind create cluster` + `kubectl apply -f
  k8s/`). Observability stack (`kube-prometheus-stack` and in-cluster
  Alloy/Loki/Tempo) is a deferred follow-up slice, not part of this pass.
```

- App's own k8s manifests (Deployment, Service, ConfigMap, Secret) are
  plain YAML, not Helm — this is already stated in `architecture.md` and
  `CLAUDE.md`; no change needed there, just confirming the new scope
  doesn't contradict it.

---

## Handoff note for Claude Code

Point Code at this file plus the existing `docs/architecture.md`,
`docs/tech-stack-versions.md`, and `status/claude_code_2026-08-18.md` for
current repo state. Suggested order:

1. Apply the two `architecture.md` doc edits above.
2. Scaffold `k8s/` per the concrete scope list — manifests first, then
   `k8s/README.md`.
3. Validate end-to-end against a real `kind` cluster (create cluster,
   apply, hit the app through Traefik, confirm meters/readings CRUD works
   against in-cluster Postgres/Kafka/Redis) — same "actually run it, don't
   just trust the plan" discipline as the load-test session on 08-18.
4. Status log as `status/claude_code_<date>.md` per the existing
   convention, including anything that didn't go as planned (the 08-18 log
   is a good model — e.g. the PreProcessor/CSV bug, the `-p` vs `-q` JMeter
   flag bug — don't smooth over friction).
