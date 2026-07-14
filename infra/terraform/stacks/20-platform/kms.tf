# Customer-managed key for RDS storage + the RDS-managed master password
# secret — demonstrates explicit KMS usage rather than the AWS-managed
# default key.
#
# KMS requires TWO layers to agree before access is granted: the calling
# role's IAM policy/boundary, AND the key's own resource policy (like an S3
# bucket policy). Both are set up here — the key policy below, and the
# matching kms:* additions in the bootstrap permissions boundary.
data "aws_iam_policy_document" "rds_kms_key" {
  statement {
    sid    = "EnableAccountRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    # The OIDC roles manage the key (policy, grants) and also need direct
    # encrypt/decrypt/data-key actions themselves: RDS validates the calling
    # principal's own KMS access before it hands off to the grant it creates
    # for its own service role.
    sid    = "AllowOidcRolesToManageTheKey"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.plan.arn, data.aws_iam_role.deploy.arn]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy",
      "kms:CreateGrant",
      "kms:RevokeGrant",
      "kms:ListGrants",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "rds" {
  description             = "CMK for RDS storage + managed master password (${var.environment})"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.rds_kms_key.json

  tags = {
    Name = "sg-showcase-${var.environment}-rds-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/sg-showcase-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}
