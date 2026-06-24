output "contact_events_queue_arn" {
  description = "ARN of the contact-events SQS queue."
  value       = module.contact_events_queue.queue_arn
}

output "contact_events_dlq_arn" {
  description = "ARN of the contact-events dead-letter queue."
  value       = module.contact_events_queue.dead_letter_queue_arn
}

output "alerts_topic_arn" {
  description = "ARN of the CMK-encrypted alerts SNS topic."
  value       = module.alerts_topic.topic_arn
}

output "contact_events_function_arn" {
  description = "ARN of the contact-events Lambda function."
  value       = module.contact_events_fn.function_arn
}

output "state_machine_arn" {
  description = "ARN of the contact-orchestration state machine."
  value       = module.contact_orchestrator.state_machine_arn
}
