terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = var.region
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sns_publish" {
  name = "${var.name_prefix}-sns-publish-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = aws_sns_topic.crypto_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "${var.name_prefix}-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:CreateTable"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "crypto_alerts" {
  name = "${var.name_prefix}-price-alerts"
}

# Subscribe email to the SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  for_each  = toset(var.alert_email)
  topic_arn = aws_sns_topic.crypto_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda" # Goes up two levels from module dir
  output_path = "${path.module}/lambda_function.zip"
  excludes    = ["__pycache__"] # Exclude Python cache if present
}

resource "aws_lambda_function" "crypto_alert" {
  filename      = "lambda_deployment.zip"
  function_name = "${var.name_prefix}-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler" # Must match exactly
  runtime       = "python3.9"
  # timeout       = 60
  memory_size = 256 # Increased memory for API calls

  source_code_hash = filebase64sha256("lambda_deployment.zip")

  environment {
    variables = {
      ALPHA_VANTAGE_API_KEY  = var.alpha_vantage_api_key
      SNS_TOPIC_ARN          = aws_sns_topic.crypto_alerts.arn
      CRYPTO_SYMBOLS         = join(",", var.crypto_symbols)
      FIAT_CURRENCY          = var.fiat_currency
      PRICE_CHANGE_THRESHOLD = tostring(var.price_change_threshold)
      DYNAMODB_TABLE         = "${var.name_prefix}-exchange-rates"

    }
  }
}

# CloudWatch Event Rule to trigger Lambda
resource "aws_cloudwatch_event_rule" "price_check_schedule" {
  name                = "${var.name_prefix}-schedule"
  description         = "Schedule for crypto price checks"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.price_check_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.crypto_alert.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crypto_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.price_check_schedule.arn
}

# DynamoDB Table 
resource "aws_dynamodb_table" "exchange_rates" {
  name         = "${var.name_prefix}-exchange-rates"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "from_currency"
  range_key    = "to_currency"

  attribute {
    name = "from_currency"
    type = "S"
  }

  attribute {
    name = "to_currency"
    type = "S"
  }
}
