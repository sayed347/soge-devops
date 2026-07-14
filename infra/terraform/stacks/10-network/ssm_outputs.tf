# Interface between stacks: every stack publishes its outputs to SSM under
# /infra/{env}/{stack}/{output}. The next stack (20-platform) reads these as
# data sources instead of terraform_remote_state.
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/infra/${var.environment}/10-network/vpc_id"
  type  = "String"
  value = aws_vpc.main.id
}

resource "aws_ssm_parameter" "vpc_cidr" {
  name  = "/infra/${var.environment}/10-network/vpc_cidr"
  type  = "String"
  value = aws_vpc.main.cidr_block
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/infra/${var.environment}/10-network/private_subnet_ids"
  type  = "StringList"
  value = join(",", [for s in aws_subnet.private : s.id])
}

resource "aws_ssm_parameter" "vpc_endpoints_sg_id" {
  name  = "/infra/${var.environment}/10-network/vpc_endpoints_sg_id"
  type  = "String"
  value = aws_security_group.vpc_endpoints.id
}
