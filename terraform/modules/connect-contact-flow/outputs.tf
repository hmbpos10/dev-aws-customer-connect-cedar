output "contact_flow_ids" {
  description = "Map of contact-flow name -> contact_flow_id."
  value       = { for k, v in aws_connect_contact_flow.this : k => v.contact_flow_id }
}

output "contact_flow_arns" {
  description = "Map of contact-flow name -> ARN."
  value       = { for k, v in aws_connect_contact_flow.this : k => v.arn }
}
