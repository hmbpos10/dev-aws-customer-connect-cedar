variable "project" {
  description = "Project identifier applied as the Project tag."
  type        = string
  default     = "connect-customer"
}

variable "environment" {
  description = "Deployment environment (single production environment for this build)."
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owning team or individual responsible for the resources."
  type        = string
}

variable "cost_centre" {
  description = "Cost-centre code for chargeback (SPEC §3 cost-centre tag)."
  type        = string
}

variable "data_classification" {
  description = "Data classification for the resources (e.g. public, internal, confidential, pii)."
  type        = string

  validation {
    condition     = contains(["public", "internal", "confidential", "pii", "pci"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, pii, pci."
  }
}

variable "extra_tags" {
  description = "Additional tags merged on top of the standard set."
  type        = map(string)
  default     = {}
}
