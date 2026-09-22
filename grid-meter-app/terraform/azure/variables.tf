# --- Core ---

variable "project_name" {
  description = "Short project identifier, used to build resource names throughout."
  type        = string
  default     = "grid-meter-app"
}

variable "azure_region" {
  description = "Azure region for every resource in this config. \"eastus\" confirmed live (2026-09-22, web search against current Azure regional pricing comparisons) as Azure's baseline/cheapest US region - matches terraform/azure/bootstrap/variables.tf's own choice and the same reasoning AWS's us-west-2 and GCP's us-central1 picks used."
  type        = string
  default     = "eastus"
}

# --- Networking ---

variable "vnet_cidr" {
  description = "VNet address space. 10.20.0.0/16 - deliberately a distinct /16 from every other cloud track this project has built (AWS's VPC: 10.0.0.0/16; GCP's subnet/PSA/master ranges: 10.10-10.12.x.x, 10.1.x.x, 10.0.0.0/28) even though these are entirely separate networks with no real routing between clouds - kept distinct anyway for a single legible numbering convention across the whole multi-cloud project, and specifically to leave 10.0.x.x/10.1.x.x/10.10-10.12.x.x alone after this session's own live-caught GCP collision lessons around reusing/assuming ranges were free."
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet for AKS node VMs. Deliberately small (/24, 256 addresses) - Azure CNI Overlay (see aks.tf) means pods draw from a separate private overlay CIDR that doesn't consume VNet address space, so this subnet only ever needs to hold node IPs, not pod IPs - a real structural difference from GCP's VPC-native GKE, which needed a much larger secondary range sized for pod IPs directly in the VNet-equivalent address space."
  type        = string
  default     = "10.20.0.0/24"
}

variable "postgres_subnet_cidr" {
  description = "Dedicated, delegated subnet for Azure Database for PostgreSQL Flexible Server's private networking (delegated to Microsoft.DBforPostgreSQL/flexibleServers - Postgres Flexible Server requires its own delegated subnet for VNet integration, a real structural requirement neither AWS's RDS nor GCP's Cloud SQL private-IP approach has - both of those just need the VPC's own private-subnet placement, no dedicated per-service delegated subnet)."
  type        = string
  default     = "10.20.1.0/24"
}

# --- AKS ---

variable "aks_node_vm_size" {
  description = "VM size for the AKS system node pool. Standard_D2as_v5 (2 vCPU, 8GB, AMD-based general-purpose) - checked live (2026-09-22) that AKS explicitly does NOT support/recommend B-series (burstable) VMs for system node pools despite B-series technically meeting the raw 2-vCPU/4GB minimum - a real, documented platform-specific constraint, unlike AWS's EKS (t3.medium, burstable, no such restriction) or GCP's GKE (e2-medium). D2as_v5 confirmed the cheapest current-generation AKS-supported general-purpose size (~$0.086/hr in eastus, web search 2026-09-22)."
  type        = string
  default     = "Standard_D2as_v5"
}

variable "aks_node_count" {
  description = "Node count for the single AKS system node pool. 3, one per zone (see aks_availability_zones) - matches AWS's eks_node_count=3 and GCP's 1x3-zones=3 sizing exactly, both already corrected through live debugging to be the minimum that lets Kafka's 3 self-hosted brokers schedule one-per-zone."
  type        = number
  default     = 3
}

variable "aks_availability_zones" {
  description = "Availability zones the AKS node pool spans. eastus has 3 zones - matches AWS's 3-AZ EKS node group and GCP's 3-zone GKE node pool exactly, same Kafka one-broker-per-zone reasoning."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "aks_kubernetes_version" {
  description = "AKS Kubernetes version. Left null deliberately (AKS's own default: the current stable version on the REGULAR-equivalent release channel) rather than pinned - re-check this against `az aks get-versions --location eastus` before the first real apply, same \"declare load-bearing defaults explicitly\" principle applied to AWS's EKS version and GCP's GKE release channel, just resolving here to \"let the platform's own current default decide\" after confirming live what that default actually is, not a silent gap."
  type        = string
  default     = null
}

# --- Azure Database for PostgreSQL Flexible Server ---

variable "postgres_sku_name" {
  description = "Compute SKU, Terraform's tier_Standard_size format. B_Standard_B1ms (Burstable, 1 vCPU, 2GB) - checked live (2026-09-22) that Postgres Flexible Server, unlike AKS node pools, DOES support Burstable (B-series) SKUs - a real, worth-noting contrast between the two Azure services rather than an inconsistency. Matches AWS's db.t4g.micro and GCP's db-f1-micro cost-conscious sizing."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  description = "PostgreSQL major version. \"18\" - confirmed live (2026-09-22, web search against Microsoft's own Azure Database for PostgreSQL release notes) that PostgreSQL 18 reached GA on Azure Flexible Server, matching this project's stack pin (docs/tech-stack-versions.md: PostgreSQL 18.4, not 19 - still beta) exactly, same result AWS's RDS and GCP's Cloud SQL version checks both found."
  type        = string
  default     = "18"
}

variable "postgres_storage_mb" {
  description = "Allocated storage in MB. 32768 (32GB) - confirmed live (2026-09-22) as both Azure Flexible Server's actual minimum allowed storage_mb value and its own default; the 20GB AWS/GCP both used isn't expressible here at all (Azure's storage sizes are a fixed enum: 32768/65536/131072/... , not an arbitrary GB integer)."
  type        = number
  default     = 32768
}

variable "postgres_db_name" {
  description = "Application database name inside the Flexible Server instance."
  type        = string
  default     = "gridmeter"
}

variable "postgres_admin_user" {
  description = "Postgres admin username. Matches AWS/GCP's own admin username choice for consistency."
  type        = string
  default     = "gridmeter"
}

# --- Azure Cache for Redis (legacy product, chosen deliberately - see rediscache.tf) ---

variable "redis_sku_name" {
  description = "Azure Cache for Redis pricing tier. \"Basic\" - the cheapest, matching AWS's/GCP's own no-HA single-node cache sizing (this project's local track already builds real Redis HA/Sentinel by hand)."
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "SKU family - \"C\" for Basic/Standard tiers (\"P\" is Premium-only, which this project doesn't need)."
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Basic/Standard capacity tier, 0-6 (C0=250MB through C6=53GB). 0 (C0, 250MB) - this project's single cached-latest-reading-per-meter workload doesn't need more, matching AWS's/GCP's own smallest-tier cache sizing."
  type        = number
  default     = 0
}

# --- Artifact Registry (ACR) ---

variable "acr_sku" {
  description = "Container Registry SKU. \"Basic\" - the cheapest tier, matching AWS ECR's/GCP Artifact Registry's own no-frills cost-conscious repo choices; this project's image count/pull volume (2 repos, KEEP-5-most-recent equivalent policy) doesn't need Standard/Premium's extra throughput or geo-replication."
  type        = string
  default     = "Basic"
}
