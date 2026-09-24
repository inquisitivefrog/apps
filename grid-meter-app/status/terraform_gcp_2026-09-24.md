
tim@Timothys-MacBook-Air gcp % terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/random from the dependency lock file
- Reusing previous version of hashicorp/google from the dependency lock file
- Using previously-installed hashicorp/random v3.9.1
- Using previously-installed hashicorp/google v8.3.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tim@Timothys-MacBook-Air gcp % terraform fmt 
tim@Timothys-MacBook-Air gcp % terraform validate
Success! The configuration is valid.

tim@Timothys-MacBook-Air gcp % terraform plan -out tfplan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated
with the following symbols:
  + create

Terraform will perform the following actions:

  # google_artifact_registry_repository.api will be created
  + resource "google_artifact_registry_repository" "api" {
      + cleanup_policy_dry_run = false
      + create_time            = (known after apply)
      + deletion_policy        = "DELETE"
      + effective_labels       = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + format                 = "DOCKER"
      + id                     = (known after apply)
      + location               = "us-central1"
      + mode                   = "STANDARD_REPOSITORY"
      + name                   = (known after apply)
      + project                = "project-4c5a8821-da4c-4c68-97f"
      + registry_uri           = (known after apply)
      + repository_id          = "grid-meter-app-api"
      + terraform_labels       = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + update_time            = (known after apply)

      + cleanup_policies {
          + action = "KEEP"
          + id     = "keep-5-most-recent"

          + most_recent_versions {
              + keep_count            = 5
              + package_name_prefixes = []
            }
        }

      + vulnerability_scanning_config (known after apply)
    }

  # google_artifact_registry_repository.frontend will be created
  + resource "google_artifact_registry_repository" "frontend" {
      + cleanup_policy_dry_run = false
      + create_time            = (known after apply)
      + deletion_policy        = "DELETE"
      + effective_labels       = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + format                 = "DOCKER"
      + id                     = (known after apply)
      + location               = "us-central1"
      + mode                   = "STANDARD_REPOSITORY"
      + name                   = (known after apply)
      + project                = "project-4c5a8821-da4c-4c68-97f"
      + registry_uri           = (known after apply)
      + repository_id          = "grid-meter-app-frontend"
      + terraform_labels       = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + update_time            = (known after apply)

      + cleanup_policies {
          + action = "KEEP"
          + id     = "keep-5-most-recent"

          + most_recent_versions {
              + keep_count            = 5
              + package_name_prefixes = []
            }
        }

      + vulnerability_scanning_config (known after apply)
    }

  # google_compute_global_address.private_service_access will be created
  + resource "google_compute_global_address" "private_service_access" {
      + address            = "10.1.0.0"
      + address_type       = "INTERNAL"
      + creation_timestamp = (known after apply)
      + deletion_policy    = "DELETE"
      + effective_labels   = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + id                 = (known after apply)
      + label_fingerprint  = (known after apply)
      + name               = "grid-meter-app-psa-range"
      + network            = (known after apply)
      + prefix_length      = 16
      + project            = "project-4c5a8821-da4c-4c68-97f"
      + purpose            = "VPC_PEERING"
      + self_link          = (known after apply)
      + terraform_labels   = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
    }

  # google_compute_network.main will be created
  + resource "google_compute_network" "main" {
      + auto_create_subnetworks                   = false
      + bgp_always_compare_med                    = (known after apply)
      + bgp_best_path_selection_mode              = (known after apply)
      + bgp_inter_region_cost                     = (known after apply)
      + delete_bgp_always_compare_med             = false
      + delete_default_routes_on_create           = false
      + deletion_policy                           = "DELETE"
      + gateway_ipv4                              = (known after apply)
      + id                                        = (known after apply)
      + internal_ipv6_range                       = (known after apply)
      + mtu                                       = (known after apply)
      + name                                      = "grid-meter-app-vpc"
      + network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
      + network_id                                = (known after apply)
      + numeric_id                                = (known after apply)
      + project                                   = "project-4c5a8821-da4c-4c68-97f"
      + routing_mode                              = (known after apply)
      + self_link                                 = (known after apply)
    }

  # google_compute_router.main will be created
  + resource "google_compute_router" "main" {
      + creation_timestamp = (known after apply)
      + deletion_policy    = "DELETE"
      + id                 = (known after apply)
      + name               = "grid-meter-app-router"
      + network            = (known after apply)
      + project            = "project-4c5a8821-da4c-4c68-97f"
      + region             = "us-central1"
      + self_link          = (known after apply)
    }

  # google_compute_router_nat.main will be created
  + resource "google_compute_router_nat" "main" {
      + auto_network_tier                   = (known after apply)
      + deletion_policy                     = "DELETE"
      + drain_nat_ips                       = (known after apply)
      + enable_dynamic_port_allocation      = (known after apply)
      + enable_endpoint_independent_mapping = (known after apply)
      + endpoint_types                      = (known after apply)
      + icmp_idle_timeout_sec               = 30
      + id                                  = (known after apply)
      + min_ports_per_vm                    = (known after apply)
      + name                                = "grid-meter-app-nat"
      + nat_ip_allocate_option              = "AUTO_ONLY"
      + nat_ips                             = (known after apply)
      + project                             = "project-4c5a8821-da4c-4c68-97f"
      + region                              = "us-central1"
      + router                              = "grid-meter-app-router"
      + source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
      + tcp_established_idle_timeout_sec    = 1200
      + tcp_time_wait_timeout_sec           = 120
      + tcp_transitory_idle_timeout_sec     = 30
      + type                                = "PUBLIC"
      + udp_idle_timeout_sec                = 30
    }

  # google_compute_subnetwork.main will be created
  + resource "google_compute_subnetwork" "main" {
      + allow_subnet_cidr_routes_overlap = (known after apply)
      + creation_timestamp               = (known after apply)
      + deletion_policy                  = "DELETE"
      + external_ipv6_prefix             = (known after apply)
      + fingerprint                      = (known after apply)
      + gateway_address                  = (known after apply)
      + id                               = (known after apply)
      + internal_ipv6_prefix             = (known after apply)
      + ip_cidr_range                    = "10.10.0.0/20"
      + ipv6_cidr_range                  = (known after apply)
      + ipv6_gce_endpoint                = (known after apply)
      + name                             = "grid-meter-app-subnet"
      + network                          = (known after apply)
      + private_ip_google_access         = true
      + private_ipv6_google_access       = (known after apply)
      + project                          = "project-4c5a8821-da4c-4c68-97f"
      + purpose                          = (known after apply)
      + region                           = "us-central1"
      + self_link                        = (known after apply)
      + stack_type                       = (known after apply)
      + state                            = (known after apply)
      + subnetwork_id                    = (known after apply)

      + secondary_ip_range {
          + ip_cidr_range = "10.11.0.0/16"
          + range_name    = "grid-meter-app-pods"
        }
      + secondary_ip_range {
          + ip_cidr_range = "10.12.0.0/20"
          + range_name    = "grid-meter-app-services"
        }
    }

  # google_container_cluster.main will be created
  + resource "google_container_cluster" "main" {
      + autopilot_privileged_admission           = (known after apply)
      + cluster_ipv4_cidr                        = (known after apply)
      + datapath_provider                        = (known after apply)
      + default_max_pods_per_node                = (known after apply)
      + deletion_policy                          = "DELETE"
      + deletion_protection                      = false
      + disable_l4_lb_firewall_reconciliation    = false
      + effective_labels                         = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + emulated_version                         = (known after apply)
      + enable_cilium_clusterwide_network_policy = false
      + enable_fqdn_network_policy               = false
      + enable_intranode_visibility              = (known after apply)
      + enable_kubernetes_alpha                  = false
      + enable_l4_ilb_subsetting                 = (known after apply)
      + enable_legacy_abac                       = false
      + enable_multi_networking                  = false
      + enable_shielded_nodes                    = true
      + endpoint                                 = (known after apply)
      + id                                       = (known after apply)
      + initial_node_count                       = 1
      + label_fingerprint                        = (known after apply)
      + location                                 = "us-central1-a"
      + logging_service                          = (known after apply)
      + master_version                           = (known after apply)
      + monitoring_service                       = (known after apply)
      + name                                     = "grid-meter-app-gke"
      + network                                  = (known after apply)
      + networking_mode                          = (known after apply)
      + node_locations                           = (known after apply)
      + node_version                             = (known after apply)
      + operation                                = (known after apply)
      + private_ipv6_google_access               = (known after apply)
      + project                                  = (known after apply)
      + remove_default_node_pool                 = true
      + self_link                                = (known after apply)
      + services_ipv4_cidr                       = (known after apply)
      + subnetwork                               = (known after apply)
      + terraform_labels                         = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + tpu_ipv4_cidr_block                      = (known after apply)

      + addons_config {
          + agent_sandbox_config (known after apply)
          + cloudrun_config (known after apply)
          + config_connector_config (known after apply)
          + dns_cache_config (known after apply)
          + gce_persistent_disk_csi_driver_config {
              + enabled = true
            }
          + gcp_filestore_csi_driver_config (known after apply)
          + gcs_fuse_csi_driver_config (known after apply)
          + gke_backup_agent_config (known after apply)
          + high_scale_checkpointing_config (known after apply)
          + horizontal_pod_autoscaling (known after apply)
          + http_load_balancing (known after apply)
          + lustre_csi_driver_config (known after apply)
          + network_policy_config (known after apply)
          + node_readiness_config (known after apply)
          + parallelstore_csi_driver_config (known after apply)
          + pod_snapshot_config (known after apply)
          + ray_operator_config (known after apply)
          + slice_controller_config (known after apply)
          + slurm_operator_config (known after apply)
          + stateful_ha_config (known after apply)
        }

      + anonymous_authentication_config (known after apply)

      + authenticator_groups_config (known after apply)

      + autopilot_cluster_policy_config (known after apply)

      + cluster_autoscaling (known after apply)

      + confidential_nodes (known after apply)

      + control_plane_endpoints_config (known after apply)

      + cost_management_config (known after apply)

      + database_encryption (known after apply)

      + default_snat_status (known after apply)

      + enterprise_config (known after apply)

      + gateway_api_config (known after apply)

      + gke_auto_upgrade_config (known after apply)

      + identity_service_config (known after apply)

      + ip_allocation_policy {
          + cluster_ipv4_cidr_block       = (known after apply)
          + cluster_secondary_range_name  = "grid-meter-app-pods"
          + services_ipv4_cidr_block      = (known after apply)
          + services_secondary_range_name = "grid-meter-app-services"
          + stack_type                    = "IPV4"

          + auto_ipam_config (known after apply)

          + network_tier_config (known after apply)

          + pod_cidr_overprovision_config (known after apply)
        }

      + logging_config (known after apply)

      + master_auth (known after apply)

      + master_authorized_networks_config (known after apply)

      + mesh_certificates (known after apply)

      + monitoring_config (known after apply)

      + node_config (known after apply)

      + node_creation_config (known after apply)

      + node_pool (known after apply)

      + node_pool_auto_config (known after apply)

      + node_pool_defaults (known after apply)

      + notification_config (known after apply)

      + pod_autoscaling (known after apply)

      + private_cluster_config {
          + enable_private_nodes   = true
          + master_ipv4_cidr_block = "10.0.0.0/28"
          + peering_name           = (known after apply)
          + private_endpoint       = (known after apply)
          + public_endpoint        = (known after apply)

          + master_global_access_config (known after apply)
        }

      + rbac_binding_config (known after apply)

      + release_channel {
          + channel = "REGULAR"
        }

      + security_posture_config (known after apply)

      + service_external_ips_config (known after apply)

      + vertical_pod_autoscaling (known after apply)

      + workload_identity_config {
          + workload_pool = "project-4c5a8821-da4c-4c68-97f.svc.id.goog"
        }
    }

  # google_container_node_pool.extra will be created
  + resource "google_container_node_pool" "extra" {
      + cluster                     = (known after apply)
      + deletion_policy             = "DELETE"
      + id                          = (known after apply)
      + initial_node_count          = (known after apply)
      + instance_group_urls         = (known after apply)
      + location                    = (known after apply)
      + managed_instance_group_urls = (known after apply)
      + max_pods_per_node           = (known after apply)
      + name                        = "grid-meter-app-nodes-extra"
      + name_prefix                 = (known after apply)
      + node_count                  = 1
      + node_locations              = [
          + "us-central1-a",
        ]
      + operation                   = (known after apply)
      + project                     = "project-4c5a8821-da4c-4c68-97f"
      + version                     = (known after apply)

      + management (known after apply)

      + network_config (known after apply)

      + node_config {
          + disk_size_gb       = 30
          + disk_type          = "pd-standard"
          + effective_taints   = (known after apply)
          + gpudirect_strategy = (known after apply)
          + image_type         = (known after apply)
          + labels             = (known after apply)
          + local_ssd_count    = (known after apply)
          + logging_variant    = (known after apply)
          + machine_type       = "e2-medium"
          + metadata           = (known after apply)
          + min_cpu_platform   = (known after apply)
          + oauth_scopes       = [
              + "https://www.googleapis.com/auth/devstorage.read_only",
              + "https://www.googleapis.com/auth/logging.write",
              + "https://www.googleapis.com/auth/monitoring",
            ]
          + preemptible        = false
          + service_account    = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
          + spot               = false

          + boot_disk (known after apply)

          + confidential_nodes (known after apply)

          + containerd_config (known after apply)

          + gcfs_config (known after apply)

          + guest_accelerator (known after apply)

          + kubelet_config (known after apply)

          + linux_node_config (known after apply)

          + node_image_config (known after apply)

          + shielded_instance_config (known after apply)

          + windows_node_config (known after apply)

          + workload_metadata_config (known after apply)
        }

      + node_drain_config (known after apply)

      + upgrade_settings (known after apply)
    }

  # google_container_node_pool.main will be created
  + resource "google_container_node_pool" "main" {
      + cluster                     = (known after apply)
      + deletion_policy             = "DELETE"
      + id                          = (known after apply)
      + initial_node_count          = (known after apply)
      + instance_group_urls         = (known after apply)
      + location                    = (known after apply)
      + managed_instance_group_urls = (known after apply)
      + max_pods_per_node           = (known after apply)
      + name                        = "grid-meter-app-nodes"
      + name_prefix                 = (known after apply)
      + node_count                  = 1
      + node_locations              = [
          + "us-central1-a",
          + "us-central1-b",
          + "us-central1-c",
        ]
      + operation                   = (known after apply)
      + project                     = "project-4c5a8821-da4c-4c68-97f"
      + version                     = (known after apply)

      + management (known after apply)

      + network_config (known after apply)

      + node_config {
          + disk_size_gb       = 30
          + disk_type          = "pd-standard"
          + effective_taints   = (known after apply)
          + gpudirect_strategy = (known after apply)
          + image_type         = (known after apply)
          + labels             = (known after apply)
          + local_ssd_count    = (known after apply)
          + logging_variant    = (known after apply)
          + machine_type       = "e2-medium"
          + metadata           = (known after apply)
          + min_cpu_platform   = (known after apply)
          + oauth_scopes       = [
              + "https://www.googleapis.com/auth/devstorage.read_only",
              + "https://www.googleapis.com/auth/logging.write",
              + "https://www.googleapis.com/auth/monitoring",
            ]
          + preemptible        = false
          + service_account    = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
          + spot               = false

          + boot_disk (known after apply)

          + confidential_nodes (known after apply)

          + containerd_config (known after apply)

          + gcfs_config (known after apply)

          + guest_accelerator (known after apply)

          + kubelet_config (known after apply)

          + linux_node_config (known after apply)

          + node_image_config (known after apply)

          + shielded_instance_config (known after apply)

          + windows_node_config (known after apply)

          + workload_metadata_config (known after apply)
        }

      + node_drain_config (known after apply)

      + upgrade_settings (known after apply)
    }

  # google_memorystore_instance.main will be created
  + resource "google_memorystore_instance" "main" {
      + authorization_mode             = "IAM_AUTH"
      + available_maintenance_versions = (known after apply)
      + backup_collection              = (known after apply)
      + create_time                    = (known after apply)
      + deletion_policy                = "DELETE"
      + deletion_protection_enabled    = false
      + discovery_endpoints            = (known after apply)
      + effective_labels               = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + effective_maintenance_version  = (known after apply)
      + endpoints                      = (known after apply)
      + engine_version                 = "VALKEY_9_0"
      + id                             = (known after apply)
      + instance_id                    = "grid-meter-app-cache"
      + is_acl_policy_in_sync          = (known after apply)
      + location                       = "us-central1"
      + maintenance_schedule           = (known after apply)
      + managed_server_ca              = (known after apply)
      + mode                           = "CLUSTER_DISABLED"
      + name                           = (known after apply)
      + node_config                    = (known after apply)
      + node_type                      = "SHARED_CORE_NANO"
      + project                        = "project-4c5a8821-da4c-4c68-97f"
      + psc_attachment_details         = (known after apply)
      + psc_auto_connections           = (known after apply)
      + replica_count                  = (known after apply)
      + server_ca_mode                 = (known after apply)
      + shard_count                    = 1
      + state                          = (known after apply)
      + state_info                     = (known after apply)
      + terraform_labels               = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + transit_encryption_mode        = "SERVER_AUTHENTICATION"
      + uid                            = (known after apply)
      + update_time                    = (known after apply)

      + cross_instance_replication_config (known after apply)

      + desired_auto_created_endpoints {
          + network    = (known after apply)
          + project_id = "project-4c5a8821-da4c-4c68-97f"
        }

      + persistence_config (known after apply)

      + zone_distribution_config (known after apply)
    }

  # google_network_connectivity_service_connection_policy.memorystore will be created
  + resource "google_network_connectivity_service_connection_policy" "memorystore" {
      + create_time      = (known after apply)
      + deletion_policy  = "DELETE"
      + effective_labels = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + etag             = (known after apply)
      + id               = (known after apply)
      + infrastructure   = (known after apply)
      + location         = "us-central1"
      + name             = "grid-meter-app-memorystore-scp"
      + network          = (known after apply)
      + project          = "project-4c5a8821-da4c-4c68-97f"
      + psc_connections  = (known after apply)
      + service_class    = "gcp-memorystore"
      + terraform_labels = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + update_time      = (known after apply)

      + psc_config {
          + producer_instance_location = (known after apply)
          + subnetworks                = (known after apply)
        }
    }

  # google_project_iam_member.app_memorystore_connect will be created
  + resource "google_project_iam_member" "app_memorystore_connect" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = "serviceAccount:grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + project = "project-4c5a8821-da4c-4c68-97f"
      + role    = "roles/memorystore.dbConnectionUser"
    }

  # google_project_iam_member.gke_node_artifact_registry will be created
  + resource "google_project_iam_member" "gke_node_artifact_registry" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + project = "project-4c5a8821-da4c-4c68-97f"
      + role    = "roles/artifactregistry.reader"
    }

  # google_project_iam_member.gke_node_sa will be created
  + resource "google_project_iam_member" "gke_node_sa" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + project = "project-4c5a8821-da4c-4c68-97f"
      + role    = "roles/container.nodeServiceAccount"
    }

  # google_secret_manager_secret.cloudsql_password will be created
  + resource "google_secret_manager_secret" "cloudsql_password" {
      + create_time           = (known after apply)
      + deletion_policy       = "DELETE"
      + deletion_protection   = false
      + effective_annotations = (known after apply)
      + effective_labels      = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }
      + expire_time           = (known after apply)
      + id                    = (known after apply)
      + name                  = (known after apply)
      + project               = "project-4c5a8821-da4c-4c68-97f"
      + secret_id             = "grid-meter-app-cloudsql-password"
      + terraform_labels      = {
          + "goog-terraform-provisioned" = "true"
          + "managed-by"                 = "terraform"
          + "project"                    = "grid-meter-app"
        }

      + replication {
          + auto {
            }
        }
    }

  # google_secret_manager_secret_version.cloudsql_password will be created
  + resource "google_secret_manager_secret_version" "cloudsql_password" {
      + create_time     = (known after apply)
      + deletion_policy = (known after apply)
      + destroy_time    = (known after apply)
      + enabled         = true
      + id              = (known after apply)
      + name            = (known after apply)
      + project         = (known after apply)
      + secret          = (known after apply)
      + secret_data     = (sensitive value)
      + secret_data_wo  = (write-only attribute)
      + version         = (known after apply)
    }

  # google_service_account.app will be created
  + resource "google_service_account" "app" {
      + account_id      = "grid-meter-app-app"
      + deletion_policy = "DELETE"
      + disabled        = false
      + display_name    = "grid-meter-app application workload identity"
      + email           = "grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + id              = (known after apply)
      + member          = "serviceAccount:grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + name            = (known after apply)
      + project         = "project-4c5a8821-da4c-4c68-97f"
      + unique_id       = (known after apply)
    }

  # google_service_account.gke_node will be created
  + resource "google_service_account" "gke_node" {
      + account_id      = "grid-meter-app-gke-node"
      + deletion_policy = "DELETE"
      + disabled        = false
      + display_name    = "grid-meter-app GKE node service account"
      + email           = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + id              = (known after apply)
      + member          = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
      + name            = (known after apply)
      + project         = "project-4c5a8821-da4c-4c68-97f"
      + unique_id       = (known after apply)
    }

  # google_service_account_iam_member.app_workload_identity will be created
  + resource "google_service_account_iam_member" "app_workload_identity" {
      + etag               = (known after apply)
      + id                 = (known after apply)
      + member             = "serviceAccount:project-4c5a8821-da4c-4c68-97f.svc.id.goog[default/grid-meter-app]"
      + role               = "roles/iam.workloadIdentityUser"
      + service_account_id = (known after apply)
    }

  # google_service_networking_connection.private_service_access will be created
  + resource "google_service_networking_connection" "private_service_access" {
      + deletion_policy         = "ABANDON"
      + id                      = (known after apply)
      + network                 = (known after apply)
      + peering                 = (known after apply)
      + reserved_peering_ranges = [
          + "grid-meter-app-psa-range",
        ]
      + service                 = "servicenetworking.googleapis.com"
    }

  # google_sql_database.main will be created
  + resource "google_sql_database" "main" {
      + charset         = (known after apply)
      + collation       = (known after apply)
      + deletion_policy = "DELETE"
      + id              = (known after apply)
      + instance        = "grid-meter-app-postgres"
      + name            = "gridmeter"
      + project         = "project-4c5a8821-da4c-4c68-97f"
      + self_link       = (known after apply)
    }

  # google_sql_database_instance.main will be created
  + resource "google_sql_database_instance" "main" {
      + available_maintenance_versions       = (known after apply)
      + connection_name                      = (known after apply)
      + database_version                     = "POSTGRES_18"
      + deletion_policy                      = "DELETE"
      + deletion_protection                  = false
      + dns_name                             = (known after apply)
      + dns_names                            = (known after apply)
      + encryption_key_name                  = (known after apply)
      + enforce_new_sql_network_architecture = (known after apply)
      + first_ip_address                     = (known after apply)
      + id                                   = (known after apply)
      + instance_type                        = (known after apply)
      + ip_address                           = (known after apply)
      + maintenance_version                  = (known after apply)
      + master_instance_name                 = (known after apply)
      + name                                 = "grid-meter-app-postgres"
      + node_count                           = (known after apply)
      + private_ip_address                   = (known after apply)
      + project                              = "project-4c5a8821-da4c-4c68-97f"
      + psc_service_attachment_link          = (known after apply)
      + public_ip_address                    = (known after apply)
      + region                               = "us-central1"
      + replica_names                        = (known after apply)
      + root_password_wo                     = (write-only attribute)
      + self_link                            = (known after apply)
      + server_ca_cert                       = (sensitive value)
      + service_account_email_address        = (known after apply)

      + replica_configuration (known after apply)

      + replication_cluster (known after apply)

      + settings {
          + activation_policy                = "ALWAYS"
          + availability_type                = "ZONAL"
          + connector_enforcement            = (known after apply)
          + data_api_access                  = (known after apply)
          + data_disk_provisioned_iops       = (known after apply)
          + data_disk_provisioned_throughput = (known after apply)
          + disk_autoresize                  = true
          + disk_autoresize_limit            = 0
          + disk_size                        = 20
          + disk_type                        = "PD_SSD"
          + edition                          = "ENTERPRISE"
          + effective_availability_type      = (known after apply)
          + pricing_plan                     = "PER_USE"
          + replication_lag_max_seconds      = (known after apply)
          + tier                             = "db-f1-micro"
          + user_labels                      = (known after apply)
          + version                          = (known after apply)

          + backup_configuration {
              + backup_tier                    = (known after apply)
              + enabled                        = true
              + point_in_time_recovery_enabled = false
              + start_time                     = (known after apply)
              + transaction_log_retention_days = (known after apply)

              + backup_retention_settings {
                  + retained_backups = 1
                  + retention_unit   = "COUNT"
                }
            }

          + connection_pool_config (known after apply)

          + data_cache_config (known after apply)

          + insights_config (known after apply)

          + ip_configuration {
              + ipv4_enabled    = false
              + private_network = (known after apply)
              + server_ca_mode  = (known after apply)
              + ssl_mode        = (known after apply)
            }

          + location_preference (known after apply)

          + read_pool_auto_scale_config (known after apply)
        }
    }

  # google_sql_user.main will be created
  + resource "google_sql_user" "main" {
      + deletion_policy         = "DELETE"
      + host                    = (known after apply)
      + iam_email               = (known after apply)
      + id                      = (known after apply)
      + instance                = "grid-meter-app-postgres"
      + name                    = "gridmeter"
      + password                = (sensitive value)
      + password_wo             = (write-only attribute)
      + project                 = "project-4c5a8821-da4c-4c68-97f"
      + sql_server_user_details = (known after apply)
    }

  # random_password.cloudsql will be created
  + resource "random_password" "cloudsql" {
      + bcrypt_hash = (sensitive value)
      + id          = (known after apply)
      + length      = 32
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + numeric     = true
      + result      = (sensitive value)
      + special     = false
      + upper       = true
    }

Plan: 25 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + artifact_registry_api_repository      = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api"
  + artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend"
  + cloudsql_connection_name              = (known after apply)
  + cloudsql_password_secret_id           = "grid-meter-app-cloudsql-password"
  + cloudsql_private_ip                   = (known after apply)
  + cloudsql_user                         = "gridmeter"
  + gcp_project_id                        = "project-4c5a8821-da4c-4c68-97f"
  + gcp_region                            = "us-central1"
  + gcp_zone                              = "us-central1-a"
  + gke_cluster_endpoint                  = (sensitive value)
  + gke_cluster_name                      = "grid-meter-app-gke"
  + kubeconfig_update_command             = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
  + memorystore_host                      = (known after apply)
  + memorystore_port                      = (known after apply)
  + vpc_id                                = (known after apply)

───────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"

tim@Timothys-MacBook-Air gcp % terraform apply tfplan
random_password.cloudsql: Creating...
random_password.cloudsql: Creation complete after 0s [id=none]
google_service_account.app: Creating...
google_service_account.gke_node: Creating...
google_compute_network.main: Creating...
google_secret_manager_secret.cloudsql_password: Creating...
google_artifact_registry_repository.frontend: Creating...
google_artifact_registry_repository.api: Creating...
google_secret_manager_secret.cloudsql_password: Creation complete after 1s [id=projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password]
google_secret_manager_secret_version.cloudsql_password: Creating...
google_secret_manager_secret_version.cloudsql_password: Creation complete after 1s [id=projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1]
google_service_account.app: Still creating... [00m10s elapsed]
google_service_account.gke_node: Still creating... [00m10s elapsed]
google_compute_network.main: Still creating... [00m10s elapsed]
google_artifact_registry_repository.frontend: Still creating... [00m10s elapsed]
google_artifact_registry_repository.api: Still creating... [00m10s elapsed]
google_artifact_registry_repository.frontend: Creation complete after 11s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend]
google_artifact_registry_repository.api: Creation complete after 11s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api]
google_service_account.app: Creation complete after 13s [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_project_iam_member.app_memorystore_connect: Creating...
google_service_account.gke_node: Creation complete after 13s [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_project_iam_member.gke_node_sa: Creating...
google_project_iam_member.gke_node_artifact_registry: Creating...
google_compute_network.main: Still creating... [00m20s elapsed]
google_project_iam_member.gke_node_artifact_registry: Creation complete after 8s [id=project-4c5a8821-da4c-4c68-97f/roles/artifactregistry.reader/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_project_iam_member.app_memorystore_connect: Creation complete after 8s [id=project-4c5a8821-da4c-4c68-97f/roles/memorystore.dbConnectionUser/serviceAccount:grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_project_iam_member.gke_node_sa: Creation complete after 8s [id=project-4c5a8821-da4c-4c68-97f/roles/container.nodeServiceAccount/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_compute_network.main: Creation complete after 22s [id=projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc]
google_compute_global_address.private_service_access: Creating...
google_compute_router.main: Creating...
google_compute_subnetwork.main: Creating...
google_compute_global_address.private_service_access: Still creating... [00m10s elapsed]
google_compute_router.main: Still creating... [00m10s elapsed]
google_compute_subnetwork.main: Still creating... [00m10s elapsed]
google_compute_router.main: Creation complete after 12s [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router]
google_compute_router_nat.main: Creating...
google_compute_global_address.private_service_access: Creation complete after 13s [id=projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range]
google_service_networking_connection.private_service_access: Creating...
google_compute_subnetwork.main: Still creating... [00m20s elapsed]
google_compute_subnetwork.main: Creation complete after 22s [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet]
google_compute_router_nat.main: Still creating... [00m10s elapsed]
google_network_connectivity_service_connection_policy.memorystore: Creating...
google_service_networking_connection.private_service_access: Still creating... [00m10s elapsed]
google_compute_router_nat.main: Creation complete after 12s [id=project-4c5a8821-da4c-4c68-97f/us-central1/grid-meter-app-router/grid-meter-app-nat]
google_container_cluster.main: Creating...
google_network_connectivity_service_connection_policy.memorystore: Still creating... [00m10s elapsed]
google_service_networking_connection.private_service_access: Still creating... [00m20s elapsed]
google_container_cluster.main: Still creating... [00m10s elapsed]
google_network_connectivity_service_connection_policy.memorystore: Creation complete after 12s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/serviceConnectionPolicies/grid-meter-app-memorystore-scp]
google_memorystore_instance.main: Creating...
google_service_networking_connection.private_service_access: Still creating... [00m30s elapsed]
google_container_cluster.main: Still creating... [00m20s elapsed]
google_memorystore_instance.main: Still creating... [00m10s elapsed]
google_service_networking_connection.private_service_access: Creation complete after 32s [id=projects%2Fproject-4c5a8821-da4c-4c68-97f%2Fglobal%2Fnetworks%2Fgrid-meter-app-vpc:servicenetworking.googleapis.com]
google_sql_database_instance.main: Creating...
google_container_cluster.main: Still creating... [00m30s elapsed]
google_memorystore_instance.main: Still creating... [00m20s elapsed]
google_sql_database_instance.main: Still creating... [00m10s elapsed]
google_container_cluster.main: Still creating... [00m40s elapsed]
google_memorystore_instance.main: Still creating... [00m30s elapsed]
google_sql_database_instance.main: Still creating... [00m20s elapsed]
google_container_cluster.main: Still creating... [00m50s elapsed]
google_memorystore_instance.main: Still creating... [00m40s elapsed]
google_sql_database_instance.main: Still creating... [00m30s elapsed]
google_container_cluster.main: Still creating... [01m00s elapsed]
google_memorystore_instance.main: Still creating... [00m50s elapsed]
google_sql_database_instance.main: Still creating... [00m40s elapsed]
google_container_cluster.main: Still creating... [01m10s elapsed]
google_memorystore_instance.main: Still creating... [01m00s elapsed]
google_sql_database_instance.main: Still creating... [00m50s elapsed]
google_container_cluster.main: Still creating... [01m20s elapsed]
google_memorystore_instance.main: Still creating... [01m10s elapsed]
google_sql_database_instance.main: Still creating... [01m00s elapsed]
google_container_cluster.main: Still creating... [01m30s elapsed]
google_memorystore_instance.main: Still creating... [01m20s elapsed]
google_sql_database_instance.main: Still creating... [01m10s elapsed]
google_container_cluster.main: Still creating... [01m40s elapsed]
google_memorystore_instance.main: Still creating... [01m30s elapsed]
google_sql_database_instance.main: Still creating... [01m20s elapsed]
google_container_cluster.main: Still creating... [01m50s elapsed]
google_memorystore_instance.main: Still creating... [01m40s elapsed]
google_sql_database_instance.main: Still creating... [01m30s elapsed]
google_container_cluster.main: Still creating... [02m00s elapsed]
google_memorystore_instance.main: Still creating... [01m50s elapsed]
google_sql_database_instance.main: Still creating... [01m40s elapsed]
google_container_cluster.main: Still creating... [02m10s elapsed]
google_memorystore_instance.main: Still creating... [02m00s elapsed]
google_sql_database_instance.main: Still creating... [01m50s elapsed]
google_container_cluster.main: Still creating... [02m20s elapsed]
google_memorystore_instance.main: Still creating... [02m10s elapsed]
google_sql_database_instance.main: Still creating... [02m00s elapsed]
google_container_cluster.main: Still creating... [02m30s elapsed]
google_memorystore_instance.main: Still creating... [02m20s elapsed]
google_sql_database_instance.main: Still creating... [02m10s elapsed]
google_container_cluster.main: Still creating... [02m40s elapsed]
google_memorystore_instance.main: Still creating... [02m30s elapsed]
google_sql_database_instance.main: Still creating... [02m20s elapsed]
google_container_cluster.main: Still creating... [02m50s elapsed]
google_memorystore_instance.main: Still creating... [02m40s elapsed]
google_sql_database_instance.main: Still creating... [02m30s elapsed]
google_container_cluster.main: Still creating... [03m00s elapsed]
google_memorystore_instance.main: Still creating... [02m50s elapsed]
google_sql_database_instance.main: Still creating... [02m40s elapsed]
google_container_cluster.main: Still creating... [03m10s elapsed]
google_memorystore_instance.main: Still creating... [03m00s elapsed]
google_sql_database_instance.main: Still creating... [02m50s elapsed]
google_container_cluster.main: Still creating... [03m20s elapsed]
google_memorystore_instance.main: Still creating... [03m10s elapsed]
google_sql_database_instance.main: Still creating... [03m00s elapsed]
google_container_cluster.main: Still creating... [03m30s elapsed]
google_memorystore_instance.main: Still creating... [03m20s elapsed]
google_sql_database_instance.main: Still creating... [03m10s elapsed]
google_container_cluster.main: Still creating... [03m40s elapsed]
google_memorystore_instance.main: Still creating... [03m30s elapsed]
google_sql_database_instance.main: Still creating... [03m20s elapsed]
google_container_cluster.main: Still creating... [03m50s elapsed]
google_memorystore_instance.main: Still creating... [03m40s elapsed]
google_sql_database_instance.main: Still creating... [03m30s elapsed]
google_container_cluster.main: Still creating... [04m00s elapsed]
google_memorystore_instance.main: Still creating... [03m50s elapsed]
google_sql_database_instance.main: Still creating... [03m40s elapsed]
google_container_cluster.main: Still creating... [04m10s elapsed]
google_memorystore_instance.main: Still creating... [04m00s elapsed]
google_sql_database_instance.main: Still creating... [03m50s elapsed]
google_container_cluster.main: Still creating... [04m20s elapsed]
google_memorystore_instance.main: Still creating... [04m10s elapsed]
google_sql_database_instance.main: Still creating... [04m00s elapsed]
google_container_cluster.main: Still creating... [04m30s elapsed]
google_memorystore_instance.main: Still creating... [04m20s elapsed]
google_sql_database_instance.main: Still creating... [04m10s elapsed]
google_container_cluster.main: Still creating... [04m40s elapsed]
google_memorystore_instance.main: Still creating... [04m31s elapsed]
google_sql_database_instance.main: Still creating... [04m20s elapsed]
google_container_cluster.main: Still creating... [04m50s elapsed]
google_memorystore_instance.main: Still creating... [04m41s elapsed]
google_sql_database_instance.main: Still creating... [04m30s elapsed]
google_container_cluster.main: Still creating... [05m00s elapsed]
google_memorystore_instance.main: Still creating... [04m51s elapsed]
google_sql_database_instance.main: Still creating... [04m40s elapsed]
google_container_cluster.main: Still creating... [05m10s elapsed]
google_memorystore_instance.main: Still creating... [05m01s elapsed]
google_sql_database_instance.main: Still creating... [04m50s elapsed]
google_container_cluster.main: Still creating... [05m20s elapsed]
google_memorystore_instance.main: Still creating... [05m11s elapsed]
google_sql_database_instance.main: Still creating... [05m00s elapsed]
google_container_cluster.main: Still creating... [05m30s elapsed]
google_memorystore_instance.main: Still creating... [05m21s elapsed]
google_sql_database_instance.main: Still creating... [05m10s elapsed]
google_memorystore_instance.main: Creation complete after 5m25s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache]
google_container_cluster.main: Still creating... [05m40s elapsed]
google_sql_database_instance.main: Still creating... [05m20s elapsed]
google_container_cluster.main: Still creating... [05m50s elapsed]
google_sql_database_instance.main: Still creating... [05m30s elapsed]
google_container_cluster.main: Still creating... [06m00s elapsed]
google_sql_database_instance.main: Still creating... [05m40s elapsed]
google_container_cluster.main: Still creating... [06m10s elapsed]
google_sql_database_instance.main: Still creating... [05m50s elapsed]
google_container_cluster.main: Still creating... [06m20s elapsed]
google_sql_database_instance.main: Still creating... [06m00s elapsed]
google_container_cluster.main: Still creating... [06m30s elapsed]
google_sql_database_instance.main: Still creating... [06m10s elapsed]
google_container_cluster.main: Still creating... [06m40s elapsed]
google_sql_database_instance.main: Still creating... [06m20s elapsed]
google_container_cluster.main: Still creating... [06m50s elapsed]
google_sql_database_instance.main: Still creating... [06m30s elapsed]
google_container_cluster.main: Still creating... [07m00s elapsed]
google_sql_database_instance.main: Still creating... [06m40s elapsed]
google_container_cluster.main: Still creating... [07m10s elapsed]
google_sql_database_instance.main: Still creating... [06m50s elapsed]
google_container_cluster.main: Still creating... [07m20s elapsed]
google_sql_database_instance.main: Still creating... [07m00s elapsed]
google_container_cluster.main: Still creating... [07m30s elapsed]
google_sql_database_instance.main: Still creating... [07m10s elapsed]
google_container_cluster.main: Still creating... [07m40s elapsed]
google_sql_database_instance.main: Still creating... [07m20s elapsed]
google_container_cluster.main: Still creating... [07m50s elapsed]
google_sql_database_instance.main: Still creating... [07m30s elapsed]
google_container_cluster.main: Still creating... [08m00s elapsed]
google_sql_database_instance.main: Still creating... [07m40s elapsed]
google_container_cluster.main: Still creating... [08m10s elapsed]
google_sql_database_instance.main: Still creating... [07m50s elapsed]
google_container_cluster.main: Still creating... [08m20s elapsed]
google_sql_database_instance.main: Still creating... [08m00s elapsed]
google_container_cluster.main: Still creating... [08m30s elapsed]
google_sql_database_instance.main: Still creating... [08m10s elapsed]
google_container_cluster.main: Still creating... [08m40s elapsed]
google_sql_database_instance.main: Still creating... [08m20s elapsed]
google_container_cluster.main: Still creating... [08m50s elapsed]
google_sql_database_instance.main: Still creating... [08m30s elapsed]
google_container_cluster.main: Still creating... [09m00s elapsed]
google_sql_database_instance.main: Still creating... [08m40s elapsed]
google_container_cluster.main: Still creating... [09m10s elapsed]
google_sql_database_instance.main: Still creating... [08m50s elapsed]
google_container_cluster.main: Still creating... [09m20s elapsed]
google_sql_database_instance.main: Still creating... [09m00s elapsed]
google_container_cluster.main: Still creating... [09m30s elapsed]
google_sql_database_instance.main: Still creating... [09m10s elapsed]
google_container_cluster.main: Still creating... [09m40s elapsed]
google_sql_database_instance.main: Still creating... [09m20s elapsed]
google_container_cluster.main: Still creating... [09m50s elapsed]
google_sql_database_instance.main: Still creating... [09m30s elapsed]
google_container_cluster.main: Still creating... [10m00s elapsed]
google_sql_database_instance.main: Still creating... [09m40s elapsed]
google_container_cluster.main: Still creating... [10m10s elapsed]
google_sql_database_instance.main: Still creating... [09m50s elapsed]
google_container_cluster.main: Still creating... [10m20s elapsed]
google_sql_database_instance.main: Still creating... [10m00s elapsed]
google_container_cluster.main: Still creating... [10m30s elapsed]
google_sql_database_instance.main: Still creating... [10m10s elapsed]
google_container_cluster.main: Still creating... [10m40s elapsed]
google_sql_database_instance.main: Still creating... [10m20s elapsed]
google_container_cluster.main: Still creating... [10m50s elapsed]
google_sql_database_instance.main: Still creating... [10m30s elapsed]
google_container_cluster.main: Still creating... [11m00s elapsed]
google_sql_database_instance.main: Still creating... [10m40s elapsed]
google_container_cluster.main: Still creating... [11m10s elapsed]
google_sql_database_instance.main: Still creating... [10m50s elapsed]
google_container_cluster.main: Creation complete after 11m12s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke]
google_service_account_iam_member.app_workload_identity: Creating...
google_container_node_pool.main: Creating...
google_container_node_pool.extra: Creating...
google_service_account_iam_member.app_workload_identity: Creation complete after 4s [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com/roles/iam.workloadIdentityUser/serviceAccount:project-4c5a8821-da4c-4c68-97f.svc.id.goog[default/grid-meter-app]]
google_sql_database_instance.main: Still creating... [11m00s elapsed]
google_container_node_pool.main: Still creating... [00m10s elapsed]
google_container_node_pool.extra: Still creating... [00m10s elapsed]
google_sql_database_instance.main: Still creating... [11m10s elapsed]
google_container_node_pool.extra: Still creating... [00m20s elapsed]
google_container_node_pool.main: Still creating... [00m20s elapsed]
google_sql_database_instance.main: Still creating... [11m20s elapsed]
google_container_node_pool.main: Still creating... [00m30s elapsed]
google_container_node_pool.extra: Still creating... [00m30s elapsed]
google_sql_database_instance.main: Still creating... [11m30s elapsed]
google_container_node_pool.extra: Still creating... [00m40s elapsed]
google_container_node_pool.main: Still creating... [00m40s elapsed]
google_sql_database_instance.main: Creation complete after 11m38s [id=grid-meter-app-postgres]
google_sql_user.main: Creating...
google_container_node_pool.extra: Still creating... [00m50s elapsed]
google_container_node_pool.main: Still creating... [00m50s elapsed]
google_sql_user.main: Creation complete after 4s [id=gridmeter//grid-meter-app-postgres]
google_sql_database.main: Creating...
google_sql_database.main: Creation complete after 6s [id=projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter]
google_container_node_pool.main: Still creating... [01m00s elapsed]
google_container_node_pool.extra: Still creating... [01m00s elapsed]
google_container_node_pool.extra: Still creating... [01m10s elapsed]
google_container_node_pool.main: Still creating... [01m10s elapsed]
google_container_node_pool.main: Still creating... [01m20s elapsed]
google_container_node_pool.extra: Still creating... [01m20s elapsed]
google_container_node_pool.extra: Creation complete after 1m23s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes-extra]
google_container_node_pool.main: Still creating... [01m30s elapsed]
google_container_node_pool.main: Still creating... [01m40s elapsed]
google_container_node_pool.main: Still creating... [01m50s elapsed]
google_container_node_pool.main: Still creating... [02m00s elapsed]
google_container_node_pool.main: Still creating... [02m10s elapsed]
google_container_node_pool.main: Still creating... [02m20s elapsed]
google_container_node_pool.main: Still creating... [02m30s elapsed]
google_container_node_pool.main: Still creating... [02m40s elapsed]
google_container_node_pool.main: Still creating... [02m50s elapsed]
google_container_node_pool.main: Still creating... [03m00s elapsed]
google_container_node_pool.main: Still creating... [03m10s elapsed]
google_container_node_pool.main: Still creating... [03m20s elapsed]
google_container_node_pool.main: Still creating... [03m30s elapsed]
google_container_node_pool.main: Still creating... [03m40s elapsed]
google_container_node_pool.main: Still creating... [03m50s elapsed]
google_container_node_pool.main: Still creating... [04m00s elapsed]
google_container_node_pool.main: Still creating... [04m10s elapsed]
google_container_node_pool.main: Still creating... [04m20s elapsed]
google_container_node_pool.main: Still creating... [04m30s elapsed]
google_container_node_pool.main: Still creating... [04m40s elapsed]
google_container_node_pool.main: Still creating... [04m50s elapsed]
google_container_node_pool.main: Still creating... [05m00s elapsed]
google_container_node_pool.main: Still creating... [05m10s elapsed]
google_container_node_pool.main: Still creating... [05m20s elapsed]
google_container_node_pool.main: Still creating... [05m30s elapsed]
google_container_node_pool.main: Still creating... [05m40s elapsed]
google_container_node_pool.main: Still creating... [05m50s elapsed]
google_container_node_pool.main: Still creating... [06m00s elapsed]
google_container_node_pool.main: Still creating... [06m10s elapsed]
google_container_node_pool.main: Still creating... [06m20s elapsed]
google_container_node_pool.main: Still creating... [06m30s elapsed]
google_container_node_pool.main: Still creating... [06m40s elapsed]
google_container_node_pool.main: Still creating... [06m50s elapsed]
google_container_node_pool.main: Still creating... [07m00s elapsed]
google_container_node_pool.main: Still creating... [07m10s elapsed]
google_container_node_pool.main: Still creating... [07m20s elapsed]
google_container_node_pool.main: Still creating... [07m30s elapsed]
google_container_node_pool.main: Still creating... [07m40s elapsed]
google_container_node_pool.main: Still creating... [07m50s elapsed]
google_container_node_pool.main: Still creating... [08m00s elapsed]
google_container_node_pool.main: Still creating... [08m10s elapsed]
google_container_node_pool.main: Still creating... [08m20s elapsed]
google_container_node_pool.main: Still creating... [08m30s elapsed]
google_container_node_pool.main: Still creating... [08m40s elapsed]
google_container_node_pool.main: Still creating... [08m50s elapsed]
google_container_node_pool.main: Still creating... [09m00s elapsed]
google_container_node_pool.main: Still creating... [09m10s elapsed]
google_container_node_pool.main: Still creating... [09m20s elapsed]
google_container_node_pool.main: Still creating... [09m30s elapsed]
google_container_node_pool.main: Still creating... [09m40s elapsed]
google_container_node_pool.main: Still creating... [09m50s elapsed]
google_container_node_pool.main: Still creating... [10m00s elapsed]
google_container_node_pool.main: Still creating... [10m10s elapsed]
google_container_node_pool.main: Still creating... [10m20s elapsed]
google_container_node_pool.main: Still creating... [10m30s elapsed]
google_container_node_pool.main: Still creating... [10m40s elapsed]
google_container_node_pool.main: Still creating... [10m50s elapsed]
google_container_node_pool.main: Still creating... [11m00s elapsed]
google_container_node_pool.main: Still creating... [11m10s elapsed]
google_container_node_pool.main: Still creating... [11m20s elapsed]
google_container_node_pool.main: Still creating... [11m30s elapsed]
google_container_node_pool.main: Still creating... [11m40s elapsed]
google_container_node_pool.main: Still creating... [11m50s elapsed]
google_container_node_pool.main: Still creating... [12m00s elapsed]
google_container_node_pool.main: Still creating... [12m10s elapsed]
google_container_node_pool.main: Still creating... [12m20s elapsed]
google_container_node_pool.main: Still creating... [12m30s elapsed]
google_container_node_pool.main: Still creating... [12m40s elapsed]
google_container_node_pool.main: Still creating... [12m50s elapsed]
google_container_node_pool.main: Still creating... [13m00s elapsed]
google_container_node_pool.main: Still creating... [13m10s elapsed]
google_container_node_pool.main: Still creating... [13m20s elapsed]
google_container_node_pool.main: Still creating... [13m30s elapsed]
google_container_node_pool.main: Still creating... [13m40s elapsed]
google_container_node_pool.main: Still creating... [13m50s elapsed]
google_container_node_pool.main: Still creating... [14m00s elapsed]
google_container_node_pool.main: Still creating... [14m10s elapsed]
google_container_node_pool.main: Still creating... [14m20s elapsed]
google_container_node_pool.main: Still creating... [14m30s elapsed]
google_container_node_pool.main: Still creating... [14m40s elapsed]
google_container_node_pool.main: Still creating... [14m50s elapsed]
google_container_node_pool.main: Still creating... [15m00s elapsed]
google_container_node_pool.main: Still creating... [15m10s elapsed]
google_container_node_pool.main: Still creating... [15m20s elapsed]
google_container_node_pool.main: Still creating... [15m30s elapsed]
google_container_node_pool.main: Still creating... [15m40s elapsed]
google_container_node_pool.main: Still creating... [15m50s elapsed]
google_container_node_pool.main: Still creating... [16m00s elapsed]
google_container_node_pool.main: Still creating... [16m10s elapsed]
google_container_node_pool.main: Still creating... [16m20s elapsed]
google_container_node_pool.main: Still creating... [16m30s elapsed]
google_container_node_pool.main: Still creating... [16m40s elapsed]
google_container_node_pool.main: Still creating... [16m50s elapsed]
google_container_node_pool.main: Still creating... [17m00s elapsed]
google_container_node_pool.main: Still creating... [17m10s elapsed]
google_container_node_pool.main: Still creating... [17m20s elapsed]
google_container_node_pool.main: Still creating... [17m30s elapsed]
google_container_node_pool.main: Still creating... [17m40s elapsed]
google_container_node_pool.main: Still creating... [17m50s elapsed]
google_container_node_pool.main: Still creating... [18m00s elapsed]
google_container_node_pool.main: Still creating... [18m10s elapsed]
google_container_node_pool.main: Still creating... [18m20s elapsed]
google_container_node_pool.main: Still creating... [18m30s elapsed]
google_container_node_pool.main: Still creating... [18m40s elapsed]
google_container_node_pool.main: Still creating... [18m50s elapsed]
google_container_node_pool.main: Still creating... [19m00s elapsed]
google_container_node_pool.main: Still creating... [19m10s elapsed]
google_container_node_pool.main: Still creating... [19m20s elapsed]
google_container_node_pool.main: Still creating... [19m30s elapsed]
google_container_node_pool.main: Still creating... [19m40s elapsed]
google_container_node_pool.main: Still creating... [19m50s elapsed]
google_container_node_pool.main: Still creating... [20m00s elapsed]
google_container_node_pool.main: Still creating... [20m10s elapsed]
google_container_node_pool.main: Still creating... [20m20s elapsed]
google_container_node_pool.main: Still creating... [20m30s elapsed]
google_container_node_pool.main: Still creating... [20m40s elapsed]
google_container_node_pool.main: Still creating... [20m50s elapsed]
google_container_node_pool.main: Still creating... [21m00s elapsed]
google_container_node_pool.main: Still creating... [21m10s elapsed]
google_container_node_pool.main: Still creating... [21m20s elapsed]
google_container_node_pool.main: Still creating... [21m30s elapsed]
google_container_node_pool.main: Still creating... [21m40s elapsed]
google_container_node_pool.main: Still creating... [21m50s elapsed]
google_container_node_pool.main: Still creating... [22m00s elapsed]
google_container_node_pool.main: Still creating... [22m10s elapsed]
google_container_node_pool.main: Still creating... [22m20s elapsed]
google_container_node_pool.main: Still creating... [22m30s elapsed]
google_container_node_pool.main: Still creating... [22m40s elapsed]
google_container_node_pool.main: Still creating... [22m50s elapsed]
google_container_node_pool.main: Still creating... [23m00s elapsed]
google_container_node_pool.main: Still creating... [23m10s elapsed]
google_container_node_pool.main: Still creating... [23m20s elapsed]
google_container_node_pool.main: Still creating... [23m30s elapsed]
google_container_node_pool.main: Still creating... [23m40s elapsed]
google_container_node_pool.main: Still creating... [23m50s elapsed]
google_container_node_pool.main: Still creating... [24m00s elapsed]
google_container_node_pool.main: Still creating... [24m10s elapsed]
google_container_node_pool.main: Still creating... [24m20s elapsed]
google_container_node_pool.main: Still creating... [24m30s elapsed]
google_container_node_pool.main: Still creating... [24m40s elapsed]
google_container_node_pool.main: Still creating... [24m50s elapsed]
google_container_node_pool.main: Still creating... [25m00s elapsed]
google_container_node_pool.main: Still creating... [25m10s elapsed]
google_container_node_pool.main: Still creating... [25m20s elapsed]
google_container_node_pool.main: Still creating... [25m30s elapsed]
google_container_node_pool.main: Still creating... [25m40s elapsed]
google_container_node_pool.main: Still creating... [25m50s elapsed]
google_container_node_pool.main: Still creating... [26m00s elapsed]
google_container_node_pool.main: Still creating... [26m10s elapsed]
google_container_node_pool.main: Still creating... [26m20s elapsed]
google_container_node_pool.main: Still creating... [26m30s elapsed]
google_container_node_pool.main: Still creating... [26m40s elapsed]
google_container_node_pool.main: Still creating... [26m50s elapsed]
google_container_node_pool.main: Still creating... [27m00s elapsed]
google_container_node_pool.main: Still creating... [27m10s elapsed]
google_container_node_pool.main: Still creating... [27m20s elapsed]
google_container_node_pool.main: Still creating... [27m30s elapsed]
google_container_node_pool.main: Still creating... [27m40s elapsed]
google_container_node_pool.main: Still creating... [27m50s elapsed]
google_container_node_pool.main: Still creating... [28m00s elapsed]
google_container_node_pool.main: Still creating... [28m10s elapsed]
google_container_node_pool.main: Still creating... [28m20s elapsed]
google_container_node_pool.main: Still creating... [28m30s elapsed]
google_container_node_pool.main: Still creating... [28m40s elapsed]
google_container_node_pool.main: Still creating... [28m50s elapsed]
google_container_node_pool.main: Still creating... [29m00s elapsed]
google_container_node_pool.main: Still creating... [29m10s elapsed]
google_container_node_pool.main: Still creating... [29m20s elapsed]
google_container_node_pool.main: Still creating... [29m30s elapsed]
google_container_node_pool.main: Still creating... [29m40s elapsed]
google_container_node_pool.main: Still creating... [31m15s elapsed]
google_container_node_pool.main: Still creating... [31m25s elapsed]
google_container_node_pool.main: Still creating... [31m35s elapsed]
google_container_node_pool.main: Still creating... [31m45s elapsed]
google_container_node_pool.main: Still creating... [36m10s elapsed]
google_container_node_pool.main: Still creating... [36m20s elapsed]
google_container_node_pool.main: Still creating... [36m30s elapsed]
google_container_node_pool.main: Still creating... [36m40s elapsed]
google_container_node_pool.main: Still creating... [36m50s elapsed]
google_container_node_pool.main: Still creating... [37m00s elapsed]
google_container_node_pool.main: Still creating... [37m10s elapsed]
google_container_node_pool.main: Still creating... [37m20s elapsed]
google_container_node_pool.main: Still creating... [37m30s elapsed]
google_container_node_pool.main: Still creating... [37m40s elapsed]
google_container_node_pool.main: Still creating... [37m50s elapsed]
google_container_node_pool.main: Still creating... [38m00s elapsed]
google_container_node_pool.main: Still creating... [38m10s elapsed]
google_container_node_pool.main: Still creating... [38m20s elapsed]
google_container_node_pool.main: Still creating... [38m30s elapsed]
google_container_node_pool.main: Still creating... [38m40s elapsed]
google_container_node_pool.main: Still creating... [38m50s elapsed]
google_container_node_pool.main: Still creating... [39m00s elapsed]
google_container_node_pool.main: Still creating... [41m10s elapsed]
google_container_node_pool.main: Still creating... [41m20s elapsed]
google_container_node_pool.main: Still creating... [41m30s elapsed]
google_container_node_pool.main: Still creating... [41m40s elapsed]
google_container_node_pool.main: Still creating... [41m50s elapsed]
google_container_node_pool.main: Still creating... [54m58s elapsed]

Error: NodePool grid-meter-app-nodes was created in the error state "RUNNING_WITH_ERROR"

  with google_container_node_pool.main,
  on gke.tf line 161, in resource "google_container_node_pool" "main":
 161: resource "google_container_node_pool" "main" {

tim@Timothys-MacBook-Air gcp % 
tim@Timothys-MacBook-Air gcp % terraform state list
google_artifact_registry_repository.api
google_artifact_registry_repository.frontend
google_compute_global_address.private_service_access
google_compute_network.main
google_compute_router.main
google_compute_router_nat.main
google_compute_subnetwork.main
google_container_cluster.main
google_container_node_pool.extra
google_container_node_pool.main
google_memorystore_instance.main
google_network_connectivity_service_connection_policy.memorystore
google_project_iam_member.app_memorystore_connect
google_project_iam_member.gke_node_artifact_registry
google_project_iam_member.gke_node_sa
google_secret_manager_secret.cloudsql_password
google_secret_manager_secret_version.cloudsql_password
google_service_account.app
google_service_account.gke_node
google_service_account_iam_member.app_workload_identity
google_service_networking_connection.private_service_access
google_sql_database.main
google_sql_database_instance.main
google_sql_user.main
random_password.cloudsql
tim@Timothys-MacBook-Air gcp % 
tim@Timothys-MacBook-Air gcp % terraform apply tfplan-fix
google_container_node_pool.main: Destroying... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m10s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m20s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m30s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m40s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m50s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m00s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m10s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m20s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m30s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m40s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m50s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m00s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m10s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m20s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m30s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m40s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m50s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m00s elapsed]
google_container_node_pool.main: Still destroying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m10s elapsed]
google_container_node_pool.main: Destruction complete after 3m13s
google_container_node_pool.main: Creating...
google_container_node_pool.main: Still creating... [00m10s elapsed]
google_container_node_pool.main: Still creating... [00m20s elapsed]
google_container_node_pool.main: Still creating... [00m30s elapsed]
google_container_node_pool.main: Still creating... [00m40s elapsed]
google_container_node_pool.main: Still creating... [00m50s elapsed]
google_container_node_pool.main: Still creating... [01m00s elapsed]
google_container_node_pool.main: Still creating... [01m10s elapsed]
google_container_node_pool.main: Still creating... [01m20s elapsed]
google_container_node_pool.main: Still creating... [01m30s elapsed]
google_container_node_pool.main: Still creating... [01m40s elapsed]
google_container_node_pool.main: Still creating... [01m50s elapsed]
google_container_node_pool.main: Creation complete after 1m53s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.1.0.9"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = <sensitive>
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.3"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % terraform state list
google_artifact_registry_repository.api
google_artifact_registry_repository.frontend
google_compute_global_address.private_service_access
google_compute_network.main
google_compute_router.main
google_compute_router_nat.main
google_compute_subnetwork.main
google_container_cluster.main
google_container_node_pool.extra
google_container_node_pool.main
google_memorystore_instance.main
google_network_connectivity_service_connection_policy.memorystore
google_project_iam_member.app_memorystore_connect
google_project_iam_member.gke_node_artifact_registry
google_project_iam_member.gke_node_sa
google_secret_manager_secret.cloudsql_password
google_secret_manager_secret_version.cloudsql_password
google_service_account.app
google_service_account.gke_node
google_service_account_iam_member.app_workload_identity
google_service_networking_connection.private_service_access
google_sql_database.main
google_sql_database_instance.main
google_sql_user.main
random_password.cloudsql


tim@Timothys-MacBook-Air gcp % terraform state show google_container_node_pool.main
# google_container_node_pool.main:
resource "google_container_node_pool" "main" {
    cluster                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    deletion_policy             = "DELETE"
    id                          = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes"
    ignore_node_count_changes   = false
    initial_node_count          = 3
    instance_group_urls         = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-grp",
    ]
    location                    = "us-central1-a"
    managed_instance_group_urls = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-grp",
    ]
    max_pods_per_node           = 110
    name                        = "grid-meter-app-nodes"
    name_prefix                 = null
    node_count                  = 3
    node_locations              = [
        "us-central1-a",
    ]
    project                     = "project-4c5a8821-da4c-4c68-97f"
    version                     = "1.35.8-gke.1036000"

    management {
        auto_repair  = true
        auto_upgrade = true
    }

    network_config {
        accelerator_network_profile = null
        create_pod_range            = false
        enable_private_nodes        = true
        pod_ipv4_cidr_block         = "10.11.0.0/16"
        pod_range                   = "grid-meter-app-pods"
        subnetwork                  = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    }

    node_config {
        boot_disk_kms_key           = null
        disk_size_gb                = 30
        disk_type                   = "pd-standard"
        effective_taints            = []
        enable_confidential_storage = false
        flex_start                  = false
        gpudirect_strategy          = null
        image_type                  = "COS_CONTAINERD"
        labels                      = {}
        local_ssd_count             = 0
        local_ssd_encryption_mode   = null
        logging_variant             = "DEFAULT"
        machine_type                = "e2-medium"
        max_run_duration            = null
        metadata                    = {
            "disable-legacy-endpoints" = "true"
        }
        min_cpu_platform            = null
        node_group                  = null
        oauth_scopes                = [
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
        ]
        preemptible                 = false
        resource_labels             = {
            "goog-gke-node-pool-provisioning-model" = "on-demand"
        }
        service_account             = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
        spot                        = false

        boot_disk {
            disk_type              = "pd-standard"
            provisioned_iops       = 0
            provisioned_throughput = 0
            size_gb                = 30
        }

        kubelet_config {
            allowed_unsafe_sysctls                      = []
            container_log_max_files                     = 0
            container_log_max_size                      = null
            cpu_cfs_quota                               = false
            cpu_cfs_quota_period                        = null
            cpu_manager_policy                          = null
            eviction_max_pod_grace_period_seconds       = 0
            image_gc_high_threshold_percent             = 0
            image_gc_low_threshold_percent              = 0
            image_maximum_gc_age                        = null
            image_minimum_gc_age                        = null
            insecure_kubelet_readonly_port_enabled      = "FALSE"
            max_parallel_image_pulls                    = 2
            pod_pids_limit                              = 0
            shutdown_grace_period_critical_pods_seconds = 0
            shutdown_grace_period_seconds               = 0
            single_process_oom_kill                     = false
        }

        node_image_config {
            image         = "gke-1358-gke1036000-cos-125-19216-532-123-c-pre"
            image_project = "gke-node-images"
        }

        shielded_instance_config {
            enable_integrity_monitoring = true
            enable_secure_boot          = false
        }

        windows_node_config {
            osversion = null
        }

        workload_metadata_config {
            mode = "GKE_METADATA"
        }
    }

    upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
        strategy        = "SURGE"
    }
}
tim@Timothys-MacBook-Air gcp % terraform state show google_container_node_pool.extra
# google_container_node_pool.extra:
resource "google_container_node_pool" "extra" {
    cluster                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    deletion_policy             = "DELETE"
    id                          = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes-extra"
    ignore_node_count_changes   = false
    initial_node_count          = 1
    instance_group_urls         = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-grp",
    ]
    location                    = "us-central1-a"
    managed_instance_group_urls = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-grp",
    ]
    max_pods_per_node           = 110
    name                        = "grid-meter-app-nodes-extra"
    name_prefix                 = null
    node_count                  = 1
    node_locations              = [
        "us-central1-a",
    ]
    project                     = "project-4c5a8821-da4c-4c68-97f"
    version                     = "1.35.8-gke.1036000"

    management {
        auto_repair  = true
        auto_upgrade = true
    }

    network_config {
        accelerator_network_profile = null
        create_pod_range            = false
        enable_private_nodes        = true
        pod_ipv4_cidr_block         = "10.11.0.0/16"
        pod_range                   = "grid-meter-app-pods"
        subnetwork                  = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    }

    node_config {
        boot_disk_kms_key           = null
        disk_size_gb                = 30
        disk_type                   = "pd-standard"
        effective_taints            = []
        enable_confidential_storage = false
        flex_start                  = false
        gpudirect_strategy          = null
        image_type                  = "COS_CONTAINERD"
        labels                      = {}
        local_ssd_count             = 0
        local_ssd_encryption_mode   = null
        logging_variant             = "DEFAULT"
        machine_type                = "e2-medium"
        max_run_duration            = null
        metadata                    = {
            "disable-legacy-endpoints" = "true"
        }
        min_cpu_platform            = null
        node_group                  = null
        oauth_scopes                = [
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
        ]
        preemptible                 = false
        resource_labels             = {
            "goog-gke-node-pool-provisioning-model" = "on-demand"
        }
        resource_manager_tags       = {}
        service_account             = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
        spot                        = false
        storage_pools               = []
        tags                        = []

        boot_disk {
            disk_type              = "pd-standard"
            provisioned_iops       = 0
            provisioned_throughput = 0
            size_gb                = 30
        }

        kubelet_config {
            allowed_unsafe_sysctls                      = []
            container_log_max_files                     = 0
            container_log_max_size                      = null
            cpu_cfs_quota                               = false
            cpu_cfs_quota_period                        = null
            cpu_manager_policy                          = null
            eviction_max_pod_grace_period_seconds       = 0
            image_gc_high_threshold_percent             = 0
            image_gc_low_threshold_percent              = 0
            image_maximum_gc_age                        = null
            image_minimum_gc_age                        = null
            insecure_kubelet_readonly_port_enabled      = "FALSE"
            max_parallel_image_pulls                    = 2
            pod_pids_limit                              = 0
            shutdown_grace_period_critical_pods_seconds = 0
            shutdown_grace_period_seconds               = 0
            single_process_oom_kill                     = false
        }

        node_image_config {
            image         = "gke-1358-gke1036000-cos-125-19216-532-123-c-pre"
            image_project = "gke-node-images"
        }

        shielded_instance_config {
            enable_integrity_monitoring = true
            enable_secure_boot          = false
        }

        windows_node_config {
            osversion = null
        }

        workload_metadata_config {
            mode = "GKE_METADATA"
        }
    }

    upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
        strategy        = "SURGE"
    }
}
tim@Timothys-MacBook-Air gcp % ./check-resources-gcp.sh 
== Checking Terraform-provisioned GCP resources for cluster 'grid-meter-app-gke' (project: project-4c5a8821-da4c-4c68-97f, region: us-central1) ==

-- Networking --
  PASS  VPC: grid-meter-app-vpc
  PASS  Subnet: grid-meter-app-subnet
  PASS  Cloud Router: grid-meter-app-router
  PASS  Cloud NAT: grid-meter-app-nat
  PASS  Private Service Access peering: servicenetworking-googleapis-com

-- GKE --
  PASS  GKE cluster status: RUNNING
  PASS  GKE node pool status: RUNNING
  PASS  GKE node service account: grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com
  PASS  GCE worker instances (expect 3, RUNNING): gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h

-- Data tier --
  PASS  Cloud SQL instance state: RUNNABLE
  PASS  Cloud SQL database version: POSTGRES_18
  PASS  Cloud SQL database: gridmeter: gridmeter
  PASS  Memorystore for Valkey state: ACTIVE
  PASS  Memorystore engine version: VALKEY_9_0

-- Secret Manager --
  PASS  Cloud SQL password secret: projects/361083726560/secrets/grid-meter-app-cloudsql-password

-- Artifact Registry --
  PASS  Repo: api: projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api
  PASS  Repo: frontend: projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend

== Summary: 17 passed, 0 failed ==
All expected Terraform-provisioned resources confirmed present and healthy.
tim@Timothys-MacBook-Air gcp % cd ../../
tim@Timothys-MacBook-Air grid-meter-app % ./k8s/deploy-gcp.sh          
== Reading Terraform outputs ==
== Fetching kubeconfig for grid-meter-app-gke ==
Fetching cluster endpoint and auth data.
kubeconfig entry generated for grid-meter-app-gke.
== Authenticating Docker to Artifact Registry ==
WARNING: Your config file at [/Users/tim/.docker/config.json] contains these credential helper entries:

{
  "credHelpers": {
    "us-central1-docker.pkg.dev": "gcloud"
  }
}
Adding credentials for: us-central1-docker.pkg.dev
gcloud credential helpers already registered correctly.
== Building + pushing images (tag: latest, platform: linux/amd64) ==
[+] Building 14.7s (17/17) FINISHED                                                        docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                       0.0s
 => => transferring dockerfile: 373B                                                                       0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:25-jre-alpine                           0.0s
 => [internal] load metadata for docker.io/library/maven:3.9-eclipse-temurin-25                            0.0s
 => [internal] load .dockerignore                                                                          0.0s
 => => transferring context: 2B                                                                            0.0s
 => [build 1/6] FROM docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83  0.0s
 => => resolve docker.io/library/maven:3.9-eclipse-temurin-25@sha256:d67198007bb4441b07d45587320f83154de8  0.0s
 => [stage-1 1/3] FROM docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a21  0.0s
 => => resolve docker.io/library/eclipse-temurin:25-jre-alpine@sha256:3137541deb3cac6626b5d9a4a2187bc0d6a  0.0s
 => [internal] load build context                                                                          0.0s
 => => transferring context: 8.49kB                                                                        0.0s
 => CACHED [stage-1 2/3] WORKDIR /app                                                                      0.0s
 => CACHED [build 2/6] WORKDIR /build                                                                      0.0s
 => CACHED [build 3/6] COPY pom.xml .                                                                      0.0s
 => CACHED [build 4/6] RUN mvn dependency:go-offline                                                       0.0s
 => CACHED [build 5/6] COPY src ./src                                                                      0.0s
 => CACHED [build 6/6] RUN mvn package -DskipTests                                                         0.0s
 => CACHED [stage-1 3/3] COPY --from=build /build/target/*.jar app.jar                                     0.0s
 => exporting to image                                                                                    14.6s
 => => exporting layers                                                                                    0.0s
 => => exporting manifest sha256:b8e5244a44d03dc311a8831999178555b2c7dc0b76af8a0f415c284dc51d08c6          0.0s
 => => exporting config sha256:0bf8173fdd5dfc0498609cbc24d67a0900c02d46c7e25fe8592abeeb4b10d4c9            0.0s
 => => naming to us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api:latest   0.0s
 => => pushing layers                                                                                     14.2s
 => => pushing manifest for us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/  0.5s
 => [auth] project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api:pull,push token for us-central1-docker.p  0.0s
 => [auth] project-4c5a8821-da4c-4c68-97f/grid-meter-app-api:pull project-4c5a8821-da4c-4c68-97f/grid-met  0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/xekbroi6ply33km97gucxjde7
[+] Building 6.5s (16/16) FINISHED                                                         docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                       0.0s
 => => transferring dockerfile: 337B                                                                       0.0s
 => [internal] load metadata for docker.io/library/node:24-alpine                                          0.0s
 => [internal] load metadata for docker.io/library/nginx:1.27-alpine                                       0.0s
 => [internal] load .dockerignore                                                                          0.0s
 => => transferring context: 2B                                                                            0.0s
 => [build 1/6] FROM docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b64130  0.0s
 => => resolve docker.io/library/node:24-alpine@sha256:e67514e5d0f6c46656005e1b693b2ec9d52e80b641307de684  0.0s
 => [internal] load build context                                                                          1.1s
 => => transferring context: 4.04MB                                                                        1.0s
 => [stage-1 1/3] FROM docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd  0.0s
 => => resolve docker.io/library/nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a5  0.0s
 => CACHED [build 2/6] WORKDIR /build                                                                      0.0s
 => CACHED [build 3/6] COPY package.json package-lock.json ./                                              0.0s
 => CACHED [build 4/6] RUN npm ci                                                                          0.0s
 => CACHED [build 5/6] COPY . .                                                                            0.0s
 => CACHED [build 6/6] RUN npm run build                                                                   0.0s
 => CACHED [stage-1 2/3] COPY --from=build /build/dist /usr/share/nginx/html                               0.0s
 => CACHED [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf                                    0.0s
 => exporting to image                                                                                     5.3s
 => => exporting layers                                                                                    0.0s
 => => exporting manifest sha256:84b707d06b573d0b966201213a6a2fe21606bf20a7c7e5f35d3d9c410836a67a          0.0s
 => => exporting config sha256:53077f1e6d67a3710e1346f67449392cfbcd71390e725b33c0a1e9039fd46011            0.0s
 => => naming to us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/fronte  0.0s
 => => pushing layers                                                                                      4.9s
 => => pushing manifest for us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-fron  0.4s
 => [auth] project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend:pull,push token for us-central  0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/3ezemj9tlv1he3vey1plo3hw3
== Applying Traefik CRDs + RBAC (shared with kind/AWS) ==
customresourcedefinition.apiextensions.k8s.io/ingressroutes.traefik.io created
customresourcedefinition.apiextensions.k8s.io/ingressroutetcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/ingressrouteudps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/middlewares.traefik.io created
customresourcedefinition.apiextensions.k8s.io/middlewaretcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/serverstransports.traefik.io created
customresourcedefinition.apiextensions.k8s.io/serverstransporttcps.traefik.io created
customresourcedefinition.apiextensions.k8s.io/tlsoptions.traefik.io created
customresourcedefinition.apiextensions.k8s.io/tlsstores.traefik.io created
customresourcedefinition.apiextensions.k8s.io/traefikservices.traefik.io created
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
== Applying Traefik controller (GCP variant - LoadBalancer, not hostPort) ==
serviceaccount/traefik-ingress-controller created
deployment.apps/traefik created
service/traefik-web created
service/traefik-metrics created
== Un-defaulting GKE's own built-in default StorageClass (standard-rwo) ==
storageclass.storage.k8s.io/standard-rwo patched
== Applying default StorageClass (XFS-formatted, needed for Kafka's PVCs) ==
storageclass.storage.k8s.io/pd-balanced-xfs created
== Fetching the real Cloud SQL password from Secret Manager (never hardcoded) ==
== Generating a fresh JWT signing secret for this deployment ==
== Applying secrets (generated at deploy time, never committed) ==
secret/grid-meter-secrets created
== Applying config (real Cloud SQL/Memorystore endpoints, generated at deploy time) ==
configmap/grid-meter-config created
== Applying Kafka (self-hosted in-cluster, unchanged from every other target) ==
service/kafka-headless created
statefulset.apps/kafka created
== Applying api + frontend (real image baked in before the first apply, not patched after) ==
deployment.apps/api created
service/api created
deployment.apps/frontend created
service/frontend created
== Forcing a rollout restart (picks up a freshly-pushed :latest on a repeat run of this script) ==
deployment.apps/api restarted
deployment.apps/frontend restarted
== Applying IngressRoute (target-agnostic - only references Service names) ==
ingressroute.traefik.io/grid-meter created
== Waiting for rollouts ==
deployment "traefik" successfully rolled out
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 3 new pods have been updated...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "api" rollout to finish: 1 old replicas are pending termination...
deployment "api" successfully rolled out
deployment "frontend" successfully rolled out
== Waiting for the LoadBalancer's public IP (provisioning takes a minute or two) ==

Done. App should be reachable at http://34.9.29.158
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % ./k8s/check-resources-gcp.sh 
== Checking Kubernetes-deployed app layer (context: gke_project-4c5a8821-da4c-4c68-97f_us-central1-a_grid-meter-app-gke) ==

-- Traefik --
  PASS  Traefik Deployment ready: 1/1
  PASS  traefik-web Service type: LoadBalancer
  PASS  traefik-web external IP assigned: 34.9.29.158
  PASS  traefik-metrics Service exists: ClusterIP

-- Kafka --
  PASS  Kafka StatefulSet ready replicas: 3
  PASS  kafka-headless Service exists: None
  PASS  Kafka PVCs bound (expect 3): 3

-- api / frontend --
  PASS  api Deployment ready: 2/2
  PASS  api Service exists: ClusterIP
  PASS  frontend Deployment ready: 1/1
  PASS  frontend Service exists: ClusterIP

-- Config/secrets/routing --
  PASS  grid-meter-config ConfigMap exists: grid-meter-config
  PASS  grid-meter-secrets Secret exists: grid-meter-secrets
  PASS  IngressRoute exists: grid-meter
  PASS  pd-balanced-xfs StorageClass is default: true

-- Observability (optional; only checked if deployed via k8s/deploy-observability.sh) --
  PASS  kube-prometheus-stack-grafana Deployment ready: 1/1
  PASS  Prometheus StatefulSet ready replicas: 1
  PASS  Loki Deployment ready: 1/1
  PASS  Tempo Deployment ready: 1/1
  PASS  Alloy Deployment ready: 1/1
  PASS  grid-meter-api ServiceMonitor exists: grid-meter-api

== Summary: 21 passed, 0 failed ==
All expected Kubernetes-deployed resources confirmed present and healthy.
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air grid-meter-app % kubectl get nodes -A -o wide
NAME                                                  STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   Ready    <none>   90m   v1.35.8-gke.1036000   10.10.0.5     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   Ready    <none>   22m   v1.35.8-gke.1036000   10.10.0.11    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   Ready    <none>   22m   v1.35.8-gke.1036000   10.10.0.10    <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   Ready    <none>   22m   v1.35.8-gke.1036000   10.10.0.9     <none>        Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
tim@Timothys-MacBook-Air grid-meter-app % kubectl get pods -A -o wide
NAMESPACE         NAME                                                             READY   STATUS    RESTARTS   AGE     IP           NODE                                                  NOMINATED NODE   READINESS GATES
default           alloy-76bbd8597-j6n9l                                            1/1     Running   0          106s    10.11.3.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           api-cdb86f4c8-8cxl6                                              1/1     Running   0          16m     10.11.1.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           api-cdb86f4c8-fvbj9                                              1/1     Running   0          17m     10.11.0.17   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           frontend-7b8d7ff885-sxnc5                                        1/1     Running   0          17m     10.11.1.6    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           kafka-0                                                          1/1     Running   0          17m     10.11.3.5    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           kafka-1                                                          1/1     Running   0          16m     10.11.1.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           kafka-2                                                          1/1     Running   0          16m     10.11.2.6    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-grafana-6f676576f9-w4bdm                   3/3     Running   0          3m10s   10.11.2.8    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-kube-state-metrics-5c4dd95655-46xzc        1/1     Running   0          3m10s   10.11.0.18   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           kube-prometheus-stack-operator-5f8985d899-bzb4j                  1/1     Running   0          3m11s   10.11.2.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-hw5tf             1/1     Running   0          3m11s   10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-m98p6             1/1     Running   0          3m11s   10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-pt2wd             1/1     Running   0          3m11s   10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           kube-prometheus-stack-prometheus-node-exporter-tmzj4             1/1     Running   0          3m11s   10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           loki-8574bfc78d-jnxhq                                            1/1     Running   0          108s    10.11.0.19   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
default           prometheus-kube-prometheus-stack-prometheus-0                    2/2     Running   0          3m2s    10.11.3.7    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
default           tempo-6cc5f67c89-b67rt                                           1/1     Running   0          107s    10.11.2.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
default           traefik-7b75595b65-dx5zn                                         1/1     Running   0          17m     10.11.1.4    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
gke-managed-cim   kube-state-metrics-0                                             2/2     Running   0          95m     10.11.0.7    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
gmp-system        collector-5k2p4                                                  2/2     Running   0          22m     10.11.3.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
gmp-system        collector-gl4xc                                                  2/2     Running   0          22m     10.11.2.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
gmp-system        collector-j2d5b                                                  2/2     Running   0          90m     10.11.0.12   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
gmp-system        collector-qj8zb                                                  2/2     Running   0          22m     10.11.1.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
gmp-system        gmp-operator-7b55ccf99-fws95                                     1/1     Running   0          82m     10.11.0.13   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       event-exporter-gke-995cd68c5-6ppvk                               2/2     Running   0          95m     10.11.0.2    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       fluentbit-gke-kfdks                                              3/3     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       fluentbit-gke-p46lf                                              3/3     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       fluentbit-gke-xbnch                                              3/3     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       fluentbit-gke-zlfvh                                              3/3     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       gke-metadata-server-k8bhb                                        1/1     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       gke-metadata-server-nj9g7                                        1/1     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       gke-metadata-server-s96q7                                        1/1     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       gke-metadata-server-vfd74                                        1/1     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       gke-metrics-agent-44g4q                                          3/3     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       gke-metrics-agent-c9p5m                                          3/3     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       gke-metrics-agent-g9v74                                          3/3     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       gke-metrics-agent-m5gjm                                          3/3     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-44dqs                              2/2     Running   0          22m     10.11.3.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-4mbrt                              2/2     Running   0          95m     10.11.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-hcfv2                              2/2     Running   0          22m     10.11.2.4    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       konnectivity-agent-84dfd5c9fd-mn9fj                              2/2     Running   0          22m     10.11.1.3    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       konnectivity-agent-autoscaler-7f44b76cdc-w28nd                   1/1     Running   0          95m     10.11.0.3    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-dns-5954f9f47-fs2d6                                         4/4     Running   0          22m     10.11.2.2    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       kube-dns-5954f9f47-v7f6l                                         4/4     Running   0          95m     10.11.0.10   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-dns-autoscaler-859854db85-t5tf8                             1/1     Running   0          95m     10.11.0.6    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   1/1     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   1/1     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   1/1     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       kube-proxy-gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   1/1     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       l7-default-backend-7d8d77ff56-52qmt                              1/1     Running   0          95m     10.11.0.9    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       metrics-server-v1.35.1-7cdd96f59b-7rf62                          1/1     Running   0          95m     10.11.0.11   gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       netd-7jtgg                                                       3/3     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       netd-j82ml                                                       3/3     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       netd-qwd7c                                                       3/3     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       netd-skhcz                                                       3/3     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       node-local-dns-8bfqp                                             2/2     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       node-local-dns-f4vgm                                             2/2     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       node-local-dns-g8mn5                                             2/2     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       node-local-dns-zsvp5                                             2/2     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
kube-system       pdcsi-node-j8s8s                                                 3/3     Running   0          22m     10.10.0.9    gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-xq4h   <none>           <none>
kube-system       pdcsi-node-lqhrk                                                 3/3     Running   0          22m     10.10.0.11   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-qwgh   <none>           <none>
kube-system       pdcsi-node-rbfx2                                                 3/3     Running   0          90m     10.10.0.5    gke-grid-meter-app-g-grid-meter-app-n-48ff21ee-qts0   <none>           <none>
kube-system       pdcsi-node-sctnz                                                 3/3     Running   0          22m     10.10.0.10   gke-grid-meter-app-g-grid-meter-app-n-d0c4d387-vgnp   <none>           <none>
tim@Timothys-MacBook-Air grid-meter-app % 

tim@Timothys-MacBook-Air gcp % terraform apply tfplan-iam
google_service_account_iam_member.app_token_creator: Creating...
google_service_account_iam_member.app_token_creator: Creation complete after 5s [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com/roles/iam.serviceAccountTokenCreator/serviceAccount:grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

app_service_account_email = "grid-meter-app-app@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api/api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend/frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.1.0.9"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = <sensitive>
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.3"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % terraform state list
google_artifact_registry_repository.api
google_artifact_registry_repository.frontend
google_compute_global_address.private_service_access
google_compute_network.main
google_compute_router.main
google_compute_router_nat.main
google_compute_subnetwork.main
google_container_cluster.main
google_container_node_pool.extra
google_container_node_pool.main
google_memorystore_instance.main
google_network_connectivity_service_connection_policy.memorystore
google_project_iam_member.app_memorystore_connect
google_project_iam_member.gke_node_artifact_registry
google_project_iam_member.gke_node_sa
google_secret_manager_secret.cloudsql_password
google_secret_manager_secret_version.cloudsql_password
google_service_account.app
google_service_account.gke_node
google_service_account_iam_member.app_token_creator
google_service_account_iam_member.app_workload_identity
google_service_networking_connection.private_service_access
google_sql_database.main
google_sql_database_instance.main
google_sql_user.main
random_password.cloudsql
tim@Timothys-MacBook-Air gcp % 


