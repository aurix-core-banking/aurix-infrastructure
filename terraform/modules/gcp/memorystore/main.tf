variable "instance_name" { type = string }
variable "region" { type = string }
variable "tier" { type = string }
variable "memory_size_gb" { type = number }

resource "google_redis_instance" "main" {
  name           = var.instance_name
  region         = var.region
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
}

output "host" {
  value = google_redis_instance.main.host
}

output "port" {
  value = google_redis_instance.main.port
}
