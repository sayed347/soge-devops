# Cross-references into security groups created elsewhere (the module's own
# per-service SG, and 20-platform's RDS SG) — kept as standalone rule
# resources, never inline, so neither side ever treats the other's rule as
# drift to revert (see the note on aws_security_group.rds in 20-platform).

resource "aws_vpc_security_group_ingress_rule" "alb_backend_from_frontend" {
  security_group_id            = aws_security_group.alb_backend.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.services["frontend"].security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_backend" {
  security_group_id            = data.aws_ssm_parameter.rds_security_group_id.value
  from_port                    = local.rds_port
  to_port                      = local.rds_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.services["backend"].security_group_id
}
