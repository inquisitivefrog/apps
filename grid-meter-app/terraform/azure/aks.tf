# AKS's own auto-created node-resource-group (default name MC_<rg>_<name>_<region>) is a real,
# Azure-specific structural quirk worth flagging explicitly rather than glossing over: creating a
# cluster here also silently creates a SECOND resource group, outside this config's own
# azurerm_resource_group.main, to hold the actual VM scale set/node NICs/load balancer backing
# the cluster. Neither AWS's EKS nor GCP's GKE has an equivalent auto-created second container -
# everything for both of those stays inside the one resource container this config manages.
# Nothing to declare for it here (Azure manages its lifecycle, deleting it automatically when the
# cluster is destroyed), but worth knowing it exists when looking at the real subscription later.
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  dns_prefix          = var.project_name
  kubernetes_version  = var.aks_kubernetes_version
  tags                = local.common_tags

  default_node_pool {
    name       = "system"
    vm_size    = var.aks_node_vm_size
    node_count = var.aks_node_count
    # null (not an empty list) when zones aren't supported on this subscription - `zones` is a set
    # type, and an explicit empty set isn't necessarily equivalent to the argument being absent
    # entirely at the API level, so null is used deliberately here rather than assumed
    # interchangeable with []. See variables.tf's aks_availability_zones for the live-confirmed
    # finding that motivated this (2026-09-23).
    zones                        = length(var.aks_availability_zones) > 0 ? var.aks_availability_zones : null
    vnet_subnet_id               = azurerm_subnet.aks.id
    os_disk_size_gb              = 30 # matches AWS's/GCP's own 30GB node boot disk sizing
    only_critical_addons_enabled = false

    # Declared explicitly, matching values AKS's own provider default already produced live
    # (confirmed via a real apply, 2026-09-23) - left undeclared, every subsequent plan tried to
    # "correct" this optional+computed block back to unset, showing a perpetual spurious diff.
    # Same "declare load-bearing defaults" principle as everywhere else in this project
    # (CLAUDE.md), just resolving here to "match the platform's own default" after confirming
    # live what that default actually is.
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  # System-assigned managed identity for the cluster itself (control plane operations - creating
  # LoadBalancers, managing the node-resource-group above). The simplest option, matching AWS/GCP's
  # own "let the platform manage the identity where possible" pattern rather than provisioning a
  # dedicated user-assigned identity this project has no other use for.
  identity {
    type = "SystemAssigned"
  }

  # Enables the app's own pods to federate a dedicated Entra ID identity (azurerm_user_assigned_identity.app
  # below) instead of riding the cluster's own SystemAssigned identity - added 2026-09-23 for
  # Managed Redis access (rediscache.tf already requires Entra ID auth; this is what actually lets
  # a pod obtain a token for it).
  workload_identity_enabled = true

  # oidc_issuer_url (referenced by azurerm_federated_identity_credential.app below) only populates
  # when this is true. It happened to already default to true on this provider version, but that
  # was an undeclared default until now - workload identity genuinely depends on it, so declaring
  # it explicitly rather than continuing to lean on the implicit value (this project's standing
  # "declare load-bearing defaults" principle, CLAUDE.md).
  oidc_issuer_enabled = true

  # Required as of azurerm 5.x (confirmed via a real `terraform validate` failure - "at least 1
  # node_provisioning_profile blocks are required" - not something the resource needed before
  # this provider generation). mode = "Manual" explicitly opts OUT of AKS's newer Node
  # Auto-Provisioning (a Karpenter-based feature that would let AKS create/destroy node pools on
  # its own) - this project wants the fixed-size default_node_pool declared above, matching the
  # deliberately-static node counts AWS's EKS and GCP's GKE both use, not dynamic provisioning.
  node_provisioning_profile {
    mode = "Manual"
  }

  # Azure CNI Overlay - confirmed live (2026-09-22, web search against Microsoft's own AKS
  # networking docs) as the current Microsoft-recommended default for new clusters as of Q4 2025;
  # kubenet (the older, simpler option) is being retired March 2028. Pods draw from a private
  # overlay CIDR (pod_cidr below) that never touches the VNet's own address space - only nodes
  # consume real VNet IPs from azurerm_subnet.aks.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    pod_cidr            = "10.244.0.0/16" # standard k8s-convention private overlay range, deliberately outside vnet_cidr's 10.20.0.0/16 even though overlay pods don't strictly need to avoid it
    service_cidr        = "10.245.0.0/16" # same reasoning, also outside vnet_cidr
    dns_service_ip      = "10.245.0.10"
    load_balancer_sku   = "standard"
  }
}

# The AKS node pool's own "kubelet identity" - a real, separate concept from the cluster identity
# above - is what the container runtime on each node actually uses to authenticate when pulling
# images. Granting it AcrPull on the registry (acr.tf) is this project's equivalent of AWS's
# node IAM role needing an explicit registry-read policy attachment and GCP's node service account
# needing roles/artifactregistry.reader added on top of roles/container.nodeServiceAccount (both
# found live, 2026-09 sessions) - the "cluster/node identity doesn't automatically include
# registry pull" gap has now shown up on all three clouds in one shape or another, so this is
# declared explicitly from the start here rather than left to be discovered the same way again.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
