output "instance_id" {
  description = "Identifier of the hearts-and-bunnies Connect instance (consumed by 30-ai-language, 40-integration)."
  value       = module.connect.instance_id
}

output "instance_arn" {
  description = "ARN of the Connect instance."
  value       = module.connect.instance_arn
}

output "storage_bucket_ids" {
  description = "Map of operational storage bucket purpose -> bucket name."
  value       = { for k, m in module.storage : k => m.s3_bucket_id }
}

output "queue_arns" {
  description = "Map of queue name -> ARN (consumed by downstream flows/integration)."
  value       = module.routing.queue_arns
}

output "routing_profile_ids" {
  description = "Map of routing-profile name -> id."
  value       = module.routing.routing_profile_ids
}

output "security_profile_ids" {
  description = "Map of security-profile name -> id."
  value       = module.security.security_profile_ids
}

output "contact_flow_arns" {
  description = "Map of contact-flow name -> ARN."
  value       = module.contact_flows.contact_flow_arns
}
