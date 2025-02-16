variable "db_storage" {
  type        = number
}

variable "db_engine_version" {
  type        = string
}

variable "db_instance_class" {
  type        = string
}

variable "db_name" {
  type        = string
}

variable "dbuser" {
  type        = string
}

variable "dbpassword" {
  type        = string
  sensitive   = true
}

variable "rds_db_subnet_group" {
  type        = string
}

variable "db_identifier" {
  type        = string
}

variable "rds_sg" {
  type        = string
}

locals {
  default_tags = {}
  resource_prefix = "FlaskApp"
}

variable "additional_tags" {}