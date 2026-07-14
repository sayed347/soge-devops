# Account-wide prerequisites, not per-environment — created once here rather
# than in a per-environment stack, where re-applying for a second
# environment would hit "already exists" on the first one's role.
resource "aws_iam_service_linked_role" "ecs_autoscaling" {
  aws_service_name = "ecs.application-autoscaling.amazonaws.com"
}
