# Interface between stacks: read 20-platform's outputs from SSM instead of
# terraform_remote_state (see CLAUDE.md's stack interface pattern).
data "aws_ssm_parameter" "ecs_cluster_name" {
  name = "/infra/${var.environment}/20-platform/ecs_cluster_name"
}

data "aws_ssm_parameter" "ecs_cluster_arn" {
  name = "/infra/${var.environment}/20-platform/ecs_cluster_arn"
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "/infra/${var.environment}/20-platform/rds_endpoint"
}

data "aws_ssm_parameter" "rds_db_name" {
  name = "/infra/${var.environment}/20-platform/rds_db_name"
}

data "aws_ssm_parameter" "rds_master_secret_arn" {
  name = "/infra/${var.environment}/20-platform/rds_master_secret_arn"
}

data "aws_ssm_parameter" "rds_security_group_id" {
  name = "/infra/${var.environment}/20-platform/rds_security_group_id"
}

data "aws_ssm_parameter" "kms_key_arn" {
  name = "/infra/${var.environment}/20-platform/kms_key_arn"
}

data "aws_ssm_parameter" "config_bucket_name" {
  name = "/infra/${var.environment}/20-platform/config_bucket_name"
}

data "aws_ssm_parameter" "ecr_backend_url" {
  name = "/infra/${var.environment}/20-platform/ecr_backend_url"
}

data "aws_ssm_parameter" "ecr_frontend_url" {
  name = "/infra/${var.environment}/20-platform/ecr_frontend_url"
}

data "aws_ssm_parameter" "backend_image_tag" {
  name = "/app/${var.environment}/payment-orders/backend/image-tag"
}

data "aws_ssm_parameter" "frontend_image_tag" {
  name = "/app/${var.environment}/payment-orders/frontend/image-tag"
}

locals {
  # RDS's own "host:port" endpoint format, split for separate DB_HOST/DB_PORT
  # container env vars.
  rds_endpoint_parts = split(":", data.aws_ssm_parameter.rds_endpoint.value)
  rds_host            = local.rds_endpoint_parts[0]
  rds_port            = local.rds_endpoint_parts[1]
}
