tim@Timothys-MacBook-Air ~ % cd Documents/workspace/java/apps/grid-meter-app/terraform/gcp/bootstrap
tim@Timothys-MacBook-Air bootstrap % terraform show
# google_storage_bucket.tfstate:
resource "google_storage_bucket" "tfstate" {
    default_event_based_hold    = false
    deletion_policy             = "DELETE"
    effective_labels            = {
        "goog-terraform-provisioned" = "true"
    }
    enable_object_retention     = false
    force_destroy               = false
    id                          = "grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
    location                    = "US-CENTRAL1"
    name                        = "grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
    project                     = "project-4c5a8821-da4c-4c68-97f"
    project_number              = 361083726560
    public_access_prevention    = "enforced"
    requester_pays              = false
    self_link                   = "https://www.googleapis.com/storage/v1/b/grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
    storage_class               = "STANDARD"
    terraform_labels            = {
        "goog-terraform-provisioned" = "true"
    }
    time_created                = "2026-09-21T17:09:34.852Z"
    uniform_bucket_level_access = true
    updated                     = "2026-09-21T17:09:34.852Z"
    url                         = "gs://grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"

    hierarchical_namespace {
        enabled = false
    }

    soft_delete_policy {
        effective_time             = "2026-09-21T17:09:34.852Z"
        retention_duration_seconds = 604800
    }

    versioning {
        enabled = true
    }
}


Outputs:

backend_config_snippet = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
        prefix = "grid-meter-app/terraform.tfstate"
      }
    }
EOT
state_bucket_name = "grid-meter-app-tfstate-project-4c5a8821-da4c-4c68-97f"
tim@Timothys-MacBook-Air bootstrap % 


tim@Timothys-MacBook-Air ~ % cd Documents/workspace/java/apps/grid-meter-app/terraform/gcp 
tim@Timothys-MacBook-Air gcp % terraform plan -out tfplan
random_password.cloudsql: Refreshing state... [id=none]
google_compute_network.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc]
google_service_account.gke_node: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_secret_manager_secret.cloudsql_password: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password]
google_artifact_registry_repository.frontend: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend]
google_artifact_registry_repository.api: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api]
google_secret_manager_secret_version.cloudsql_password: Refreshing state... [id=projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1]
google_project_iam_member.gke_node_sa: Refreshing state... [id=project-4c5a8821-da4c-4c68-97f/roles/container.nodeServiceAccount/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_compute_router.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router]
google_compute_global_address.private_service_access: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range]
google_compute_subnetwork.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet]
google_service_networking_connection.private_service_access: Refreshing state... [id=projects%2Fproject-4c5a8821-da4c-4c68-97f%2Fglobal%2Fnetworks%2Fgrid-meter-app-vpc:servicenetworking.googleapis.com]
google_compute_router_nat.main: Refreshing state... [id=project-4c5a8821-da4c-4c68-97f/us-central1/grid-meter-app-router/grid-meter-app-nat]
google_container_cluster.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke]
google_container_node_pool.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_memorystore_instance.main will be created
  + resource "google_memorystore_instance" "main" {
      + authorization_mode             = (known after apply)
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
      + transit_encryption_mode        = (known after apply)
      + uid                            = (known after apply)
      + update_time                    = (known after apply)

      + cross_instance_replication_config (known after apply)

      + desired_auto_created_endpoints {
          + network    = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
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
      + network          = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
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
          + subnetworks                = [
              + "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet",
            ]
        }
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
              + private_network = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
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

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cloudsql_connection_name              = (known after apply)
  + cloudsql_private_ip                   = (known after apply)
  + memorystore_host                      = (known after apply)
  + memorystore_port                      = (known after apply)

───────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
tim@Timothys-MacBook-Air gcp % terraform apply tfplan
google_network_connectivity_service_connection_policy.memorystore: Creating...
google_sql_database_instance.main: Creating...
google_network_connectivity_service_connection_policy.memorystore: Still creating... [00m10s elapsed]
google_sql_database_instance.main: Still creating... [00m10s elapsed]
google_network_connectivity_service_connection_policy.memorystore: Creation complete after 12s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/serviceConnectionPolicies/grid-meter-app-memorystore-scp]
google_memorystore_instance.main: Creating...
google_sql_database_instance.main: Still creating... [00m20s elapsed]
google_memorystore_instance.main: Still creating... [00m10s elapsed]
google_sql_database_instance.main: Still creating... [00m30s elapsed]
google_memorystore_instance.main: Still creating... [00m20s elapsed]
google_sql_database_instance.main: Still creating... [00m40s elapsed]
google_memorystore_instance.main: Still creating... [00m30s elapsed]
google_sql_database_instance.main: Still creating... [00m50s elapsed]
google_memorystore_instance.main: Still creating... [00m40s elapsed]
google_sql_database_instance.main: Still creating... [01m00s elapsed]
google_memorystore_instance.main: Still creating... [00m50s elapsed]
google_sql_database_instance.main: Still creating... [01m10s elapsed]
google_memorystore_instance.main: Still creating... [01m00s elapsed]
google_sql_database_instance.main: Still creating... [01m20s elapsed]
google_memorystore_instance.main: Still creating... [01m10s elapsed]
google_sql_database_instance.main: Still creating... [01m30s elapsed]
google_memorystore_instance.main: Still creating... [01m20s elapsed]
google_sql_database_instance.main: Still creating... [01m40s elapsed]
google_memorystore_instance.main: Still creating... [01m30s elapsed]
google_sql_database_instance.main: Still creating... [01m50s elapsed]
google_memorystore_instance.main: Still creating... [01m40s elapsed]
google_sql_database_instance.main: Still creating... [02m00s elapsed]
google_memorystore_instance.main: Still creating... [01m50s elapsed]
google_sql_database_instance.main: Still creating... [02m10s elapsed]
google_memorystore_instance.main: Still creating... [02m00s elapsed]
google_sql_database_instance.main: Still creating... [02m20s elapsed]
google_memorystore_instance.main: Still creating... [02m10s elapsed]
google_sql_database_instance.main: Still creating... [02m30s elapsed]
google_memorystore_instance.main: Still creating... [02m20s elapsed]
google_sql_database_instance.main: Still creating... [02m40s elapsed]
google_memorystore_instance.main: Still creating... [02m30s elapsed]
google_sql_database_instance.main: Still creating... [02m50s elapsed]
google_memorystore_instance.main: Still creating... [02m40s elapsed]
google_sql_database_instance.main: Still creating... [03m00s elapsed]
google_memorystore_instance.main: Still creating... [02m50s elapsed]
google_sql_database_instance.main: Still creating... [03m10s elapsed]
google_memorystore_instance.main: Still creating... [03m00s elapsed]
google_sql_database_instance.main: Still creating... [03m20s elapsed]
google_memorystore_instance.main: Still creating... [03m10s elapsed]
google_sql_database_instance.main: Still creating... [03m30s elapsed]
google_memorystore_instance.main: Still creating... [03m20s elapsed]
google_sql_database_instance.main: Still creating... [03m40s elapsed]
google_memorystore_instance.main: Still creating... [03m30s elapsed]
google_sql_database_instance.main: Still creating... [03m50s elapsed]
google_memorystore_instance.main: Still creating... [03m40s elapsed]
google_sql_database_instance.main: Still creating... [04m00s elapsed]
google_memorystore_instance.main: Still creating... [03m50s elapsed]
google_sql_database_instance.main: Still creating... [04m10s elapsed]
google_memorystore_instance.main: Still creating... [04m00s elapsed]
google_sql_database_instance.main: Still creating... [04m20s elapsed]
google_memorystore_instance.main: Still creating... [04m10s elapsed]
google_sql_database_instance.main: Still creating... [04m30s elapsed]
google_memorystore_instance.main: Still creating... [04m20s elapsed]
google_sql_database_instance.main: Still creating... [04m40s elapsed]
google_memorystore_instance.main: Still creating... [04m30s elapsed]
google_sql_database_instance.main: Still creating... [04m50s elapsed]
google_memorystore_instance.main: Still creating... [04m40s elapsed]
google_sql_database_instance.main: Still creating... [05m00s elapsed]
google_memorystore_instance.main: Still creating... [04m50s elapsed]
google_sql_database_instance.main: Still creating... [05m10s elapsed]
google_memorystore_instance.main: Still creating... [05m00s elapsed]
google_sql_database_instance.main: Still creating... [05m20s elapsed]
google_memorystore_instance.main: Still creating... [05m10s elapsed]
google_sql_database_instance.main: Still creating... [05m30s elapsed]
google_memorystore_instance.main: Still creating... [05m20s elapsed]
google_sql_database_instance.main: Still creating... [05m40s elapsed]
google_memorystore_instance.main: Still creating... [05m30s elapsed]
google_sql_database_instance.main: Still creating... [05m50s elapsed]
google_memorystore_instance.main: Still creating... [05m40s elapsed]
google_memorystore_instance.main: Creation complete after 5m45s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache]
google_sql_database_instance.main: Still creating... [06m00s elapsed]
google_sql_database_instance.main: Still creating... [06m10s elapsed]
google_sql_database_instance.main: Still creating... [06m20s elapsed]
google_sql_database_instance.main: Still creating... [06m30s elapsed]
google_sql_database_instance.main: Still creating... [06m40s elapsed]
google_sql_database_instance.main: Still creating... [06m50s elapsed]
google_sql_database_instance.main: Still creating... [07m00s elapsed]
google_sql_database_instance.main: Still creating... [07m10s elapsed]
google_sql_database_instance.main: Still creating... [07m20s elapsed]
google_sql_database_instance.main: Still creating... [07m30s elapsed]
google_sql_database_instance.main: Still creating... [07m40s elapsed]
google_sql_database_instance.main: Still creating... [07m50s elapsed]
google_sql_database_instance.main: Still creating... [08m00s elapsed]
google_sql_database_instance.main: Still creating... [08m10s elapsed]
google_sql_database_instance.main: Still creating... [08m20s elapsed]
google_sql_database_instance.main: Still creating... [08m30s elapsed]
google_sql_database_instance.main: Still creating... [08m40s elapsed]
google_sql_database_instance.main: Still creating... [08m50s elapsed]
google_sql_database_instance.main: Still creating... [09m00s elapsed]
google_sql_database_instance.main: Still creating... [09m10s elapsed]
google_sql_database_instance.main: Still creating... [09m20s elapsed]
google_sql_database_instance.main: Still creating... [09m30s elapsed]
google_sql_database_instance.main: Still creating... [09m40s elapsed]
google_sql_database_instance.main: Still creating... [09m50s elapsed]
google_sql_database_instance.main: Still creating... [10m00s elapsed]
google_sql_database_instance.main: Still creating... [10m10s elapsed]
google_sql_database_instance.main: Still creating... [10m20s elapsed]
google_sql_database_instance.main: Still creating... [10m30s elapsed]
google_sql_database_instance.main: Still creating... [10m40s elapsed]
google_sql_database_instance.main: Still creating... [10m50s elapsed]
google_sql_database_instance.main: Still creating... [11m00s elapsed]
google_sql_database_instance.main: Still creating... [11m10s elapsed]
google_sql_database_instance.main: Still creating... [11m20s elapsed]
google_sql_database_instance.main: Still creating... [11m30s elapsed]
google_sql_database_instance.main: Still creating... [11m40s elapsed]
google_sql_database_instance.main: Still creating... [11m50s elapsed]
google_sql_database_instance.main: Still creating... [12m00s elapsed]
google_sql_database_instance.main: Still creating... [12m10s elapsed]
google_sql_database_instance.main: Still creating... [12m20s elapsed]
google_sql_database_instance.main: Still creating... [12m30s elapsed]
google_sql_database_instance.main: Still creating... [12m40s elapsed]
google_sql_database_instance.main: Still creating... [12m50s elapsed]
google_sql_database_instance.main: Still creating... [13m00s elapsed]
google_sql_database_instance.main: Still creating... [13m10s elapsed]
google_sql_database_instance.main: Still creating... [13m20s elapsed]
google_sql_database_instance.main: Still creating... [13m30s elapsed]
google_sql_database_instance.main: Still creating... [13m40s elapsed]
google_sql_database_instance.main: Still creating... [13m50s elapsed]
google_sql_database_instance.main: Still creating... [14m00s elapsed]
google_sql_database_instance.main: Still creating... [14m10s elapsed]
google_sql_database_instance.main: Still creating... [14m20s elapsed]
google_sql_database_instance.main: Still creating... [14m30s elapsed]
google_sql_database_instance.main: Still creating... [14m40s elapsed]
google_sql_database_instance.main: Still creating... [14m50s elapsed]
google_sql_database_instance.main: Creation complete after 14m52s [id=grid-meter-app-postgres]
google_sql_database.main: Creating...
google_sql_user.main: Creating...
google_sql_database.main: Creation complete after 7s [id=projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter]
google_sql_user.main: Still creating... [00m10s elapsed]
google_sql_user.main: Creation complete after 11s [id=gridmeter//grid-meter-app-postgres]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.243.0.3"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = <sensitive>
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.12"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % terraform show        
# google_artifact_registry_repository.api:
resource "google_artifact_registry_repository" "api" {
    cleanup_policy_dry_run = false
    create_time            = "2026-09-21T17:11:42.155491Z"
    deletion_policy        = "DELETE"
    description            = null
    effective_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    format                 = "DOCKER"
    id                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api"
    kms_key_name           = null
    labels                 = {}
    location               = "us-central1"
    mode                   = "STANDARD_REPOSITORY"
    name                   = "grid-meter-app-api"
    project                = "project-4c5a8821-da4c-4c68-97f"
    registry_uri           = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
    repository_id          = "grid-meter-app-api"
    terraform_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time            = "2026-09-21T17:11:42.155491Z"

    cleanup_policies {
        action = "KEEP"
        id     = "keep-5-most-recent"

        most_recent_versions {
            keep_count            = 5
            package_name_prefixes = []
        }
    }

    vulnerability_scanning_config {
        enablement_config       = null
        enablement_state        = "SCANNING_DISABLED"
        enablement_state_reason = "API containerscanning.googleapis.com is not enabled."
    }
}

# google_artifact_registry_repository.frontend:
resource "google_artifact_registry_repository" "frontend" {
    cleanup_policy_dry_run = false
    create_time            = "2026-09-21T17:11:42.207513Z"
    deletion_policy        = "DELETE"
    description            = null
    effective_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    format                 = "DOCKER"
    id                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend"
    kms_key_name           = null
    labels                 = {}
    location               = "us-central1"
    mode                   = "STANDARD_REPOSITORY"
    name                   = "grid-meter-app-frontend"
    project                = "project-4c5a8821-da4c-4c68-97f"
    registry_uri           = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
    repository_id          = "grid-meter-app-frontend"
    terraform_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time            = "2026-09-21T17:11:42.207513Z"

    cleanup_policies {
        action = "KEEP"
        id     = "keep-5-most-recent"

        most_recent_versions {
            keep_count            = 5
            package_name_prefixes = []
        }
    }

    vulnerability_scanning_config {
        enablement_config       = null
        enablement_state        = "SCANNING_DISABLED"
        enablement_state_reason = "API containerscanning.googleapis.com is not enabled."
    }
}

# google_compute_global_address.private_service_access:
resource "google_compute_global_address" "private_service_access" {
    address            = "10.243.0.0"
    address_type       = "INTERNAL"
    creation_timestamp = "2026-09-21T10:11:54.245-07:00"
    deletion_policy    = "DELETE"
    description        = null
    effective_labels   = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    id                 = "projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range"
    ip_version         = null
    label_fingerprint  = "XecKUg2ClAs="
    labels             = {}
    name               = "grid-meter-app-psa-range"
    network            = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    prefix_length      = 16
    project            = "project-4c5a8821-da4c-4c68-97f"
    purpose            = "VPC_PEERING"
    self_link          = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range"
    terraform_labels   = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
}

# google_compute_network.main:
resource "google_compute_network" "main" {
    auto_create_subnetworks                   = false
    bgp_always_compare_med                    = false
    bgp_best_path_selection_mode              = "LEGACY"
    bgp_inter_region_cost                     = null
    delete_bgp_always_compare_med             = false
    delete_default_routes_on_create           = false
    deletion_policy                           = "DELETE"
    description                               = null
    enable_ula_internal_ipv6                  = false
    gateway_ipv4                              = null
    id                                        = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    internal_ipv6_range                       = null
    mtu                                       = 0
    name                                      = "grid-meter-app-vpc"
    network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
    network_id                                = "1993557537871158187"
    network_profile                           = null
    numeric_id                                = "1993557537871158187"
    project                                   = "project-4c5a8821-da4c-4c68-97f"
    routing_mode                              = "REGIONAL"
    self_link                                 = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
}

# google_compute_router.main:
resource "google_compute_router" "main" {
    creation_timestamp            = "2026-09-21T10:11:54.430-07:00"
    deletion_policy               = "DELETE"
    description                   = null
    encrypted_interconnect_router = false
    id                            = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router"
    name                          = "grid-meter-app-router"
    ncc_gateway                   = null
    network                       = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    project                       = "project-4c5a8821-da4c-4c68-97f"
    region                        = "us-central1"
    self_link                     = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router"
}

# google_compute_router_nat.main:
resource "google_compute_router_nat" "main" {
    deletion_policy                      = "DELETE"
    drain_nat_ips                        = []
    enable_dynamic_port_allocation       = false
    enable_endpoint_independent_mapping  = false
    endpoint_types                       = [
        "ENDPOINT_TYPE_VM",
    ]
    icmp_idle_timeout_sec                = 30
    id                                   = "project-4c5a8821-da4c-4c68-97f/us-central1/grid-meter-app-router/grid-meter-app-nat"
    max_ports_per_vm                     = 0
    min_ports_per_vm                     = 0
    name                                 = "grid-meter-app-nat"
    nat_ip_allocate_option               = "AUTO_ONLY"
    nat_ips                              = []
    project                              = "project-4c5a8821-da4c-4c68-97f"
    region                               = "us-central1"
    router                               = "grid-meter-app-router"
    source_subnetwork_ip_ranges_to_nat   = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    source_subnetwork_ip_ranges_to_nat64 = null
    tcp_established_idle_timeout_sec     = 1200
    tcp_time_wait_timeout_sec            = 120
    tcp_transitory_idle_timeout_sec      = 30
    type                                 = "PUBLIC"
    udp_idle_timeout_sec                 = 30
}

# google_compute_subnetwork.main:
resource "google_compute_subnetwork" "main" {
    allow_subnet_cidr_routes_overlap = false
    creation_timestamp               = "2026-09-21T10:11:54.977-07:00"
    deletion_policy                  = "DELETE"
    description                      = null
    external_ipv6_prefix             = null
    gateway_address                  = "10.10.0.1"
    id                               = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    internal_ipv6_prefix             = null
    ip_cidr_range                    = "10.10.0.0/20"
    ip_collection                    = null
    ipv6_access_type                 = null
    ipv6_cidr_range                  = null
    ipv6_gce_endpoint                = null
    name                             = "grid-meter-app-subnet"
    network                          = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    private_ip_google_access         = true
    private_ipv6_google_access       = "DISABLE_GOOGLE_ACCESS"
    project                          = "project-4c5a8821-da4c-4c68-97f"
    purpose                          = "PRIVATE"
    region                           = "us-central1"
    reserved_internal_range          = null
    resolve_subnet_mask              = null
    role                             = null
    self_link                        = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    stack_type                       = "IPV4_ONLY"
    state                            = null
    subnetwork_id                    = 716732557556505525

    secondary_ip_range {
        ip_cidr_range           = "10.11.0.0/16"
        range_name              = "grid-meter-app-pods"
        reserved_internal_range = null
    }
    secondary_ip_range {
        ip_cidr_range           = "10.12.0.0/20"
        range_name              = "grid-meter-app-services"
        reserved_internal_range = null
    }
}

# google_container_cluster.main:
resource "google_container_cluster" "main" {
    autopilot_privileged_admission           = []
    cluster_ipv4_cidr                        = "10.11.0.0/16"
    datapath_provider                        = null
    default_max_pods_per_node                = 110
    deletion_policy                          = "DELETE"
    deletion_protection                      = false
    description                              = null
    disable_l4_lb_firewall_reconciliation    = false
    effective_labels                         = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    emulated_version                         = null
    enable_autopilot                         = false
    enable_cilium_clusterwide_network_policy = false
    enable_fqdn_network_policy               = false
    enable_intranode_visibility              = false
    enable_kubernetes_alpha                  = false
    enable_l4_ilb_subsetting                 = false
    enable_legacy_abac                       = false
    enable_multi_networking                  = false
    enable_shielded_nodes                    = true
    enable_tpu                               = false
    endpoint                                 = "34.123.227.116"
    id                                       = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    in_transit_encryption_config             = null
    initial_node_count                       = 1
    label_fingerprint                        = "36c4afcc"
    location                                 = "us-central1-a"
    logging_service                          = "logging.googleapis.com/kubernetes"
    master_version                           = "1.35.8-gke.1036000"
    monitoring_service                       = "monitoring.googleapis.com/kubernetes"
    name                                     = "grid-meter-app-gke"
    network                                  = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    networking_mode                          = "VPC_NATIVE"
    node_locations                           = []
    node_version                             = "1.35.8-gke.1036000"
    private_ipv6_google_access               = null
    project                                  = "project-4c5a8821-da4c-4c68-97f"
    remove_default_node_pool                 = true
    resource_labels                          = {}
    self_link                                = "https://container.googleapis.com/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/clusters/grid-meter-app-gke"
    services_ipv4_cidr                       = "10.12.0.0/20"
    subnetwork                               = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    terraform_labels                         = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    tpu_ipv4_cidr_block                      = null

    addons_config {
        dns_cache_config {
            enabled = true
        }
        gce_persistent_disk_csi_driver_config {
            enabled = true
        }
        network_policy_config {
            disabled = true
        }
        node_readiness_config {
            enabled = false
        }
    }

    anonymous_authentication_config {
        mode = "LIMITED"
    }

    binary_authorization {
        enabled         = false
        evaluation_mode = null
    }

    cluster_autoscaling {
        auto_provisioning_locations   = []
        autoscaling_profile           = "BALANCED"
        default_compute_class_enabled = false
        enabled                       = false

        auto_provisioning_defaults {
            boot_disk_kms_key = null
            disk_size         = 0
            disk_type         = null
            image_type        = "COS_CONTAINERD"
            min_cpu_platform  = null
            oauth_scopes      = [
                "https://www.googleapis.com/auth/devstorage.read_only",
                "https://www.googleapis.com/auth/logging.write",
                "https://www.googleapis.com/auth/monitoring",
                "https://www.googleapis.com/auth/service.management.readonly",
                "https://www.googleapis.com/auth/servicecontrol",
                "https://www.googleapis.com/auth/trace.append",
            ]
            service_account   = "default"

            management {
                auto_repair     = true
                auto_upgrade    = true
                upgrade_options = []
            }
        }
    }

    control_plane_endpoints_config {
        dns_endpoint_config {
            allow_external_traffic    = false
            enable_k8s_certs_via_dns  = false
            enable_k8s_tokens_via_dns = false
            endpoint                  = "gke-561a75e15c8e431aaf0de6d6d9ff722a6dd5-361083726560.us-central1-a.gke.goog"
        }
        ip_endpoints_config {
            enabled = true
        }
    }

    database_encryption {
        key_name = null
        state    = "DECRYPTED"
    }

    default_snat_status {
        disabled = false
    }

    enterprise_config {
        cluster_tier = "STANDARD"
        desired_tier = null
    }

    ip_allocation_policy {
        cluster_ipv4_cidr_block       = "10.11.0.0/16"
        cluster_secondary_range_name  = "grid-meter-app-pods"
        services_ipv4_cidr_block      = "10.12.0.0/20"
        services_secondary_range_name = "grid-meter-app-services"
        stack_type                    = "IPV4"

        network_tier_config {
            network_tier = "NETWORK_TIER_DEFAULT"
        }

        pod_cidr_overprovision_config {
            disabled = false
        }
    }

    logging_config {
        enable_components = [
            "SYSTEM_COMPONENTS",
            "WORKLOADS",
        ]
    }

    master_auth {
        client_certificate     = null
        client_key             = (sensitive value)
        cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVMRENDQXBTZ0F3SUJBZ0lRZlBpc0k4RXJ4eExZWFc1ZDR1U20xekFOQmdrcWhraUc5dzBCQVFzRkFEQXYKTVMwd0t3WURWUVFERXlReU9EZzJNV0V5Tmkxak1tTm1MVFF3TVRVdE9UQXhNQzFoTnpVeFlXSmhZV1E1TmpRdwpJQmNOTWpZd09USXhNVFl4TWpJeFdoZ1BNakExTmpBNU1UTXhOekV5TWpGYU1DOHhMVEFyQmdOVkJBTVRKREk0Ck9EWXhZVEkyTFdNeVkyWXROREF4TlMwNU1ERXdMV0UzTlRGaFltRmhaRGsyTkRDQ0FhSXdEUVlKS29aSWh2Y04KQVFFQkJRQURnZ0dQQURDQ0FZb0NnZ0dCQUp1aWgwaGtneG1xclJKR1dzTlM2dFFjWEp4NnFTVjJkNTREWUEydQpJTUVEM01GZ1dUUXk5MElvbHlYMTRCZ0VFMllsODIwQlJ6dHNBSDVmTjdxbmY0V1dCYTRhUkFMWHJ1Zm1pYS81CmNUY0szUVNkMHlqeDhreEF3aUdrZkdLQmVXSU1tNGZIVFVBdEpweUhuMFlucWhaMkI4T1dTVGI1dzN1NmRwYjYKZ2p1L1RHZ2thZ3l3eS81UWNGNGNYOTladDhjRHMweHZBOERibzZOZnk1TG9OdEhmV1dKWEVyOXRJQzFoUFh2MApPam13TldsbFNZUkJjWkI2UHFvaDNwdEhqckFSd01FbCtpbGd6VUdhaDFxMmNKQkR0Y3ZpMUxOUitQYkJxYUR6CkZENkZsd0J4bDhLY05WcmtMTmpnTlA4QnVGV3dsR096ZlNiY3dJdGpMbzR6djlBZmV6SzcwMTZhSnhOdXgvKzQKZ25RcS9ZVHUxaUFkZmtaZFR1RUJ2Y3ZkSHYrR2x1Wm1UT3lqNitScjd1Rmd0OXI1cU5SN1QyRGcvNXNJTzE0ZgpWK2R2dzdQOFNJL01PdFMyc2hOZlVCaXNOd0JwS29sOGhiTnBubTAxdXVNM2Z4M2tmdlViL2lZc1dCSHBDNE1zClBkVkszT0lGTFJsRHVVcUVjK3JiZGRYWG5RSURBUUFCbzBJd1FEQU9CZ05WSFE4QkFmOEVCQU1DQWdRd0R3WUQKVlIwVEFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVVYSDhrM1ZwN01DTVBML01MOFlub0EvWXpRQzR3RFFZSgpLb1pJaHZjTkFRRUxCUUFEZ2dHQkFIdEdZdTRjTEtiZjZWdXBkMXJNUXEzK2VLZzMvV2NESjVCUXczcllOemR1CjdlaW1UQVh3VGZNeUlsQ0ZQQjRqaVRQeHdsQ3pXeWVlOWVqSGpkbkVML203cFBKenM5ZTJrZExteEY3aFBYZkQKWERxNHZOa3hmVjNTN3ZhZ1lRQ0pQVmJuUk13QzJ2bUFaczFNTFU4TGdNemlZZVRvalVaOHpDeEhTWGxYbVo3KwpxZHhUSlJVaUozZmptZ0FxUnA5bWpUN1hQTWZNL0pLa1BVeGRHbnFaWEJlSTVlZXd4UVFtZkxKeEZwR2I5eUVkCmZWaDBHY0RvdThleERUMVVpQUpTUXVlM09Pdmt6bmZ3dmFTNnFyRUFNOHlTTWg3aXNVdS9yV2pVbjdzOUZXaVMKTnNHU0pGT1EvdG9RL3lWTXUzYndreFhXczNNaC96Z2xPNGtuUHp1aTFHL0FKRlpIUUx1UWNUS1J0Vk1LejdtTQpsQUZ1NmJ2V0FuQkpzdW5COE0zMDBNY0IzR3pVbC9LbnJRYWV3YTdDeEhjU3E1QVVFbjFMRzNTWWRnQUY4SW43CmJ5RG9TUnNWMElNT3cyZVRqd2Z6THFBWHFqZTRpcWlwdEJybGJ3aURUWEpVTVFPNjNqeTdMTDd0TjBzRUZVc0QKanp3SHhQcWMxc0F6OXkwQlJ4N3N2dz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"

        client_certificate_config {
            issue_client_certificate = false
        }
    }

    monitoring_config {
        enable_components = [
            "CADVISOR",
            "DAEMONSET",
            "DCGM",
            "DEPLOYMENT",
            "HPA",
            "JOBSET",
            "KUBELET",
            "POD",
            "STATEFULSET",
            "STORAGE",
            "SYSTEM_COMPONENTS",
        ]

        advanced_datapath_observability_config {
            enable_metrics = false
            enable_relay   = false
        }

        managed_prometheus {
            enabled = true
        }
    }

    network_policy {
        enabled  = false
        provider = "PROVIDER_UNSPECIFIED"
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
    }

    node_creation_config {
        node_creation_mode = "VIA_KUBELET"
    }

    node_pool {
        ignore_node_count_changes   = false
        initial_node_count          = 3
        instance_group_urls         = [
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
        ]
        managed_instance_group_urls = [
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
        ]
        max_pods_per_node           = 110
        name                        = "grid-meter-app-nodes"
        name_prefix                 = null
        node_count                  = 3
        node_locations              = [
            "us-central1-a",
            "us-central1-b",
            "us-central1-c",
        ]
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
        }

        upgrade_settings {
            max_surge       = 1
            max_unavailable = 0
            strategy        = "SURGE"
        }
    }

    node_pool_auto_config {
        resource_manager_tags = {}

        node_kubelet_config {
            insecure_kubelet_readonly_port_enabled = "FALSE"
        }
    }

    node_pool_defaults {
        node_config_defaults {
            insecure_kubelet_readonly_port_enabled = "FALSE"
            logging_variant                        = "DEFAULT"
        }
    }

    notification_config {
        pubsub {
            enabled = false
            topic   = null
        }
    }

    pod_autoscaling {
        hpa_profile = "PERFORMANCE"
    }

    private_cluster_config {
        enable_private_endpoint     = false
        enable_private_nodes        = true
        master_ipv4_cidr_block      = "172.16.0.0/28"
        peering_name                = null
        private_endpoint            = "172.16.0.2"
        private_endpoint_subnetwork = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/gke-grid-meter-app-gke-0ef79996-pe-subnet"
        public_endpoint             = "34.123.227.116"

        master_global_access_config {
            enabled = false
        }
    }

    rbac_binding_config {
        enable_insecure_binding_system_authenticated   = true
        enable_insecure_binding_system_unauthenticated = true
    }

    release_channel {
        channel = "REGULAR"
    }

    secret_manager_config {
        enabled = false
    }

    secret_sync_config {
        enabled = false
    }

    security_posture_config {
        mode               = "BASIC"
        vulnerability_mode = "VULNERABILITY_MODE_UNSPECIFIED"
    }

    service_external_ips_config {
        enabled = false
    }
}

# google_container_node_pool.main:
resource "google_container_node_pool" "main" {
    cluster                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    deletion_policy             = "DELETE"
    id                          = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes"
    ignore_node_count_changes   = false
    initial_node_count          = 3
    instance_group_urls         = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
    ]
    location                    = "us-central1-a"
    managed_instance_group_urls = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
    ]
    max_pods_per_node           = 110
    name                        = "grid-meter-app-nodes"
    name_prefix                 = null
    node_count                  = 3
    node_locations              = [
        "us-central1-a",
        "us-central1-b",
        "us-central1-c",
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
    }

    upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
        strategy        = "SURGE"
    }
}

# google_memorystore_instance.main:
resource "google_memorystore_instance" "main" {
    authorization_mode             = "AUTH_DISABLED"
    available_maintenance_versions = []
    backup_collection              = null
    create_time                    = "2026-09-21T17:39:12.018803673Z"
    deletion_policy                = "DELETE"
    deletion_protection_enabled    = false
    discovery_endpoints            = []
    effective_labels               = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    effective_maintenance_version  = "MEMORYSTORE_20260813_00_00"
    endpoints                      = [
        {
            connections = [
                {
                    psc_auto_connection = [
                        {
                            connection_type    = "CONNECTION_TYPE_PRIMARY"
                            forwarding_rule    = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-b36db569-25eb-49c9-9547-ee57b2b67b1d"
                            ip_address         = "10.10.0.12"
                            network            = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
                            port               = 6379
                            project_id         = "project-4c5a8821-da4c-4c68-97f"
                            psc_connection_id  = "40140811761483788"
                            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa"
                        },
                    ]
                },
                {
                    psc_auto_connection = [
                        {
                            connection_type    = "CONNECTION_TYPE_READER"
                            forwarding_rule    = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-21af715c-9c9c-469b-b15f-1d1abcb4949a"
                            ip_address         = "10.10.0.13"
                            network            = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
                            port               = 6379
                            project_id         = "project-4c5a8821-da4c-4c68-97f"
                            psc_connection_id  = "40140811761483789"
                            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa-2"
                        },
                    ]
                },
            ]
        },
    ]
    engine_version                 = "VALKEY_9_0"
    id                             = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache"
    instance_id                    = "grid-meter-app-cache"
    is_acl_policy_in_sync          = false
    kms_key                        = null
    location                       = "us-central1"
    maintenance_schedule           = []
    maintenance_version            = null
    managed_server_ca              = []
    mode                           = "CLUSTER_DISABLED"
    name                           = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache"
    node_config                    = [
        {
            size_gb = 1.4
        },
    ]
    node_type                      = "SHARED_CORE_NANO"
    project                        = "project-4c5a8821-da4c-4c68-97f"
    psc_attachment_details         = [
        {
            connection_type    = "CONNECTION_TYPE_PRIMARY"
            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa"
        },
        {
            connection_type    = "CONNECTION_TYPE_READER"
            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa-2"
        },
    ]
    psc_auto_connections           = []
    replica_count                  = 0
    server_ca_mode                 = "SERVER_CA_MODE_UNSPECIFIED"
    server_ca_pool                 = null
    shard_count                    = 1
    state                          = "ACTIVE"
    state_info                     = []
    terraform_labels               = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    transit_encryption_mode        = "TRANSIT_ENCRYPTION_DISABLED"
    uid                            = "791f8cc7-8bf4-483c-9e02-869d20c9ccb4"
    update_time                    = "2026-09-21T17:44:49.668470110Z"

    desired_auto_created_endpoints {
        network    = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
        project_id = "project-4c5a8821-da4c-4c68-97f"
    }

    persistence_config {
        mode = "DISABLED"
    }

    zone_distribution_config {
        mode = "MULTI_ZONE"
        zone = null
    }
}

# google_network_connectivity_service_connection_policy.memorystore:
resource "google_network_connectivity_service_connection_policy" "memorystore" {
    create_time      = "2026-09-21T17:38:59.916253820Z"
    deletion_policy  = "DELETE"
    description      = null
    effective_labels = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    etag             = "TPfKpS8q3kXIhywOfISUI4urBj8jjyoWgszPVNuhsZg"
    id               = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/serviceConnectionPolicies/grid-meter-app-memorystore-scp"
    infrastructure   = "PSC"
    location         = "us-central1"
    name             = "grid-meter-app-memorystore-scp"
    network          = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    project          = "project-4c5a8821-da4c-4c68-97f"
    psc_connections  = []
    service_class    = "gcp-memorystore"
    terraform_labels = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time      = "2026-09-21T17:39:09.189900334Z"

    psc_config {
        limit                      = null
        producer_instance_location = null
        subnetworks                = [
            "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet",
        ]
    }
}

# google_project_iam_member.gke_node_sa:
resource "google_project_iam_member" "gke_node_sa" {
    etag    = "BwZcAV+Cbwc="
    id      = "project-4c5a8821-da4c-4c68-97f/roles/container.nodeServiceAccount/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    member  = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    project = "project-4c5a8821-da4c-4c68-97f"
    role    = "roles/container.nodeServiceAccount"
}

# google_secret_manager_secret.cloudsql_password:
resource "google_secret_manager_secret" "cloudsql_password" {
    annotations           = {}
    create_time           = "2026-09-21T17:11:32.574458Z"
    deletion_policy       = "DELETE"
    deletion_protection   = false
    effective_annotations = {}
    effective_labels      = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    expire_time           = null
    id                    = "projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password"
    labels                = {}
    name                  = "projects/361083726560/secrets/grid-meter-app-cloudsql-password"
    project               = "project-4c5a8821-da4c-4c68-97f"
    secret_id             = "grid-meter-app-cloudsql-password"
    terraform_labels      = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    version_aliases       = {}
    version_destroy_ttl   = null

    replication {
        auto {
        }
    }
}

# google_secret_manager_secret_version.cloudsql_password:
resource "google_secret_manager_secret_version" "cloudsql_password" {
    create_time           = "2026-09-21T17:11:33.708526Z"
    deletion_policy       = "DELETE"
    destroy_time          = null
    enabled               = true
    id                    = "projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1"
    is_secret_data_base64 = false
    name                  = "projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1"
    secret                = "projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password"
    secret_data           = (sensitive value)
    secret_data_wo        = (write-only attribute)
    version               = "1"
}

# google_service_account.gke_node:
resource "google_service_account" "gke_node" {
    account_id      = "grid-meter-app-gke-node"
    deletion_policy = "DELETE"
    description     = null
    disabled        = false
    display_name    = "grid-meter-app GKE node service account"
    email           = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    id              = "projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    member          = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    name            = "projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    project         = "project-4c5a8821-da4c-4c68-97f"
    unique_id       = "101610449387927989138"
}

# google_service_networking_connection.private_service_access:
resource "google_service_networking_connection" "private_service_access" {
    deletion_policy         = "DELETE"
    id                      = "projects%2Fproject-4c5a8821-da4c-4c68-97f%2Fglobal%2Fnetworks%2Fgrid-meter-app-vpc:servicenetworking.googleapis.com"
    network                 = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    peering                 = "servicenetworking-googleapis-com"
    reserved_peering_ranges = [
        "grid-meter-app-psa-range",
    ]
    service                 = "servicenetworking.googleapis.com"
}

# google_sql_database.main:
resource "google_sql_database" "main" {
    charset         = "UTF8"
    collation       = "en_US.UTF8"
    deletion_policy = "DELETE"
    id              = "projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter"
    instance        = "grid-meter-app-postgres"
    name            = "gridmeter"
    project         = "project-4c5a8821-da4c-4c68-97f"
    self_link       = "https://sqladmin.googleapis.com/sql/v1beta4/projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter"
}

# google_sql_database_instance.main:
resource "google_sql_database_instance" "main" {
    available_maintenance_versions       = []
    connection_name                      = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
    database_version                     = "POSTGRES_18"
    deletion_policy                      = "DELETE"
    deletion_protection                  = false
    dns_name                             = null
    dns_names                            = []
    enforce_new_sql_network_architecture = true
    first_ip_address                     = "10.243.0.3"
    id                                   = "grid-meter-app-postgres"
    instance_type                        = "CLOUD_SQL_INSTANCE"
    ip_address                           = [
        {
            ip_address     = "10.243.0.3"
            time_to_retire = null
            type           = "PRIVATE"
        },
    ]
    maintenance_version                  = "POSTGRES_18_6.R20260712.01_10"
    master_instance_name                 = null
    name                                 = "grid-meter-app-postgres"
    node_count                           = 0
    private_ip_address                   = "10.243.0.3"
    project                              = "project-4c5a8821-da4c-4c68-97f"
    psc_service_attachment_link          = null
    public_ip_address                    = null
    region                               = "us-central1"
    replica_names                        = []
    root_password_wo                     = (write-only attribute)
    self_link                            = "https://sqladmin.googleapis.com/sql/v1beta4/projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres"
    server_ca_cert                       = (sensitive value)
    service_account_email_address        = "p361083726560-lt8qzd@gcp-sa-cloud-sql.iam.gserviceaccount.com"

    replication_cluster {
        dr_replica               = false
        failover_dr_replica_name = null
        psa_write_endpoint       = null
    }

    settings {
        activation_policy                = "ALWAYS"
        auto_upgrade_enabled             = false
        availability_type                = "ZONAL"
        collation                        = null
        connector_enforcement            = "NOT_REQUIRED"
        data_api_access                  = null
        data_disk_provisioned_iops       = 0
        data_disk_provisioned_throughput = 0
        deletion_protection_enabled      = false
        disk_autoresize                  = true
        disk_autoresize_limit            = 0
        disk_size                        = 20
        disk_type                        = "PD_SSD"
        edition                          = "ENTERPRISE"
        effective_availability_type      = "ZONAL"
        enable_dataplex_integration      = false
        enable_google_ml_integration     = false
        pricing_plan                     = "PER_USE"
        replication_lag_max_seconds      = 31536000
        retain_backups_on_delete         = false
        tier                             = "db-f1-micro"
        time_zone                        = null
        user_labels                      = {}
        version                          = 1

        backup_configuration {
            backup_tier                    = "STANDARD"
            binary_log_enabled             = false
            enabled                        = true
            location                       = null
            point_in_time_recovery_enabled = false
            start_time                     = "12:00"
            transaction_log_retention_days = 7

            backup_retention_settings {
                retained_backups = 1
                retention_unit   = "COUNT"
            }
        }

        data_cache_config {
            data_cache_enabled = false
        }

        ip_configuration {
            allocated_ip_range                            = null
            enable_private_path_for_google_cloud_services = false
            ipv4_enabled                                  = false
            private_network                               = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
            server_ca_mode                                = "GOOGLE_MANAGED_INTERNAL_CA"
            server_ca_pool                                = null
            server_certificate_rotation_mode              = "SERVER_CERTIFICATE_ROTATION_MODE_UNSPECIFIED"
            ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
        }

        location_preference {
            follow_gae_application = null
            secondary_zone         = null
            zone                   = "us-central1-c"
        }

        read_pool_auto_scale_config {
            disable_scale_in           = false
            enabled                    = false
            max_node_count             = 0
            min_node_count             = 0
            scale_in_cooldown_seconds  = 0
            scale_out_cooldown_seconds = 0
        }
    }
}

# google_sql_user.main:
resource "google_sql_user" "main" {
    deletion_policy         = "DELETE"
    host                    = null
    iam_email               = null
    id                      = "gridmeter//grid-meter-app-postgres"
    instance                = "grid-meter-app-postgres"
    name                    = "gridmeter"
    password                = (sensitive value)
    password_wo             = (write-only attribute)
    project                 = "project-4c5a8821-da4c-4c68-97f"
    sql_server_user_details = []
    type                    = null
}

# random_password.cloudsql:
resource "random_password" "cloudsql" {
    bcrypt_hash = (sensitive value)
    id          = "none"
    length      = 32
    lower       = true
    min_lower   = 0
    min_numeric = 0
    min_special = 0
    min_upper   = 0
    number      = true
    numeric     = true
    result      = (sensitive value)
    special     = false
    upper       = true
}


Outputs:

artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.243.0.3"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = (sensitive value)
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.12"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % 

tim@Timothys-MacBook-Air ~ % cd Documents/workspace/java/apps/grid-meter-app/terraform/gcp
tim@Timothys-MacBook-Air gcp % terraform plan -out tfplan
random_password.cloudsql: Refreshing state... [id=none]
google_service_account.gke_node: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_compute_network.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc]
google_secret_manager_secret.cloudsql_password: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password]
google_artifact_registry_repository.frontend: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend]
google_artifact_registry_repository.api: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api]
google_project_iam_member.gke_node_sa: Refreshing state... [id=project-4c5a8821-da4c-4c68-97f/roles/container.nodeServiceAccount/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com]
google_secret_manager_secret_version.cloudsql_password: Refreshing state... [id=projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1]
google_compute_router.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router]
google_compute_subnetwork.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet]
google_compute_global_address.private_service_access: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range]
google_network_connectivity_service_connection_policy.memorystore: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/serviceConnectionPolicies/grid-meter-app-memorystore-scp]
google_service_networking_connection.private_service_access: Refreshing state... [id=projects%2Fproject-4c5a8821-da4c-4c68-97f%2Fglobal%2Fnetworks%2Fgrid-meter-app-vpc:servicenetworking.googleapis.com]
google_compute_router_nat.main: Refreshing state... [id=project-4c5a8821-da4c-4c68-97f/us-central1/grid-meter-app-router/grid-meter-app-nat]
google_container_cluster.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke]
google_memorystore_instance.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache]
google_sql_database_instance.main: Refreshing state... [id=grid-meter-app-postgres]
google_sql_database.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter]
google_sql_user.main: Refreshing state... [id=gridmeter//grid-meter-app-postgres]
google_container_node_pool.main: Refreshing state... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with
the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # google_container_node_pool.main will be updated in-place
  ~ resource "google_container_node_pool" "main" {
        id                          = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes"
        name                        = "grid-meter-app-nodes"
      ~ node_count                  = 3 -> 1
        # (12 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
tim@Timothys-MacBook-Air gcp % terraform apply tfplan
google_container_node_pool.main: Modifying... [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m10s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m20s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m30s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m40s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 00m50s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m00s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m10s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m20s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m30s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m40s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 01m50s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m00s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m10s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m20s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m30s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m40s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 02m50s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m00s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m10s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m20s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m30s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m40s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 03m50s elapsed]
google_container_node_pool.main: Still modifying... [id=projects/project-4c5a8821-da4c-4c68-97f...app-gke/nodePools/grid-meter-app-nodes, 04m00s elapsed]
google_container_node_pool.main: Modifications complete after 4m6s [id=projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.243.0.3"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = <sensitive>
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.12"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % terraform show
# google_artifact_registry_repository.api:
resource "google_artifact_registry_repository" "api" {
    cleanup_policy_dry_run = false
    create_time            = "2026-09-21T17:11:42.155491Z"
    deletion_policy        = "DELETE"
    description            = null
    effective_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    format                 = "DOCKER"
    id                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-api"
    kms_key_name           = null
    labels                 = {}
    location               = "us-central1"
    mode                   = "STANDARD_REPOSITORY"
    name                   = "grid-meter-app-api"
    project                = "project-4c5a8821-da4c-4c68-97f"
    registry_uri           = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
    repository_id          = "grid-meter-app-api"
    terraform_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time            = "2026-09-21T17:11:42.155491Z"

    cleanup_policies {
        action = "KEEP"
        id     = "keep-5-most-recent"

        most_recent_versions {
            keep_count            = 5
            package_name_prefixes = []
        }
    }

    vulnerability_scanning_config {
        enablement_config       = null
        enablement_state        = "SCANNING_DISABLED"
        enablement_state_reason = "API containerscanning.googleapis.com is not enabled."
    }
}

# google_artifact_registry_repository.frontend:
resource "google_artifact_registry_repository" "frontend" {
    cleanup_policy_dry_run = false
    create_time            = "2026-09-21T17:11:42.207513Z"
    deletion_policy        = "DELETE"
    description            = null
    effective_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    format                 = "DOCKER"
    id                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/repositories/grid-meter-app-frontend"
    kms_key_name           = null
    labels                 = {}
    location               = "us-central1"
    mode                   = "STANDARD_REPOSITORY"
    name                   = "grid-meter-app-frontend"
    project                = "project-4c5a8821-da4c-4c68-97f"
    registry_uri           = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
    repository_id          = "grid-meter-app-frontend"
    terraform_labels       = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time            = "2026-09-21T17:11:42.207513Z"

    cleanup_policies {
        action = "KEEP"
        id     = "keep-5-most-recent"

        most_recent_versions {
            keep_count            = 5
            package_name_prefixes = []
        }
    }

    vulnerability_scanning_config {
        enablement_config       = null
        enablement_state        = "SCANNING_DISABLED"
        enablement_state_reason = "API containerscanning.googleapis.com is not enabled."
    }
}

# google_compute_global_address.private_service_access:
resource "google_compute_global_address" "private_service_access" {
    address            = "10.243.0.0"
    address_type       = "INTERNAL"
    creation_timestamp = "2026-09-21T10:11:54.245-07:00"
    deletion_policy    = "DELETE"
    description        = null
    effective_labels   = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    id                 = "projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range"
    ip_version         = null
    label_fingerprint  = "XecKUg2ClAs="
    labels             = {}
    name               = "grid-meter-app-psa-range"
    network            = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    prefix_length      = 16
    project            = "project-4c5a8821-da4c-4c68-97f"
    purpose            = "VPC_PEERING"
    self_link          = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/addresses/grid-meter-app-psa-range"
    terraform_labels   = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
}

# google_compute_network.main:
resource "google_compute_network" "main" {
    auto_create_subnetworks                   = false
    bgp_always_compare_med                    = false
    bgp_best_path_selection_mode              = "LEGACY"
    bgp_inter_region_cost                     = null
    delete_bgp_always_compare_med             = false
    delete_default_routes_on_create           = false
    deletion_policy                           = "DELETE"
    description                               = null
    enable_ula_internal_ipv6                  = false
    gateway_ipv4                              = null
    id                                        = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    internal_ipv6_range                       = null
    mtu                                       = 0
    name                                      = "grid-meter-app-vpc"
    network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
    network_id                                = "1993557537871158187"
    network_profile                           = null
    numeric_id                                = "1993557537871158187"
    project                                   = "project-4c5a8821-da4c-4c68-97f"
    routing_mode                              = "REGIONAL"
    self_link                                 = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
}

# google_compute_router.main:
resource "google_compute_router" "main" {
    creation_timestamp            = "2026-09-21T10:11:54.430-07:00"
    deletion_policy               = "DELETE"
    description                   = null
    encrypted_interconnect_router = false
    id                            = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router"
    name                          = "grid-meter-app-router"
    ncc_gateway                   = null
    network                       = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    project                       = "project-4c5a8821-da4c-4c68-97f"
    region                        = "us-central1"
    self_link                     = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/routers/grid-meter-app-router"
}

# google_compute_router_nat.main:
resource "google_compute_router_nat" "main" {
    deletion_policy                      = "DELETE"
    drain_nat_ips                        = []
    enable_dynamic_port_allocation       = false
    enable_endpoint_independent_mapping  = false
    endpoint_types                       = [
        "ENDPOINT_TYPE_VM",
    ]
    icmp_idle_timeout_sec                = 30
    id                                   = "project-4c5a8821-da4c-4c68-97f/us-central1/grid-meter-app-router/grid-meter-app-nat"
    max_ports_per_vm                     = 0
    min_ports_per_vm                     = 0
    name                                 = "grid-meter-app-nat"
    nat_ip_allocate_option               = "AUTO_ONLY"
    nat_ips                              = []
    project                              = "project-4c5a8821-da4c-4c68-97f"
    region                               = "us-central1"
    router                               = "grid-meter-app-router"
    source_subnetwork_ip_ranges_to_nat   = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    source_subnetwork_ip_ranges_to_nat64 = null
    tcp_established_idle_timeout_sec     = 1200
    tcp_time_wait_timeout_sec            = 120
    tcp_transitory_idle_timeout_sec      = 30
    type                                 = "PUBLIC"
    udp_idle_timeout_sec                 = 30
}

# google_compute_subnetwork.main:
resource "google_compute_subnetwork" "main" {
    allow_subnet_cidr_routes_overlap = false
    creation_timestamp               = "2026-09-21T10:11:54.977-07:00"
    deletion_policy                  = "DELETE"
    description                      = null
    external_ipv6_prefix             = null
    gateway_address                  = "10.10.0.1"
    id                               = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    internal_ipv6_prefix             = null
    ip_cidr_range                    = "10.10.0.0/20"
    ip_collection                    = null
    ipv6_access_type                 = null
    ipv6_cidr_range                  = null
    ipv6_gce_endpoint                = null
    name                             = "grid-meter-app-subnet"
    network                          = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    private_ip_google_access         = true
    private_ipv6_google_access       = "DISABLE_GOOGLE_ACCESS"
    project                          = "project-4c5a8821-da4c-4c68-97f"
    purpose                          = "PRIVATE"
    region                           = "us-central1"
    reserved_internal_range          = null
    resolve_subnet_mask              = null
    role                             = null
    self_link                        = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    stack_type                       = "IPV4_ONLY"
    state                            = null
    subnetwork_id                    = 716732557556505525

    secondary_ip_range {
        ip_cidr_range           = "10.11.0.0/16"
        range_name              = "grid-meter-app-pods"
        reserved_internal_range = null
    }
    secondary_ip_range {
        ip_cidr_range           = "10.12.0.0/20"
        range_name              = "grid-meter-app-services"
        reserved_internal_range = null
    }
}

# google_container_cluster.main:
resource "google_container_cluster" "main" {
    autopilot_privileged_admission           = []
    cluster_ipv4_cidr                        = "10.11.0.0/16"
    datapath_provider                        = null
    default_max_pods_per_node                = 110
    deletion_policy                          = "DELETE"
    deletion_protection                      = false
    description                              = null
    disable_l4_lb_firewall_reconciliation    = false
    effective_labels                         = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    emulated_version                         = null
    enable_autopilot                         = false
    enable_cilium_clusterwide_network_policy = false
    enable_fqdn_network_policy               = false
    enable_intranode_visibility              = false
    enable_kubernetes_alpha                  = false
    enable_l4_ilb_subsetting                 = false
    enable_legacy_abac                       = false
    enable_multi_networking                  = false
    enable_shielded_nodes                    = true
    enable_tpu                               = false
    endpoint                                 = "34.123.227.116"
    id                                       = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    in_transit_encryption_config             = null
    initial_node_count                       = 1
    label_fingerprint                        = "36c4afcc"
    location                                 = "us-central1-a"
    logging_service                          = "logging.googleapis.com/kubernetes"
    master_version                           = "1.35.8-gke.1036000"
    monitoring_service                       = "monitoring.googleapis.com/kubernetes"
    name                                     = "grid-meter-app-gke"
    network                                  = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    networking_mode                          = "VPC_NATIVE"
    node_locations                           = []
    node_version                             = "1.35.8-gke.1036000"
    private_ipv6_google_access               = null
    project                                  = "project-4c5a8821-da4c-4c68-97f"
    remove_default_node_pool                 = true
    resource_labels                          = {}
    self_link                                = "https://container.googleapis.com/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/clusters/grid-meter-app-gke"
    services_ipv4_cidr                       = "10.12.0.0/20"
    subnetwork                               = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet"
    terraform_labels                         = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    tpu_ipv4_cidr_block                      = null

    addons_config {
        dns_cache_config {
            enabled = true
        }
        gce_persistent_disk_csi_driver_config {
            enabled = true
        }
        network_policy_config {
            disabled = true
        }
        node_readiness_config {
            enabled = false
        }
    }

    anonymous_authentication_config {
        mode = "LIMITED"
    }

    binary_authorization {
        enabled         = false
        evaluation_mode = null
    }

    cluster_autoscaling {
        auto_provisioning_locations   = []
        autoscaling_profile           = "BALANCED"
        default_compute_class_enabled = false
        enabled                       = false

        auto_provisioning_defaults {
            boot_disk_kms_key = null
            disk_size         = 0
            disk_type         = null
            image_type        = "COS_CONTAINERD"
            min_cpu_platform  = null
            oauth_scopes      = [
                "https://www.googleapis.com/auth/devstorage.read_only",
                "https://www.googleapis.com/auth/logging.write",
                "https://www.googleapis.com/auth/monitoring",
                "https://www.googleapis.com/auth/service.management.readonly",
                "https://www.googleapis.com/auth/servicecontrol",
                "https://www.googleapis.com/auth/trace.append",
            ]
            service_account   = "default"

            management {
                auto_repair     = true
                auto_upgrade    = true
                upgrade_options = []
            }
        }
    }

    control_plane_endpoints_config {
        dns_endpoint_config {
            allow_external_traffic    = false
            enable_k8s_certs_via_dns  = false
            enable_k8s_tokens_via_dns = false
            endpoint                  = "gke-561a75e15c8e431aaf0de6d6d9ff722a6dd5-361083726560.us-central1-a.gke.goog"
        }
        ip_endpoints_config {
            enabled = true
        }
    }

    database_encryption {
        key_name = null
        state    = "DECRYPTED"
    }

    default_snat_status {
        disabled = false
    }

    enterprise_config {
        cluster_tier = "STANDARD"
        desired_tier = null
    }

    ip_allocation_policy {
        cluster_ipv4_cidr_block       = "10.11.0.0/16"
        cluster_secondary_range_name  = "grid-meter-app-pods"
        services_ipv4_cidr_block      = "10.12.0.0/20"
        services_secondary_range_name = "grid-meter-app-services"
        stack_type                    = "IPV4"

        network_tier_config {
            network_tier = "NETWORK_TIER_DEFAULT"
        }

        pod_cidr_overprovision_config {
            disabled = false
        }
    }

    logging_config {
        enable_components = [
            "SYSTEM_COMPONENTS",
            "WORKLOADS",
        ]
    }

    master_auth {
        client_certificate     = null
        client_key             = (sensitive value)
        cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVMRENDQXBTZ0F3SUJBZ0lRZlBpc0k4RXJ4eExZWFc1ZDR1U20xekFOQmdrcWhraUc5dzBCQVFzRkFEQXYKTVMwd0t3WURWUVFERXlReU9EZzJNV0V5Tmkxak1tTm1MVFF3TVRVdE9UQXhNQzFoTnpVeFlXSmhZV1E1TmpRdwpJQmNOTWpZd09USXhNVFl4TWpJeFdoZ1BNakExTmpBNU1UTXhOekV5TWpGYU1DOHhMVEFyQmdOVkJBTVRKREk0Ck9EWXhZVEkyTFdNeVkyWXROREF4TlMwNU1ERXdMV0UzTlRGaFltRmhaRGsyTkRDQ0FhSXdEUVlKS29aSWh2Y04KQVFFQkJRQURnZ0dQQURDQ0FZb0NnZ0dCQUp1aWgwaGtneG1xclJKR1dzTlM2dFFjWEp4NnFTVjJkNTREWUEydQpJTUVEM01GZ1dUUXk5MElvbHlYMTRCZ0VFMllsODIwQlJ6dHNBSDVmTjdxbmY0V1dCYTRhUkFMWHJ1Zm1pYS81CmNUY0szUVNkMHlqeDhreEF3aUdrZkdLQmVXSU1tNGZIVFVBdEpweUhuMFlucWhaMkI4T1dTVGI1dzN1NmRwYjYKZ2p1L1RHZ2thZ3l3eS81UWNGNGNYOTladDhjRHMweHZBOERibzZOZnk1TG9OdEhmV1dKWEVyOXRJQzFoUFh2MApPam13TldsbFNZUkJjWkI2UHFvaDNwdEhqckFSd01FbCtpbGd6VUdhaDFxMmNKQkR0Y3ZpMUxOUitQYkJxYUR6CkZENkZsd0J4bDhLY05WcmtMTmpnTlA4QnVGV3dsR096ZlNiY3dJdGpMbzR6djlBZmV6SzcwMTZhSnhOdXgvKzQKZ25RcS9ZVHUxaUFkZmtaZFR1RUJ2Y3ZkSHYrR2x1Wm1UT3lqNitScjd1Rmd0OXI1cU5SN1QyRGcvNXNJTzE0ZgpWK2R2dzdQOFNJL01PdFMyc2hOZlVCaXNOd0JwS29sOGhiTnBubTAxdXVNM2Z4M2tmdlViL2lZc1dCSHBDNE1zClBkVkszT0lGTFJsRHVVcUVjK3JiZGRYWG5RSURBUUFCbzBJd1FEQU9CZ05WSFE4QkFmOEVCQU1DQWdRd0R3WUQKVlIwVEFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVVYSDhrM1ZwN01DTVBML01MOFlub0EvWXpRQzR3RFFZSgpLb1pJaHZjTkFRRUxCUUFEZ2dHQkFIdEdZdTRjTEtiZjZWdXBkMXJNUXEzK2VLZzMvV2NESjVCUXczcllOemR1CjdlaW1UQVh3VGZNeUlsQ0ZQQjRqaVRQeHdsQ3pXeWVlOWVqSGpkbkVML203cFBKenM5ZTJrZExteEY3aFBYZkQKWERxNHZOa3hmVjNTN3ZhZ1lRQ0pQVmJuUk13QzJ2bUFaczFNTFU4TGdNemlZZVRvalVaOHpDeEhTWGxYbVo3KwpxZHhUSlJVaUozZmptZ0FxUnA5bWpUN1hQTWZNL0pLa1BVeGRHbnFaWEJlSTVlZXd4UVFtZkxKeEZwR2I5eUVkCmZWaDBHY0RvdThleERUMVVpQUpTUXVlM09Pdmt6bmZ3dmFTNnFyRUFNOHlTTWg3aXNVdS9yV2pVbjdzOUZXaVMKTnNHU0pGT1EvdG9RL3lWTXUzYndreFhXczNNaC96Z2xPNGtuUHp1aTFHL0FKRlpIUUx1UWNUS1J0Vk1LejdtTQpsQUZ1NmJ2V0FuQkpzdW5COE0zMDBNY0IzR3pVbC9LbnJRYWV3YTdDeEhjU3E1QVVFbjFMRzNTWWRnQUY4SW43CmJ5RG9TUnNWMElNT3cyZVRqd2Z6THFBWHFqZTRpcWlwdEJybGJ3aURUWEpVTVFPNjNqeTdMTDd0TjBzRUZVc0QKanp3SHhQcWMxc0F6OXkwQlJ4N3N2dz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"

        client_certificate_config {
            issue_client_certificate = false
        }
    }

    monitoring_config {
        enable_components = [
            "CADVISOR",
            "DAEMONSET",
            "DCGM",
            "DEPLOYMENT",
            "HPA",
            "JOBSET",
            "KUBELET",
            "POD",
            "STATEFULSET",
            "STORAGE",
            "SYSTEM_COMPONENTS",
        ]

        advanced_datapath_observability_config {
            enable_metrics = false
            enable_relay   = false
        }

        managed_prometheus {
            enabled = true
        }
    }

    network_policy {
        enabled  = false
        provider = "PROVIDER_UNSPECIFIED"
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
    }

    node_creation_config {
        node_creation_mode = "VIA_KUBELET"
    }

    node_pool {
        ignore_node_count_changes   = false
        initial_node_count          = 3
        instance_group_urls         = [
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
        ]
        managed_instance_group_urls = [
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
            "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
        ]
        max_pods_per_node           = 110
        name                        = "grid-meter-app-nodes"
        name_prefix                 = null
        node_count                  = 3
        node_locations              = [
            "us-central1-a",
            "us-central1-b",
            "us-central1-c",
        ]
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
        }

        upgrade_settings {
            max_surge       = 1
            max_unavailable = 0
            strategy        = "SURGE"
        }
    }

    node_pool_auto_config {
        resource_manager_tags = {}

        node_kubelet_config {
            insecure_kubelet_readonly_port_enabled = "FALSE"
        }
    }

    node_pool_defaults {
        node_config_defaults {
            insecure_kubelet_readonly_port_enabled = "FALSE"
            logging_variant                        = "DEFAULT"
        }
    }

    notification_config {
        pubsub {
            enabled = false
            topic   = null
        }
    }

    pod_autoscaling {
        hpa_profile = "PERFORMANCE"
    }

    private_cluster_config {
        enable_private_endpoint     = false
        enable_private_nodes        = true
        master_ipv4_cidr_block      = "172.16.0.0/28"
        peering_name                = null
        private_endpoint            = "172.16.0.2"
        private_endpoint_subnetwork = "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/gke-grid-meter-app-gke-0ef79996-pe-subnet"
        public_endpoint             = "34.123.227.116"

        master_global_access_config {
            enabled = false
        }
    }

    rbac_binding_config {
        enable_insecure_binding_system_authenticated   = true
        enable_insecure_binding_system_unauthenticated = true
    }

    release_channel {
        channel = "REGULAR"
    }

    secret_manager_config {
        enabled = false
    }

    secret_sync_config {
        enabled = false
    }

    security_posture_config {
        mode               = "BASIC"
        vulnerability_mode = "VULNERABILITY_MODE_UNSPECIFIED"
    }

    service_external_ips_config {
        enabled = false
    }
}

# google_container_node_pool.main:
resource "google_container_node_pool" "main" {
    cluster                     = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke"
    deletion_policy             = "DELETE"
    id                          = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1-a/clusters/grid-meter-app-gke/nodePools/grid-meter-app-nodes"
    ignore_node_count_changes   = false
    initial_node_count          = 1
    instance_group_urls         = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroupManagers/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
    ]
    location                    = "us-central1-a"
    managed_instance_group_urls = [
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-a/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-9625d049-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-b/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-bd657538-grp",
        "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/zones/us-central1-c/instanceGroups/gke-grid-meter-app-g-grid-meter-app-n-d4dfbaa8-grp",
    ]
    max_pods_per_node           = 110
    name                        = "grid-meter-app-nodes"
    name_prefix                 = null
    node_count                  = 1
    node_locations              = [
        "us-central1-a",
        "us-central1-b",
        "us-central1-c",
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
    }

    upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
        strategy        = "SURGE"
    }
}

# google_memorystore_instance.main:
resource "google_memorystore_instance" "main" {
    authorization_mode             = "AUTH_DISABLED"
    available_maintenance_versions = []
    backup_collection              = null
    create_time                    = "2026-09-21T17:39:12.018803673Z"
    deletion_policy                = "DELETE"
    deletion_protection_enabled    = false
    discovery_endpoints            = []
    effective_labels               = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    effective_maintenance_version  = "MEMORYSTORE_20260813_00_00"
    endpoints                      = [
        {
            connections = [
                {
                    psc_auto_connection = [
                        {
                            connection_type    = "CONNECTION_TYPE_PRIMARY"
                            forwarding_rule    = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-b36db569-25eb-49c9-9547-ee57b2b67b1d"
                            ip_address         = "10.10.0.12"
                            network            = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
                            port               = 6379
                            project_id         = "project-4c5a8821-da4c-4c68-97f"
                            psc_connection_id  = "40140811761483788"
                            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa"
                        },
                    ]
                },
                {
                    psc_auto_connection = [
                        {
                            connection_type    = "CONNECTION_TYPE_READER"
                            forwarding_rule    = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-21af715c-9c9c-469b-b15f-1d1abcb4949a"
                            ip_address         = "10.10.0.13"
                            network            = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
                            port               = 6379
                            project_id         = "project-4c5a8821-da4c-4c68-97f"
                            psc_connection_id  = "40140811761483789"
                            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa-2"
                        },
                    ]
                },
            ]
        },
    ]
    engine_configs                 = {}
    engine_version                 = "VALKEY_9_0"
    id                             = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache"
    instance_id                    = "grid-meter-app-cache"
    is_acl_policy_in_sync          = false
    kms_key                        = null
    labels                         = {}
    location                       = "us-central1"
    maintenance_schedule           = []
    maintenance_version            = null
    managed_server_ca              = []
    mode                           = "CLUSTER_DISABLED"
    name                           = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/instances/grid-meter-app-cache"
    node_config                    = [
        {
            size_gb = 1.4
        },
    ]
    node_type                      = "SHARED_CORE_NANO"
    project                        = "project-4c5a8821-da4c-4c68-97f"
    psc_attachment_details         = [
        {
            connection_type    = "CONNECTION_TYPE_PRIMARY"
            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa"
        },
        {
            connection_type    = "CONNECTION_TYPE_READER"
            service_attachment = "projects/990856038565/regions/us-central1/serviceAttachments/gcp-memorystore-auto-ce20136c4443bd87-psc-sa-2"
        },
    ]
    psc_auto_connections           = []
    replica_count                  = 0
    server_ca_mode                 = "SERVER_CA_MODE_UNSPECIFIED"
    server_ca_pool                 = null
    shard_count                    = 1
    state                          = "ACTIVE"
    state_info                     = []
    terraform_labels               = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    transit_encryption_mode        = "TRANSIT_ENCRYPTION_DISABLED"
    uid                            = "791f8cc7-8bf4-483c-9e02-869d20c9ccb4"
    update_time                    = "2026-09-21T17:44:49.668470110Z"

    desired_auto_created_endpoints {
        network    = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
        project_id = "project-4c5a8821-da4c-4c68-97f"
    }

    persistence_config {
        mode = "DISABLED"
    }

    zone_distribution_config {
        mode = "MULTI_ZONE"
        zone = null
    }
}

# google_network_connectivity_service_connection_policy.memorystore:
resource "google_network_connectivity_service_connection_policy" "memorystore" {
    create_time      = "2026-09-21T17:38:59.916253820Z"
    deletion_policy  = "DELETE"
    description      = null
    effective_labels = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    etag             = "TPfKpS8q3kXIhywOfISUI4urBj8jjyoWgszPVNuhsZg"
    id               = "projects/project-4c5a8821-da4c-4c68-97f/locations/us-central1/serviceConnectionPolicies/grid-meter-app-memorystore-scp"
    infrastructure   = "PSC"
    labels           = {}
    location         = "us-central1"
    name             = "grid-meter-app-memorystore-scp"
    network          = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    project          = "project-4c5a8821-da4c-4c68-97f"
    psc_connections  = [
        {
            consumer_address         = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/addresses/sca-auto-addr-ecf8c836-9a22-4ea4-9f03-d06b67ad0bbe"
            consumer_forwarding_rule = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-b36db569-25eb-49c9-9547-ee57b2b67b1d"
            consumer_target_project  = "project-4c5a8821-da4c-4c68-97f"
            error                    = []
            error_info               = []
            error_type               = null
            gce_operation            = "operation-1790012467665-65c01c147593d-1f412a1b-b643c9d5"
            psc_connection_id        = "40140811761483788"
            state                    = "ACTIVE"
        },
        {
            consumer_address         = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/addresses/sca-auto-addr-2ffcc477-cb21-40af-9d60-cbe232aac235"
            consumer_forwarding_rule = "https://www.googleapis.com/compute/v1/projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/forwardingRules/sca-auto-fr-21af715c-9c9c-469b-b15f-1d1abcb4949a"
            consumer_target_project  = "project-4c5a8821-da4c-4c68-97f"
            error                    = []
            error_info               = []
            error_type               = null
            gce_operation            = "operation-1790012467882-65c01c14aa8a8-ac34679a-0cbf9dfc"
            psc_connection_id        = "40140811761483789"
            state                    = "ACTIVE"
        },
    ]
    service_class    = "gcp-memorystore"
    terraform_labels = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    update_time      = "2026-09-21T17:39:09.189900334Z"

    psc_config {
        allowed_google_producers_resource_hierarchy_level = []
        limit                                             = null
        producer_instance_location                        = null
        subnetworks                                       = [
            "projects/project-4c5a8821-da4c-4c68-97f/regions/us-central1/subnetworks/grid-meter-app-subnet",
        ]
    }
}

# google_project_iam_member.gke_node_sa:
resource "google_project_iam_member" "gke_node_sa" {
    etag    = "BwZcAV+Cbwc="
    id      = "project-4c5a8821-da4c-4c68-97f/roles/container.nodeServiceAccount/serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    member  = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    project = "project-4c5a8821-da4c-4c68-97f"
    role    = "roles/container.nodeServiceAccount"
}

# google_secret_manager_secret.cloudsql_password:
resource "google_secret_manager_secret" "cloudsql_password" {
    annotations           = {}
    create_time           = "2026-09-21T17:11:32.574458Z"
    deletion_policy       = "DELETE"
    deletion_protection   = false
    effective_annotations = {}
    effective_labels      = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    expire_time           = null
    id                    = "projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password"
    labels                = {}
    name                  = "projects/361083726560/secrets/grid-meter-app-cloudsql-password"
    project               = "project-4c5a8821-da4c-4c68-97f"
    secret_id             = "grid-meter-app-cloudsql-password"
    terraform_labels      = {
        "goog-terraform-provisioned" = "true"
        "managed-by"                 = "terraform"
        "project"                    = "grid-meter-app"
    }
    version_aliases       = {}
    version_destroy_ttl   = null

    replication {
        auto {
        }
    }
}

# google_secret_manager_secret_version.cloudsql_password:
resource "google_secret_manager_secret_version" "cloudsql_password" {
    create_time           = "2026-09-21T17:11:33.708526Z"
    deletion_policy       = "DELETE"
    destroy_time          = null
    enabled               = true
    id                    = "projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1"
    is_secret_data_base64 = false
    name                  = "projects/361083726560/secrets/grid-meter-app-cloudsql-password/versions/1"
    secret                = "projects/project-4c5a8821-da4c-4c68-97f/secrets/grid-meter-app-cloudsql-password"
    secret_data           = (sensitive value)
    secret_data_wo        = (write-only attribute)
    version               = "1"
}

# google_service_account.gke_node:
resource "google_service_account" "gke_node" {
    account_id      = "grid-meter-app-gke-node"
    deletion_policy = "DELETE"
    description     = null
    disabled        = false
    display_name    = "grid-meter-app GKE node service account"
    email           = "grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    id              = "projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    member          = "serviceAccount:grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    name            = "projects/project-4c5a8821-da4c-4c68-97f/serviceAccounts/grid-meter-app-gke-node@project-4c5a8821-da4c-4c68-97f.iam.gserviceaccount.com"
    project         = "project-4c5a8821-da4c-4c68-97f"
    unique_id       = "101610449387927989138"
}

# google_service_networking_connection.private_service_access:
resource "google_service_networking_connection" "private_service_access" {
    deletion_policy         = "DELETE"
    id                      = "projects%2Fproject-4c5a8821-da4c-4c68-97f%2Fglobal%2Fnetworks%2Fgrid-meter-app-vpc:servicenetworking.googleapis.com"
    network                 = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
    peering                 = "servicenetworking-googleapis-com"
    reserved_peering_ranges = [
        "grid-meter-app-psa-range",
    ]
    service                 = "servicenetworking.googleapis.com"
}

# google_sql_database.main:
resource "google_sql_database" "main" {
    charset         = "UTF8"
    collation       = "en_US.UTF8"
    deletion_policy = "DELETE"
    id              = "projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter"
    instance        = "grid-meter-app-postgres"
    name            = "gridmeter"
    project         = "project-4c5a8821-da4c-4c68-97f"
    self_link       = "https://sqladmin.googleapis.com/sql/v1beta4/projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres/databases/gridmeter"
}

# google_sql_database_instance.main:
resource "google_sql_database_instance" "main" {
    available_maintenance_versions       = []
    connection_name                      = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
    database_version                     = "POSTGRES_18"
    deletion_policy                      = "DELETE"
    deletion_protection                  = false
    dns_name                             = null
    dns_names                            = []
    enforce_new_sql_network_architecture = true
    first_ip_address                     = "10.243.0.3"
    id                                   = "grid-meter-app-postgres"
    instance_type                        = "CLOUD_SQL_INSTANCE"
    ip_address                           = [
        {
            ip_address     = "10.243.0.3"
            time_to_retire = null
            type           = "PRIVATE"
        },
    ]
    maintenance_version                  = "POSTGRES_18_6.R20260712.01_10"
    master_instance_name                 = null
    name                                 = "grid-meter-app-postgres"
    node_count                           = 0
    private_ip_address                   = "10.243.0.3"
    project                              = "project-4c5a8821-da4c-4c68-97f"
    psc_service_attachment_link          = null
    public_ip_address                    = null
    region                               = "us-central1"
    replica_names                        = []
    root_password_wo                     = (write-only attribute)
    self_link                            = "https://sqladmin.googleapis.com/sql/v1beta4/projects/project-4c5a8821-da4c-4c68-97f/instances/grid-meter-app-postgres"
    server_ca_cert                       = (sensitive value)
    service_account_email_address        = "p361083726560-lt8qzd@gcp-sa-cloud-sql.iam.gserviceaccount.com"

    replication_cluster {
        dr_replica               = false
        failover_dr_replica_name = null
        psa_write_endpoint       = null
    }

    settings {
        activation_policy                = "ALWAYS"
        auto_upgrade_enabled             = false
        availability_type                = "ZONAL"
        collation                        = null
        connector_enforcement            = "NOT_REQUIRED"
        data_api_access                  = null
        data_disk_provisioned_iops       = 0
        data_disk_provisioned_throughput = 0
        deletion_protection_enabled      = false
        disk_autoresize                  = true
        disk_autoresize_limit            = 0
        disk_size                        = 20
        disk_type                        = "PD_SSD"
        edition                          = "ENTERPRISE"
        effective_availability_type      = "ZONAL"
        enable_dataplex_integration      = false
        enable_google_ml_integration     = false
        pricing_plan                     = "PER_USE"
        replication_lag_max_seconds      = 31536000
        retain_backups_on_delete         = false
        tier                             = "db-f1-micro"
        time_zone                        = null
        user_labels                      = {}
        version                          = 1

        backup_configuration {
            backup_tier                    = "STANDARD"
            binary_log_enabled             = false
            enabled                        = true
            location                       = null
            point_in_time_recovery_enabled = false
            start_time                     = "12:00"
            transaction_log_retention_days = 7

            backup_retention_settings {
                retained_backups = 1
                retention_unit   = "COUNT"
            }
        }

        data_cache_config {
            data_cache_enabled = false
        }

        ip_configuration {
            allocated_ip_range                            = null
            custom_subject_alternative_names              = []
            enable_private_path_for_google_cloud_services = false
            ipv4_enabled                                  = false
            private_network                               = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
            server_ca_mode                                = "GOOGLE_MANAGED_INTERNAL_CA"
            server_ca_pool                                = null
            server_certificate_rotation_mode              = "SERVER_CERTIFICATE_ROTATION_MODE_UNSPECIFIED"
            ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
        }

        location_preference {
            follow_gae_application = null
            secondary_zone         = null
            zone                   = "us-central1-c"
        }

        read_pool_auto_scale_config {
            disable_scale_in           = false
            enabled                    = false
            max_node_count             = 0
            min_node_count             = 0
            scale_in_cooldown_seconds  = 0
            scale_out_cooldown_seconds = 0
        }
    }
}

# google_sql_user.main:
resource "google_sql_user" "main" {
    deletion_policy         = "DELETE"
    host                    = null
    iam_email               = null
    id                      = "gridmeter//grid-meter-app-postgres"
    instance                = "grid-meter-app-postgres"
    name                    = "gridmeter"
    password                = (sensitive value)
    password_wo             = (write-only attribute)
    project                 = "project-4c5a8821-da4c-4c68-97f"
    sql_server_user_details = []
    type                    = null
}

# random_password.cloudsql:
resource "random_password" "cloudsql" {
    bcrypt_hash = (sensitive value)
    id          = "none"
    length      = 32
    lower       = true
    min_lower   = 0
    min_numeric = 0
    min_special = 0
    min_upper   = 0
    number      = true
    numeric     = true
    result      = (sensitive value)
    special     = false
    upper       = true
}


Outputs:

artifact_registry_api_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-api"
artifact_registry_frontend_repository = "us-central1-docker.pkg.dev/project-4c5a8821-da4c-4c68-97f/grid-meter-app-frontend"
cloudsql_connection_name = "project-4c5a8821-da4c-4c68-97f:us-central1:grid-meter-app-postgres"
cloudsql_password_secret_id = "grid-meter-app-cloudsql-password"
cloudsql_private_ip = "10.243.0.3"
cloudsql_user = "gridmeter"
gcp_project_id = "project-4c5a8821-da4c-4c68-97f"
gcp_region = "us-central1"
gcp_zone = "us-central1-a"
gke_cluster_endpoint = (sensitive value)
gke_cluster_name = "grid-meter-app-gke"
kubeconfig_update_command = "gcloud container clusters get-credentials grid-meter-app-gke --zone us-central1-a --project project-4c5a8821-da4c-4c68-97f"
memorystore_host = "10.10.0.12"
memorystore_port = 6379
vpc_id = "projects/project-4c5a8821-da4c-4c68-97f/global/networks/grid-meter-app-vpc"
tim@Timothys-MacBook-Air gcp % 

