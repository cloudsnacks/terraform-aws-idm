output "web_client_id" {
  description = "ID of the web app client."
  value       = try(aws_cognito_user_pool_client.web[0].id, null)
}

output "web_client_secret" {
  description = "Secret of the web app client (only when web_generate_secret is true)."
  value       = try(aws_cognito_user_pool_client.web[0].client_secret, null)
  sensitive   = true
}

output "m2m_client_id" {
  description = "ID of the machine-to-machine client."
  value       = try(aws_cognito_user_pool_client.m2m[0].id, null)
}

output "m2m_client_secret" {
  description = "Secret of the machine-to-machine client."
  value       = try(aws_cognito_user_pool_client.m2m[0].client_secret, null)
  sensitive   = true
}

output "resource_server_identifier" {
  description = "Identifier of the resource server."
  value       = try(aws_cognito_resource_server.this[0].identifier, null)
}

output "scope_names" {
  description = "Fully-qualified OAuth scope names exposed by the resource server."
  value       = local.resource_server_scope_names
}

output "group_names" {
  description = "Names of the Cognito user groups created for this app."
  value       = [for g in aws_cognito_user_group.this : g.name]
}
