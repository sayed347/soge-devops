resource "aws_ssm_parameter" "ecs_cluster_name" {
  name  = "/infra/${var.environment}/20-platform/ecs_cluster_name"
  type  = "String"
  value = aws_ecs_cluster.main.name
}

resource "aws_ssm_parameter" "ecs_cluster_arn" {
  name  = "/infra/${var.environment}/20-platform/ecs_cluster_arn"
  type  = "String"
  value = aws_ecs_cluster.main.arn
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/infra/${var.environment}/20-platform/rds_endpoint"
  type  = "String"
  value = aws_db_instance.main.endpoint
}

resource "aws_ssm_parameter" "rds_master_secret_arn" {
  name  = "/infra/${var.environment}/20-platform/rds_master_secret_arn"
  type  = "String"
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

resource "aws_ssm_parameter" "rds_db_name" {
  name  = "/infra/${var.environment}/20-platform/rds_db_name"
  type  = "String"
  value = aws_db_instance.main.db_name
}

resource "aws_ssm_parameter" "rds_security_group_id" {
  name  = "/infra/${var.environment}/20-platform/rds_security_group_id"
  type  = "String"
  value = aws_security_group.rds.id
}

resource "aws_ssm_parameter" "kms_key_arn" {
  name  = "/infra/${var.environment}/20-platform/kms_key_arn"
  type  = "String"
  value = aws_kms_key.rds.arn
}

resource "aws_ssm_parameter" "config_bucket_name" {
  name  = "/infra/${var.environment}/20-platform/config_bucket_name"
  type  = "String"
  value = aws_s3_bucket.config.bucket
}

resource "aws_ssm_parameter" "ecr_backend_url" {
  name  = "/infra/${var.environment}/20-platform/ecr_backend_url"
  type  = "String"
  value = aws_ecr_repository.backend.repository_url
}

resource "aws_ssm_parameter" "ecr_frontend_url" {
  name  = "/infra/${var.environment}/20-platform/ecr_frontend_url"
  type  = "String"
  value = aws_ecr_repository.frontend.repository_url
}
