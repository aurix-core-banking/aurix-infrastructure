# Aurix Platform - Outputs Terraform Azure

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.aurix.name
}

output "vnet_id" {
  description = "ID da VNet"
  value       = azurerm_virtual_network.aurix.id
}

output "aks_cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.aurix.name
}

output "aks_cluster_fqdn" {
  description = "FQDN do API server do AKS"
  value       = azurerm_kubernetes_cluster.aurix.fqdn
}

output "aks_cluster_identity" {
  description = "Identity principal do AKS"
  value       = azurerm_kubernetes_cluster.aurix.kube_config[0].client_key
  sensitive   = true
}

output "aks_kube_config" {
  description = "Kube config do AKS (sensivel)"
  value       = azurerm_kubernetes_cluster.aurix.kube_config_raw
  sensitive   = true
}

output "sql_server_fqdn" {
  description = "FQDN do Azure SQL Server"
  value       = azurerm_mssql_server.aurix.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Nome do banco de dados"
  value       = azurerm_mssql_database.aurix.name
}

output "redis_hostname" {
  description = "Hostname do Azure Cache for Redis"
  value       = azurerm_redis_cache.aurix.hostname
}

output "redis_ssl_port" {
  description = "Porta SSL do Redis"
  value       = azurerm_redis_cache.aurix.ssl_port
}

output "redis_primary_access_key" {
  description = "Chave de acesso primaria do Redis"
  value       = azurerm_redis_cache.aurix.primary_access_key
  sensitive   = true
}

output "storage_account_name" {
  description = "Nome da Storage Account"
  value       = azurerm_storage_account.aurix.name
}

output "storage_account_id" {
  description = "ID da Storage Account"
  value       = azurerm_storage_account.aurix.id
}

output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.aurix.workspace_id
}
