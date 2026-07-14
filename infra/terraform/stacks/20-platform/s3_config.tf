# Optional config bucket read by apps/backend/docker/setup.sh (CONFIG_BUCKET
# env var) — skipped gracefully by the app if unset, as it is locally.
resource "aws_s3_bucket" "config" {
  bucket = "sg-showcase-${var.environment}-config-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "sg-showcase-${var.environment}-config"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
