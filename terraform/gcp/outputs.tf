# Aurix Platform - Outputs Terraform GCP

output "vpc_id" {
  description = "ID da VPC"
  value       = google_compute_network.aurix.id
}

output "gke_cluster_name" {
  description = "Nome do cluster GKE"
  value       = google_container_cluster.aurix.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint do API server GKE"
  value       = google_container_cluster.aurix.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "Certificado CA do GKE (base64)"
  value       = google_container_cluster.aurix.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cloudsql_connection_name" {
  description = "Connection name do Cloud SQL"
  value       = google_sql_database_instance.aurix.connection_name
}

output "cloudsql_public_ip" {
  description = "IP publico do Cloud SQL (se habilitado)"
  value       = google_sql_database_instance.aurix.public_ip_address
}

output "cloudsql_private_ip" {
  description = "IP privado do Cloud SQL"
  value       = google_sql_database_instance.aurix.private_ip_address
}

output "cloudsql_reader_ip" {
  description = "IP da read replica Cloud SQL"
  value       = google_sql_database_instance.aurix_reader.private_ip_address
}

output "redis_host" {
  description = "Host do Memorystore Redis"
  value       = google_redis_instance.aurix.host
}

output "redis_port" {
  description = "Porta do Redis"
  value       = google_redis_instance.aurix.port
}

output "redis_auth_string" {
  description = "String de autenticacao do Redis"
  value       = google_redis_instance.aurix.auth_string
  sensitive   = true
}

output "storage_bronze_url" {
  description = "URL do bucket Bronze"
  value       = google_storage_bucket.bronze.url
}

output "storage_silver_url" {
  description = "URL do bucket Silver"
  value       = google_storage_bucket.silver.url
}

output "storage_gold_url" {
  description = "URL do bucket Gold"
  value       = google_storage_bucket.gold.url
}

output "storage_backups_url" {
  description = "URL do bucket de Backups"
  value       = google_storage_bucket.backups.url
}

output "kms_key_ring" {
  description = "Nome do Key Ring"
  value       = google_kms_key_ring.aurix.name
}

output "gke_service_account_email" {
  description = "Email do service account dos nodes GKE"
  value       = google_service_account.gke_nodes.email
}
