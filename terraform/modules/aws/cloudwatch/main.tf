variable "log_group_name" { type = string }
variable "retention_days" { type = number }

resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_group_name
  retention_in_days = var.retention_days

  tags = {
    Name = var.log_group_name
  }
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.main.arn
}
