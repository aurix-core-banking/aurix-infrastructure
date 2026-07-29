variable "vpc_name" { type = string }
variable "region" { type = string }

resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = true

  routing_mode = "REGIONAL"
}
