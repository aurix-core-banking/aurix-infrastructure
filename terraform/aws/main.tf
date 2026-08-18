# Aurix Platform - Terraform AWS
# EKS, RDS PostgreSQL Multi-AZ, ElastiCache Redis, S3 (Bronze/Silver/Gold), VPC, IAM

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aurix-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Cloud       = "aws"
    }
  }
}

# ---------------------------------------------------------------------------
# VPC, Subnets, NAT Gateway
# ---------------------------------------------------------------------------

resource "aws_vpc" "aurix" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "aurix-vpc-${var.environment}" }
}

resource "aws_internet_gateway" "aurix" {
  vpc_id = aws_vpc.aurix.id
  tags   = { Name = "aurix-igw-${var.environment}" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "aurix-nat-eip-${var.environment}" }
}

resource "aws_nat_gateway" "aurix" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "aurix-nat-${var.environment}" }
}

resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.aurix.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "aurix-public-${var.azs[count.index]}" }
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.aurix.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(var.azs))
  availability_zone = var.azs[count.index]
  tags = { Name = "aurix-private-${var.azs[count.index]}" }
}

resource "aws_subnet" "database" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.aurix.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(var.azs) * 2)
  availability_zone = var.azs[count.index]
  tags = { Name = "aurix-database-${var.azs[count.index]}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.aurix.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aurix.id
  }
  tags = { Name = "aurix-public-rt-${var.environment}" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.aurix.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aurix.id
  }
  tags = { Name = "aurix-private-rt-${var.environment}" }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.aurix.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aurix.id
  }
  tags = { Name = "aurix-database-rt-${var.environment}" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name_prefix = "aurix-eks-cluster-${var.environment}-"
  vpc_id      = aws_vpc.aurix.id
  description = "Security group do cluster EKS Aurix"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS para API do EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aurix-eks-cluster-sg-${var.environment}" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "rds" {
  name_prefix = "aurix-rds-${var.environment}-"
  vpc_id      = aws_vpc.aurix.id
  description = "Security group do RDS PostgreSQL Aurix"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "PostgreSQL vindo do EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aurix-rds-sg-${var.environment}" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "redis" {
  name_prefix = "aurix-redis-${var.environment}-"
  vpc_id      = aws_vpc.aurix.id
  description = "Security group do ElastiCache Redis Aurix"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Redis vindo do EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "aurix-redis-sg-${var.environment}" }
  lifecycle { create_before_destroy = true }
}

# ---------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "aurix-eks-cluster-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "aurix" {
  name     = "aurix-eks-${var.environment}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# ---------------------------------------------------------------------------
# EKS Node Groups (ondemand + spot)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "eks_nodes" {
  name = "aurix-eks-node-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.aurix.name
  node_group_name = "aurix-main-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.eks_node_instance_types

  scaling_config {
    min_size     = var.eks_min_nodes
    max_size     = var.eks_max_nodes
    desired_size = var.eks_desired_nodes
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_registry,
  ]

  tags = { Name = "aurix-eks-nodes-${var.environment}" }
}

resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.aurix.name
  node_group_name = "aurix-spot-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.eks_spot_instance_types
  capacity_type   = "SPOT"

  scaling_config {
    min_size     = 0
    max_size     = var.eks_max_nodes
    desired_size = var.eks_spot_desired_nodes
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_registry,
  ]

  tags = { Name = "aurix-eks-spot-${var.environment}" }
}

# OIDC provider para IRSA
data "tls_certificate" "eks" {
  url = aws_eks_cluster.aurix.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.aurix.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

# ---------------------------------------------------------------------------
# RDS PostgreSQL (Aurora Multi-AZ)
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "aurix" {
  name       = "aurix-db-${var.environment}"
  subnet_ids = aws_subnet.database[*].id
  tags       = { Name = "aurix-db-subnet-${var.environment}" }
}

resource "aws_rds_cluster_parameter_group" "aurix" {
  name   = "aurix-pg-params-${var.environment}"
  family = "aurora-postgresql15"

  parameter {
    name  = "shared_preload_libraries"
    value = "timescaledb,pg_stat_statements"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = { Name = "aurix-pg-params-${var.environment}" }
}

resource "aws_rds_cluster" "aurix" {
  cluster_identifier              = "aurix-postgres-${var.environment}"
  engine                          = "aurora-postgresql"
  engine_version                  = var.rds_engine_version
  database_name                   = var.db_name
  master_username                 = var.db_username
  master_password                 = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.aurix.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurix.name

  backup_retention_period      = 30
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  storage_encrypted   = true
  skip_final_snapshot = var.environment != "prod"

  final_snapshot_identifier = var.environment == "prod" ? "aurix-final-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = { Name = "aurix-postgres-${var.environment}" }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier              = "aurix-pg-writer-${var.environment}"
  cluster_identifier      = aws_rds_cluster.aurix.id
  instance_class          = var.rds_instance_class
  engine                  = aws_rds_cluster.aurix.engine
  engine_version          = aws_rds_cluster.aurix.engine_version
  publicly_accessible     = false
  db_parameter_group_name = aws_rds_cluster_parameter_group.aurix.name
  tags = { Name = "aurix-pg-writer-${var.environment}" }
}

resource "aws_rds_cluster_instance" "readers" {
  count                   = var.rds_reader_count
  identifier              = "aurix-pg-reader-${var.environment}-${count.index + 1}"
  cluster_identifier      = aws_rds_cluster.aurix.id
  instance_class          = var.rds_instance_class
  engine                  = aws_rds_cluster.aurix.engine
  engine_version          = aws_rds_cluster.aurix.engine_version
  publicly_accessible     = false
  db_parameter_group_name = aws_rds_cluster_parameter_group.aurix.name
  tags = { Name = "aurix-pg-reader-${var.environment}-${count.index + 1}" }
}

# ---------------------------------------------------------------------------
# ElastiCache Redis (Multi-AZ com failover automatico)
# ---------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "aurix" {
  name       = "aurix-redis-${var.environment}"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "aurix" {
  replication_group_id = "aurix-redis-${var.environment}"
  description          = "Cluster Redis Aurix Platform"
  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_num_nodes
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.aurix.name
  security_group_ids   = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  tags = { Name = "aurix-redis-${var.environment}" }
}

# ---------------------------------------------------------------------------
# S3 Buckets (Data Lake: Bronze / Silver / Gold + Backups)
# ---------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description             = "KMS para buckets S3 Aurix (${var.environment})"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = { Name = "aurix-s3-kms-${var.environment}" }
}

resource "aws_s3_bucket" "bronze" {
  bucket = "aurix-bronze-${var.environment}"
  tags   = { Name = "aurix-bronze-${var.environment}"; Layer = "bronze" }
}

resource "aws_s3_bucket" "silver" {
  bucket = "aurix-silver-${var.environment}"
  tags   = { Name = "aurix-silver-${var.environment}"; Layer = "silver" }
}

resource "aws_s3_bucket" "gold" {
  bucket = "aurix-gold-${var.environment}"
  tags   = { Name = "aurix-gold-${var.environment}"; Layer = "gold" }
}

resource "aws_s3_bucket" "backups" {
  bucket = "aurix-backups-${var.environment}"
  tags   = { Name = "aurix-backups-${var.environment}"; Purpose = "backups" }
}

locals {
  s3_buckets = [aws_s3_bucket.bronze, aws_s3_bucket.silver, aws_s3_bucket.gold, aws_s3_bucket.backups]
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = { for b in local.s3_buckets : b.id => b }
  bucket   = each.key
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = { for b in local.s3_buckets : b.id => b }
  bucket   = each.key
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = { for b in local.s3_buckets : b.id => b }
  bucket   = each.key
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  rule {
    id     = "transition-para-ia-glacier"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    expiration { days = 365 }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "retention-backups"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    expiration { days = 730 }
  }
}

# ---------------------------------------------------------------------------
# IAM - IRSA para backups
# ---------------------------------------------------------------------------

resource "aws_iam_role" "eks_irsa_backups" {
  name = "aurix-irsa-backups-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.aurix.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:aurix-data-platform:backup-sa"
          "${replace(aws_eks_cluster.aurix.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eks_irsa_backups" {
  name = "aurix-backups-policy-${var.environment}"
  role = aws_iam_role.eks_irsa_backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.backups.arn,
        "${aws_s3_bucket.backups.arn}/*",
        aws_s3_bucket.bronze.arn,
        "${aws_s3_bucket.bronze.arn}/*"
      ]
    }]
  })
}
