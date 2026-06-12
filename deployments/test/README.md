# Test deployment

Stands up the full auth-gateway stack into an AWS account for validation.

## What it creates

- A Cognito user pool (`auth-gateway-test`) with the `custom:okta_groups` attribute.
- The group-sync pre-token-generation Lambda + IAM role + log group.
- A hosted UI domain.
- One demo app: web client (PKCE), M2M client (client credentials), a resource
  server with `read`/`write` scopes, and two groups.

By default `create_okta_idp = false`, so it deploys **without** a real Okta app
— the web client federates to `COGNITO`. This lets you validate all the plumbing
before the Okta app is granted.

## Deploy

```bash
cd deployments/test

# uses your default AWS credentials / profile
terraform init
terraform plan
terraform apply
```

If apply fails with a domain-already-exists error, set a different
`domain_prefix` (it must be globally unique):

```bash
terraform apply -var 'domain_prefix=auth-gateway-test-<something-unique>'
```

## Smoke test (M2M, no Okta needed)

After apply, exercise the client-credentials flow end to end:

```bash
BASE=$(terraform output -raw hosted_ui_base_url)
CID=$(terraform output -raw demo_m2m_client_id)
CSECRET=$(terraform output -raw demo_m2m_client_secret)

curl -s -X POST "$BASE/oauth2/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -u "$CID:$CSECRET" \
  -d 'grant_type=client_credentials&scope=https://api.demo.test/read'
```

A JSON response with an `access_token` confirms the resource server, scopes,
and M2M client are wired correctly.

## Wiring in Okta later

1. Request the Okta OIDC app with redirect URI:
   `terraform output -raw okta_idpresponse_redirect_uri`
2. Re-apply with the real values:

   ```bash
   terraform apply \
     -var 'create_okta_idp=true' \
     -var 'okta_oidc_client_id=...' \
     -var 'okta_oidc_client_secret=...' \
     -var 'okta_oidc_issuer=https://your-org.okta.com'
   ```

   The web client's identity provider switches from `COGNITO` to `Okta`.

## Tear down

```bash
terraform destroy
```
