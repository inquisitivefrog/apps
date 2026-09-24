
Redis
-----
tim@Timothys-MacBook-Air aws % terraform state show aws_elasticache_replication_group.main
# aws_elasticache_replication_group.main:
resource "aws_elasticache_replication_group" "main" {
    arn                        = "arn:aws:elasticache:us-west-2:084375569056:replicationgroup:grid-meter-app-cache"
    at_rest_encryption_enabled = "true"
    auth_token                 = (sensitive value)
    auth_token_wo              = (write-only attribute)
    auto_minor_version_upgrade = "true"
    automatic_failover_enabled = false
    cluster_enabled            = false
    cluster_mode               = "disabled"
    data_tiering_enabled       = false
    description                = "grid-meter-app Valkey cache"
    durability                 = null
    engine                     = "valkey"
    engine_version             = "9.1"
    engine_version_actual      = "9.1.0"
    id                         = "grid-meter-app-cache"
    ip_discovery               = "ipv4"
    kms_key_id                 = null
    maintenance_window         = "wed:07:30-wed:08:30"
    member_clusters            = [
        "grid-meter-app-cache-001",
    ]
    multi_az_enabled           = false
    network_type               = "ipv4"
    node_type                  = "cache.t4g.micro"
    num_cache_clusters         = 1
    num_node_groups            = 1
    parameter_group_name       = "default.valkey9"
    port                       = 6379
    primary_endpoint_address   = "master.grid-meter-app-cache.dfvt8u.usw2.cache.amazonaws.com"
    reader_endpoint_address    = "replica.grid-meter-app-cache.dfvt8u.usw2.cache.amazonaws.com"
    region                     = "us-west-2"
    replicas_per_node_group    = 0
    replication_group_id       = "grid-meter-app-cache"
    security_group_ids         = [
        "sg-035f738cd20b6c5cd",
    ]
    security_group_names       = []
    snapshot_retention_limit   = 0
    snapshot_window            = "12:30-13:30"
    subnet_group_name          = "grid-meter-app-cache-subnet-group"
    tags                       = {
        "Name" = "grid-meter-app-cache"
    }
    tags_all                   = {
        "ManagedBy" = "terraform"
        "Name"      = "grid-meter-app-cache"
        "Project"   = "grid-meter-app"
    }
    transit_encryption_enabled = true
    transit_encryption_mode    = "required"
    user_group_ids             = [
        "grid-meter-app-users",
    ]

    node_group_configuration {
        node_group_id              = "0001"
        primary_availability_zone  = "us-west-2c"
        primary_outpost_arn        = null
        replica_availability_zones = []
        replica_count              = 0
        replica_outpost_arns       = []
        slots                      = null
    }
}
tim@Timothys-MacBook-Air aws %

Postgres
--------
tim@Timothys-MacBook-Air aws % terraform state show aws_db_instance.main
# aws_db_instance.main:
resource "aws_db_instance" "main" {
    address                               = "grid-meter-app-postgres.cpwiwo2c4ikf.us-west-2.rds.amazonaws.com"
    allocated_storage                     = 20
    apply_immediately                     = false
    arn                                   = "arn:aws:rds:us-west-2:084375569056:db:grid-meter-app-postgres"
    auto_minor_version_upgrade            = true
    availability_zone                     = "us-west-2a"
    backup_retention_period               = 1
    backup_target                         = "region"
    backup_window                         = "13:07-13:37"
    ca_cert_identifier                    = "rds-ca-rsa2048-g1"
    character_set_name                    = null
    copy_tags_to_snapshot                 = false
    custom_iam_instance_profile           = null
    customer_owned_ip_enabled             = false
    database_insights_mode                = "standard"
    db_name                               = "gridmeter"
    db_subnet_group_name                  = "grid-meter-app-db-subnet-group"
    dedicated_log_volume                  = false
    delete_automated_backups              = true
    deletion_protection                   = false
    domain                                = null
    domain_auth_secret_arn                = null
    domain_fqdn                           = null
    domain_iam_role_name                  = null
    domain_ou                             = null
    endpoint                              = "grid-meter-app-postgres.cpwiwo2c4ikf.us-west-2.rds.amazonaws.com:5432"
    engine                                = "postgres"
    engine_lifecycle_support              = "open-source-rds-extended-support"
    engine_version                        = "18.4"
    engine_version_actual                 = "18.4"
    hosted_zone_id                        = "Z1PVIF0B656C1W"
    iam_database_authentication_enabled   = false
    id                                    = "db-ATGMU3VR2BUT3IQMKNG4FPZ54A"
    identifier                            = "grid-meter-app-postgres"
    identifier_prefix                     = null
    instance_class                        = "db.t4g.micro"
    iops                                  = 3000
    kms_key_id                            = "arn:aws:kms:us-west-2:084375569056:key/5d968067-ec60-4127-9fef-627a7a2670ca"
    latest_restorable_time                = "2026-09-24T15:34:08Z"
    license_model                         = "postgresql-license"
    listener_endpoint                     = []
    maintenance_window                    = "mon:12:28-mon:12:58"
    manage_master_user_password           = true
    master_user_secret                    = [
        {
            kms_key_id    = "arn:aws:kms:us-west-2:084375569056:key/1473aa91-27d5-4c69-b070-5b5c03419f36"
            secret_arn    = "arn:aws:secretsmanager:us-west-2:084375569056:secret:rds!db-9b9de98f-90c7-41c6-8784-a21420cfab7c-LLNbsh"
            secret_status = "active"
        },
    ]
    max_allocated_storage                 = 0
    monitoring_interval                   = 0
    monitoring_role_arn                   = null
    multi_az                              = false
    nchar_character_set_name              = null
    network_type                          = "IPV4"
    option_group_name                     = "default:postgres-18"
    parameter_group_name                  = "default.postgres18"
    password_wo                           = (write-only attribute)
    performance_insights_enabled          = false
    performance_insights_kms_key_id       = null
    performance_insights_retention_period = 0
    port                                  = 5432
    publicly_accessible                   = false
    region                                = "us-west-2"
    replica_mode                          = null
    replicas                              = []
    replicate_source_db                   = null
    resource_id                           = "db-ATGMU3VR2BUT3IQMKNG4FPZ54A"
    skip_final_snapshot                   = true
    status                                = "available"
    storage_encrypted                     = true
    storage_throughput                    = 125
    storage_type                          = "gp3"
    tags                                  = {
        "Name" = "grid-meter-app-postgres"
    }
    tags_all                              = {
        "ManagedBy" = "terraform"
        "Name"      = "grid-meter-app-postgres"
        "Project"   = "grid-meter-app"
    }
    timezone                              = null
    upgrade_rollout_order                 = "second"
    username                              = "gridmeter"
    vpc_security_group_ids                = [
        "sg-0fe9f6b238470cbcd",
    ]
}
tim@Timothys-MacBook-Air aws % 

