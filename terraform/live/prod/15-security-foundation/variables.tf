variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "connect_account_role_arn" {
  description = "Execution role ARN to assume in the Connect account (CMKs, IAM boundary, Secrets, Directory)."
  type        = string
}

variable "management_account_role_arn" {
  description = "Execution role ARN to assume in the management account for IAM Identity Center permission sets."
  type        = string
}

variable "key_administrators" {
  description = "IAM ARNs allowed to administer (not use) the platform CMKs. Typically a break-glass/platform-admin role."
  type        = list(string)
  default     = []
}

variable "directory_name" {
  description = "Fully-qualified DNS name for the Managed Microsoft AD used for Connect agent auth (SPEC §4 identity federation)."
  type        = string
  default     = "corp.hearts-and-bunnies.internal"
}

variable "directory_edition" {
  description = "Managed Microsoft AD edition."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Enterprise"], var.directory_edition)
    error_message = "directory_edition must be Standard or Enterprise."
  }
}

variable "directory_admin_secret_name" {
  description = "Secrets Manager secret name holding the Managed AD admin password."
  type        = string
  default     = "connect/directory/admin-password"
}

variable "permission_sets" {
  description = "IAM Identity Center permission sets keyed by name. managed_policy_arns are AWS-managed policy ARNs attached to the set."
  type = map(object({
    description         = string
    session_duration    = optional(string, "PT1H")
    managed_policy_arns = optional(list(string), [])
  }))
  default = {}
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
