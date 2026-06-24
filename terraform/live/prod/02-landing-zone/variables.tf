variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "management_account_role_arn" {
  description = "Execution role ARN to assume in the org management account."
  type        = string
}

variable "landing_zone_version" {
  description = "AWS Control Tower landing-zone version (e.g. 4.0). Verify the current supported version before applying."
  type        = string
}

variable "governed_regions" {
  description = "Regions governed by the landing zone."
  type        = list(string)
  default     = ["eu-west-2"]
}

variable "logging_account_id" {
  description = "Pre-existing centralised-logging account ID referenced by the manifest."
  type        = string
}

variable "security_account_id" {
  description = "Pre-existing audit/security account ID referenced by the manifest."
  type        = string
}

variable "kms_key_arn" {
  description = "CMK ARN used by Control Tower to encrypt config/CloudTrail (pre-existing, in the management account)."
  type        = string
}

variable "region_deny_control" {
  description = "Whether to enable the Control Tower region-deny guardrail."
  type        = bool
  default     = true
}

variable "owner" {
  description = "Owning team for tagging."
  type        = string
  default     = "cloud-platform"
}

variable "cost_centre" {
  description = "Cost-centre code for tagging."
  type        = string
}
