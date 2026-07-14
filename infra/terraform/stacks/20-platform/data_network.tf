# Interface between stacks: read 10-network's outputs from SSM instead of
# terraform_remote_state (see CLAUDE.md's stack interface pattern).
data "aws_ssm_parameter" "vpc_id" {
  name = "/infra/${var.environment}/10-network/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/infra/${var.environment}/10-network/private_subnet_ids"
}

locals {
  vpc_id             = data.aws_ssm_parameter.vpc_id.value
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}
