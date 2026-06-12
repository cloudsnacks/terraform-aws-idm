variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "okta_oidc_client_id" {
  description = "OIDC client ID of the requested Okta application."
  type        = string
}

variable "okta_oidc_client_secret" {
  description = "OIDC client secret of the requested Okta application."
  type        = string
  sensitive   = true
}

variable "okta_oidc_issuer" {
  description = "Okta OIDC issuer URL."
  type        = string
}
