# Standardised customer-managed KMS key. Thin wrapper over terraform-aws-modules/kms
# so every CMK in the platform (recordings, DDB, Kinesis, logs, SNS, CloudWatch Logs —
# SPEC §3) gets rotation, a scoped policy, and an alias consistently.

module "this" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  description             = var.description
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days

  # Scoped policy — never the default root-only/blanket policy.
  key_administrators                 = var.key_administrators
  key_users                          = var.key_users
  key_service_users                  = var.service_principals
  key_statements                     = []
  enable_default_policy              = true
  bypass_policy_lockout_safety_check = false

  # The module prepends "alias/" itself, so pass the bare name.
  aliases = [var.alias_name]

  tags = var.tags
}
