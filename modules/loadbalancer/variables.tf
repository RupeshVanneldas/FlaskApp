variable "frontend_lb_sg" {}

variable "public_subnets" {}

variable "private_subnets" {}

variable "vpc_id" {}

variable "app_lb_sg" {}

variable "myazs" {}

locals {
  default_tags    = {}
  resource_prefix = "FlaskApp"
}

variable "additional_tags" {}