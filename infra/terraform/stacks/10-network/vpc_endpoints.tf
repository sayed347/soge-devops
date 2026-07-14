# No NAT Gateway, no Internet Gateway — every AWS API this project's tasks
# need to reach goes through a VPC endpoint instead. Exactly the services
# listed in CLAUDE.md: ECR (api+dkr) for pulling images, S3 (gateway, free)
# for ECR image layers, CloudWatch Logs for app logs, SSM + Secrets Manager
# for config/secrets, STS for the task role's own credential refresh.
locals {
  interface_endpoints = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "ssm",
    "secretsmanager",
    "sts",
  ]
}

resource "aws_security_group" "vpc_endpoints" {
  # "sg-" prefix is reserved by AWS for its own auto-generated IDs.
  name_prefix = "showcase-${var.environment}-vpce-"
  description = "Allows HTTPS from inside the VPC to interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-showcase-${var.environment}-vpce-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "sg-showcase-${var.environment}-vpce-${each.value}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "sg-showcase-${var.environment}-vpce-s3"
  }
}
