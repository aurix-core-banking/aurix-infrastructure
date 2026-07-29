variable "cluster_id" { type = string }
variable "node_type" { type = string }
variable "num_cache_nodes" { type = number }
variable "parameter_group_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }

resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.cluster_id}-subnet-group"
  description = "Subnet group for ${var.cluster_id}"
  subnet_ids  = var.subnet_ids
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = var.cluster_id
  description                   = "Redis replication group for ${var.cluster_id}"
  node_type                     = var.node_type
  num_cache_clusters            = var.num_cache_nodes
  port                          = 6379
  parameter_group_name          = var.parameter_group_name
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = var.security_group_ids
  automatic_failover_enabled    = true
  multi_az_enabled              = var.num_cache_nodes > 1

  tags = {
    Name = var.cluster_id
  }
}

output "cluster_endpoint" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "cluster_port" {
  value = aws_elasticache_replication_group.main.port
}
