################################################################################
# Group sync Lambda (option 1: verbatim passthrough)
#
# Pre-token-generation trigger that copies the parsed Okta groups claim
# (custom:okta_groups) into the ID token's cognito:groups claim, so that
# group/role-based authorization reflects Okta membership. A user pool may have
# exactly one pre-token-generation trigger, so this lives in the bootstrap
# module rather than per-app.
################################################################################

data "archive_file" "group_sync" {
  count = local.create_group_sync_lambda ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/lambda/group_sync/index.py"
  output_path = "${path.module}/lambda/group_sync/index.zip"
}

data "aws_iam_policy_document" "group_sync_assume" {
  count = local.create_group_sync_lambda ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "group_sync" {
  count = local.create_group_sync_lambda ? 1 : 0

  name               = "${var.name}-group-sync"
  assume_role_policy = data.aws_iam_policy_document.group_sync_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "group_sync_basic" {
  count = local.create_group_sync_lambda ? 1 : 0

  role       = aws_iam_role.group_sync[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "group_sync" {
  count = local.create_group_sync_lambda ? 1 : 0

  name              = "/aws/lambda/${var.name}-group-sync"
  retention_in_days = var.group_sync_lambda_log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "group_sync" {
  count = local.create_group_sync_lambda ? 1 : 0

  function_name = "${var.name}-group-sync"
  description   = "Maps Okta groups (custom:okta_groups) into cognito:groups for ${var.name}."
  role          = aws_iam_role.group_sync[0].arn
  handler       = "index.handler"
  runtime       = var.group_sync_lambda_runtime
  timeout       = 5

  filename         = data.archive_file.group_sync[0].output_path
  source_code_hash = data.archive_file.group_sync[0].output_base64sha256

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.group_sync_basic,
    aws_cloudwatch_log_group.group_sync,
  ]
}

resource "aws_lambda_permission" "group_sync_cognito" {
  count = local.create_group_sync_lambda ? 1 : 0

  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.group_sync[0].function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}
