# Aurix Platform - Terraform GCP
# GKE, Cloud SQL PostgreSQL, Cloud Memorystore Redis, Cloud Storage, VPC, Firewall

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ---------------------------------------------------------------------------
# VPC e Subnets
# ---------------------------------------------------------------------------

resource "google_compute_network" "aurix" {
  name                    = "aurix-vpc-${var.environment}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  name          = "aurix-gke-${var.environment}"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.aurix.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.gke_services_cidr
  }

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "database" {
  name          = "aurix-db-${var.environment}"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.aurix.id
}

resource "google_compute_subnetwork" "redis" {
  name          = "aurix-redis-${var.environment}"
  ip_cidr_range = var.redis_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.aurix.id
}

# Cloud NAT para subnets privadas
resource "google_compute_router" "aurix" {
  name    = "aurix-router-${var.environment}"
  region  = var.gcp_region
  network = google_compute_network.aurix.id
}

resource "google_compute_router_nat" "aurix" {
  name                               = "aurix-nat-${var.environment}"
  router                             = google_compute_router.aurix.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# IP privado para Cloud SQL
resource "google_compute_global_address" "private_ip" {
  name          = "aurix-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.aurix.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.aurix.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

# ---------------------------------------------------------------------------
# Firewall Rules
# ---------------------------------------------------------------------------

resource "google_compute_firewall" "allow_internal" {
  name    = "aurix-allow-internal-${var.environment}"
  network = google_compute_network.aurix.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
    var.database_subnet_cidr,
    var.redis_subnet_cidr,
  ]
}

resource "google_compute_firewall" "allow_healthchecks" {
  name    = "aurix-allow-healthchecks-${var.environment}"
  network = google_compute_network.aurix.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "allow_aks_control_plane" {
  name    = "aurix-allow-master-${var.environment}"
  network = google_compute_network.aurix.name

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  source_ranges = ["172.16.0.0/12"]
}

# ---------------------------------------------------------------------------
# GKE Cluster
# ---------------------------------------------------------------------------

resource "google_service_account" "gke_nodes" {
  account_id   = "aurix-gke-${var.environment}"
  display_name = "Service account dos nodes GKE Aurix"
}

resource "google_project_iam_member" "gke_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_cluster" "aurix" {
  name     = "aurix-gke-${var.environment}"
  location = var.gcp_region

  network    = google_compute_network.aurix.name
  subnetwork = google_compute_subnetwork.gke.name

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_network_cidr
      display_name = "Acesso autorizado"
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  resource_labels = {
    project     = "aurix-platform"
    environment = var.environment
  }
}

resource "google_container_node_pool" "main" {
  name     = "aurix-main-${var.environment}"
  location = var.gcp_region
  cluster  = google_container_cluster.aurix.name

  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      project     = "aurix-platform"
      environment = var.environment
      pool        = "main"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "spot" {
  name     = "aurix-spot-${var.environment}"
  location = var.gcp_region
  cluster  = google_container_cluster.aurix.name

  autoscaling {
    min_node_count = 0
    max_node_count = var.gke_max_nodes
  }

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      project     = "aurix-platform"
      environment = var.environment
      pool        = "spot"
    }

    spot = true

    taint {
      key    = "cloud.google.com/gke-spot"
      value  = "true"
      effect = "PREFER_NO_SCHEDULE"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ---------------------------------------------------------------------------
# Cloud SQL PostgreSQL (HA)
# ---------------------------------------------------------------------------

resource "google_sql_database_instance" "aurix" {
  name             = "aurix-postgres-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  depends_on = [google_service_networking_connection.private_vpc]

  settings {
    tier              = var.cloudsql_tier
    availability_type = "REGIONAL"

    disk_size    = 100
    disk_type    = "PD_SSD"
    disk_autoresize = true

    backup_configuration {
      enabled          = true
      start_time       = "03:00"
      point_in_time_recovery_enabled = true
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      record_application_tags = true
      record_client_address   = true
    }

    database_flags {
      name  = "shared_preload_libraries"
      value = "timescaledb,pg_stat_statements"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.aurix.id
    }

    user_labels = {
      project     = "aurix-platform"
      environment = var.environment
    }
  }

  deletion_protection = var.environment == "prod"
}

resource "google_sql_database" "aurix" {
  name     = "aurix_db"
  instance = google_sql_database_instance.aurix.name
}

resource "google_sql_user" "aurix" {
  name     = var.db_username
  instance = google_sql_database_instance.aurix.name
  password = var.db_password
}

# Read replica
resource "google_sql_database_instance" "aurix_reader" {
  name             = "aurix-postgres-reader-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  master_instance_name = google_sql_database_instance.aurix.name

  replica_configuration {
    failover_target = false
  }

  settings {
    tier            = var.cloudsql_tier
    availability_type = "ZONAL"
    disk_size       = 100
    disk_type       = "PD_SSD"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.aurix.id
    }

    user_labels = {
      project     = "aurix-platform"
      environment = var.environment
      role        = "reader"
    }
  }
}

# ---------------------------------------------------------------------------
# Cloud Memorystore Redis (HA)
# ---------------------------------------------------------------------------

resource "google_redis_instance" "aurix" {
  name           = "aurix-redis-${var.environment}"
  region         = var.gcp_region
  tier           = "STANDARD_HA"
  memory_size_gb = var.redis_memory_gb
  redis_version  = "REDIS_7_0"

  authorized_network = google_compute_network.aurix.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  transit_encryption_mode = "SERVER_AUTHENTICATION"
  auth_enabled           = true

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 5
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels = {
    project     = "aurix-platform"
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Cloud Storage Buckets (Data Lake)
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "bronze" {
  name          = "aurix-bronze-${var.environment}-${var.gcp_project_id}"
  location      = var.gcp_region
  storage_class = "STANDARD"
  force_destroy = var.environment != "prod"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.s3.id
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  uniform_bucket_level_access = true
  labels = { layer = "bronze", environment = var.environment }
}

resource "google_storage_bucket" "silver" {
  name          = "aurix-silver-${var.environment}-${var.gcp_project_id}"
  location      = var.gcp_region
  storage_class = "STANDARD"
  force_destroy = var.environment != "prod"

  versioning { enabled = true }
  uniform_bucket_level_access = true
  labels = { layer = "silver", environment = var.environment }
}

resource "google_storage_bucket" "gold" {
  name          = "aurix-gold-${var.environment}-${var.gcp_project_id}"
  location      = var.gcp_region
  storage_class = "STANDARD"
  force_destroy = var.environment != "prod"

  versioning { enabled = true }
  uniform_bucket_level_access = true
  labels = { layer = "gold", environment = var.environment }
}

resource "google_storage_bucket" "backups" {
  name          = "aurix-backups-${var.environment}-${var.gcp_project_id}"
  location      = var.gcp_region
  storage_class = "STANDARD"
  force_destroy = var.environment != "prod"

  versioning { enabled = true }

  lifecycle_rule {
    condition { age = 30 }
    action { type = "SetStorageClass"; storage_class = "NEARLINE" }
  }

  lifecycle_rule {
    condition { age = 90 }
    action { type = "SetStorageClass"; storage_class = "COLDLINE" }
  }

  uniform_bucket_level_access = true
  labels = { purpose = "backups", environment = var.environment }
}

# KMS para encriptacao
resource "google_kms_key_ring" "aurix" {
  name     = "aurix-${var.environment}"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "s3" {
  name     = "aurix-s3-key-${var.environment}"
  key_ring = google_kms_key_ring.aurix.id

  lifecycle {
    prevent_destroy = true
  }
}
