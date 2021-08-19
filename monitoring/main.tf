module "lambda_shutdown_hub" {
  source = "terraform-aws-modules/lambda/aws"
  version = "~> 1.43.0"

  function_name = "shutdown-hub"
  description   = "Shut down JupyterHub by setting the EKS core nodegroup's ASG max size to 0"
  handler       = "shutdown_hub.lambda_handler"
  runtime       = "python3.9"
  #publish       = false

  source_path = [
    {
      # This is the lambda itself. The code in path will be placed directly into the lambda execution path
      path = "${path.module}/lambda"
      pip_requirements = false
    },
  ]

  # ensures that terraform doesn't try to mess with IAM
  create_role = false
  attach_cloudwatch_logs_policy = false
  attach_dead_letter_policy = false
  attach_network_policy = false
  attach_tracing_policy = false
  attach_async_event_policy = false

  # TODO: ITSD wil create this, put something in variables.tf
  lambda_role = "???" #nonsensitive(data.aws_ssm_parameter.lambda_cloudwatch_role.value)
}

resource "aws_cloudwatch_event_target" "efs_exceeded_limit" {
  rule      = aws_cloudwatch_event_rule.refresh_cache_logs.name
  target_id = "lambda"
  arn       = module.lambda_shutdown_hub.this_lambda_function_arn
}
