# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
resource "aws_vpc" "three-tier-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-vpc"
    },
    var.additional_tags
  )
}

# Fetch Available AWS Availability Zones
data "aws_availability_zones" "myazs" {}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-igw"
    },
    var.additional_tags
  )
}

# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "pb_sn" {
  count                   = var.pb_sn_count
  vpc_id                  = aws_vpc.three-tier-vpc.id
  cidr_block              = "10.0.${10 + count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.myazs.names[count.index]

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-public-subnet-${count.index + 1}"
      Tier = "public"
    },
    var.additional_tags
  )
}

# Public Route Table
resource "aws_route_table" "pb_rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-public-route-table"
    },
    var.additional_tags
  )
}

# Default Route for Public Subnet
resource "aws_route" "def_public_route" {
  route_table_id         = aws_route_table.pb_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "pb_rt_asc" {
  count          = var.pb_sn_count
  route_table_id = aws_route_table.pb_rt.id
  subnet_id      = aws_subnet.pb_sn.*.id[count.index]
}

# -----------------------------------------------------------------------------
# NAT Gateway for Private Subnets
# -----------------------------------------------------------------------------

# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "eip" {
  domain = "vpc"
}

# Create NAT Gateway in the First Public Subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pb_sn[0].id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-nat-gateway"
    },
    var.additional_tags
  )
}

# -----------------------------------------------------------------------------
# Application Private Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "app_pr_sn" {
  count                   = var.app_pr_sn_count
  vpc_id                  = aws_vpc.three-tier-vpc.id
  availability_zone       = data.aws_availability_zones.myazs.names[count.index]
  cidr_block              = "10.0.${20 + count.index}.0/24"
  map_public_ip_on_launch = false

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-app-private-subnet-${count.index + 1}"
      Tier = "private"
    },
    var.additional_tags
  )
}

# Application Route Table
resource "aws_route_table" "app_pr_rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-app-private-route-table"
    },
    var.additional_tags
  )
}

# Default Route for Application Private Subnets
resource "aws_route" "def_pr_route" {
  route_table_id         = aws_route_table.app_pr_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Route Table with Application Private Subnets
resource "aws_route_table_association" "app_pr_rt_asc" {
  count          = var.app_pr_sn_count
  route_table_id = aws_route_table.app_pr_rt.id
  subnet_id      = aws_subnet.app_pr_sn.*.id[count.index]
}

# -----------------------------------------------------------------------------
# Database Private Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "db_pr_sn" {
  count                   = var.db_pr_sn_count
  vpc_id                  = aws_vpc.three-tier-vpc.id
  cidr_block              = "10.0.${30 + count.index}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.myazs.names[count.index]
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-db-private-subnet-${count.index + 1}"
      Tier = "private"
    },
    var.additional_tags
  )
}

# Database Route Table
resource "aws_route_table" "db_pr_sn_rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
}

# Default Route for Database Private Subnets
resource "aws_route" "def_db_route" {
  route_table_id         = aws_route_table.db_pr_sn_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Route Table with Database Private Subnets
resource "aws_route_table_association" "db_pr_sn_asc" {
  count          = var.db_pr_sn_count
  route_table_id = aws_route_table.db_pr_sn_rt.id
  subnet_id      = aws_subnet.db_pr_sn.*.id[count.index]
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

# Web Load Balancer Security Group
resource "aws_security_group" "web_lb_sg" {
  name        = "${local.resource_prefix}-web-lb-sg"
  description = "Security group for web load balancer"
  vpc_id      = aws_vpc.three-tier-vpc.id

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-web-lb-sg"
    },
    var.additional_tags
  )
  ingress {
    protocol    = "TCP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web Tier Security Group
resource "aws_security_group" "web_sg" {
  name        = "${local.resource_prefix}-web-sg"
  description = "Security group for Web-Tier"
  vpc_id      = aws_vpc.three-tier-vpc.id

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-web-sg"
    },
    var.additional_tags
  )
  ingress {
    protocol        = "TCP"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.web_lb_sg.id]
  }

  ingress {
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer Security Group
resource "aws_security_group" "app_lb_sg" {
  name        = "${local.resource_prefix}-app-lb-sg"
  description = "Security group for app load balancer"
  vpc_id      = aws_vpc.three-tier-vpc.id

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-app-lb-sg"
    },
    var.additional_tags
  )
  ingress {
    protocol        = "TCP"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.web_lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Tier Security Group
resource "aws_security_group" "app_sg" {
  name        = "${local.resource_prefix}-app-sg"
  description = "Security group for App-Tier"
  vpc_id      = aws_vpc.three-tier-vpc.id

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-app-sg"
    },
    var.additional_tags
  )
  ingress {
    protocol        = "TCP"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.app_lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "${local.resource_prefix}-db-sg"
  description = "Security group for DB-Tier"
  vpc_id      = aws_vpc.three-tier-vpc.id

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-DB-sg"
    },
    var.additional_tags
  )

  ingress {
    protocol        = "TCP"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.app_sg.id, aws_security_group.web_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Database Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "db_sn_group" {
  name       = "db_sn_group"
  subnet_ids = [aws_subnet.db_pr_sn[0].id, aws_subnet.db_pr_sn[1].id]
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}-db-subnet-group"
    },
    var.additional_tags
  )
}
