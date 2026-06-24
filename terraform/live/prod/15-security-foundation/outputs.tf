# CMK ARNs/IDs are consumed by downstream layers (20-connect-core storage encryption,
# 40-integration Lambda/SNS, Zone 4 DynamoDB/Kinesis) via terraform_remote_state.

output "cmk_key_arns" {
  description = "Map of CMK domain -> key ARN (recordings, dynamodb, kinesis, logs, sns, secrets)."
  value       = { for k, m in module.cmk : k => m.key_arn }
}

output "cmk_key_ids" {
  description = "Map of CMK domain -> key ID."
  value       = { for k, m in module.cmk : k => m.key_id }
}

output "cmk_alias_names" {
  description = "Map of CMK domain -> fully-qualified alias name."
  value       = { for k, m in module.cmk : k => m.alias_name }
}

output "permission_boundary_arn" {
  description = "ARN of the workload permission boundary attached to every downstream role (SPEC §9)."
  value       = aws_iam_policy.permission_boundary.arn
}

output "directory_id" {
  description = "Managed Microsoft AD directory ID (consumed by 20-connect-core for EXISTING_DIRECTORY auth)."
  value       = aws_directory_service_directory.connect.id
}

output "directory_dns_ip_addresses" {
  description = "DNS IP addresses of the Managed AD directory."
  value       = aws_directory_service_directory.connect.dns_ip_addresses
}

output "directory_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the directory admin password."
  value       = aws_secretsmanager_secret.directory_admin.arn
}

output "permission_set_arns" {
  description = "Map of Identity Center permission set name -> ARN."
  value       = { for k, ps in aws_ssoadmin_permission_set.this : k => ps.arn }
}
