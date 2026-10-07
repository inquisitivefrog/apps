# --- Shared / provider ---

variable "aws_region" {
  description = "AWS region to deploy into. Repointed 2026-10-06 from this project's usual us-west-2 to us-east-2 - confirmed live via a real ec2:DescribeVpcs/s3:CreateBucket probe that account 184375956348 (the newer, free-tier/credits-program account this now targets) has an AWS Organizations SCP (arn:aws:organizations::979700392224:policy/o-ehxoc2g98d/service_control_policy/p-72raajd7, applied by a separate org/payer account this project has no IAM visibility into - likely the credits program's own management account) that explicitly denies EC2/S3 operations in us-east-1 and us-west-2, but allows us-east-2. Not something to assume carries to any future third account - re-verify live if this ever points somewhere new."
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to authenticate with (see ~/.aws/credentials). Repointed 2026-10-06 to the 'grid-meter-freetier' profile (account 184375956348) - see backend.tf for why. The original 'grid-meter' profile (account 084375569056) is left configured and unused, not deleted, in case that account is needed again."
  type        = string
  default     = "grid-meter-freetier"
}

variable "project_name" {
  description = "Short project identifier, used to name/tag resources."
  type        = string
  default     = "grid-meter-app"
}

# --- VPC / networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets/nodes across. 3 matches this project's existing Kafka topologySpreadConstraints (k8s/kafka.yaml), which already assumes real zone spread exists to schedule against."
  type        = number
  default     = 3
}

# --- EKS ---

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane. Checked live via `aws eks describe-cluster-versions` (2026-09-17): 1.36 is the current default, in STANDARD_SUPPORT."
  type        = string
  default     = "1.36"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for the EKS managed node group. Changed 2026-10-06 from t3.medium to t3.micro - confirmed live that EKS's own node-group-creation free-tier check (distinct from this account's AWS Organizations SCPs - a separate, undocumented validation tied to the account's credits program) rejects any non-free-tier-eligible EC2 instance type outright (InvalidParameterCombination on node group creation, not a quota/capacity issue). t3.micro (x86_64), not t4g.micro (ARM/Graviton, also free-tier-eligible) - this project's container images are built for linux/amd64 throughout (see k8s/deploy-aws.sh), so an ARM node would be an architecture mismatch. Changed AGAIN, same day, from t3.micro to t3.small: t3.micro's 1GiB RAM leaves only ~514Mi allocatable after EKS's kubelet/system-reserved overhead, confirmed live via a real FailedScheduling event that Kafka's StatefulSet (768Mi memory limit, which Kubernetes defaults to an equal 768Mi *request* since no request is set explicitly) cannot schedule onto ANY t3.micro node regardless of count - not a contention problem more nodes fixes, a per-node capacity ceiling below what one Kafka broker alone needs. t3.small (2GiB RAM) was confirmed NOT blocked by the account's SCPs via a live `ec2:RunInstances --dry-run` test (only t3.medium+ triggered the separate EKS free-tier-eligibility rejection) - whether EKS's own node-group validation accepts t3.small specifically was unverified at decision time, confirmed by the next real apply."
  type        = string
  default     = "t3.small"
}

variable "eks_node_count" {
  description = "Fixed node count for the managed node group (desired = min = max, no autoscaling). Originally 2 for cost-conscious sizing; bumped to 3 (2026-09-18) after a real live deploy found 2 nodes genuinely overcommitted (one at 94% memory requests) once api's memory limit was corrected to a realistic value - also gives Kafka's 3 brokers a real shot at one-node-per-broker spread across the existing 3 AZs, which 2 nodes structurally couldn't provide regardless of sizing. Bumped again to 4 (2026-10-06) after switching to t3.micro (free-tier SCP constraint, see eks_node_instance_type) - t3.micro's EKS max-pods ceiling (an ENI/IP-count formula, not a memory limit) left every node fully saturated by just the 3 mandatory daemonsets (kube-proxy, aws-node, ebs-csi-node) plus one Kafka broker, confirmed live via a real FailedScheduling event ('3 Insufficient memory, 3 Too many pods') - zero room remained for ebs-csi-controller, which structurally cannot move to Fargate like coredns/metrics-server did (fargate.tf's kube-system selector) because it needs real AWS API credentials and no Fargate pod on this account can get any (no IMDS path off-node, IRSA blocked account-wide). The 4th node exists specifically to give ebs-csi-controller a schedulable EC2 slot, not for general headroom."
  type        = number
  default     = 4
}

# --- RDS (PostgreSQL, replaces self-hosted Patroni for the cloud target) ---

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_engine_version" {
  description = "RDS PostgreSQL engine version. Checked live via `aws rds describe-db-engine-versions` (2026-09-17): 18.4 is directly supported, matching this project's own pinned version in docs/tech-stack-versions.md exactly."
  type        = string
  default     = "18.4"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB. 20 is the practical minimum for gp3 storage at this instance class."
  type        = number
  default     = 20
}

variable "rds_db_name" {
  description = "Initial database name, matching the app's existing spring.datasource.url convention (docker-compose.yml: 'gridmeter')."
  type        = string
  default     = "gridmeter"
}

variable "rds_master_username" {
  description = "Master username. The password is NOT a variable here - the DB instance uses manage_master_user_password (AWS Secrets Manager-backed), so no plaintext password ever exists in Terraform state or config."
  type        = string
  default     = "gridmeter"
}

# --- ElastiCache (Valkey, replaces self-hosted Redis Sentinel for the cloud target) ---

variable "cache_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "cache_engine_version" {
  description = "ElastiCache Valkey engine version. Checked live via `aws elasticache describe-cache-engine-versions` (2026-09-17): AWS's 'redis' engine tops out at 7.1 (pre-2024-relicensing) with no Redis 8.x offered at all; 'valkey' is AWS's actual current path and 9.1 is the newest available - chosen over the older redis 7.1 engine per explicit user sign-off."
  type        = string
  default     = "9.1"
}
