variable "name" { type = string }
variable "location" { type = string }

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location

  tags = {
    Name = var.name
  }
}

output "name" {
  value = azurerm_resource_group.main.name
}
