# Grants the app's own pods a distinct Entra ID identity so they can obtain tokens for Managed
# Redis (rediscache.tf) - previously nothing in this config gave a pod its own cloud identity at
# all (the AKS cluster's SystemAssigned identity in aks.tf is for control-plane operations, not
# workload auth; kubelet_identity in aks.tf is node-level, for image pulls only). AWS and GCP got
# the equivalent treatment the same day (terraform/aws/elasticache-iam-auth.tf,
# terraform/gcp/gke.tf's google_service_account.app) - this is Azure's version of the same
# decision (Managed Redis's Entra-ID-only requirement is what originally prompted aligning all
# three clouds onto IAM/token-based Redis auth, see rediscache.tf's header comment).

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.project_name}-app-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  tags                = local.common_tags
}

# Federates the app's own K8s ServiceAccount ("grid-meter-app" in the "default" namespace - not
# yet created; see below) to this identity via AKS's OIDC issuer, so a pod can exchange its K8s
# service account token for a real Entra ID token with no secret/certificate involved.
resource "azurerm_federated_identity_credential" "app" {
  name                      = "${var.project_name}-app-fic"
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:default:grid-meter-app"
  audience                  = ["api://AzureADTokenExchange"] # Azure's fixed, documented audience value for this exchange - not project-specific
}

# Confirmed live (2026-09-23, web search): Managed Redis's Entra ID data-plane access is granted
# via a dedicated access-policy-assignment resource, NOT a generic azurerm_role_assignment (Azure
# RBAC controls management-plane access to the resource itself; this controls actual data
# read/write access) - a genuinely different access-control layer from Key Vault's RBAC model
# used elsewhere in postgresql.tf. Omitting an explicit access-policy name grants full data
# access (all commands, all keys) per the resource's own documented behavior, matching this
# project's existing no-command-restriction posture on the AWS/GCP Redis users.
resource "azurerm_managed_redis_access_policy_assignment" "app" {
  managed_redis_id = azurerm_managed_redis.main.id
  object_id        = azurerm_user_assigned_identity.app.principal_id
}

# Terraform-side only, deliberately: the K8s ServiceAccount object itself (with the
# azure.workload.identity/client-id annotation set to azurerm_user_assigned_identity.app.client_id,
# plus a matching label on the pod template and k8s/api-azure.yaml's serviceAccountName field -
# k8s/api-azure.yaml doesn't exist yet at all, since AKS app deployment hasn't been built out this
# far yet) and the Lettuce credential-provider app code (Entra ID token acquisition via
# azure-identity's DefaultAzureCredential/WorkloadIdentityCredential) are real manifest/app-code
# work, already tracked in this project's README/status log as required follow-up - not attempted
# inline here. This Terraform is inert (no pod can federate this identity yet) until that
# follow-up lands.
