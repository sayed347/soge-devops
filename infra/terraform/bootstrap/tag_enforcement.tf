# Real enforcement (not just labeling): the deploy role can only create,
# modify, or delete resources tagged Owner=demosg. Two exceptions exist,
# both Terraform's own operational plumbing rather than infrastructure
# resources — scoped to one exact, hardcoded ARN each instead of a tag,
# which is at least as strict. Everything else goes through a tag check.
#
# Note: IAM action strings must have a literal service prefix — "*:Describe*"
# is rejected by AWS ("Action vendors must not contain wildcards"), only the
# part after the colon may use a wildcard. Every action below is scoped to a
# real service used by this project instead.
#
# Kept as few statements as possible — customer-managed IAM policies have a
# hard 6144-character limit, and this boundary hit it once already. Sids are
# only kept on the four conceptual statements below; the various narrow
# exceptions further down are consolidated into as few statements as their
# differing conditions allow, without a Sid each (optional, costs bytes,
# HCL comments document them for free instead since comments never reach the
# rendered JSON).
data "aws_iam_policy_document" "demosg_boundary" {
  statement {
    sid    = "AllowReadOnlyAndAutoscaling"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "ec2:Describe*", "ec2:GetSecurityGroupsForVpc", "ec2:GetManagedPrefixListEntries",
      "ecs:Describe*", "ecs:List*",
      "rds:Describe*", "rds:List*",
      "elasticloadbalancing:Describe*",
      "s3:Get*", "s3:List*",
      "dynamodb:Describe*", "dynamodb:List*", "dynamodb:GetItem",
      "ssm:Describe*", "ssm:Get*", "ssm:List*",
      "secretsmanager:Describe*", "secretsmanager:Get*", "secretsmanager:List*",
      "ecr:Describe*", "ecr:Get*", "ecr:List*",
      "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability",
      "kms:Describe*", "kms:Get*", "kms:List*",
      "logs:Describe*", "logs:Get*", "logs:List*", "logs:FilterLogEvents",
      "iam:Get*", "iam:List*",
      # Full service wildcards, not enumerated actions, for services that
      # hold no sensitive data, carry no meaningful cost/blast-radius risk,
      # and have no real resource-level permission granularity to scope
      # against — CloudWatch and Application Auto Scaling repeatedly
      # surfaced missing individual actions this session; CloudFront/WAFv2
      # are the same category (edge routing/rules, not data).
      "cloudwatch:*",
      "application-autoscaling:*",
      "cloudfront:*",
      "wafv2:*",
      # ECS doesn't support resource-level scoping for this action at all —
      # AWS evaluates it against a literal "*", so any ARN pattern here
      # would never match. Low risk to leave unconditioned: it only marks
      # an existing task definition revision INACTIVE.
      "ecs:DeregisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    # Every action that creates a new resource, or that sets tags as part of
    # its own request (TagResource-style calls) — the request itself must
    # carry Owner=demosg.
    sid    = "AllowCreateWithOwnerTag"
    effect = "Allow"
    actions = [
      "ec2:Create*", "ec2:RunInstances", "ec2:CreateTags",
      "ec2:AuthorizeSecurityGroupEgress", "ec2:AuthorizeSecurityGroupIngress",
      "ecs:Create*", "ecs:Run*", "ecs:RegisterTaskDefinition", "ecs:TagResource",
      "rds:Create*", "rds:AddTagsToResource",
      "elasticloadbalancing:Create*", "elasticloadbalancing:AddTags",
      "dynamodb:CreateTable", "dynamodb:TagResource",
      "ssm:PutParameter", "ssm:AddTagsToResource",
      "secretsmanager:CreateSecret", "secretsmanager:TagResource",
      "ecr:CreateRepository", "ecr:TagResource",
      "kms:CreateKey", "kms:TagResource",
      "logs:CreateLogGroup", "logs:TagResource", "logs:TagLogGroup",
      "iam:CreateRole", "iam:TagRole",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Owner"
      values   = ["demosg"]
    }
  }

  statement {
    # Two ResourceTag-conditioned cases merged: (1) some EC2 create actions
    # build a resource that lives inside an already-tagged parent (a subnet
    # inside a VPC, etc.) and need authorization on that parent too, and (2)
    # kms:CreateAlias/DeleteAlias check authorization on the target key,
    # which is likewise an already-tagged parent. Add more resource-type ARN
    # patterns here if a future stack's error message points at a parent
    # resource type not yet listed.
    sid    = "AllowActingOnAlreadyTaggedParents"
    effect = "Allow"
    actions = [
      "ec2:Create*", "ec2:RunInstances", "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress", "ec2:AuthorizeSecurityGroupIngress",
      "kms:CreateAlias", "kms:DeleteAlias",
    ]
    resources = [
      "arn:aws:ec2:*:*:vpc/*",
      "arn:aws:ec2:*:*:route-table/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:internet-gateway/*",
      "arn:aws:kms:*:*:key/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Owner"
      values   = ["demosg"]
    }
  }

  statement {
    # Everything that acts on a resource that must already exist — modify,
    # delete, remove a tag, or pass a role to a service — requires that
    # resource to already carry the tag.
    sid    = "AllowActingOnAlreadyTaggedResources"
    effect = "Allow"
    actions = [
      "ec2:Modify*", "ec2:Terminate*", "ec2:Delete*", "ec2:DeleteTags",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable", "ec2:DetachInternetGateway",
      "ec2:RevokeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress",
      "ecs:Update*", "ecs:Delete*", "ecs:Stop*", "ecs:UntagResource",
      "rds:Modify*", "rds:Delete*", "rds:RemoveTagsFromResource",
      "elasticloadbalancing:Modify*", "elasticloadbalancing:Delete*", "elasticloadbalancing:RemoveTags",
      "dynamodb:UpdateTable", "dynamodb:DeleteTable", "dynamodb:UntagResource",
      "ssm:DeleteParameter", "ssm:RemoveTagsFromResource",
      "secretsmanager:UpdateSecret", "secretsmanager:DeleteSecret", "secretsmanager:UntagResource",
      "ecr:DeleteRepository", "ecr:UntagResource", "ecr:SetRepositoryPolicy", "ecr:DeleteRepositoryPolicy",
      "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage",
      "kms:DisableKey", "kms:ScheduleKeyDeletion", "kms:UntagResource",
      "kms:PutKeyPolicy", "kms:CreateGrant", "kms:RevokeGrant", "kms:ListGrants",
      "kms:EnableKeyRotation",
      "kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom", "kms:ReEncryptTo",
      "logs:DeleteLogGroup", "logs:PutLogEvents", "logs:UntagLogGroup",
      "iam:DeleteRole", "iam:PutRolePolicy", "iam:AttachRolePolicy",
      "iam:DetachRolePolicy", "iam:DeleteRolePolicy",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Owner"
      values   = ["demosg"]
    }
  }

  statement {
    # Everything below can't be tag-conditioned at all — either the resource
    # type doesn't support tags (KMS/S3 naming exceptions), the action is a
    # whole-bucket S3 call, a just-created log group's retention policy, or
    # a versioned ECS task definition revision (aws:RequestTag/
    # aws:ResourceTag don't reliably evaluate on these, confirmed
    # empirically), or the resource has no tagging parameter (the
    # CI-published image-tag SSM parameter). Merged into one statement (safe:
    # AWS enforces that an action can only ever apply to its own service's
    # real resource type, regardless of what else is listed here) —
    # naming-pattern scoped, only resources following this project's
    # convention.
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "kms:CreateAlias", "kms:DeleteAlias",
      "s3:CreateBucket", "s3:DeleteBucket", "s3:PutBucketTagging",
      "s3:PutBucketVersioning", "s3:PutBucketPublicAccessBlock",
      "logs:PutRetentionPolicy",
      "ssm:PutParameter",
    ]
    resources = [
      "arn:aws:iam::*:role/sg-showcase-*",
      "arn:aws:kms:*:*:alias/sg-showcase-*",
      "arn:aws:s3:::sg-showcase-*",
      "arn:aws:logs:*:*:log-group:/ecs/sg-showcase-*",
      "arn:aws:logs:*:*:log-group:/sg-showcase/*",
      "arn:aws:ssm:*:*:parameter/app/*/payment-orders/*/image-tag",
    ]
  }

  statement {
    # RDS/ELB/ECS/ECS-autoscaling auto-create their service-linked role on
    # first use in an account/region — CreateServiceLinkedRole has no
    # tagging parameter, so it's scoped by which service is allowed to
    # request one instead, per AWS's own recommended pattern.
    effect  = "Allow"
    actions = ["iam:CreateServiceLinkedRole"]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/*",
      "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/*",
      "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/*",
      "arn:aws:iam::*:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/*",
      "arn:aws:iam::*:role/aws-service-role/vpcorigin.cloudfront.amazonaws.com/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "rds.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs.application-autoscaling.amazonaws.com",
        "vpcorigin.cloudfront.amazonaws.com",
      ]
    }
  }

  statement {
    # Terraform's own operational plumbing — the state lock (DynamoDB) and
    # the state file itself (S3) — never tagged by Terraform, scoped to
    # their exact known ARNs instead.
    effect = "Allow"
    actions = [
      "dynamodb:PutItem", "dynamodb:DeleteItem",
      "s3:PutObject", "s3:GetObject", "s3:DeleteObject",
    ]
    resources = [
      aws_dynamodb_table.tf_lock.arn,
      "${aws_s3_bucket.tf_state.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "demosg_boundary" {
  name        = "sg-showcase-demosg-boundary"
  description = "Permissions boundary: deploy role can only create/modify/delete resources tagged Owner=demosg"
  policy      = data.aws_iam_policy_document.demosg_boundary.json
}
