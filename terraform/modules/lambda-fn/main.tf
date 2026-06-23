# VPC-attached Lambda with reserved concurrency, DLQ, CMK-encrypted env, and a published
# prod alias (SPEC §7). Thin wrapper over terraform-aws-modules/lambda so every function
# gets its own least-privilege execution role (one role per function — SPEC §7, §9).

module "function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name = var.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  source_path   = var.source_path

  # Private VPC attachment (never public).
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  attach_network_policy  = true

  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Dead-letter queue for failed async events.
  dead_letter_target_arn    = var.dead_letter_target_arn
  attach_dead_letter_policy = true

  # CMK encryption for environment variables.
  kms_key_arn           = var.kms_key_arn
  environment_variables = var.environment_variables

  # Publish a version so the alias can target it.
  publish = true

  tags = var.tags
}

# Named alias (the module exposes alias creation as a separate submodule).
module "alias" {
  source  = "terraform-aws-modules/lambda/aws//modules/alias"
  version = "8.8.0"

  name             = var.alias_name
  function_name    = module.function.lambda_function_name
  function_version = module.function.lambda_function_version
}
