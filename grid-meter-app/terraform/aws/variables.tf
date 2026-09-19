# --- Shared / provider ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to authenticate with (see ~/.aws/credentials)."
  type        = string
  default     = "grid-meter"
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
  description = "EC2 instance type for the EKS managed node group."
  type        = string
  default     = "t3.medium"
}

variable "eks_node_count" {
  description = "Fixed node count for the managed node group (desired = min = max, no autoscaling). Originally 2 for cost-conscious sizing; bumped to 3 (2026-09-18) after a real live deploy found 2 nodes genuinely overcommitted (one at 94% memory requests) once api's memory limit was corrected to a realistic value - also gives Kafka's 3 brokers a real shot at one-node-per-broker spread across the existing 3 AZs, which 2 nodes structurally couldn't provide regardless of sizing."
  type        = number
  default     = 3
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
