# -----------------------------------------------------------------------------
# Fetch the latest Amazon Linux 2 AMI from AWS SSM Parameter Store
# -----------------------------------------------------------------------------
data "aws_ssm_parameter" "three_tier_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# -----------------------------------------------------------------------------
# Web Tier
# -----------------------------------------------------------------------------

locals {
  app_py           = filebase64("${path.module}/../../flask-app/app.py")
  mysql_sql        = filebase64("${path.module}/../../flask-app/mysql.sql")
  templates = { for file in fileset("${path.module}/../../flask-app/templates", "**") :
    file => filebase64("${path.module}/../../flask-app/templates/${file}")
  }
}

# Launch Template for Web-Tier Instances
resource "aws_launch_template" "web_tier_instance" {
  name_prefix            = "${local.resource_prefix}-web-"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.three_tier_ami.value
  vpc_security_group_ids = [var.frontend_app_sg]
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", merge(local.db_vars, {
    app_py           = local.app_py
    mysql_sql        = local.mysql_sql
    templates        = local.templates
  })))
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.default_tags,
      {
        Name = "${local.resource_prefix}-web-instance"
      },
      var.additional_tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.default_tags,
      {
        Name = "${local.resource_prefix}-web-volume"
      },
      var.additional_tags
    )
  }
}

# Auto Scaling Group for Web-Tier
resource "aws_autoscaling_group" "web_tier_asg" {
  name                = "${local.resource_prefix}-web-asg"
  vpc_zone_identifier = var.public_subnets
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.web_tier_instance.id
    version = "$Latest"
  }
}

# Attach Web-Tier ASG to Load Balancer Target Group
resource "aws_autoscaling_attachment" "web_asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.web_tier_asg.id
  lb_target_group_arn    = var.web_tg
}

# -----------------------------------------------------------------------------
# Application Tier
# -----------------------------------------------------------------------------

# Launch Template for App-Tier Instances
resource "aws_launch_template" "app_tier_instance" {
  name_prefix            = "${local.resource_prefix}-app-"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.three_tier_ami.value
  vpc_security_group_ids = [var.app_sg]
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.default_tags,
      {
        Name = "${local.resource_prefix}-app-instance"
      },
      var.additional_tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.default_tags,
      {
        Name = "${local.resource_prefix}-app-volume"
      },
      var.additional_tags
    )
  }
}

# Auto Scaling Group for App-Tier
resource "aws_autoscaling_group" "app_tier_asg" {
  name                = "${local.resource_prefix}-app-asg"
  vpc_zone_identifier = var.app_subnets
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.app_tier_instance.id
    version = "$Latest"
  }
}

# Attach App-Tier ASG to Load Balancer Target Group
resource "aws_autoscaling_attachment" "app_asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.app_tier_asg.id
  lb_target_group_arn    = var.app_tg
}
