output "state_bucket_name" {
  description = "S3 bucket holding Terraform state."
  value       = module.state_bucket.s3_bucket_id
}

output "lock_table_name" {
  description = "DynamoDB table used for state locking."
  value       = aws_dynamodb_table.locks.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "plan_role_arn" {
  description = "Read-only role assumed by PR/feature-branch plan jobs (set as TF_PLAN_ROLE_ARN)."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Privileged role assumed by main apply jobs (set as TF_APPLY_ROLE_ARN)."
  value       = aws_iam_role.apply.arn
}
