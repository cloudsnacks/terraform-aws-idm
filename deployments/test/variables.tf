variable "region" {
  description = "AWS region for the test deployment."
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  description = "Name of the user pool / resource prefix."
  type        = string
  default     = "idm-test"
}

variable "domain_prefix" {
  description = "Globally-unique Cognito hosted UI domain prefix. Change this if apply fails with a domain-taken error."
  type        = string
  default     = "idm-test-3f9a"
}

# ---------------------------------------------------------------------------
# Okta wiring. Leave create_okta_idp = false until the Okta app is provisioned;
# then set it true and fill the three okta_oidc_* values.
# ---------------------------------------------------------------------------

variable "create_okta_idp" {
  description = "Set true once the Okta OIDC app exists."
  type        = bool
  default     = false
}

variable "okta_oidc_client_id" {
  description = "Okta OIDC client ID (required when create_okta_idp = true)."
  type        = string
  default     = null
}

variable "okta_oidc_client_secret" {
  description = "Okta OIDC client secret (required when create_okta_idp = true)."
  type        = string
  sensitive   = true
  default     = null
}

variable "okta_oidc_issuer" {
  description = "Okta OIDC issuer URL (required when create_okta_idp = true)."
  type        = string
  default     = null
}
