# The frontend ALB's own security group (created in 30-services) has no
# ingress rule yet by design — this is the one place that finally opens it,
# scoped to CloudFront's own managed prefix list rather than 0.0.0.0/0.
resource "aws_vpc_security_group_ingress_rule" "alb_frontend_from_cloudfront" {
  security_group_id = data.aws_ssm_parameter.frontend_alb_security_group_id.value
  from_port          = 80
  to_port            = 80
  ip_protocol        = "tcp"
  prefix_list_id     = data.aws_ec2_managed_prefix_list.cloudfront.id
}
