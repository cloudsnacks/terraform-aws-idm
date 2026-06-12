################################################################################
# General
################################################################################

variable "name" {
  description = "Name of the Cognito user pool and base name for related resources."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# User pool
################################################################################

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the user pool."
  type        = bool
  default     = true
}

variable "username_attributes" {
  description = "Attributes that can be used as a username when a user signs up (e.g. email, phone_number)."
  type        = list(string)
  default     = ["email"]
}

variable "auto_verified_attributes" {
  description = "Attributes to be auto-verified (e.g. email, phone_number)."
  type        = list(string)
  default     = ["email"]
}

variable "mfa_configuration" {
  description = "Multi-factor authentication mode: OFF, ON, or OPTIONAL."
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be one of OFF, ON, OPTIONAL."
  }
}

variable "advanced_security_mode" {
  description = "Advanced security (threat protection) mode: OFF, AUDIT, or ENFORCED."
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be one of OFF, AUDIT, ENFORCED."
  }
}

variable "allow_admin_create_user_only" {
  description = "If true, only administrators can create users (self-registration disabled). Federated users are still created on first login."
  type        = bool
  default     = true
}

variable "password_policy" {
  description = "Password policy for native (non-federated) users."
  type = object({
    minimum_length                   = optional(number, 12)
    require_lowercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    require_uppercase                = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)
  })
  default = {}
}

variable "account_recovery_mechanisms" {
  description = "Ordered list of account recovery mechanisms."
  type = list(object({
    name     = string
    priority = number
  }))
  default = [
    { name = "verified_email", priority = 1 },
  ]
}

variable "schema_attributes" {
  description = "Custom schema attributes to add to the user pool. The okta_groups attribute is used to receive the Okta groups claim."
  type = list(object({
    name                = string
    attribute_data_type = optional(string, "String")
    mutable             = optional(bool, true)
    required            = optional(bool, false)
    min_length          = optional(number, 0)
    max_length          = optional(number, 2048)
  }))
  default = [
    {
      name                = "okta_groups"
      attribute_data_type = "String"
      mutable             = true
      required            = false
    },
  ]
}

variable "lambda_config" {
  description = <<-EOT
    Optional Lambda trigger configuration for the user pool. Use pre_token_generation
    to wire a function that maps the Okta groups claim (custom:okta_groups) into the
    cognito:groups claim so that group->IAM-role authorization reflects Okta membership.
  EOT
  type = object({
    pre_token_generation = optional(string)
    pre_authentication   = optional(string)
    post_authentication  = optional(string)
    post_confirmation    = optional(string)
    pre_sign_up          = optional(string)
    custom_message       = optional(string)
    user_migration       = optional(string)
  })
  default = null
}

################################################################################
# Hosted UI domain
################################################################################

variable "domain" {
  description = "Cognito hosted UI domain. A prefix for an amazoncognito.com domain, or a full custom FQDN when custom_domain_certificate_arn is set. Set to null to skip."
  type        = string
  default     = null
}

variable "custom_domain_certificate_arn" {
  description = "ACM certificate ARN (in us-east-1) for a custom hosted UI domain. When set, var.domain must be a full FQDN."
  type        = string
  default     = null
}

################################################################################
# Okta OIDC identity provider (single app)
################################################################################

variable "create_okta_idp" {
  description = "Whether to create the Okta OIDC identity provider. Set to false to stand up the pool and app clients before the Okta app exists (apps then use COGNITO as the provider)."
  type        = bool
  default     = true
}

variable "okta_provider_name" {
  description = "Name of the Okta identity provider as it appears in Cognito and in app client supported_identity_providers."
  type        = string
  default     = "Okta"
}

variable "okta_oidc_client_id" {
  description = "OIDC client ID of the Okta application provisioned for this setup. Required when create_okta_idp is true."
  type        = string
  default     = null
}

variable "okta_oidc_client_secret" {
  description = "OIDC client secret of the Okta application. Required when create_okta_idp is true."
  type        = string
  sensitive   = true
  default     = null
}

variable "okta_oidc_issuer" {
  description = "Okta OIDC issuer URL, e.g. https://your-org.okta.com or https://your-org.okta.com/oauth2/default. Cognito uses it for OIDC discovery. Required when create_okta_idp is true."
  type        = string
  default     = null
}

variable "okta_authorize_scopes" {
  description = "Space-delimited OAuth scopes requested from Okta. Include 'groups' to receive group membership."
  type        = string
  default     = "openid profile email groups"
}

variable "okta_attributes_request_method" {
  description = "HTTP method Cognito uses to fetch the Okta userinfo endpoint (GET or POST)."
  type        = string
  default     = "GET"
}

variable "okta_oidc_endpoints" {
  description = "Optional explicit Okta endpoints if OIDC discovery is not used (authorize_url, token_url, attributes_url, jwks_uri)."
  type        = map(string)
  default     = {}
}

variable "okta_attribute_mapping" {
  description = "Mapping of Cognito user pool attributes (keys) to Okta claims (values)."
  type        = map(string)
  default = {
    email                = "email"
    given_name           = "given_name"
    family_name          = "family_name"
    username             = "sub"
    "custom:okta_groups" = "groups"
  }
}

################################################################################
# Group sync Lambda
################################################################################

variable "create_group_sync_lambda" {
  description = "Whether to create the pre-token-generation Lambda that maps Okta groups (custom:okta_groups) into cognito:groups. When true, it is wired as pre_token_generation unless lambda_config.pre_token_generation is set explicitly."
  type        = bool
  default     = false
}

variable "group_sync_lambda_runtime" {
  description = "Runtime for the group-sync Lambda."
  type        = string
  default     = "python3.12"
}

variable "group_sync_lambda_log_retention_days" {
  description = "CloudWatch log retention (days) for the group-sync Lambda."
  type        = number
  default     = 14
}
