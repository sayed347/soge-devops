resource "aws_ecr_repository" "backend" {
  name                 = "sg-showcase-backend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "sg-showcase-${var.environment}-ecr-backend"
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "sg-showcase-frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "sg-showcase-${var.environment}-ecr-frontend"
  }
}

# Resource-based policy on each repo (in addition to the IAM side already
# granted via the boundary): plan gets read-only, deploy gets read+write.
data "aws_iam_policy_document" "ecr_repo_policy" {
  statement {
    sid    = "AllowPlanReadOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.plan.arn]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
  }

  statement {
    sid    = "AllowDeployReadWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.deploy.arn]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
  }
}

resource "aws_ecr_repository_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy.json
}

resource "aws_ecr_repository_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy.json
}
