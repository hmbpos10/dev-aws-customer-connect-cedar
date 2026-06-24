output "hours_of_operation_ids" {
  description = "Map of hours-of-operation name -> id."
  value       = { for k, v in aws_connect_hours_of_operation.this : k => v.hours_of_operation_id }
}

output "queue_ids" {
  description = "Map of queue name -> queue_id."
  value       = { for k, v in aws_connect_queue.this : k => v.queue_id }
}

output "queue_arns" {
  description = "Map of queue name -> ARN."
  value       = { for k, v in aws_connect_queue.this : k => v.arn }
}

output "routing_profile_ids" {
  description = "Map of routing-profile name -> id."
  value       = { for k, v in aws_connect_routing_profile.this : k => v.routing_profile_id }
}
