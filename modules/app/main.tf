################################################################################
# Auth Gateway - App
#
# Per-application authorization in a shared Cognito user pool:
#   - a resource server exposing custom OAuth scopes (API authorization)
#   - a web app client (authorization code + PKCE) federated to Okta
#   - a machine-to-machine client (client credentials)
#   - Cognito user groups for group/role-based authorization
################################################################################

locals {
  resource_server_scope_names = var.create_resource_server ? [
    for s in var.resource_server_scopes : "${var.resource_server_identifier}/${s.scope_name}"
  ] : []

  web_oauth_scopes = distinct(concat(
    var.web_oauth_scopes,
    var.web_include_resource_scopes ? local.resource_server_scope_names : [],
  ))

  m2m_oauth_scopes = length(var.m2m_oauth_scopes) > 0 ? var.m2m_oauth_scopes : local.resource_server_scope_names
}

resource "aws_cognito_resource_server" "this" {
  count = var.create_resource_server ? 1 : 0

  user_pool_id = var.user_pool_id
  identifier   = var.resource_server_identifier
  name         = var.name

  dynamic "scope" {
    for_each = var.resource_server_scopes
    content {
      scope_name        = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}

resource "aws_cognito_user_pool_client" "web" {
  count = var.create_web_client ? 1 : 0

  name         = "${var.name}-web"
  user_pool_id = var.user_pool_id

  generate_secret              = var.web_generate_secret
  supported_identity_providers = var.supported_identity_providers

  callback_urls        = var.web_callback_urls
  logout_urls          = var.web_logout_urls
  default_redirect_uri = length(var.web_callback_urls) > 0 ? var.web_callback_urls[0] : null

  allowed_oauth_flows                  = var.web_allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = local.web_oauth_scopes

  explicit_auth_flows = var.web_explicit_auth_flows

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = var.web_access_token_validity
  id_token_validity      = var.web_id_token_validity
  refresh_token_validity = var.web_refresh_token_validity

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [aws_cognito_resource_server.this]
}

resource "aws_cognito_user_pool_client" "m2m" {
  count = var.create_m2m_client ? 1 : 0

  name         = "${var.name}-m2m"
  user_pool_id = var.user_pool_id

  generate_secret              = true
  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = local.m2m_oauth_scopes

  enable_token_revocation = true

  access_token_validity = var.m2m_access_token_validity

  token_validity_units {
    access_token = "minutes"
  }

  depends_on = [aws_cognito_resource_server.this]

  lifecycle {
    precondition {
      condition     = length(local.m2m_oauth_scopes) > 0
      error_message = "create_m2m_client requires resource server scopes: set create_resource_server with resource_server_scopes, or provide m2m_oauth_scopes."
    }
  }
}

resource "aws_cognito_user_group" "this" {
  for_each = { for g in var.groups : g.name => g }

  name         = each.value.name
  user_pool_id = var.user_pool_id
  description  = each.value.description
  precedence   = each.value.precedence
  role_arn     = each.value.role_arn
}
