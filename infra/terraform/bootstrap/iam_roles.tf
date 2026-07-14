locals {
  repo_full = "${var.github_owner}/${var.github_repo}"
}

# ---------------------------------------------------------------------------
# Plan role: read-only, assumable from any branch/PR/event on this repo.
# Low risk by design (no write permissions), so the trust condition stays
# broad — the real safety net is the attached ReadOnlyAccess policy.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repo_full}:*"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "sg-showcase-ci-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state_access" {
  statement {
    sid       = "StateBucketReadForPlan"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.tf_state.arn, "${aws_s3_bucket.tf_state.arn}/*"]
  }

  statement {
    # terraform plan still takes a state lock even though it writes nothing.
    sid       = "StateLockForPlan"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.tf_lock.arn]
  }
}

resource "aws_iam_role_policy" "plan_state_access" {
  name   = "state-access"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state_access.json
}

# ---------------------------------------------------------------------------
# Deploy role: real write access, only assumable by jobs running under a
# "deploy-*" GitHub Environment (deploy-dev, deploy-prod...).
#
# NOTE: once a job specifies `environment:`, GitHub changes the OIDC "sub"
# claim format from "repo:OWNER/REPO:ref:refs/heads/BRANCH" to
# "repo:OWNER/REPO:environment:ENV_NAME" — it stops reflecting the branch
# entirely. So branch restriction can no longer live in this trust policy;
# it's enforced instead via each GitHub Environment's own "Deployment
# branches and tags" setting (Settings > Environments > deploy-dev >
# restrict to main).
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repo_full}:environment:deploy-*"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "sg-showcase-ci-deploy"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  permissions_boundary = aws_iam_policy.demosg_boundary.arn
}

resource "aws_iam_role_policy_attachment" "deploy_power_user" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "deploy_extra" {
  statement {
    # PowerUserAccess deliberately excludes most IAM actions — add back just
    # enough to manage the ECS task/execution roles this project creates,
    # scoped to the sg-showcase-* naming convention.
    sid = "ScopedIamForEcsRoles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy", "iam:AttachRolePolicy",
      "iam:DetachRolePolicy", "iam:TagRole", "iam:UntagRole",
      "iam:PassRole", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::*:role/sg-showcase-*"]
  }

  statement {
    sid       = "StateBucketAccessForApply"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.tf_state.arn, "${aws_s3_bucket.tf_state.arn}/*"]
  }

  statement {
    sid       = "StateLockForApply"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.tf_lock.arn]
  }
}

resource "aws_iam_role_policy" "deploy_extra" {
  name   = "scoped-extra-access"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_extra.json
}
