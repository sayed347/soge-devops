resource "aws_db_subnet_group" "main" {
  name       = "sg-showcase-${var.environment}-db"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "sg-showcase-${var.environment}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  # No "sg-" prefix in the name — AWS rejects security group names starting
  # with it (reserved for its own auto-generated IDs).
  # No inline ingress/egress blocks — every rule is its own resource, so a
  # different stack can safely add its own ingress rule against this SG's ID
  # later without this resource treating it as a drift to revert.
  name_prefix = "showcase-${var.environment}-rds-"
  description = "RDS PostgreSQL"
  vpc_id      = local.vpc_id

  tags = {
    Name = "sg-showcase-${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

locals {
  # Dynamic, not hardcoded — see variables.tf for the percentage.
  db_max_allocated_storage = ceil(var.db_allocated_storage * var.db_max_allocated_storage_percent / 100)
}

resource "aws_db_instance" "main" {
  identifier     = "sg-showcase-${var.environment}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = local.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username

  # RDS generates and rotates this itself in Secrets Manager — Terraform
  # never sees or stores the actual password.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  backup_retention_period = 1

  # Demo/dry-run tradeoffs — in production these would be the opposite
  # (deletion_protection = true, a final snapshot taken, longer retention).
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "sg-showcase-${var.environment}-db"
  }
}
