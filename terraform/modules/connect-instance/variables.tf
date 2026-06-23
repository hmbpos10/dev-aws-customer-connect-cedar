variable "instance_alias" {
  description = "Alias for the Amazon Connect instance (e.g. hearts-and-bunnies)."
  type        = string
}

variable "identity_management_type" {
  description = "Identity management for the instance. SAML or EXISTING_DIRECTORY — never CONNECT_MANAGED for production (SPEC §5: not default admin)."
  type        = string
  default     = "SAML"

  validation {
    condition     = contains(["SAML", "EXISTING_DIRECTORY"], var.identity_management_type)
    error_message = "Use SAML or EXISTING_DIRECTORY; CONNECT_MANAGED is disallowed for production."
  }
}

variable "directory_id" {
  description = "Directory ID, required when identity_management_type is EXISTING_DIRECTORY."
  type        = string
  default     = null
}

variable "inbound_calls_enabled" {
  description = "Whether inbound calls are enabled."
  type        = bool
  default     = true
}

variable "outbound_calls_enabled" {
  description = "Whether outbound calls are enabled."
  type        = bool
  default     = true
}

variable "contact_lens_enabled" {
  description = "Whether Contact Lens is enabled (SPEC §6 redaction/analytics)."
  type        = bool
  default     = true
}

variable "recordings_bucket_name" {
  description = "S3 bucket for call recordings (CALL_RECORDINGS)."
  type        = string
}

variable "transcripts_bucket_name" {
  description = "S3 bucket for chat transcripts (CHAT_TRANSCRIPTS)."
  type        = string
}

variable "exports_bucket_name" {
  description = "S3 bucket for exported reports (SCHEDULED_REPORTS)."
  type        = string
}

variable "kms_key_arn" {
  description = "Full ARN of the CMK used to encrypt all instance storage (SPEC §3 CMK everywhere)."
  type        = string
}

variable "ctr_kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream receiving Contact Trace Records. Null disables CTR streaming (wired by the analytics layer)."
  type        = string
  default     = null
}
