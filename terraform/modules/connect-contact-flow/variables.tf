variable "instance_id" {
  description = "Identifier of the Amazon Connect instance."
  type        = string
}

variable "contact_flows" {
  description = "Map of contact flows keyed by name. template_path points at a .tftpl in the caller; template_vars are interpolated into it (e.g. queue ARNs, Lex bot aliases)."
  type = map(object({
    description   = optional(string)
    type          = optional(string, "CONTACT_FLOW")
    template_path = string
    template_vars = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to contact flows."
  type        = map(string)
}
