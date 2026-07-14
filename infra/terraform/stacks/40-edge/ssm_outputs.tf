resource "aws_ssm_parameter" "cloudfront_domain_name" {
  name  = "/infra/${var.environment}/40-edge/cloudfront_domain_name"
  type  = "String"
  value = aws_cloudfront_distribution.main.domain_name
}
