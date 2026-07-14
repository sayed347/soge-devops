locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sg-showcase-${var.environment}-vpc"
  }
}

# Single tier of private subnets, shared by ECS tasks, internal ALBs, RDS,
# and VPC endpoint ENIs. No public subnets exist in this design — all AWS
# API traffic goes out through VPC endpoints (see vpc_endpoints.tf), no NAT
# Gateway, no Internet Gateway.
resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value)

  tags = {
    Name = "sg-showcase-${var.environment}-private-${each.key}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sg-showcase-${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
