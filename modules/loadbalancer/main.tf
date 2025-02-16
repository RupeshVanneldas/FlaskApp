# -----------------------------------------------------------------------------
# Load Balancers Configuration
# -----------------------------------------------------------------------------

# The internet-facing load balancer distributes traffic from the internet to web servers.
# The internal-facing load balancer distributes traffic from web servers to application servers.

# -----------------------------------------------------------------------------
# Internet-facing Load Balancer
# -----------------------------------------------------------------------------
resource "aws_lb" "web_lb" {
  name            = "${local.resource_prefix}web-lb"
  security_groups = [var.frontend_lb_sg]
  subnets         = var.public_subnets
  idle_timeout    = 300

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}web-lb"
    },
    var.additional_tags
  )
}

# Target Group for Web-Tier Load Balancer
resource "aws_lb_target_group" "web_tg" {
  name     = "${local.resource_prefix}web-tg"
  port     = 80
  protocol = "HTTP" # Change HTTP to HTTP
  vpc_id   = var.vpc_id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}web-tg"
    },
    var.additional_tags
  )
}

# Listener for Web Load Balancer
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# -----------------------------------------------------------------------------
# Internal-facing Load Balancer
# -----------------------------------------------------------------------------
resource "aws_lb" "app_lb" {
  name            = "${local.resource_prefix}app-lb"
  subnets         = var.private_subnets
  security_groups = [var.app_lb_sg]
  idle_timeout    = 300

  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}web-lb"
    },
    var.additional_tags
  )
}

# Target Group for App-Tier Load Balancer
resource "aws_lb_target_group" "app_tg" {
  name     = "${local.resource_prefix}app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = merge(
    local.default_tags,
    {
      Name = "${local.resource_prefix}app-tg"
    },
    var.additional_tags
  )
}

# Listener for App Load Balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
