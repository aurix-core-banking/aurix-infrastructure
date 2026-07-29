# AUREUS Platform - Terraform Configuration
# Infraestrutura como código para AWS, Azure e GCP

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Configuração do provider AWS
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "aurix-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Configuração do provider Azure
provider "azurerm" {
  features {}
}

# Configuração do provider Google Cloud
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Configuração do provider Kubernetes
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# VPC para AWS
module "aws_vpc" {
  source = "./modules/aws/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  environment          = var.environment
  project_name         = "aurix-platform"
}

# EKS Cluster para AWS
module "aws_eks" {
  source = "./modules/aws/eks"
  
  cluster_name    = "aurix-eks"
  cluster_version = "1.28"
  vpc_id          = module.aws_vpc.vpc_id
  subnet_ids      = module.aws_vpc.private_subnet_ids
  
  node_groups = {
    main = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
    spot = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "SPOT"
      min_size      = 0
      max_size      = 5
      desired_size  = 1
    }
  }
  
  depends_on = [module.aws_vpc]
}

# RDS PostgreSQL para AWS
module "aws_rds" {
  source = "./modules/aws/rds"
  
  cluster_identifier = "aurix-postgres"
  engine            = "aurora-postgresql"
  engine_version    = "15.4"
  instance_class    = "db.r6g.large"
  
  vpc_id     = module.aws_vpc.vpc_id
  subnet_ids = module.aws_vpc.database_subnet_ids
  
  database_name = "aurix_core_banking"
  master_username = "aurix"
  master_password = var.db_password
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  security_group_ids = [module.aws_security.rds_sg_id]
  
  depends_on = [module.aws_vpc, module.aws_security]
}

# ElastiCache Redis para AWS
module "aws_redis" {
  source = "./modules/aws/redis"
  
  cluster_id         = "aurix-redis"
  node_type          = "cache.r6g.large"
  num_cache_nodes    = 2
  parameter_group_name = "default.redis7"
  
  vpc_id     = module.aws_vpc.vpc_id
  subnet_ids = module.aws_vpc.private_subnet_ids
  
  security_group_ids = [module.aws_security.redis_sg_id]
  
  depends_on = [module.aws_vpc, module.aws_security]
}

# Application Load Balancer para AWS
module "aws_alb" {
  source = "./modules/aws/alb"
  
  name               = "aurix-alb"
  vpc_id            = module.aws_vpc.vpc_id
  subnet_ids        = module.aws_vpc.public_subnet_ids
  certificate_arn   = var.ssl_certificate_arn
  
  security_group_ids = [module.aws_security.alb_sg_id]
  
  depends_on = [module.aws_vpc, module.aws_security]
}

# CloudFront CDN para AWS
module "aws_cloudfront" {
  source = "./modules/aws/cloudfront"
  
  origin_domain_name = module.aws_alb.dns_name
  certificate_arn    = var.ssl_certificate_arn
  
  depends_on = [module.aws_alb]
}

# S3 Bucket para AWS
module "aws_s3" {
  source = "./modules/aws/s3"
  
  bucket_name = "aurix-platform-${var.environment}"
  versioning  = true
  encryption  = true
  
  lifecycle_rules = [
    {
      id      = "log_archiving"
      enabled = true
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]
}

# CloudWatch Logs para AWS
module "aws_cloudwatch" {
  source = "./modules/aws/cloudwatch"
  
  log_group_name = "/aws/eks/aurix-platform"
  retention_days = 30
}

# IAM Roles para AWS
module "aws_iam" {
  source = "./modules/aws/iam"
  
  cluster_name      = module.aws_eks.cluster_name
  environment       = var.environment
  oidc_provider_arn = module.aws_eks.oidc_provider_arn
}

# Security Groups para AWS
module "aws_security" {
  source = "./modules/aws/security"
  
  vpc_id = module.aws_vpc.vpc_id
  
  depends_on = [module.aws_vpc]
}

# Resource Group para Azure
module "azure_resource_group" {
  source = "./modules/azure/resource-group"
  
  name     = "aurix-platform-${var.environment}"
  location = var.azure_location
}

# AKS Cluster para Azure
module "azure_aks" {
  source = "./modules/azure/aks"
  
  cluster_name    = "aurix-aks"
  resource_group_name = module.azure_resource_group.name
  location       = var.azure_location
  node_count     = 3
  vm_size        = "Standard_D2s_v3"
  
  depends_on = [module.azure_resource_group]
}

# PostgreSQL para Azure
module "azure_postgresql" {
  source = "./modules/azure/postgresql"
  
  server_name         = "aurix-postgres-${var.environment}"
  resource_group_name = module.azure_resource_group.name
  location           = var.azure_location
  sku_name           = "GP_Gen5_2"
  storage_mb         = 102400
  
  administrator_login    = "aurix"
  administrator_password = var.db_password
  
  depends_on = [module.azure_resource_group]
}

# Redis Cache para Azure
module "azure_redis" {
  source = "./modules/azure/redis"
  
  name                = "aurix-redis-${var.environment}"
  resource_group_name = module.azure_resource_group.name
  location           = var.azure_location
  sku_name           = "Premium"
  family             = "P"
  capacity           = 1
  
  depends_on = [module.azure_resource_group]
}

# GKE Cluster para Google Cloud
module "gcp_gke" {
  source = "./modules/gcp/gke"
  
  cluster_name    = "aurix-gke"
  location       = var.gcp_region
  node_count     = 3
  machine_type   = "e2-medium"
  
  depends_on = [module.gcp_vpc]
}

# VPC para Google Cloud
module "gcp_vpc" {
  source = "./modules/gcp/vpc"
  
  vpc_name = "aurix-vpc"
  region   = var.gcp_region
}

# Cloud SQL PostgreSQL para Google Cloud
module "gcp_cloud_sql" {
  source = "./modules/gcp/cloud-sql"
  
  instance_name = "aurix-postgres"
  database_version = "POSTGRES_15"
  region        = var.gcp_region
  tier          = "db-standard-2"
  
  database_name = "aurix_core_banking"
  user_name     = "aurix"
  user_password = var.db_password
  
  depends_on = [module.gcp_vpc]
}

# Memorystore Redis para Google Cloud
module "gcp_memorystore" {
  source = "./modules/gcp/memorystore"
  
  instance_name = "aurix-redis"
  region       = var.gcp_region
  tier         = "STANDARD_HA"
  memory_size_gb = 1
  
  depends_on = [module.gcp_vpc]
}

# Outputs
output "aws_eks_cluster_endpoint" {
  value = module.aws_eks.cluster_endpoint
}

output "aws_eks_cluster_name" {
  value = module.aws_eks.cluster_name
}

output "aws_rds_endpoint" {
  value = module.aws_rds.cluster_endpoint
}

output "aws_redis_endpoint" {
  value = module.aws_redis.cluster_endpoint
}

output "aws_alb_dns_name" {
  value = module.aws_alb.dns_name
}

output "aws_cloudfront_domain_name" {
  value = module.aws_cloudfront.domain_name
}

output "azure_aks_cluster_endpoint" {
  value = module.azure_aks.cluster_endpoint
}

output "azure_postgresql_endpoint" {
  value = module.azure_postgresql.fqdn
}

output "gcp_gke_cluster_endpoint" {
  value = module.gcp_gke.cluster_endpoint
}

output "gcp_cloud_sql_connection_name" {
  value = module.gcp_cloud_sql.connection_name
}
