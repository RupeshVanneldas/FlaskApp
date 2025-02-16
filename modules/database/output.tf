output "db_instance_endpoint" {
  value = aws_db_instance.rds_db.endpoint
}

output "db_instance_id" {
  value = aws_db_instance.rds_db.id
}

output "db_instance_arn" {
  value = aws_db_instance.rds_db.arn
}

output "db_instance_username" {
  value = aws_db_instance.rds_db.username
}

output "db_instance_port" {
  value = aws_db_instance.rds_db.port
}

output "db_instance_status" {
  value = aws_db_instance.rds_db.status
}
