output "frontend_alb_dns_name" {
  value = aws_lb.frontend.dns_name
}

output "frontend_alb_arn" {
  value = aws_lb.frontend.arn
}

output "frontend_alb_security_group_id" {
  value = aws_security_group.alb_frontend.id
}

output "backend_alb_dns_name" {
  value = aws_lb.backend.dns_name
}
