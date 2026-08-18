# Aurix Platform - Variaveis Terraform AWS

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ambiente deve ser: dev, staging ou prod."
  }
}

variable "aws_region" {
  description = "Regiao AWS"
  type        = string
  default     = "sa-east-1"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# EKS

variable "eks_version" {
  description = "Versao do cluster EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Tipos de instancia para on-demand nodes"
  type        = list(string)
  default     = ["m6i.xlarge", "m6i.2xlarge"]
}

variable "eks_spot_instance_types" {
  description = "Tipos de instancia para spot nodes"
  type        = list(string)
  default     = ["m6i.xlarge", "m6i.2xlarge", "m5.xlarge"]
}

variable "eks_min_nodes" {
  description = "Minimo de nodes on-demand"
  type        = number
  default     = 3
}

variable "eks_max_nodes" {
  description = "Maximo de nodes"
  type        = number
  default     = 20
}

variable "eks_desired_nodes" {
  description = "Numero desejado de nodes on-demand"
  type        = number
  default     = 5
}

variable "eks_spot_desired_nodes" {
  description = "Numero desejado de nodes spot"
  type        = number
  default     = 2
}

# RDS PostgreSQL

variable "rds_engine_version" {
  description = "Versao do Aurora PostgreSQL"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "Classe de instancia do Aurora"
  type        = string
  default     = "db.r6g.xlarge"
}

variable "rds_reader_count" {
  description = "Numero de read replicas"
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Nome do banco de dados principal"
  type        = string
  default     = "aurix_db"
}

variable "db_username" {
  description = "Usuario master do banco"
  type        = string
  default     = "aurix"
}

variable "db_password" {
  description = "Senha do usuario master do banco"
  type        = string
  sensitive   = true
}

# ElastiCache Redis

variable "redis_node_type" {
  description = "Tipo de instancia do Redis"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_nodes" {
  description = "Numero de clusters Redis (minimo 2 para Multi-AZ)"
  type        = number
  default     = 2
}
