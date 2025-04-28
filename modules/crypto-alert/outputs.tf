output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.crypto_alerts.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.crypto_alert.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for price history"
  value       = aws_dynamodb_table.exchange_rates.name
}
