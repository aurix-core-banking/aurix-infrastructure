variable "server_name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "administrator_login" { type = string }
variable "administrator_password" { type = string }

resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  version                = "15"

  tags = {
    Name = var.server_name
  }
}



output "fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}
