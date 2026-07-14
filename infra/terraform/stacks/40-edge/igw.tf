# Prerequisite for CloudFront VPC origins — CloudFront requires the VPC to
# have an internet gateway attached, but never actually routes through it:
# no route table references it, so every subnet stays exactly as private as
# before.
resource "aws_internet_gateway" "main" {
  vpc_id = local.vpc_id

  tags = {
    Name = "sg-showcase-${var.environment}-igw"
  }
}
