output "function_arn" {
  description = "Unqualified ARN of the Lambda function."
  value       = module.function.lambda_function_arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = module.function.lambda_function_name
}

output "qualified_arn" {
  description = "Version-qualified ARN of the Lambda function."
  value       = module.function.lambda_function_qualified_arn
}

output "role_arn" {
  description = "ARN of the function's dedicated execution role."
  value       = module.function.lambda_role_arn
}

output "role_name" {
  description = "Name of the function's dedicated execution role (for attaching extra inline policies)."
  value       = module.function.lambda_role_name
}

output "alias_arn" {
  description = "ARN of the published alias."
  value       = module.alias.lambda_alias_arn
}
