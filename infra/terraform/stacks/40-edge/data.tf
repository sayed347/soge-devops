# Interface between stacks: read 10-network's and 30-services' outputs from
# SSM instead of terraform_remote_state.
data "aws_ssm_parameter" "vpc_id" {
  name = "/infra/${var.environment}/10-network/vpc_id"
}

data "aws_ssm_parameter" "frontend_alb_arn" {
  name = "/infra/${var.environment}/30-services/frontend_alb_arn"
}

data "aws_ssm_parameter" "frontend_alb_dns_name" {
  name = "/infra/${var.environment}/30-services/frontend_alb_dns_name"
}

data "aws_ssm_parameter" "frontend_alb_security_group_id" {
  name = "/infra/${var.environment}/30-services/frontend_alb_security_group_id"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

locals {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}
