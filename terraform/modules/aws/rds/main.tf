variable "cluster_identifier" { type = string }
variable "engine" { type = string }
variable "engine_version" { type = string }
variable "instance_class" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "database_name" { type = string }
variable "master_username" { type = string }
variable "master_password" { type = string }
variable "backup_retention_period" { type = number }
variable "backup_window" { type = string }
variable "maintenance_window" { type = string }
variable "security_group_ids" { type = list(string) }

resource "aws_db_subnet_group" "main" {
  name        = "${var.cluster_identifier}-subnet-group"
  description = "Subnet group for ${var.cluster_identifier}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.cluster_identifier}-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.cluster_identifier}-param-group"
  family      = "aurora-postgresql15"
  description = "Parameter group for ${var.cluster_identifier}"

  tags = {
    Name = "${var.cluster_identifier}-param-group"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier  = var.cluster_identifier
  engine              = var.engine
  engine_version      = var.engine_version
  engine_mode         = "provisioned"
  database_name       = var.database_name
  master_username     = var.master_username
  master_password     = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  storage_encrypted  = true
  skip_final_snapshot = true

  tags = {
    Name = var.cluster_identifier
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.cluster_identifier}-writer"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  publicly_accessible = false

  tags = {
    Name = "${var.cluster_identifier}-writer"
  }
}

resource "aws_rds_cluster_instance" "reader" {
  count              = 1
  identifier         = "${var.cluster_identifier}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  publicly_accessible = false

  tags = {
    Name = "${var.cluster_identifier}-reader-${count.index + 1}"
  }
}

output "cluster_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "cluster_port" {
  value = aws_rds_cluster.main.port
}

output "cluster_arn" {
  value = aws_rds_cluster.main.arn
}
