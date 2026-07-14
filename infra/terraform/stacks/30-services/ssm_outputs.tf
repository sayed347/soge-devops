resource "aws_ssm_parameter" "frontend_alb_dns_name" {
  name  = "/infra/${var.environment}/30-services/frontend_alb_dns_name"
  type  = "String"
  value = aws_lb.frontend.dns_name
}

resource "aws_ssm_parameter" "frontend_alb_arn" {
  name  = "/infra/${var.environment}/30-services/frontend_alb_arn"
  type  = "String"
  value = aws_lb.frontend.arn
}

resource "aws_ssm_parameter" "frontend_alb_security_group_id" {
  name  = "/infra/${var.environment}/30-services/frontend_alb_security_group_id"
  type  = "String"
  value = aws_security_group.alb_frontend.id
}
