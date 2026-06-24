variable "account_ids" {
  description = "Map of logical account name -> 12-digit AWS account ID (management, connect, logging, security, shared)."
  type        = map(string)

  validation {
    condition     = alltrue([for id in values(var.account_ids) : can(regex("^[0-9]{12}$", id))])
    error_message = "Every account ID must be exactly 12 digits."
  }
}

variable "execution_role_name" {
  description = "Name of the cross-account execution role to assume in each target account."
  type        = string
  default     = "TerraformExecution"
}
