################################################################################
# Auth Gateway - Bootstrap
#
# Provisions the top-level Cognito user pool, federates it to a single Okta
# OIDC application, and exposes the hosted UI domain. Per-app authorization
# (app clients, resource servers, scopes, groups) is handled by the modules/app
# submodule.
################################################################################

data "aws_region" "current" {}

locals {
  is_custom_domain = var.custom_domain_certificate_arn != null

  hosted_ui_domain = var.domain == null ? null : (
    local.is_custom_domain
    ? var.domain
    : "${var.domain}.auth.${data.aws_region.current.region}.amazoncognito.com"
  )

  okta_provider_details = merge(
    {
      client_id                 = var.okta_oidc_client_id
      client_secret             = var.okta_oidc_client_secret
      oidc_issuer               = var.okta_oidc_issuer
      authorize_scopes          = var.okta_authorize_scopes
      attributes_request_method = var.okta_attributes_request_method
    },
    var.okta_oidc_endpoints,
  )

  create_group_sync_lambda = var.create_group_sync_lambda

  group_sync_lambda_arn = local.create_group_sync_lambda ? aws_lambda_function.group_sync[0].arn : null

  # The group-sync Lambda fills pre_token_generation only when the caller has
  # not supplied their own. Any explicit lambda_config always wins.
  group_sync_override = (
    local.group_sync_lambda_arn != null && try(var.lambda_config.pre_token_generation, null) == null
    ? { pre_token_generation = local.group_sync_lambda_arn }
    : {}
  )

  effective_lambda_config = (
    var.lambda_config == null && length(local.group_sync_override) == 0
    ? null
    : merge(
      var.lambda_config == null ? {} : var.lambda_config,
      local.group_sync_override,
    )
  )
}

resource "aws_cognito_user_pool" "this" {
  name = var.name

  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"

  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes
  mfa_configuration        = var.mfa_configuration

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = true
    }
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only
  }

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    require_uppercase                = var.password_policy.require_uppercase
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  account_recovery_setting {
    dynamic "recovery_mechanism" {
      for_each = var.account_recovery_mechanisms
      content {
        name     = recovery_mechanism.value.name
        priority = recovery_mechanism.value.priority
      }
    }
  }

  dynamic "schema" {
    for_each = { for s in var.schema_attributes : s.name => s }
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      mutable                  = schema.value.mutable
      required                 = schema.value.required
      developer_only_attribute = false

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [1] : []
        content {
          min_length = schema.value.min_length
          max_length = schema.value.max_length
        }
      }
    }
  }

  dynamic "lambda_config" {
    for_each = local.effective_lambda_config != null ? [local.effective_lambda_config] : []
    content {
      pre_token_generation = lookup(lambda_config.value, "pre_token_generation", null)
      pre_authentication   = lookup(lambda_config.value, "pre_authentication", null)
      post_authentication  = lookup(lambda_config.value, "post_authentication", null)
      post_confirmation    = lookup(lambda_config.value, "post_confirmation", null)
      pre_sign_up          = lookup(lambda_config.value, "pre_sign_up", null)
      custom_message       = lookup(lambda_config.value, "custom_message", null)
      user_migration       = lookup(lambda_config.value, "user_migration", null)
    }
  }

  tags = var.tags

  lifecycle {
    # Schema attributes cannot be removed once created; ignore ordering churn.
    ignore_changes = [schema]
  }
}

resource "aws_cognito_identity_provider" "okta" {
  count = var.create_okta_idp ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = var.okta_provider_name
  provider_type = "OIDC"

  provider_details  = local.okta_provider_details
  attribute_mapping = var.okta_attribute_mapping

  lifecycle {
    precondition {
      condition = var.okta_oidc_client_id != null && var.okta_oidc_client_secret != null && var.okta_oidc_issuer != null
      error_message = "okta_oidc_client_id, okta_oidc_client_secret and okta_oidc_issuer are required when create_okta_idp is true."
    }
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.domain != null ? 1 : 0

  domain          = var.domain
  user_pool_id    = aws_cognito_user_pool.this.id
  certificate_arn = var.custom_domain_certificate_arn
}
