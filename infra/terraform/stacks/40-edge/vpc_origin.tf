resource "aws_cloudfront_vpc_origin" "frontend" {
  provider = aws.us_east_1

  vpc_origin_endpoint_config {
    name                   = "sg-showcase-${var.environment}-frontend"
    arn                    = data.aws_ssm_parameter.frontend_alb_arn.value
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = {
    Name = "sg-showcase-${var.environment}-vpc-origin-frontend"
  }

  depends_on = [aws_internet_gateway.main]
}
