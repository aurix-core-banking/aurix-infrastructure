# Aurix Platform - Terraform Azure
# AKS, Azure SQL Hyperscale, Azure Cache Redis, Blob Storage, VNet, NSGs

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "aurix" {
  name     = "aurix-${var.environment}"
  location = var.azure_location
  tags = {
    Project     = "aurix-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# VNet, Subnets, NSGs
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "aurix" {
  name                = "aurix-vnet-${var.environment}"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name
  tags = { Name = "aurix-vnet-${var.environment}" }
}

resource "azurerm_subnet" "aks" {
  name                 = "aurix-aks-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.aurix.name
  virtual_network_name = azurerm_virtual_network.aurix.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "database" {
  name                 = "aurix-db-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.aurix.name
  virtual_network_name = azurerm_virtual_network.aurix.name
  address_prefixes     = [var.database_subnet_cidr]
}

resource "azurerm_subnet" "redis" {
  name                 = "aurix-redis-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.aurix.name
  virtual_network_name = azurerm_virtual_network.aurix.name
  address_prefixes     = [var.redis_subnet_cidr]
}

resource "azurerm_subnet" "data" {
  name                 = "aurix-data-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.aurix.name
  virtual_network_name = azurerm_virtual_network.aurix.name
  address_prefixes     = [var.data_subnet_cidr]
}

# NSG - AKS
resource "azurerm_network_security_group" "aks" {
  name                = "aurix-aks-nsg-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = { Name = "aurix-aks-nsg-${var.environment}" }
}

# NSG - Database
resource "azurerm_network_security_group" "database" {
  name                = "aurix-db-nsg-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name

  security_rule {
    name                       = "AllowPostgreSQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = { Name = "aurix-db-nsg-${var.environment}" }
}

# NSG - Redis
resource "azurerm_network_security_group" "redis" {
  name                = "aurix-redis-nsg-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name

  security_rule {
    name                       = "AllowRedis"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6380"
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = { Name = "aurix-redis-nsg-${var.environment}" }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_subnet_network_security_group_association" "redis" {
  subnet_id                 = azurerm_subnet.redis.id
  network_security_group_id = azurerm_network_security_group.redis.id
}

# ---------------------------------------------------------------------------
# AKS Cluster
# ---------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "aurix" {
  name                = "aurix-aks-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name
  dns_prefix          = "aurix-${var.environment}"
  kubernetes_version  = var.aks_version

  default_node_pool {
    name                = "system"
    vm_size             = var.aks_vm_size
    node_count          = var.aks_node_count
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = var.aks_min_nodes
    max_count           = var.aks_max_nodes
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aurix.id
  }

  tags = { Name = "aurix-aks-${var.environment}" }
}

# Pool de spot para workloads batch
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aurix.id
  vm_size               = var.aks_vm_size
  vnet_subnet_id        = azurerm_subnet.aks.id
  enable_auto_scaling   = true
  min_count             = 0
  max_count             = var.aks_max_nodes
  priority              = "Spot"
  eviction_policy       = "Delete"

  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]

  tags = { Name = "aurix-aks-spot-${var.environment}" }
}

# ---------------------------------------------------------------------------
# Azure SQL Database (Hyperscale)
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server" "aurix" {
  name                         = "aurix-sql-${var.environment}"
  resource_group_name          = azurerm_resource_group.aurix.name
  location                     = azurerm_resource_group.aurix.location
  version                      = "12.0"
  administrator_login          = var.db_username
  administrator_login_password = var.db_password
  minimum_tls_version          = "1.2"

  tags = { Name = "aurix-sql-${var.environment}" }
}

resource "azurerm_mssql_database" "aurix" {
  name      = "aurix_db"
  server_id = azurerm_mssql_server.aurix.id
  sku_name  = "HS_Gen5_2"

  short_term_retention_policy {
    retention_days = 35
  }

  long_term_retention_policy {
    weekly_retention  = "P4W"
    monthly_retention = "P12M"
    yearly_retention  = "P5Y"
  }

  tags = { Name = "aurix-sqldb-${var.environment}" }
}

resource "azurerm_mssql_firewall_rule" "aks" {
  name             = "AllowAKS"
  server_id        = azurerm_mssql_server.aurix.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ---------------------------------------------------------------------------
# Azure Cache for Redis
# ---------------------------------------------------------------------------

resource "azurerm_redis_cache" "aurix" {
  name                = "aurix-redis-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name
  capacity            = var.redis_capacity
  family              = "P"
  sku_name            = "Premium"
  minimum_tls_version = "1.2"
  subnet_id           = azurerm_subnet.redis.id

  redis_version = "7"

  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 5
  }

  tags = { Name = "aurix-redis-${var.environment}" }
}

# ---------------------------------------------------------------------------
# Blob Storage (Data Lake)
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "aurix" {
  name                     = "aurix${var.environment}${random_string.storage.result}"
  resource_group_name      = azurerm_resource_group.aurix.name
  location                 = azurerm_resource_group.aurix.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  is_hns_enabled           = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = { Name = "aurix-storage-${var.environment}" }
}

resource "random_string" "storage" {
  length  = 8
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.aurix.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.aurix.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.aurix.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.aurix.name
  container_access_type = "private"
}

# Lifecycle management para blobs
resource "azurerm_storage_management_policy" "aurix" {
  storage_account_id = azurerm_storage_account.aurix.id

  rule {
    name    = "bronze-lifecycle"
    enabled = true
    filters {
      prefix_match = ["bronze/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "backups-lifecycle"
    enabled = true
    filters {
      prefix_match = ["backups/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Log Analytics (monitoramento AKS)
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "aurix" {
  name                = "aurix-logs-${var.environment}"
  location            = azurerm_resource_group.aurix.location
  resource_group_name = azurerm_resource_group.aurix.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = { Name = "aurix-logs-${var.environment}" }
}
