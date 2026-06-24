output "security_profile_ids" {
  description = "Map of security-profile name -> security_profile_id."
  value       = { for k, v in aws_connect_security_profile.this : k => v.security_profile_id }
}

output "security_profile_arns" {
  description = "Map of security-profile name -> ARN."
  value       = { for k, v in aws_connect_security_profile.this : k => v.arn }
}
