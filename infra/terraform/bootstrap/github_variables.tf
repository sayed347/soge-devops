# Publishes everything the GitHub Actions workflows need to know as repo
# variables — no ARNs/bucket names hardcoded in any .yml file.
resource "github_actions_variable" "aws_region" {
  repository    = var.github_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "plan_role_arn" {
  repository    = var.github_repo
  variable_name = "PLAN_ROLE_ARN"
  value         = aws_iam_role.plan.arn
}

resource "github_actions_variable" "deploy_role_arn" {
  repository    = var.github_repo
  variable_name = "DEPLOY_ROLE_ARN"
  value         = aws_iam_role.deploy.arn
}

resource "github_actions_variable" "tf_state_bucket" {
  repository    = var.github_repo
  variable_name = "TF_STATE_BUCKET"
  value         = aws_s3_bucket.tf_state.bucket
}

resource "github_actions_variable" "tf_lock_table" {
  repository    = var.github_repo
  variable_name = "TF_LOCK_TABLE"
  value         = aws_dynamodb_table.tf_lock.name
}
