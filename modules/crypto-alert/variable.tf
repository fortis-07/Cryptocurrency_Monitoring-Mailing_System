variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "crypto-alert"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "alpha_vantage_api_key" {
  description = "API key for Alpha Vantage"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email address to receive alerts"
  type        = list(string)
}

variable "fiat_currency" {
  description = "The fiat currency to compare against (e.g., USD, EUR)"
  type        = string
  default     = "USD"
}

variable "crypto_symbols" {
  description = "List of cryptocurrency symbols to monitor"
  type        = list(string)
  default     = ["BTC", "ETH", "USDT", "USDC", "XRP", "SOL", "ADA", "TRX", "DOGE", "BNB"]
}

variable "price_change_threshold" {
  description = "Percentage change required to trigger an alert"
  type        = number
  default     = 0.1 # Now 0.5% instead of 1%
}

variable "schedule_expression" {
  description = "CloudWatch schedule expression for how often to check prices"
  type        = string
  default     = "rate(5 minutes)"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 30
}
