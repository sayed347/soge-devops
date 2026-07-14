resource "aws_ecs_cluster" "main" {
  name = "sg-showcase-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "sg-showcase-${var.environment}-ecs-cluster"
  }
}
