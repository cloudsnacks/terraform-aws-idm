################################################################################
# Bootstrap: one user pool federated to a single Okta OIDC app
################################################################################

module "auth_gateway" {
  source = "../../"

  name   = "acme-idm"
  domain = "acme-idm" # -> acme-idm.auth.<region>.amazoncognito.com

  okta_oidc_client_id     = var.okta_oidc_client_id
  okta_oidc_client_secret = var.okta_oidc_client_secret
  okta_oidc_issuer        = var.okta_oidc_issuer

  tags = {
    Project = "terraform-aws-idm"
    Env     = "prod"
  }
}

################################################################################
# App 1: customer web portal (web client + API scopes + groups)
################################################################################

module "portal" {
  source = "../../modules/app"

  name         = "portal"
  user_pool_id = module.auth_gateway.user_pool_id

  supported_identity_providers = [module.auth_gateway.okta_provider_name]

  resource_server_identifier = "https://api.portal.acme.com"
  resource_server_scopes = [
    { scope_name = "read", scope_description = "Read portal data" },
    { scope_name = "write", scope_description = "Modify portal data" },
  ]

  web_generate_secret = false # public SPA -> PKCE
  web_callback_urls   = ["https://portal.acme.com/auth/callback"]
  web_logout_urls     = ["https://portal.acme.com/"]

  groups = [
    { name = "portal-admins", description = "Portal administrators", precedence = 1 },
    { name = "portal-users", description = "Portal end users", precedence = 10 },
  ]
}

################################################################################
# App 2: backend service (M2M only)
################################################################################

module "billing_service" {
  source = "../../modules/app"

  name         = "billing-service"
  user_pool_id = module.auth_gateway.user_pool_id

  create_web_client = false

  resource_server_identifier = "https://api.billing.acme.com"
  resource_server_scopes = [
    { scope_name = "invoices.read", scope_description = "Read invoices" },
    { scope_name = "invoices.write", scope_description = "Issue invoices" },
  ]
}
