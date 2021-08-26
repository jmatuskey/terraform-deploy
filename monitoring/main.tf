# Set the cluster name in the lambda function code
resource "null_resource" "modify_lambda_function" {
  provisioner "local-exec" {
    command = "sed -i \"s/cluster = '<terraform assigns this value>'/cluster = '${var.cluster_name}'/g\" lambda/shutdown_hub.py" 
  }
}

# On destroy, restore the unmodified lambda file
resource "null_resource" "restore_lambda_function" {
  provisioner "local-exec" {
    command = "git checkout lambda/shutdown_hub.py"
    when = destroy
  }
}

module "lambda_shutdown_hub" {
  depends_on = [null_resource.modify_lambda_function]

  source = "terraform-aws-modules/lambda/aws"
  version = "~> 1.43.0"

  function_name = "shutdown-hub"
  description   = "Shut down JupyterHub by setting the EKS nodegroups' ASG max size to 0"
  handler       = "shutdown_hub.lambda_handler"
  runtime       = "python3.8"
  cloudwatch_logs_retention_in_days = 365

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
}


resource "aws_cloudwatch_event_target" "efs_exceeded_limit_target" {
  rule      = aws_cloudwatch_event_rule.efs_exceeded_limit_rule.name
  target_id = "lambda"
  arn       = module.lambda_shutdown_hub.this_lambda_function_arn
}


resource "aws_cloudwatch_metric_alarm" "efs_exceeded_limit_alarm" {
  alarm_name                = "efs-exceeded-limit"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StorageBytes"
  namespace                 = "AWS/EFS"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "11000000000"
  treat_missing_data        = "ignore"

  dimensions = {
    FileSystemId = var.user_home_efs_id
    StorageClass = "Total"
  }
}


# This is really an EventBridge rule, they just haven't updated the API
resource "aws_cloudwatch_event_rule" "efs_exceeded_limit_rule" {
  name = "efs-exceeded-limit"

  event_pattern = <<PATTERN
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "resources": ["${aws_cloudwatch_metric_alarm.efs_exceeded_limit_alarm.arn}"]
}
PATTERN
}


# Inspired by https://medium.com/@raghuram.arumalla153/aws-sns-topic-subscription-with-email-protocol-using-terraform-ed05f4f19b73
#
# Note: there is no support for the email protocol in Terraform as of now, so to get around
#       that limitation we create a CloudFormation stack to create the SNS topic
data "template_file" "efs_exceeded_limit_cf_sns_stack" {
  template = file("${path.module}/template/cf_aws_sns_email_stack.json.tpl")
  vars = {
    sns_topic_name        = "efs-exceeded-limit"
    sns_display_name      = var.sns_topic_display_name
    sns_subscription_list = join(
      ",", formatlist(
        "{\"Endpoint\": \"%s\",\"Protocol\": \"%s\"}",
        var.sns_subscription_email_address_list,
        var.sns_subscription_protocol
      )
    )
  }
}


resource "aws_cloudformation_stack" "efs_exceeded_limit_sns_topic" {
  name = "efs-exceeded-limit"
  template_body = data.template_file.efs_exceeded_limit_cf_sns_stack.rendered
}


































