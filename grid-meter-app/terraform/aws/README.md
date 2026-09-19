# terraform/aws

Provisions the AWS infrastructure `grid-meter-app` runs on in the cloud: a VPC, an EKS cluster
+ managed node group, a managed RDS PostgreSQL instance, and a managed ElastiCache (Valkey)
instance. **Infrastructure only** — the app itself is deployed onto the cluster via
`k8s/deploy-aws.sh` (`kubectl apply`, plus ECR image build/push), the AWS-specific counterpart of
the local `k8s/deploy.sh`/`kind` flow. No ArgoCD/GitOps in this pass; ordinary `kubectl` is enough
for this project's deploy cadence.

See `docs/cloud-deployment-scope.md` for the full per-layer reasoning (why Postgres/Redis are
managed here but Kafka is self-hosted in-cluster identically across every target — `kind`, this,
and the eventual GCP/Azure configs).

## Prerequisites

1. **`terraform/aws/bootstrap/` already applied** — this config's `backend.tf` points at the S3
   bucket that module creates. See `bootstrap/README.md` if that hasn't been done yet.
2. AWS CLI configured with a profile named `grid-meter` (`~/.aws/credentials`/`config`) with
   permissions to create VPC/EKS/RDS/ElastiCache/IAM resources.
3. Terraform >= 1.11.0 (this dev machine runs 1.13.2).
4. `kubectl` installed, for interacting with the cluster once it exists.

## What this creates

| Resource | Sizing | Replaces (locally) |
|---|---|---|
| VPC, 3 AZs, public+private subnets, 1 NAT gateway | — | — |
| EKS cluster + managed node group | 3x `t3.medium`, fixed size (no autoscaling) | The `kind` cluster |
| RDS PostgreSQL | `db.t4g.micro`, single-AZ, 20GB gp3 | Self-hosted Patroni + Consul |
| ElastiCache (Valkey) | `cache.t4g.micro`, single node | Self-hosted Redis + Sentinel |
| ECR (api + frontend repos) | 5-image lifecycle cap each | `kind load docker-image` |
| EBS CSI driver + `gp3`/XFS StorageClass (via `k8s/storageclass-aws.yaml`) | — | `local-path-provisioner` |
| `metrics-server` addon | — | (not present on `kind` either — new) |

Bumped from 2x to 3x `t3.medium` (2026-09-18) after a live deploy found 2 nodes genuinely
overcommitted once `api`'s memory limit was corrected to a realistic value — see
`variables.tf`'s `eks_node_count` for the full reasoning.

Kafka is **not** created here — it stays self-hosted in-cluster (see `k8s/kafka.yaml`), deployed
the same way as every other environment, per `docs/cloud-deployment-scope.md`'s decision that no
cloud offers a truly comparable managed Kafka across all three providers.

**Sizing philosophy**: smallest viable, matching this project's own stated practice of
`terraform destroy` between interview/demo uses (see "Spin-up and teardown" below) — not tuned
for production load.

**Observability is not part of this deployment.** `kube-prometheus-stack`/Loki/Tempo/Alloy (the
Grafana/Loki dashboard demo) is built and validated against the `kind` cluster only — this AWS
deployment demonstrates real Terraform/cloud-native infrastructure provisioning, not the
load+dashboards story. Two deliberately separate tracks; see `docs/cloud-deployment-scope.md`'s
"Two tracks" section. Use `kind` for the load-test/dashboard demo, this for the "I can stand up
real cloud infra with Terraform" demo.

## Spin-up and teardown (interview day)

Designed to go from nothing to a fully working, functionally-verified deployment and back to
zero residual cost in one sitting. **Every real `terraform apply`/`terraform destroy` is run by
you, not Claude Code** — Claude Code's own safety tooling won't run either against real
infrastructure, and destructive/billed operations deserve a human's own hands on them regardless.

### 1. Spin up infrastructure

```bash
cd terraform/aws
terraform init        # only needed if .terraform/ isn't already present
terraform plan -out=tfplan
terraform apply tfplan
```

`bootstrap/`'s S3 state bucket must already exist first (one-time setup, not part of this cycle
— see `bootstrap/README.md`). A full `apply` from clean takes roughly 10-12 minutes, dominated by
the EKS cluster (~8-9 min) and node group (~2 min).

### 2. Deploy the app onto the cluster

```bash
../../k8s/deploy-aws.sh
```

Reads every endpoint it needs (cluster name, ECR URLs, RDS/ElastiCache endpoints) live from
`terraform output` — nothing hardcoded. Builds+pushes `api`/`frontend` images to ECR, points
`kubectl` at the real cluster, applies Traefik/StorageClass/Kafka/api/frontend, generates a fresh
JWT secret and pulls the real RDS password from Secrets Manager, and prints the public load-balancer
hostname once everything's rolled out. Takes several minutes, mostly image build/push and Kafka's
StatefulSet coming up.

**Note**: every run of `deploy-aws.sh` generates a brand-new JWT secret and points at a freshly
re-provisioned RDS/ElastiCache — there is no data carried over between spin-up cycles. Demo
login is always the Flyway-seeded `demo`/`GridMeter!Demo2026`.

### 3. Demo

App is reachable at `http://<the load-balancer hostname deploy-aws.sh printed>`. `kubectl get pods -o wide`,
`kubectl top nodes`/`kubectl top pods` (metrics-server addon) are useful for showing live cluster
state during the walkthrough.

### 4. Tear down the app layer first

```bash
../../k8s/teardown-aws.sh
```

**This step is not optional and must run before `terraform destroy`.** The `traefik-web` Service
(type `LoadBalancer`) and Kafka's 3 PVCs both caused real AWS resources — a load balancer (a
**Classic ELB**, confirmed live 2026-09-18, not the NLB originally assumed — no
`aws-load-balancer-type` annotation is set and this cluster has no AWS Load Balancer Controller
addon, so EKS's in-tree default provider handled it) and 3 EBS volumes — to be provisioned by
Kubernetes itself (the EKS cloud-controller and the EBS CSI driver), not by any Terraform resource
block. Terraform has no idea either one exists and cannot delete them. Skipping this step risks
two real, distinct failure modes, not just one:

- **Orphaned, still-billing resources** `terraform destroy` will never find or clean up (the load
  balancer, the 3 EBS volumes) — exactly the "forgot to shut something down" outcome this whole
  exercise is meant to avoid, since nothing in `terraform destroy`'s own output would ever mention
  them.
- **A hung or failing `terraform destroy`** — AWS refuses to delete a VPC/subnet/security group
  that still has an active ENI attached (which the load balancer has, as long as it exists), so
  destroying the VPC before it's gone can make `terraform destroy` itself fail partway through.

The script deletes the Service, then **polls the real AWS API** (both the `elbv2` and classic
`elb` APIs, since which one applies depends on the cluster's own default) until the load balancer
is actually confirmed gone. It then deletes Kafka's StatefulSet **before** its PVCs — confirmed
live (2026-09-18) that deleting the PVCs first, while the pods still had them mounted, left all 3
stuck in `Terminating` indefinitely (a PVC can't finish deleting, and its EBS volume can't
actually be released, while a running pod still claims it) — then polls until the EBS volumes are
actually confirmed gone too. It will not tell you it's safe to continue if either isn't confirmed
cleared within its 5-minute polling window.

### 5. Destroy the infrastructure

```bash
cd terraform/aws
terraform plan -destroy -out=tfplan-destroy   # review what will actually be removed
terraform destroy
```

Confirmed clean by design, checked live (2026-09-18), not assumed:
- RDS: `skip_final_snapshot = true` — no final snapshot left behind.
- ElastiCache: no `final_snapshot_identifier` set, `SnapshotRetentionLimit: 0` confirmed live —
  no snapshot left behind.
- ECR: both repos have `force_delete = true` (added 2026-09-18, after confirming live that both
  repos already held 6 images each — without this, `terraform destroy` would have failed outright
  on a non-empty repository).
- `bootstrap/`'s S3 state bucket is **deliberately not** touched by this destroy — it has its own
  separate lifecycle (see `bootstrap/README.md`) and costs a few cents/month at most. Seeing it
  still there afterward is correct, not a leftover.

### 6. Confirm no residue (don't just trust "Destroy complete")

Run every check below after `terraform destroy` finishes. All should return empty/zero:

```bash
# EKS cluster gone
aws eks list-clusters --profile grid-meter --region us-west-2 \
  --query "clusters[?@=='grid-meter-app-eks']"

# EC2 instances gone (the 3 worker nodes)
aws ec2 describe-instances --profile grid-meter --region us-west-2 \
  --filters "Name=tag:eks:cluster-name,Values=grid-meter-app-eks" \
            "Name=instance-state-name,Values=running,pending,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId'

# Load balancers gone (should already be confirmed by teardown-aws.sh, double-check here anyway -
# check BOTH APIs, since this resolves to a Classic ELB on this cluster, not an NLB/ALB; the
# elbv2-only check would silently miss a leftover Classic ELB and give a false all-clear)
aws elbv2 describe-load-balancers --profile grid-meter --region us-west-2 \
  --query "LoadBalancers[?contains(LoadBalancerName, 'traefik')]"
aws elb describe-load-balancers --profile grid-meter --region us-west-2 \
  --query "LoadBalancerDescriptions[?contains(LoadBalancerName, 'traefik')]"

# EBS volumes gone (should already be confirmed by teardown-aws.sh, double-check here anyway)
aws ec2 describe-volumes --profile grid-meter --region us-west-2 \
  --filters "Name=tag:kubernetes.io/created-for/pvc/name,Values=kafka-data*" \
  --query 'Volumes[].VolumeId'

# NAT gateway gone
aws ec2 describe-nat-gateways --profile grid-meter --region us-west-2 \
  --filter "Name=tag:Name,Values=grid-meter-app*" "Name=state,Values=available,pending" \
  --query 'NatGateways[].NatGatewayId'

# RDS instance gone
aws rds describe-db-instances --profile grid-meter --region us-west-2 \
  --query "DBInstances[?DBInstanceIdentifier=='grid-meter-app-postgres']"

# ElastiCache replication group gone
aws elasticache describe-replication-groups --profile grid-meter --region us-west-2 \
  --query "ReplicationGroups[?ReplicationGroupId=='grid-meter-app-cache']"

# RDS-managed Secrets Manager secret gone (RDS auto-deletes this with the instance -
# confirm rather than assume, since it's a small but real recurring charge if it survives)
aws secretsmanager list-secrets --profile grid-meter --region us-west-2 \
  --query "SecretList[?contains(Name, 'grid-meter-app')].Name"
```

If any of these return something, **stop and investigate before assuming it's harmless** — this
is exactly the class of thing that quietly keeps accruing cost. `terraform destroy` printing
"Destroy complete" only confirms Terraform-tracked resources were removed; it says nothing about
the load-balancer/EBS-volume class of resource this whole section exists to catch, and running
these checks is the only way to actually know rather than assume.

**Optional second, independent cross-check**: `./check-costs.sh` queries real AWS Cost Explorer
data by service instead of resource-existence APIs. It cannot confirm "zero cost right now" —
Cost Explorer data lags 24-48h, confirmed live 2026-09-18 querying it immediately after a same-day
teardown (it showed a stale picture, missing known real charges from that same day, not zero) —
but re-run a day or two after a teardown, it's a genuinely independent confirmation that costs
actually dropped rather than trusting the same class of API twice.

## Real, checked cost estimate (not a guess)

Every figure below was queried directly against AWS's own Pricing API for `us-west-2`
(2026-09-17/2026-09-18), not looked up in a table or estimated from memory:

| Resource | Rate | Notes |
|---|---|---|
| EKS control plane | $0.10/hr | Flat, identical in every region |
| EKS nodes (3x `t3.medium`) | $0.1248/hr | $0.0416/hr each |
| RDS `db.t4g.micro` | $0.016/hr | Single-AZ |
| ElastiCache Valkey `cache.t4g.micro` | $0.0128/hr | |
| NAT gateway | $0.045/hr | Base rate only — excludes per-GB data processing, which is usage-dependent |
| Load balancer (Classic ELB — confirmed live 2026-09-18, not an NLB as originally assumed) | $0.025/hr | Plus $0.008/GB data processed, usage-dependent — negligible at demo traffic volumes |
| **Total (compute/control-plane only)** | **~$0.324/hr ≈ $7.77/day if left running** | |

Not included above (all small relative to the above, but real): EBS root volumes for the 3 EKS
nodes, Kafka's 3x 12Gi gp3 volumes (~$2.88/mo if left running), RDS's 20GB gp3 storage
(~$2.30/mo), Secrets Manager's per-secret storage fee (~$0.40/mo), and any actual data transfer.
**None of this applies if you follow the spin-up/teardown cycle above** — it only matters if the
stack is left running between uses.

## Explicitly out of scope for this pass

- Observability (`kube-prometheus-stack`, Loki/Tempo/Alloy, Grafana dashboards) — `kind`-only, by
  deliberate choice (see "Observability is not part of this deployment" above).
- A load test run against this specific deployment — `load-tests/*.jmx` has only ever targeted
  Compose/`kind`.
- GCP and Azure equivalents (`terraform/gcp/`, `terraform/azure/`) — per
  `docs/cloud-deployment-scope.md`'s own sequencing, AWS gets built and fully validated first.
- A real live-fire validation of RDS/ElastiCache failover behavior against this specific cluster
  — nothing to fail over to/from has been exercised yet at the time this was written.
