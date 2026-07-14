resource "aws_cloudwatch_metric_alarm" "backend_p95_latency" {
  alarm_name          = "sg-showcase-${var.environment}-backend-p95-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Backend p95 response time above 1s"

  dimensions = {
    LoadBalancer = aws_lb.backend.arn_suffix
    TargetGroup  = aws_lb_target_group.backend.arn_suffix
  }

  tags = {
    Name = "sg-showcase-${var.environment}-backend-p95-alarm"
  }
}
