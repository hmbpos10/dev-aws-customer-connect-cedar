variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "description" {
  description = "Function description."
  type        = string
  default     = null
}

variable "handler" {
  description = "Entrypoint handler (e.g. app.handler)."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g. python3.11)."
  type        = string
  default     = "python3.11"
}

variable "source_path" {
  description = "Path to the function source to package."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "Private subnet IDs — Lambda runs VPC-attached, never public (SPEC §7)."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the function's ENIs."
  type        = list(string)
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency cap (SPEC §7)."
  type        = number
  default     = 10
}

variable "dead_letter_target_arn" {
  description = "SQS/SNS DLQ target ARN for failed async invocations (SPEC §7)."
  type        = string
}

variable "kms_key_arn" {
  description = "CMK ARN for environment-variable encryption (SPEC §3)."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "alias_name" {
  description = "Named alias to publish (single prod env — SPEC §7 aliases reconciled to prod only; ADR notes)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags applied to the function."
  type        = map(string)
}
