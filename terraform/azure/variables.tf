# Aurix Platform - Variaveis Terraform Azure

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ambiente deve ser: dev, staging ou prod."
  }
}

variable "azure_location" {
  description = "Regiao Azure"
  type        = string
  default     = "brazilsouth"
}

variable "vnet_cidr" {
  description = "CIDR block da VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR da subnet AKS"
  type        = string
  default     = "10.0.1.0/24"
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

variable "data_subnet_cidr" {
  description = "CIDR da subnet de dados"
  type        = string
  default     = "10.0.4.0/24"
}

# AKS

variable "aks_version" {
  description = "Versao do Kubernetes no AKS"
  type        = string
  default     = "1.29"
}

variable "aks_vm_size" {
  description = "Tamanho das VMs do AKS"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_node_count" {
  description = "Numero inicial de nodes"
  type        = number
  default     = 3
}

variable "aks_min_nodes" {
  description = "Minimo de nodes"
  type        = number
  default     = 2
}

variable "aks_max_nodes" {
  description = "Maximo de nodes"
  type        = number
  default     = 15
}

# Azure SQL

variable "db_username" {
  description = "Usuario master do Azure SQL"
  type        = string
  default     = "aurixadmin"
}

variable "db_password" {
  description = "Senha do Azure SQL"
  type        = string
  sensitive   = true
}

# Redis

variable "redis_capacity" {
  description = "Capacidade do Redis (1-6 para Premium)"
  type        = number
  default     = 2
}
