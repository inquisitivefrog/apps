resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres 5432 from the EKS cluster security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from EKS nodes/pods"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.rds_db_name
  username = var.rds_master_username
  # No password variable exists anywhere in this config - manage_master_user_password
  # generates and stores the master password in AWS Secrets Manager automatically,
  # so no plaintext credential ever exists in Terraform state or .tf files.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Single-AZ, matching the "smallest viable" sizing decision - this
  # project's own local track already builds real Patroni-based Postgres
  # HA by hand (docs/postgres-ha-scope.md); this cloud target's job is to
  # demonstrate managed-service judgment, not to duplicate that HA work a
  # second time on a different substrate.
  multi_az = false

  # Kept short and declared explicitly rather than left at the engine
  # default (7 days) - a demo database's backups have no real recovery
  # value, and shorter retention means less backup storage cost.
  backup_retention_period = 1

  # This is a demo app with synthetic data (see docs/architecture.md) -
  # skip_final_snapshot=true means `terraform destroy` doesn't leave an
  # orphaned, indefinitely-billed snapshot behind. Never appropriate for a
  # database holding real data.
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
