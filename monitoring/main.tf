module "lambda_shutdown_hub" {
  source = "terraform-aws-modules/lambda/aws"
  version = "~> 1.43.0"

  function_name = "shutdown-hub"
  description   = "Shut down JupyterHub by setting the EKS core nodegroup's ASG max size to 0"
  handler       = "shutdown_hub.lambda_handler"
  runtime       = "python3.8"
  #publish       = false

  source_path = [
    {
      # This is the lambda itself. The code in path will be placed directly into the lambda execution path
      path = "${path.module}/lambda"
      pip_requirements = false
    },
  ]

  # Don't mess with IAM
  create_role = false
  attach_cloudwatch_logs_policy = false
  attach_dead_letter_policy = false
  attach_network_policy = false
  attach_tracing_policy = false
  attach_async_event_policy = false

  lambda_role = var.lambda_rolearn
}


resource "aws_cloudwatch_event_target" "efs_exceeded_limit_target" {
  #depends_on = [module.lambda_shutdown_hub]
  rule      = aws_cloudwatch_event_rule.efs_exceeded_limit_rule.name
  target_id = "lambda"
  arn       = module.lambda_shutdown_hub.this_lambda_function_arn
}


resource "aws_cloudwatch_metric_alarm" "efs_exceeded_limit_alarm" {
  alarm_name                = "efs_exceeded_limit"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "StorageBytes"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "80"

  dimensions = {
    FileSystemId = var.user_home_efs_id
  }
}


# This is really an EventBridge rule, they just haven't updated the API
resource "aws_cloudwatch_event_rule" "efs_exceeded_limit_rule" {
  name        = "efs_exceeded_limit"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "CloudWatch Alarm State Change"
  ],
  "source": [
    "aws.cloudwatch"
  ],
  "region": [
    "us-east-1"
  ],
  "resources": ["${aws_cloudwatch_metric_alarm.efs_exceeded_limit_alarm.arn}"]
}
PATTERN
}
