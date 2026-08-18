# Aurix Platform - Variaveis Terraform GCP

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ambiente deve ser: dev, staging ou prod."
  }
}

variable "gcp_project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "gcp_region" {
  description = "Regiao GCP"
  type        = string
  default     = "southamerica-east1"
}

# VPC

variable "gke_subnet_cidr" {
  description = "CIDR da subnet GKE"
  type        = string
  default     = "10.0.1.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR para pods do GKE"
  type        = string
  default     = "10.4.0.0/14"
}

variable "gke_services_cidr" {
  description = "CIDR para services do GKE"
  type        = string
  default     = "10.8.0.0/20"
}

variable "gke_master_cidr" {
  description = "CIDR do master do GKE (privado)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "database_subnet_cidr" {
  description = "CIDR da subnet de banco de dados"
  type        = string
  default     = "10.0.2.0/24"
}

variable "redis_subnet_cidr" {
  description = "CIDR da subnet Redis"
  type        = string
  default     = "10.0.3.0/24"
}

variable "authorized_network_cidr" {
  description = "CIDR autorizado para acessar o master do GKE"
  type        = string
  default     = "0.0.0.0/0"
}

# GKE

variable "gke_machine_type" {
  description = "Tipo de maquina para nodes GKE"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_min_nodes" {
  description = "Minimo de nodes por zona"
  type        = number
  default     = 2
}

variable "gke_max_nodes" {
  description = "Maximo de nodes por zona"
  type        = number
  default     = 10
}

# Cloud SQL

variable "cloudsql_tier" {
  description = "Tier do Cloud SQL"
  type        = string
  default     = "db-standard-4"
}

variable "db_username" {
  description = "Usuario do Cloud SQL"
  type        = string
  default     = "aurix"
}

variable "db_password" {
  description = "Senha do Cloud SQL"
  type        = string
  sensitive   = true
}

# Memorystore Redis

variable "redis_memory_gb" {
  description = "Memoria do Redis em GB"
  type        = number
  default     = 5
}
