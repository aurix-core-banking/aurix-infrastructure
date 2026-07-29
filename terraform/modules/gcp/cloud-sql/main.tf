variable "instance_name" { type = string }
variable "database_version" { type = string }
variable "region" { type = string }
variable "tier" { type = string }
variable "database_name" { type = string }
variable "user_name" { type = string }
variable "user_password" { type = string }

resource "google_sql_database_instance" "main" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region

  settings {
    tier = var.tier

   ip_configuration {
      ipv4_enabled    = false
      require_ssl     = true
    }
  }

}

resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  name     = var.user_name
  instance = google_sql_database_instance.main.name
  password = var.user_password
}

output "connection_name" {
  value = google_sql_database_instance.main.connection_name
}
