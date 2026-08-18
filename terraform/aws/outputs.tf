# Aurix Platform - Outputs Terraform AWS

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.aurix.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs das subnets publicas"
  value       = aws_subnet.public[*].id
}

output "database_subnet_ids" {
  description = "IDs das subnets de banco de dados"
  value       = aws_subnet.database[*].id
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.aurix.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.aurix.endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Certificado CA do EKS (base64)"
  value       = aws_eks_cluster.aurix.certificate_authority[0].data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN do OIDC provider do EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "rds_cluster_endpoint" {
  description = "Endpoint do writer Aurora"
  value       = aws_rds_cluster.aurix.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "Endpoint do reader Aurora"
  value       = aws_rds_cluster.aurix.reader_endpoint
}

output "rds_cluster_port" {
  description = "Porta do Aurora PostgreSQL"
  value       = aws_rds_cluster.aurix.port
}

output "redis_endpoint" {
  description = "Endpoint do ElastiCache Redis"
  value       = aws_elasticache_replication_group.aurix.primary_endpoint_address
}

output "redis_port" {
  description = "Porta do Redis"
  value       = aws_elasticache_replication_group.aurix.port
}

output "s3_bronze_bucket" {
  description = "Nome do bucket Bronze"
  value       = aws_s3_bucket.bronze.id
}

output "s3_silver_bucket" {
  description = "Nome do bucket Silver"
  value       = aws_s3_bucket.silver.id
}

output "s3_gold_bucket" {
  description = "Nome do bucket Gold"
  value       = aws_s3_bucket.gold.id
}

output "s3_backups_bucket" {
  description = "Nome do bucket de Backups"
  value       = aws_s3_bucket.backups.id
}

output "eks_irsa_backups_role_arn" {
  description = "ARN da role IRSA para backups"
  value       = aws_iam_role.eks_irsa_backups.arn
}
