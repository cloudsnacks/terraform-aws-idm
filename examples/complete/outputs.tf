output "user_pool_id" {
  description = "Shared Cognito user pool ID."
  value       = module.auth_gateway.user_pool_id
}

output "hosted_ui_base_url" {
  description = "Base URL for the Cognito hosted UI / OAuth endpoints."
  value       = module.auth_gateway.hosted_ui_base_url
}

output "portal_web_client_id" {
  description = "Portal SPA client ID."
  value       = module.portal.web_client_id
}

output "portal_scopes" {
  description = "Portal API scopes."
  value       = module.portal.scope_names
}

output "billing_m2m_client_id" {
  description = "Billing service M2M client ID."
  value       = module.billing_service.m2m_client_id
}
