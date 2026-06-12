################################################################################
# Test deployment
#
# Stands up the whole stack end to end:
#   - Cognito user pool + group-sync Lambda
#   - one app (web + m2m clients, resource server scopes, groups)
#
# By default create_okta_idp = false so it deploys WITHOUT a real Okta app:
# the web client uses COGNITO as its identity provider. Once the Okta app is
# provisioned, set create_okta_idp = true (+ okta_oidc_* vars) and re-apply;
# the web client's identity provider flips to Okta automatically.
################################################################################

locals {
  identity_provider = var.create_okta_idp ? module.auth_gateway.okta_provider_name : "COGNITO"
}

module "auth_gateway" {
  source = "../../"

  name          = var.name
  domain        = var.domain_prefix
  deletion_protection = false # throwaway test stack

  create_okta_idp         = var.create_okta_idp
  okta_oidc_client_id     = var.okta_oidc_client_id
  okta_oidc_client_secret = var.okta_oidc_client_secret
  okta_oidc_issuer        = var.okta_oidc_issuer

  create_group_sync_lambda = true
}

module "demo_app" {
  source = "../../modules/app"

  name         = "demo"
  user_pool_id = module.auth_gateway.user_pool_id

  supported_identity_providers = [local.identity_provider]

  resource_server_identifier = "https://api.demo.test"
  resource_server_scopes = [
    { scope_name = "read", scope_description = "Read demo data" },
    { scope_name = "write", scope_description = "Modify demo data" },
  ]

  web_generate_secret = false
  web_callback_urls   = ["http://localhost:3000/auth/callback"]
  web_logout_urls     = ["http://localhost:3000/"]

  groups = [
    { name = "demo-admins", description = "Demo administrators", precedence = 1 },
    { name = "demo-users", description = "Demo end users", precedence = 10 },
  ]
}
