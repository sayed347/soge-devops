data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Shared by both services — fetches images from ECR, ships logs to
# CloudWatch, and resolves the RDS-managed secret before the container
# starts (the actual DB credentials never pass through the task role).
resource "aws_iam_role" "execution" {
  name               = "sg-showcase-${var.environment}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "PullFromEcr"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PullOurRepos"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/sg-showcase-backend",
      "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/sg-showcase-frontend",
    ]
  }

  statement {
    sid    = "WriteOurLogGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/sg-showcase-${var.environment}-backend:*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/sg-showcase-${var.environment}-frontend:*",
    ]
  }

  statement {
    sid       = "ReadTheRdsManagedSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_ssm_parameter.rds_master_secret_arn.value]
  }

  statement {
    # KMS's own key policy already delegates to account IAM (its
    # "EnableAccountRootPermissions" statement) — no key-policy change
    # needed for this role, only this identity-side grant.
    sid       = "DecryptTheSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_ssm_parameter.kms_key_arn.value]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "scoped-access"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# Backend-only — the app itself calls SSM (info parameter) and, optionally,
# S3 (docker/setup.sh's config fetch). The frontend makes no AWS calls.
resource "aws_iam_role" "backend_task" {
  name               = "sg-showcase-${var.environment}-backend-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "backend_task" {
  statement {
    sid       = "ReadInfoParameter"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/app/${var.environment}/payment-orders/*"]
  }

  statement {
    sid       = "ReadConfigBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${data.aws_ssm_parameter.config_bucket_name.value}/*"]
  }
}

resource "aws_iam_role_policy" "backend_task" {
  name   = "scoped-access"
  role   = aws_iam_role.backend_task.id
  policy = data.aws_iam_policy_document.backend_task.json
}
