data "aws_region" "current" {}

resource "aws_security_group" "this" {
  # No "sg-" prefix in the name — reserved by AWS for its own auto-generated IDs.
  # No inline ingress/egress blocks — every rule is its own resource below, so
  # nothing here ever fights over which set of rules is "authoritative".
  name_prefix = "showcase-${var.environment}-${var.service_name}-"
  description = "${var.service_name} service"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-showcase-${var.environment}-${var.service_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.this.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ingress_security_group_id
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/sg-showcase-${var.environment}-${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "sg-showcase-${var.environment}-${var.service_name}-logs"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "sg-showcase-${var.environment}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.image
      essential = true
      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]
      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]
      secrets = [
        for k, v in var.secrets : { name = k, valueFrom = v }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.service_name
        }
      }
    }
  ])

  tags = {
    Name = "sg-showcase-${var.environment}-${var.service_name}-taskdef"
  }
}

resource "aws_ecs_service" "this" {
  name            = "sg-showcase-${var.environment}-${var.service_name}"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Without this, ECS starts enforcing ALB health check results the moment a
  # task registers with the target group — a slow JVM/Hibernate cold start
  # (and a possible first-connection retry to RDS) can outlast that, so ECS
  # kills the task as unhealthy before it ever finishes starting.
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name    = var.service_name
    container_port    = var.container_port
  }

  tags = {
    Name = "sg-showcase-${var.environment}-${var.service_name}-service"
  }
}

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "sg-showcase-${var.environment}-${var.service_name}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}
