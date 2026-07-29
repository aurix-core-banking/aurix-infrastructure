variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku_name" { type = string }
variable "family" { type = string }
variable "capacity" { type = number }

resource "azurerm_redis_cache" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  capacity = var.capacity
  family   = var.family
  sku_name = var.sku_name

  non_ssl_port_enabled = false

  tags = {
    Name = var.name
  }
}

output "hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "ssl_port" {
  value = azurerm_redis_cache.main.ssl_port
}
