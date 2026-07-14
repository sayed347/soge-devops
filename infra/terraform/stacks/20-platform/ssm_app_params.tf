# Non-secret app config, read by the backend at runtime (SsmParameterService
# / InfoController) — the one real secret (the RDS password) never goes
# through SSM, it's managed entirely by RDS in Secrets Manager instead.
resource "aws_ssm_parameter" "info_message" {
  name  = "/app/${var.environment}/payment-orders/info-message"
  type  = "String"
  value = "Hello from AWS SSM (${var.environment})"
}

resource "aws_ssm_parameter" "config_bucket" {
  name  = "/app/${var.environment}/payment-orders/config-bucket"
  type  = "String"
  value = aws_s3_bucket.config.bucket
}
