variable "cluster_name" { type = string }
variable "location" { type = string }
variable "node_count" { type = number }
variable "machine_type" { type = string }

resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_container_node_pool" "main" {
  name       = "${var.cluster_name}-nodes"
  location   = var.location
  cluster    = google_container_cluster.main.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

output "cluster_endpoint" {
  value = google_container_cluster.main.endpoint
}
