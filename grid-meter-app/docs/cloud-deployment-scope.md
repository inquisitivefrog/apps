# grid-meter-app — Cloud deployment scope (multi-cloud, Terraform)

## Why this doc exists

Reverses two prior "explicitly out of scope" decisions — Terraform in
`architecture.md` and TLS/port 443 in `identity.md` — both of which named
"a real externally-reachable deployment target" as their own trigger for
revisiting. That trigger has now fired: the goal is real Terraform
knowledge demonstrated across AWS, GCP, and Azure, with the app runnable
independently of the laptop so it's viewable during an interview at any
time (the laptop remains a second, complementary deployment target — see
"Two tracks," not a replaced one).

## Two tracks, not a replacement

Laptop-based deployment (Docker Compose + `kind`, per `architecture.md`
and `k8s-terraform-decisions-2026-08-19.md`) stays exactly as scoped. This
project now deliberately serves two purposes at once, not one superseding
the other:

- **Local (laptop)** — self-host everything, including the HA mechanisms
  scoped in `ha-scope.md` (Patroni + etcd/Consul for Postgres, Sentinel
  for Redis, multi-broker KRaft for Kafka), built and operated by hand.
  Purpose: hands-on re-familiarization with these tools after time away
  from infra-focused work. Actually standing up and breaking a Patroni
  cluster teaches things a managed RDS failover event never will.
- **Cloud (AWS / GCP / Azure)** — real Terraform-provisioned
  infrastructure, running independently of the laptop, viewable in an
  interview via already-applied state. Purpose: demonstrate Terraform
  fluency and cloud-native judgment — including knowing *when not* to
  reinvent a mechanism a mature managed service already solves well.

These two tracks produce a genuinely stronger interview answer together
than either alone: *"I built Patroni myself to understand exactly what a
managed Postgres failover does under the hood, then used RDS for the
actual cloud deployment — reproducing that mechanism in production when
AWS/GCP/Azure already run it at a scale I can't match isn't rigor, it's
ego."* Depth and judgment in one sentence.

## Decision: per-layer cloud strategy — managed where mature, self-hosted where deliberate

- **PostgreSQL — managed** (RDS for PostgreSQL / Cloud SQL for PostgreSQL
  / Azure Database for PostgreSQL). All three are genuinely comparable:
  real managed automated failover, native read-replica support — directly
  enabling the writer/reader star topology and writer-node trend alert
  already scoped in `testing-strategy-ha-supplement.md`, without
  hand-building Patroni in production.
- **Redis — managed** (ElastiCache for Redis / Memorystore for Redis /
  Azure Cache for Redis). Reasonably symmetric across all three, built-in
  automatic failover, low operational risk either way.
- **Kafka — self-hosted, deliberately.** This is the one layer this
  project intentionally does *not* reach for a managed service, and it's
  worth stating as a decision, not a gap: managed Kafka isn't actually
  symmetric across the three clouds. AWS has MSK (genuine managed Kafka).
  GCP has no first-party managed Kafka — the practical option is Confluent
  Cloud via the marketplace, a third-party dependency, not a native
  primitive. Azure's Event Hubs is Kafka-*protocol*-compatible but a
  materially different product underneath, not real Kafka. "Managed Kafka
  everywhere" would mean three different services with different
  operational models, undermining the parallel-structure goal. Self-
  hosting the same multi-broker KRaft cluster already scoped for the
  laptop in `ha-scope.md` inside each cloud's managed Kubernetes
  (EKS/GKE/AKS) instead produces the *identical* Kafka deployment artifact
  everywhere — the same manifests running on `kind`, EKS, GKE, and AKS
  alike.
  - This also demonstrates a specific, real, and namable SRE skill:
    recognizing when a chosen technology hasn't yet been folded into a
    given cloud's managed-service catalog — a genuinely common situation
    in fast-moving infra — and self-hosting it competently (VMs, k8s
    pods, or containers) rather than being blocked by "there's no managed
    option" or forcing an ill-fitting substitute (Event Hubs standing in
    for real Kafka semantics it doesn't actually provide).

## Generalizable principle: self-host + hand-instrument when the managed layer hasn't caught up

The Kafka decision above isn't a one-off — it's a specific instance of a
repeatable pattern worth naming explicitly, since it's a real, recurring
situation in infrastructure work: **a technology worth adopting is often
ahead of any given cloud's managed-service catalog**, sometimes
permanently for a niche tool, sometimes just until the provider catches
up. The competent response is the same every time: self-host it (VM, k8s
pod, or container — whichever fits), then hand-build whatever
observability doesn't come for free, rather than waiting on the provider
or forcing an ill-fitting managed substitute.

This generalizes well beyond Kafka. A few illustrative cases, at
different points on the maturity spectrum, without any of them being
in scope for this project:

- **Blockchain nodes** (`bitcoind`, `geth`) — no serious cloud-managed
  option exists for running a real public-chain node; self-hosting is the
  norm, not a workaround. The easier half here is that the ecosystem
  mostly ships its own Prometheus exporters already (`geth` natively,
  well-maintained `bitcoind` exporters exist); the harder half is
  logs — chain reorgs, peer churn, mempool pressure aren't structured for
  parsing out of the box, so shaping them into something Loki-queryable
  is genuinely hand-built work, similar in kind to what Alloy already
  does for this project's container stdout.
- **AI/ML serving** — SageMaker/Vertex AI/Azure ML cover mainstream
  frameworks, but a brand-new serving stack (a fresh inference engine, a
  newly-published architecture) is typically ahead of what any managed
  offering supports, forcing self-hosted GPU VMs or a GPU-enabled k8s node
  pool — the same shape as the Kafka gap, just with hardware instead of a
  broker. Observability is almost entirely hand-built here: hardware-level
  GPU utilization has decent tooling (NVIDIA's DCGM exporter), but
  model-level metrics that actually matter operationally — tokens/sec,
  queue depth, time-to-first-token — usually don't exist until someone
  writes the exporter.
- **Quantum computing** — a genuinely different case worth distinguishing
  rather than treating as a third instance of the same pattern: quantum
  *hardware* can't be self-hosted at all (IBM Quantum, Braket, Azure
  Quantum are the only ways to touch real qubits). What's actually
  self-hostable is the classical *simulator* layer (Qiskit Aer, Cirq) for
  algorithm development, or a newer SDK an aggregator hasn't onboarded
  yet — a substitution of classical approximation for hardware access,
  not a workaround for a missing managed wrapper around the same
  underlying thing.

**The concrete, learnable technique underlying all of these**: when a
self-hosted tool doesn't speak Prometheus's exposition format natively,
write the exporter yourself — a small HTTP endpoint that reads whatever
internal state the tool already exposes (an admin API, a metrics socket,
structured or unstructured logs) and reformats it as
`metric_name{labels} value`. This is a bounded, well-understood skill, not
a research problem, and it's the same underlying move this project's
Kafka decision demonstrates at a smaller, already-scoped scale — worth
naming explicitly in an interview as a repeatable capability, not a
one-time trick that happened to apply to Kafka.



Recorded so scaffolding choices don't assume the wrong baseline:

- **AWS** — real production experience, but predates Fargate: EC2 + S3,
  then ECS (pre-Fargate). Comfortable with core compute/storage
  primitives; EKS specifically and Fargate are newer ground.
- **GCP** — prior experience with both Kubernetes and Terraform, but
  day-to-day infra management was typically UI-driven rather than
  CLI/HCL-first. Real familiarity with the concepts, less muscle memory
  with `terraform apply` as the primary interface.
- **Azure** — least familiar of the three; treat as most likely to need
  extra explanation of primitive names/equivalents (see mapping table
  below).
- **Kafka on AWS specifically** — no hands-on MSK experience; prior AWS
  messaging experience is SQS/SNS, not Kafka. Doesn't change the
  self-hosted-Kafka decision above (self-hosting sidesteps needing to
  learn MSK's operational model to hit the same deployment goal), but
  worth knowing going in.

## Primitive mapping (AWS / GCP / Azure)

| Concern | AWS | GCP | Azure |
|---|---|---|---|
| Managed Kubernetes | EKS | GKE | AKS |
| Managed PostgreSQL | RDS for PostgreSQL | Cloud SQL for PostgreSQL | Azure Database for PostgreSQL |
| Managed Redis | ElastiCache for Redis | Memorystore for Redis | Azure Cache for Redis |
| Managed Kafka (not used — self-hosted instead, see above) | MSK | *(no native option — Confluent Cloud via marketplace)* | Event Hubs *(Kafka-protocol-compatible only, not real Kafka)* |
| Terraform state backend | S3 + DynamoDB (locking) | GCS | Azure Storage (Blob) |
| Public entry / TLS | ALB or NLB in front of in-cluster Traefik | Google Cloud Load Balancing in front of in-cluster Traefik | Azure Application Gateway / Load Balancer in front of in-cluster Traefik |

## Ingress: Traefik stays the constant across all three clouds

Rather than replacing Traefik with each cloud's native ingress controller,
Traefik remains the in-cluster Ingress controller on EKS/GKE/AKS alike —
the same role it already plays in the `kind` first slice per
`k8s-terraform-decisions-2026-08-19.md`. This is the one piece of the
routing story that stays identical across all three clouds *and* the
laptop. Each cloud's native load balancer sits in front of it purely for
public IP assignment and TLS termination at the edge — the standard
real-world pattern (cloud L4/L7 LB → in-cluster ingress controller), not
a replacement of the existing routing decision.

## TLS: reversed from `identity.md`

Real external deployment needs real TLS now — a genuine network path
(the public internet) exists between clients and this app for the first
time, which is exactly the condition `identity.md` named as its own
trigger for revisiting.

**Recommended approach:** cert-manager + Let's Encrypt, issuing/renewing
certs against the in-cluster Traefik ingress. This is the one part of the
TLS story that can be genuinely identical across all three clouds despite
the "separate configs" philosophy elsewhere, since ACME-based issuance
doesn't depend on any cloud-specific primitive. Each cloud's own
managed-cert service (ACM, Google-managed certs, Azure App Service certs)
remains a valid alternative if a cloud-native LB ever terminates TLS
directly instead of the in-cluster ingress — a case-by-case call once
each cloud's LB setup is actually built, not something to settle now.

### `identity.md` doc edit

Replace the "TLS / port 443: not needed for this project" section with:

```markdown
## TLS / port 443

**Reversed 2026-08-27** — see `docs/cloud-deployment-scope.md`. Real
external cloud deployment (AWS/GCP/Azure) is now an explicit project
goal, which is the exact trigger this section originally named for
revisiting the no-TLS decision. Local Docker Compose / `kind` deployment
remains HTTP-only (no real network path exists there for TLS to protect).
Cloud deployments terminate TLS via cert-manager + Let's Encrypt at the
in-cluster Traefik ingress, consistent across all three providers.
```

## Terraform: reversed from `architecture.md`

### `architecture.md` doc edit

Replace the "Terraform — explicitly out of scope" section with:

```markdown
### Terraform — multi-cloud deployment (AWS, GCP, Azure)

**Reversed 2026-08-27** — see `docs/cloud-deployment-scope.md` for the
full scope. Real cloud deployment (interview-portable, running
independently of the laptop) is now an explicit project goal. Separate
Terraform configurations per provider — `terraform/aws/`,
`terraform/gcp/`, `terraform/azure/` — designed with parallel structure
from the outset rather than a single abstracted multi-cloud codebase, so
each provider's own idioms stay legible rather than flattened into a
lowest-common-denominator abstraction (same reasoning already applied to
plain-YAML k8s manifests over Helm). Managed PostgreSQL and managed Redis
per provider; Kafka self-hosted identically across all three (see
`docs/cloud-deployment-scope.md` for why). Local Docker Compose/`kind`
deployment is unaffected and remains a fully separate, still-maintained
track.
```

## Directory structure

```
terraform/
  aws/      # RDS, ElastiCache, EKS, S3+DynamoDB backend
  gcp/      # Cloud SQL, Memorystore, GKE, GCS backend
  azure/    # Azure Database for PostgreSQL, Azure Cache for Redis, AKS, Azure Storage backend
```

Each directory gets its own `README.md`, `variables.tf`, and state
backend — separate per provider, consistent naming and structure across
all three for legibility, matching the "why this shape" framing already
used for `k8s/` in `k8s-terraform-decisions-2026-08-19.md`.

## Sequencing

"Design for all three from day one" is satisfied by establishing the
shared directory structure, naming conventions, and README shape across
all three immediately — it does not require building and validating all
three simultaneously, which would be hard to debug and easy to get wrong
in three places at once. Recommend building and fully validating **AWS
first** (closest match to real prior experience), then replicating the
established pattern to GCP, then Azure — each subsequent provider
benefiting from whatever the first pass gets wrong.

## Cost awareness

Nothing in this project has cost real money before now — the laptop stack
has no ceiling beyond hardware already owned; every cloud resource does.

- Check each provider's current free-tier limits before relying on them
  (RDS/Cloud SQL/Azure DB each have some free-tier allowance, though
  limited; managed-Kubernetes control-plane pricing differs by provider —
  AKS's control plane is free, EKS charges a flat hourly fee regardless of
  free tier, GKE includes one free zonal cluster per billing account).
- `terraform destroy` between interview uses rather than leaving three
  clouds' infrastructure running continuously — the project's own
  Terraform-provisioned nature makes clean teardown/rebuild a real,
  demonstrable capability worth mentioning directly in an interview, not
  just a cost-saving afterthought.
- Cloud providers periodically run SRE/architect-targeted free-credit
  programs (AWS Activate, Google Cloud for Startups, Microsoft's
  equivalent) — worth checking current offers before assuming full retail
  pricing, since these change often enough that they shouldn't be assumed
  from memory.

## Revisit note on `ha-scope.md`

The "revisit only if a real externally-reachable deployment target is
added" trigger already named in `ha-scope.md`'s edge/observability-tier
section (and in `identity.md`'s TLS section) has now fired via this doc.
This does not change the *local* HA scope decision itself — Kafka-first,
self-hosted, Redis/Postgres deferred — the local track keeps its own
independent purpose (hands-on re-familiarization, see "Two tracks" above)
regardless of what the cloud track does with managed services.
