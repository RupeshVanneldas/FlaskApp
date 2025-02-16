resource "aws_db_instance" "rds_db" {
  allocated_storage      = var.db_storage
  engine                 = "mysql"
  engine_version         = "8.0.40"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.dbuser
  password               = var.dbpassword
  db_subnet_group_name   = var.rds_db_subnet_group
  identifier             = var.db_identifier
  skip_final_snapshot    = true
  vpc_security_group_ids = [var.rds_sg]
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-rds-db"
    },
    var.additional_tags
  )
}
