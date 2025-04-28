output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.crypto_alerts.sns_topic_arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.crypto_alerts.lambda_function_arn
}
