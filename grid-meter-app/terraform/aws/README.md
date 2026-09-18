# terraform/aws

Provisions the AWS infrastructure `grid-meter-app` runs on in the cloud: a VPC, an EKS cluster
+ managed node group, a managed RDS PostgreSQL instance, and a managed ElastiCache (Valkey)
instance. **Infrastructure only** — the app itself is deployed onto the cluster the same way it
is locally, via `k8s/deploy.sh` (`kubectl apply`), just pointed at this cluster's kubeconfig
instead of `kind`'s. No ArgoCD/GitOps in this pass; ordinary `kubectl` is enough for this
project's deploy cadence.

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
| EKS cluster + managed node group | 2x `t3.medium`, fixed size (no autoscaling) | The `kind` cluster |
| RDS PostgreSQL | `db.t4g.micro`, single-AZ, 20GB gp3 | Self-hosted Patroni + Consul |
| ElastiCache (Valkey) | `cache.t4g.micro`, single node | Self-hosted Redis + Sentinel |

Kafka is **not** created here — it stays self-hosted in-cluster (see `k8s/kafka.yaml`), deployed
the same way as every other environment, per `docs/cloud-deployment-scope.md`'s decision that no
cloud offers a truly comparable managed Kafka across all three providers.

**Sizing philosophy**: smallest viable, matching this project's own stated practice of
`terraform destroy` between interview/demo uses (see "Teardown" below) — not tuned for
production load.

## A real gap worth knowing about before this hits a genuinely fresh EKS cluster

`k8s/kafka.yaml`'s `volumeClaimTemplates` deliberately leaves `storageClassName` unset, so it
picks up whichever StorageClass a cluster marks as its own default (`local-path-provisioner` on
`kind`). **GKE and AKS both auto-mark a default StorageClass; EKS 1.30+ does not** (confirmed
2026-09-11, see `docs/cloud-deployment-scope.md`'s "Gating read-through" section) — a PVC with no
`storageClassName` will fail to bind on this cluster until one exists. This config does **not**
yet create/mark a default StorageClass — do that (via `kubectl` after the cluster exists, e.g.
applying the AWS EBS CSI driver's `gp2`/`gp3` StorageClass with the
`storageclass.kubernetes.io/is-default-class: "true"` annotation) before running `k8s/deploy.sh`
against this cluster, or Kafka's pods will sit `Pending`.

## Usage

```bash
cd terraform/aws
terraform init      # already run once this session; safe to re-run
terraform plan       # review before applying - last full plan: 35 to add, 0 errors
terraform apply
```

Then point `kubectl`/`k8s/deploy.sh` at the real cluster:

```bash
terraform output -raw kubeconfig_update_command | bash
```

Retrieve the RDS master password (auto-generated into Secrets Manager, never in Terraform state
or any file in this repo):

```bash
aws secretsmanager get-secret-value \
  --secret-id "$(terraform output -raw rds_master_user_secret_arn)" \
  --profile grid-meter --query SecretString --output text
```

## Real, checked cost estimate (not a guess)

Every figure below was queried directly against AWS's own Pricing API for `us-west-2`
(2026-09-17), not looked up in a table or estimated from memory:

| Resource | Rate | Notes |
|---|---|---|
| EKS control plane | $0.10/hr | Flat, identical in every region |
| EKS nodes (2x `t3.medium`) | $0.0832/hr | $0.0416/hr each |
| RDS `db.t4g.micro` | $0.016/hr | Single-AZ |
| ElastiCache Valkey `cache.t4g.micro` | $0.0128/hr | |
| NAT gateway | $0.045/hr | Base rate only — excludes per-GB data processing, which is usage-dependent |
| **Total (compute/control-plane only)** | **~$0.257/hr ≈ $6.17/day ≈ $188/mo if left running** | |

Not included above (all small relative to the above, but real): EBS root volumes for the 2 EKS
nodes, RDS's 20GB gp3 storage (~$2.30/mo), Secrets Manager's per-secret storage fee
(~$0.40/mo), and any actual data transfer.

## Teardown

```bash
terraform destroy
```

Per `docs/cloud-deployment-scope.md`'s own stated practice: `terraform destroy` between
interview/demo uses rather than leaving this running continuously — the project's own
Terraform-provisioned nature makes clean teardown/rebuild a real, demonstrable capability, not
just a cost-saving afterthought. `bootstrap/`'s S3 bucket is deliberately *not* torn down by this
- it has its own separate lifecycle (see `bootstrap/README.md`).

## Explicitly out of scope for this pass

- The default-StorageClass gap noted above — needs its own `kubectl` step before first real use.
- Wiring `k8s/deploy.sh`/`configmap.yaml` for the AWS target specifically (real RDS/ElastiCache
  endpoints, `SPRING_PROFILES_ACTIVE=cloud`, skipping `postgres.yaml`/`redis.yaml`/
  `sentinel.yaml`) — needs this config's real outputs to exist first; tracked as its own
  follow-up.
- GCP and Azure equivalents (`terraform/gcp/`, `terraform/azure/`) — per
  `docs/cloud-deployment-scope.md`'s own sequencing, AWS gets built and fully validated first.
- A real live-fire validation of RDS/ElastiCache failover behavior against this specific cluster
  — nothing to fail over to/from has been exercised yet at the time this was written.
