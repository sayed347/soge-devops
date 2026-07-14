locals {
  services = {
    backend = {
      image                      = "${data.aws_ssm_parameter.ecr_backend_url.value}:${data.aws_ssm_parameter.backend_image_tag.value}"
      container_port             = 8081
      cpu                        = 512
      memory                     = 1024
      task_role_arn              = aws_iam_role.backend_task.arn
      target_group_arn           = aws_lb_target_group.backend.arn
      ingress_security_group_id  = aws_security_group.alb_backend.id
      environment_variables = {
        DB_HOST            = local.rds_host
        DB_PORT            = local.rds_port
        DB_NAME            = data.aws_ssm_parameter.rds_db_name.value
        APP_ENV            = var.environment
        CONFIG_BUCKET      = data.aws_ssm_parameter.config_bucket_name.value
        SSM_PARAMETER_NAME = "/app/${var.environment}/payment-orders/info-message"
      }
      secrets = {
        DB_USER     = "${data.aws_ssm_parameter.rds_master_secret_arn.value}:username::"
        DB_PASSWORD = "${data.aws_ssm_parameter.rds_master_secret_arn.value}:password::"
      }
    }

    frontend = {
      image                     = "${data.aws_ssm_parameter.ecr_frontend_url.value}:${data.aws_ssm_parameter.frontend_image_tag.value}"
      container_port            = 8080
      cpu                       = 256
      memory                    = 512
      task_role_arn             = null
      target_group_arn          = aws_lb_target_group.frontend.arn
      ingress_security_group_id = aws_security_group.alb_frontend.id
      environment_variables = {
        BACKEND_HOST = aws_lb.backend.dns_name
      }
      secrets = {}
    }
  }
}

module "services" {
  source   = "../../modules/ecs-service"
  for_each = local.services

  service_name              = each.key
  environment               = var.environment
  cluster_name              = data.aws_ssm_parameter.ecs_cluster_name.value
  cluster_arn               = data.aws_ssm_parameter.ecs_cluster_arn.value
  vpc_id                    = local.vpc_id
  subnet_ids                = local.private_subnet_ids
  execution_role_arn        = aws_iam_role.execution.arn
  task_role_arn             = each.value.task_role_arn
  image                     = each.value.image
  container_port            = each.value.container_port
  cpu                       = each.value.cpu
  memory                    = each.value.memory
  environment_variables     = each.value.environment_variables
  secrets                   = each.value.secrets
  target_group_arn          = each.value.target_group_arn
  ingress_security_group_id = each.value.ingress_security_group_id

  # ECS refuses to register a service against a target group that isn't yet
  # attached to a listener — both listeners must exist before either service
  # is created, not just the one target group this particular service uses.
  depends_on = [aws_lb_listener.frontend, aws_lb_listener.backend]
}
