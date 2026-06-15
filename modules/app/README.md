# terraform-aws-idm / app

Per-application authorization within a shared Cognito user pool created by the
parent `terraform-aws-idm` bootstrap module.

Creates, for one application:

- **Resource server + scopes** — custom OAuth scopes for API authorization
  (`<identifier>/<scope_name>`), consumed by web and M2M clients.
- **Web app client** — authorization code grant (use with PKCE for public SPAs,
  or a secret for confidential server-side apps), federated to Okta.
- **M2M client** — client credentials grant for service-to-service calls,
  scoped to this app's resource server.
- **Groups** — Cognito user groups for group/role-based authorization, each
  optionally bound to an IAM `role_arn`.

## Usage

```hcl
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

  web_generate_secret = false
  web_callback_urls   = ["https://portal.acme.com/auth/callback"]
  web_logout_urls     = ["https://portal.acme.com/"]

  groups = [
    { name = "portal-admins", description = "Administrators", precedence = 1, role_arn = aws_iam_role.portal_admin.arn },
    { name = "portal-users", description = "End users", precedence = 10 },
  ]
}
```

## Notes

- **M2M requires scopes.** `create_m2m_client = true` needs a resource server
  with scopes (or explicit `m2m_oauth_scopes`); the client credentials grant
  cannot use reserved OIDC scopes like `openid`.
- **Ordering.** Pass `supported_identity_providers` from the bootstrap module's
  `okta_provider_name` output so the IdP exists before the client references it.
- Set `create_web_client = false` for backend-only apps, or
  `create_m2m_client = false` for UI-only apps.
