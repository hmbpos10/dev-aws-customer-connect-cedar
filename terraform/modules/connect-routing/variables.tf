variable "instance_id" {
  description = "Identifier of the Amazon Connect instance."
  type        = string
}

variable "hours_of_operation" {
  description = "Map of hours-of-operation definitions keyed by a stable name."
  type = map(object({
    description = optional(string)
    time_zone   = string
    config = list(object({
      day        = string
      start_time = object({ hours = number, minutes = number })
      end_time   = object({ hours = number, minutes = number })
    }))
  }))
}

variable "queues" {
  description = "Map of queue definitions keyed by a stable name. hours_of_operation_key references a key in var.hours_of_operation."
  type = map(object({
    description             = optional(string)
    hours_of_operation_key  = string
    max_contacts            = optional(number)
    status                  = optional(string, "ENABLED")
    outbound_caller_id_name = optional(string)
  }))
  default = {}
}

variable "routing_profiles" {
  description = "Map of routing-profile definitions keyed by a stable name. default_outbound_queue_key and queue_configs[].queue_key reference keys in var.queues."
  type = map(object({
    description                = string
    default_outbound_queue_key = string
    media_concurrencies = list(object({
      channel     = string
      concurrency = number
    }))
    queue_configs = optional(list(object({
      channel   = string
      delay     = number
      priority  = number
      queue_key = string
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to routing resources."
  type        = map(string)
}
