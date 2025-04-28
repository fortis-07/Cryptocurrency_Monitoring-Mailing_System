module "crypto_alerts" {
  source = "./modules/crypto-alert"

  name_prefix            = "prod-crypto-alerts"
  alpha_vantage_api_key  = var.alpha_vantage_api_key
  alert_email            = var.alert_email
  crypto_symbols         = var.crypto_symbols
  price_change_threshold = var.price_change_threshold
}
