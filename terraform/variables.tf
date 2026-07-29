# AUREUS Platform - Terraform Variables
# Variáveis para configuração da infraestrutura

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS"
  type        = string
  default     = ""
}

# Azure Variables
variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

# Google Cloud Variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

# Database Variables
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

# Kubernetes Variables
variable "k8s_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "aurix-platform"
}

variable "k8s_replicas" {
  description = "Number of replicas for each service"
  type        = number
  default     = 3
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Security Variables
variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Scaling Variables
variable "min_capacity" {
  description = "Minimum capacity for auto-scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum capacity for auto-scaling"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for auto-scaling"
  type        = number
  default     = 70
}

# Cost Optimization Variables
variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = true
}

variable "enable_savings_plans" {
  description = "Enable AWS Savings Plans"
  type        = bool
  default     = false
}

# Network Variables
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = true
}

# Compliance Variables
variable "enable_compliance" {
  description = "Enable compliance features (HIPAA, SOC2, etc.)"
  type        = bool
  default     = false
}

variable "compliance_framework" {
  description = "Compliance framework to implement"
  type        = string
  default     = "SOC2"
  
  validation {
    condition     = contains(["SOC2", "HIPAA", "PCI-DSS", "ISO27001"], var.compliance_framework)
    error_message = "Compliance framework must be one of: SOC2, HIPAA, PCI-DSS, ISO27001."
  }
}

# Disaster Recovery Variables
variable "enable_dr" {
  description = "Enable disaster recovery"
  type        = bool
  default     = false
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "us-west-2"
}

# Performance Variables
variable "enable_cdn" {
  description = "Enable CDN for static content"
  type        = bool
  default     = true
}

variable "enable_caching" {
  description = "Enable Redis caching"
  type        = bool
  default     = true
}

# Frontend deploy (apontamento = API/gateway URL usado no build do frontend)
variable "deploy_frontend" {
  description = "Include frontend build and optional upload in deploy (admin + web)"
  type        = bool
  default     = false
}

variable "frontend_api_url" {
  description = "API/gateway URL for frontend (REACT_APP_API_URL). Same cloud: ALB/CloudFront URL; separate: external API URL"
  type        = string
  default     = "http://localhost:8080"
}

variable "frontend_s3_bucket_admin" {
  description = "S3 bucket name for aurix-admin static site (optional; requires AWS)"
  type        = string
  default     = ""
}

variable "frontend_s3_bucket_web" {
  description = "S3 bucket name for aurix-web static site (optional; requires AWS)"
  type        = string
  default     = ""
}

# Development Variables
variable "enable_debug" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level for applications"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARN, ERROR."
  }
}
