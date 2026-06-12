# auth-gateway

A Terraform IDM module that uses **Okta** as the identity source (users & groups)
and **Amazon Cognito** as the application authorization layer (app auth rules,
OAuth clients, scopes, and group/role mappings).

A single Okta OIDC application is federated into one Cognito user pool. Each
downstream application then gets its own authorization surface — OAuth clients,
API scopes, and groups — without requesting additional Okta apps.

```
                +-------------------+
   users +----> |       Okta        |  identity source (users, groups)
   groups       |  (1 OIDC app)     |
                +---------+---------+
                          | OIDC federation
                          v
                +-------------------+
                |  Cognito user pool|  <- this module (bootstrap)
                |  + Okta IdP       |
                |  + hosted UI      |
                +---------+---------+
                          | per-app authorization (modules/app)
        +-----------------+-----------------+
        v                                   v
  app: portal                         app: billing-service
  - web client (PKCE)                 - m2m client (client_credentials)
  - resource server + scopes          - resource server + scopes
  - groups -> roles
```

## Layout

| Path            | Purpose                                                              |
| --------------- | ------------------------------------------------------------------- |
| `./`            | Bootstrap: user pool, Okta OIDC IdP, hosted UI domain, group claim. |
| `modules/app`   | Per-application: OAuth clients, resource server/scopes, groups.     |
| `examples/complete` | End-to-end example wiring the bootstrap to two apps.            |

## Usage

```hcl
module "auth_gateway" {
  source = "github.com/swibrow/auth-gateway"

  name   = "acme-idm"
  domain = "acme-idm"

  okta_oidc_client_id     = var.okta_oidc_client_id
  okta_oidc_client_secret = var.okta_oidc_client_secret
  okta_oidc_issuer        = "https://acme.okta.com"
}

module "portal" {
  source = "github.com/swibrow/auth-gateway//modules/app"

  name         = "portal"
  user_pool_id = module.auth_gateway.user_pool_id

  supported_identity_providers = [module.auth_gateway.okta_provider_name]

  resource_server_identifier = "https://api.portal.acme.com"
  resource_server_scopes = [
    { scope_name = "read", scope_description = "Read portal data" },
  ]

  web_callback_urls = ["https://portal.acme.com/auth/callback"]
  groups            = [{ name = "portal-admins", precedence = 1 }]
}
```

## Requesting the Okta app

Since Okta is not directly managed here, request **one** OIDC web application
with:

- **Sign-in redirect URI:** `https://<hosted_ui_domain>/oauth2/idpresponse`
- **Grant types:** Authorization Code
- **Scopes:** `openid`, `profile`, `email`, `groups`
- A **groups claim** added to the ID token (claim name `groups`).

Feed the returned client ID, client secret, and issuer into the bootstrap module.

## Okta groups → Cognito groups

The Okta `groups` claim is mapped into the user pool attribute
`custom:okta_groups` (see `okta_attribute_mapping`). Cognito does **not**
automatically place federated users into Cognito groups, so to drive
group→IAM-role authorization from Okta membership, attach a
**pre-token-generation Lambda** via `lambda_config.pre_token_generation` that
reads `custom:okta_groups` and injects `cognito:groups` / role claims. The
`modules/app` `groups` (with `role_arn`) define the canonical RBAC targets.

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5    |
| aws       | >= 5.0    |

See `variables.tf` for the full set of inputs and `outputs.tf` for outputs.
