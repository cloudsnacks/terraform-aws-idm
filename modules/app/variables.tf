################################################################################
# General
################################################################################

variable "name" {
  description = "Name of the application. Used as the base name for clients, resource server and groups."
  type        = string
}

variable "user_pool_id" {
  description = "ID of the Cognito user pool created by the bootstrap module."
  type        = string
}

variable "supported_identity_providers" {
  description = "Identity providers available to the web client (e.g. the Okta provider name, and/or COGNITO for native users)."
  type        = list(string)
  default     = ["Okta"]
}

################################################################################
# Resource server + scopes (API authorization)
################################################################################

variable "create_resource_server" {
  description = "Whether to create a resource server and custom OAuth scopes for this app."
  type        = bool
  default     = true
}

variable "resource_server_identifier" {
  description = "Unique identifier for the resource server (e.g. https://api.example.com or an app URN). Required when create_resource_server is true."
  type        = string
  default     = null
}

variable "resource_server_scopes" {
  description = "Custom OAuth scopes exposed by the resource server."
  type = list(object({
    scope_name        = string
    scope_description = string
  }))
  default = []
}

################################################################################
# Web app client (authorization code + PKCE)
################################################################################

variable "create_web_client" {
  description = "Whether to create a user-facing web app client (authorization code grant)."
  type        = bool
  default     = true
}

variable "web_generate_secret" {
  description = "Whether the web client has a secret. Use false for public SPAs (PKCE), true for confidential server-side web apps."
  type        = bool
  default     = false
}

variable "web_callback_urls" {
  description = "Allowed callback (redirect) URLs for the web client."
  type        = list(string)
  default     = []
}

variable "web_logout_urls" {
  description = "Allowed sign-out URLs for the web client."
  type        = list(string)
  default     = []
}

variable "web_allowed_oauth_flows" {
  description = "OAuth flows for the web client. 'code' is recommended (use with PKCE)."
  type        = list(string)
  default     = ["code"]
}

variable "web_oauth_scopes" {
  description = "Base OAuth scopes for the web client (OIDC + reserved scopes)."
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "web_include_resource_scopes" {
  description = "Whether to also grant this app's resource server scopes to the web client."
  type        = bool
  default     = true
}

variable "web_explicit_auth_flows" {
  description = "Explicit auth flows for the web client. Federated apps typically only need refresh token auth."
  type        = list(string)
  default     = ["ALLOW_REFRESH_TOKEN_AUTH"]
}

variable "web_access_token_validity" {
  description = "Web client access token validity (minutes)."
  type        = number
  default     = 60
}

variable "web_id_token_validity" {
  description = "Web client ID token validity (minutes)."
  type        = number
  default     = 60
}

variable "web_refresh_token_validity" {
  description = "Web client refresh token validity (days)."
  type        = number
  default     = 30
}

################################################################################
# Machine-to-machine client (client credentials)
################################################################################

variable "create_m2m_client" {
  description = "Whether to create a machine-to-machine client (client credentials grant). Requires a resource server with scopes."
  type        = bool
  default     = true
}

variable "m2m_oauth_scopes" {
  description = "Resource server scopes granted to the M2M client. Defaults to all of this app's resource server scopes."
  type        = list(string)
  default     = []
}

variable "m2m_access_token_validity" {
  description = "M2M client access token validity (minutes)."
  type        = number
  default     = 60
}

################################################################################
# Authorization groups (group -> role mapping)
################################################################################

variable "groups" {
  description = <<-EOT
    Cognito user groups for role-based authorization. Each group may carry an IAM
    role_arn (assumed via an identity pool) and a precedence. To reflect Okta group
    membership, pair these with a pre-token-generation Lambda on the user pool.
  EOT
  type = list(object({
    name        = string
    description = optional(string)
    precedence  = optional(number)
    role_arn    = optional(string)
  }))
  default = []
}
