# Frontend ALB has no ingress rule yet — it stays unreachable from anywhere
# until a later stage adds the rule that's allowed to reach it. Target group
# health checks aren't affected: the ALB reaches its targets directly inside
# the VPC regardless of who's allowed to reach the ALB's own listener.
resource "aws_security_group" "alb_frontend" {
  name_prefix = "showcase-${var.environment}-alb-front-"
  description = "Frontend internal ALB"
  vpc_id      = local.vpc_id

  tags = {
    Name = "sg-showcase-${var.environment}-alb-front-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_frontend_all" {
  security_group_id = aws_security_group.alb_frontend.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "alb_backend" {
  name_prefix = "showcase-${var.environment}-alb-back-"
  description = "Backend internal ALB"
  vpc_id      = local.vpc_id

  tags = {
    Name = "sg-showcase-${var.environment}-alb-back-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_backend_all" {
  security_group_id = aws_security_group.alb_backend.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "frontend" {
  name               = "showcase-${var.environment}-front"
  internal           = true
  load_balancer_type = "application"
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.alb_frontend.id]

  tags = {
    Name = "sg-showcase-${var.environment}-alb-front"
  }
}

resource "aws_lb" "backend" {
  name               = "showcase-${var.environment}-back"
  internal           = true
  load_balancer_type = "application"
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.alb_backend.id]

  tags = {
    Name = "sg-showcase-${var.environment}-alb-back"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "showcase-${var.environment}-front-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }

  tags = {
    Name = "sg-showcase-${var.environment}-front-tg"
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "showcase-${var.environment}-back-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }

  tags = {
    Name = "sg-showcase-${var.environment}-back-tg"
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
