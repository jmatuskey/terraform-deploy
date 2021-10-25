module "lambda_shutdown_hub" {
  source = "terraform-aws-modules/lambda/aws"
  version = "~> 2.16.0"

  function_name = "shutdown-hub"
  description   = "Shut down JupyterHub by setting the EKS nodegroups' ASG max size to 0"
  handler       = "shutdown_hub.lambda_handler"
  runtime       = "python3.8"
  cloudwatch_logs_retention_in_days = 365
  create_current_version_allowed_triggers = false

  source_path = [
    {
      path = "${path.module}/lambda"
      pip_requirements = false
    }
  ]

  # Don't mess with IAM
  create_role = false
  attach_cloudwatch_logs_policy = false
  attach_dead_letter_policy = false
  attach_network_policy = false
  attach_tracing_policy = false
  attach_async_event_policy = false

  lambda_role = var.lambda_rolearn

  allowed_triggers = {
    OneRule = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.efs_exceeded_limit_rule.arn
    }
  }

  environment_variables = {
    CLUSTER_NAME = var.cluster_name
    ACCOUNT_ID = var.account_id
    EFS_ID = var.user_home_efs_id
    RECIPIENT_EMAILS = var.recipient_emails
  }
}


resource "aws_cloudwatch_metric_alarm" "efs_exceeded_limit_alarm" {
  alarm_name          = "efs-exceeded-limit"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StorageBytes"
  namespace           = "AWS/EFS"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.efs_threshold
  treat_missing_data  = "ignore"

  dimensions = {
    FileSystemId = var.user_home_efs_id
    StorageClass = "Total"
  }
}


resource "aws_cloudwatch_event_target" "efs_exceeded_limit_target" {
  rule      = aws_cloudwatch_event_rule.efs_exceeded_limit_rule.name
  target_id = "shutdown-hub"
  arn  = module.lambda_shutdown_hub.lambda_function_arn
}


# This is really an EventBridge rule, they just haven't updated the API
resource "aws_cloudwatch_event_rule" "efs_exceeded_limit_rule" {
  name = "efs-exceeded-limit"
  role_arn = var.lambda_rolearn

  event_pattern = <<PATTERN
{
  "detail-type": [
    "CloudWatch Alarm State Change"
  ],
  "detail": {
    "state": {
      "value": [
        "ALARM"
      ]
    }
  },
  "resources": [
    "arn:aws:cloudwatch:us-east-1:${var.account_id}:alarm:efs-exceeded-limit"
  ],
  "source": [
    "aws.cloudwatch"
  ]
}
PATTERN
}
