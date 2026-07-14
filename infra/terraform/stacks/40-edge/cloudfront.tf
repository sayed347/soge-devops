resource "aws_cloudfront_distribution" "main" {
  provider = aws.us_east_1

  enabled     = true
  comment     = "sg-showcase ${var.environment}"
  web_acl_id  = aws_wafv2_web_acl.main.arn
  price_class = "PriceClass_100"

  origin {
    domain_name = data.aws_ssm_parameter.frontend_alb_dns_name.value
    origin_id   = "frontend"

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.frontend.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods          = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # No caching on the API — otherwise k6 load results (and the app's own
  # PENDING -> SETTLED transitions) would be masked by cached responses.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods          = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["X-Correlation-Id"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "sg-showcase-${var.environment}-cloudfront"
  }

  depends_on = [aws_vpc_security_group_ingress_rule.alb_frontend_from_cloudfront]
}
