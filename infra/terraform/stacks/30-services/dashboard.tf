resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "sg-showcase-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Backend requests/s"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", aws_lb_target_group.backend.arn_suffix, "LoadBalancer", aws_lb.backend.arn_suffix, { stat = "Sum" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Backend p95 latency"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", aws_lb_target_group.backend.arn_suffix, "LoadBalancer", aws_lb.backend.arn_suffix, { stat = "p95" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Backend 5xx"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", aws_lb_target_group.backend.arn_suffix, "LoadBalancer", aws_lb.backend.arn_suffix, { stat = "Sum" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Backend task CPU"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", data.aws_ssm_parameter.ecs_cluster_name.value, "ServiceName", module.services["backend"].service_name, { stat = "Average" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Backend running tasks"
          region = data.aws_region.current.name
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", data.aws_ssm_parameter.ecs_cluster_name.value, "ServiceName", module.services["backend"].service_name, { stat = "Average" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "RDS connections"
          region = data.aws_region.current.name
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "sg-showcase-${var.environment}-db", { stat = "Average" }],
          ]
          period = 60
        }
      },
    ]
  })
}
