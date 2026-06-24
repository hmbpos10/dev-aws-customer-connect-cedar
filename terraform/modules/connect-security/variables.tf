variable "instance_id" {
  description = "Identifier of the Amazon Connect instance."
  type        = string
}

variable "security_profiles" {
  description = "Map of custom least-privilege security profiles keyed by name (SPEC §5: not blanket Admin). Permissions are Connect security-profile permission strings."
  type = map(object({
    description = optional(string)
    permissions = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in var.security_profiles : !contains(p.permissions, "*")
    ])
    error_message = "Security profiles must not use a '*' permission (no blanket Admin) — SPEC §5."
  }
}

variable "hierarchy_levels" {
  description = "Ordered list of up to five agent-hierarchy level names (level one first). Empty list creates no hierarchy structure."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.hierarchy_levels) <= 5
    error_message = "Amazon Connect supports at most five hierarchy levels."
  }
}

variable "tags" {
  description = "Tags applied to security profiles."
  type        = map(string)
}
