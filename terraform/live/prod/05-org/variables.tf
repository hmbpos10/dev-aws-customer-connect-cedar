variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "management_account_role_arn" {
  description = "Execution role ARN to assume in the org management account."
  type        = string
}

variable "contact_centre_ou_name" {
  description = "Name of the dedicated contact-centre OU (SPEC §4)."
  type        = string
  default     = "ContactCentre"
}

variable "vended_accounts" {
  description = "Member accounts to vend through Account Factory (CT-enrolled). Keyed by logical name."
  type = map(object({
    account_email       = string
    account_name        = string
    sso_user_email      = string
    sso_user_first_name = string
    sso_user_last_name  = string
    organizational_unit = string
  }))
  default = {}
}

variable "account_factory_path_id" {
  description = "Service Catalog path ID for the Account Factory product (required when the portfolio exposes multiple paths)."
  type        = string
  default     = null
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
