output "user_pool_id" {
  description = "Cognito user pool ID."
  value       = module.auth_gateway.user_pool_id
}

output "user_pool_endpoint" {
  description = "User pool issuer endpoint (for token validation)."
  value       = module.auth_gateway.user_pool_endpoint
}

output "hosted_ui_base_url" {
  description = "Base URL of the Cognito hosted UI / OAuth endpoints."
  value       = module.auth_gateway.hosted_ui_base_url
}

output "okta_idpresponse_redirect_uri" {
  description = "Redirect URI to register on the Okta OIDC app."
  value       = "${module.auth_gateway.hosted_ui_base_url}/oauth2/idpresponse"
}

output "group_sync_lambda_name" {
  description = "Name of the group-sync Lambda."
  value       = module.auth_gateway.group_sync_lambda_name
}

output "demo_web_client_id" {
  description = "Demo app web client ID."
  value       = module.demo_app.web_client_id
}

output "demo_m2m_client_id" {
  description = "Demo app M2M client ID."
  value       = module.demo_app.m2m_client_id
}

output "demo_m2m_client_secret" {
  description = "Demo app M2M client secret."
  value       = module.demo_app.m2m_client_secret
  sensitive   = true
}

output "demo_scopes" {
  description = "Demo app resource server scopes."
  value       = module.demo_app.scope_names
}

output "demo_token_endpoint" {
  description = "Token endpoint for the demo app (M2M client_credentials)."
  value       = "${module.auth_gateway.hosted_ui_base_url}/oauth2/token"
}
