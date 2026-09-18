resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-elasticache-sg"
  description = "Allow Valkey 6379 from the EKS cluster security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Valkey from EKS nodes/pods"
    from_port       = 6379
    to_port         = 6379
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
    Name = "${var.project_name}-elasticache-sg"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-cache"
  description          = "${var.project_name} Valkey cache"
  engine               = "valkey"
  # See variables.tf's cache_engine_version comment for why valkey, not
  # redis, and how the version was checked live against this account.
  engine_version = var.cache_engine_version
  node_type      = var.cache_node_type
  port           = 6379

  # aws_elasticache_cluster (the simpler single-node resource) still
  # client-side-validates engine against only ["memcached", "redis"] in
  # this provider version (6.65.0), confirmed by a real `terraform
  # validate` failure - even though AWS's own API genuinely supports
  # valkey (confirmed live via `aws elasticache describe-cache-engine-versions`).
  # aws_elasticache_replication_group's validator has been updated to
  # accept it, so that's the resource used here instead - not because HA
  # replication is wanted (num_cache_clusters = 1 below is still a single
  # node, matching the "smallest viable" sizing decision), just to work
  # around the other resource's stale client-side validation.
  num_cache_clusters = 1

  # This app's own Redis/Valkey usage (a cache of the latest reading per
  # meter, per docs/architecture.md) already has a documented cache-miss
  # fallback to Postgres, so a single cache node's lack of failover is an
  # accepted, low-consequence tradeoff here, the same reasoning already
  # applied to this app's own Sentinel min-replicas-to-write gap in
  # docs/redis-ha-scope.md.

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  tags = {
    Name = "${var.project_name}-cache"
  }
}
