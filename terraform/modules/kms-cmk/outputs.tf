output "key_arn" {
  description = "ARN of the CMK."
  value       = module.this.key_arn
}

output "key_id" {
  description = "ID of the CMK."
  value       = module.this.key_id
}

output "alias_arn" {
  description = "ARN of the key alias."
  value       = module.this.aliases[var.alias_name].arn
}

output "alias_name" {
  description = "Fully-qualified alias name (with 'alias/' prefix)."
  value       = "alias/${var.alias_name}"
}
