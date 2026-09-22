resource "random_password" "cloudsql" {
  length  = 32
  special = false # Cloud SQL's own generated-password path avoids specials too; keeps this simple to pass through shells/URLs unescaped.
}

# GCP has no RDS-style manage_master_user_password convenience - this is
# the standard idiomatic substitute: generate the password with the random
# provider, store it in Secret Manager, and never let it appear in
# Terraform state as a bare resource attribute (random_password's own
# `result` does live in state, same caveat AWS's approach avoided
# entirely - flagged here rather than glossed over).
resource "google_secret_manager_secret" "cloudsql_password" {
  secret_id = "${var.project_name}-cloudsql-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "cloudsql_password" {
  secret      = google_secret_manager_secret.cloudsql_password.id
  secret_data = random_password.cloudsql.result
}

resource "google_sql_database_instance" "main" {
  name                = "${var.project_name}-postgres"
  database_version    = var.cloudsql_postgres_version
  region              = var.gcp_region
  deletion_protection = false # Same reasoning as gke.tf - a demo cluster's DB needs to destroy cleanly.

  # depends_on the PSA peering (network.tf) - private_network below can't
  # actually route until that VPC peering connection exists.
  depends_on = [google_service_networking_connection.private_service_access]

  settings {
    # Declared explicitly after a real, live apply failure (2026-09-21):
    # `edition` is `optional, computed` in the provider schema, and this
    # project/account's implicit default resolved to ENTERPRISE_PLUS, which
    # rejects db-f1-micro outright ("Invalid Tier (db-f1-micro) for
    # (ENTERPRISE_PLUS) Edition" - error 400, not a plan-time warning).
    # ENTERPRISE is the classic edition that actually supports the
    # shared-core tiers (db-f1-micro/db-g1-small) this project's
    # cost-conscious sizing depends on - another live instance of this
    # project's standing "undeclared defaults" lesson (CLAUDE.md), found
    # via a real apply, not caught by `terraform plan` or `validate`.
    edition           = "ENTERPRISE"
    tier              = var.cloudsql_tier
    disk_size         = var.cloudsql_disk_size_gb
    disk_type         = "PD_SSD"
    availability_type = "ZONAL" # Single-zone, not REGIONAL (GA Multi-AZ equivalent) - same "smallest viable" sizing decision as AWS's multi_az=false, for the same reason: this project's local track already builds real Patroni HA by hand (docs/postgres-ha-scope.md).

    ip_configuration {
      ipv4_enabled    = false # No public IP - private-IP-only, matching AWS's publicly_accessible=false.
      private_network = google_compute_network.main.id
    }

    backup_configuration {
      enabled = true
      # point_in_time_recovery_enabled declared explicitly false - it's
      # Postgres-specific WAL-based PITR, genuinely separate from daily
      # backups, and this demo database has no real recovery value to
      # justify the extra WAL storage cost either way (same reasoning as
      # AWS's short backup_retention_period=1).
      point_in_time_recovery_enabled = false
      backup_retention_settings {
        retained_backups = 1
      }
    }
  }
}

resource "google_sql_database" "main" {
  name     = var.cloudsql_db_name
  instance = google_sql_database_instance.main.name

  # Found via a second real live `terraform destroy` (2026-09-21, later the same day as the
  # original race below): the first fix - depends_on = [google_sql_database.main] on
  # google_sql_user.main - had the dependency direction backwards, and a live retry reproduced the
  # exact original error verbatim as proof. Terraform's destroy order is the REVERSE of its create
  # order for a depends_on edge: if A depends_on B, B is created first (correct, and what happened
  # here), but A is destroyed FIRST and B second - not "B finishes destroying, then A" as the
  # original comment assumed. So the old edge (user depends_on database) forced the USER to be
  # destroyed before the database, every time - `google_sql_user.main: Destroying...` started in
  # the very first batch of the retry, and `google_sql_database.main` never got a "Destroying..."
  # line at all before the DROP ROLE call failed identically to the first time. The actual fix is
  # to invert which resource carries the depends_on: the database now depends_on the user, so
  # destroy order becomes database-first, user-second - DROP DATABASE (and everything it owns)
  # actually completes before DROP ROLE is attempted, which is what removes the "5 objects in
  # database gridmeter" the role-drop kept tripping over. Confirmed this doesn't disturb create
  # order in any way that matters - a Cloud SQL user only needs the instance to exist, not the
  # database, so creating the user before the database (the new implied order) is fine.
  depends_on = [google_sql_user.main]
}

resource "google_sql_user" "main" {
  name     = var.cloudsql_user
  instance = google_sql_database_instance.main.name
  password = random_password.cloudsql.result
}
