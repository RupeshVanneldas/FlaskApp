variable "frontend_app_sg" {}
variable "app_sg" {}
variable "public_subnets" {}
variable "app_subnets" {}
variable "web_tg" {}
variable "web_tg_name" {}
variable "app_tg" {}
variable "instance_type" {}
variable "app_tg_name" {}
variable "db_endpoint" {
  description = "The database endpoint for the RDS instance"
  type        = string
}

variable "db_user" {}
variable "db_password" {}
variable "db_name" {}
locals {
  default_tags    = {}
  resource_prefix = "FlaskApp"
  db_vars = {
    db_host     = "localhost"
    db_user     = "root"
    db_password = "password"
    db_name     = "employees"
  }
}


variable "additional_tags" {}