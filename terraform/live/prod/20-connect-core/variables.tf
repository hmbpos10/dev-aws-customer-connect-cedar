variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "connect_account_role_arn" {
  description = "Execution role ARN to assume in the Connect account."
  type        = string
}

variable "instance_alias" {
  description = "Alias for the Amazon Connect instance."
  type        = string
  default     = "hearts-and-bunnies"
}

variable "identity_management_type" {
  description = "Identity management for the instance: SAML or EXISTING_DIRECTORY (never CONNECT_MANAGED — SPEC §5)."
  type        = string
  default     = "EXISTING_DIRECTORY"

  validation {
    condition     = contains(["SAML", "EXISTING_DIRECTORY"], var.identity_management_type)
    error_message = "Use SAML or EXISTING_DIRECTORY; CONNECT_MANAGED is disallowed for production."
  }
}

variable "owner" {
  description = "Owning team for tagging."
  type        = string
  default     = "contact-centre-platform"
}

variable "cost_centre" {
  description = "Cost-centre code for tagging."
  type        = string
}
