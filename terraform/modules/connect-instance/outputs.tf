output "instance_id" {
  description = "Identifier of the Amazon Connect instance."
  value       = aws_connect_instance.this.id
}

output "instance_arn" {
  description = "ARN of the Amazon Connect instance."
  value       = aws_connect_instance.this.arn
}

output "service_role" {
  description = "Service-linked role ARN of the instance."
  value       = aws_connect_instance.this.service_role
}
