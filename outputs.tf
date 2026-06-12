output "user_pool_id" {
  description = "ID of the Cognito user pool."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito user pool."
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "Endpoint (issuer) of the Cognito user pool, used to validate tokens."
  value       = aws_cognito_user_pool.this.endpoint
}

output "user_pool_name" {
  description = "Name of the Cognito user pool."
  value       = aws_cognito_user_pool.this.name
}

output "okta_provider_name" {
  description = "Name of the Okta identity provider. Pass this to the app submodule as an identity provider for web clients."
  value       = try(aws_cognito_identity_provider.okta[0].provider_name, null)
}

output "group_sync_lambda_arn" {
  description = "ARN of the group-sync pre-token-generation Lambda, if created."
  value       = try(aws_lambda_function.group_sync[0].arn, null)
}

output "group_sync_lambda_name" {
  description = "Name of the group-sync Lambda, if created."
  value       = try(aws_lambda_function.group_sync[0].function_name, null)
}

output "domain" {
  description = "Configured Cognito hosted UI domain (prefix or FQDN), if any."
  value       = try(aws_cognito_user_pool_domain.this[0].domain, null)
}

output "hosted_ui_domain" {
  description = "Fully-qualified hosted UI domain used to build authorize/token URLs."
  value       = local.hosted_ui_domain
}

output "hosted_ui_base_url" {
  description = "Base URL of the Cognito hosted UI / OAuth endpoints."
  value       = local.hosted_ui_domain == null ? null : "https://${local.hosted_ui_domain}"
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution backing a custom hosted UI domain (for DNS alias records)."
  value       = try(aws_cognito_user_pool_domain.this[0].cloudfront_distribution_arn, null)
}
