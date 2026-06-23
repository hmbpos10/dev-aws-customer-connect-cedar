output "role_arns" {
  description = "Map of logical account name -> cross-account execution role ARN to assume."
  value       = local.role_arns
}
