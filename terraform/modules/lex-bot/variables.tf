variable "name" {
  description = "Unique Lex V2 bot name."
  type        = string
}

variable "description" {
  description = "Bot description."
  type        = string
  default     = null
}

variable "role_arn" {
  description = "IAM role ARN Lex assumes to access the bot."
  type        = string
}

variable "child_directed" {
  description = "COPPA child-directed flag (data_privacy)."
  type        = bool
  default     = false
}

variable "idle_session_ttl_in_seconds" {
  description = "Seconds Lex retains conversation context (60-86400)."
  type        = number
  default     = 300
}

variable "locale_id" {
  description = "Language/locale for the bot (e.g. en_GB for the London deployment)."
  type        = string
  default     = "en_GB"
}

variable "nlu_intent_confidence_threshold" {
  description = "Confidence threshold below which fallback intents trigger."
  type        = number
  default     = 0.4
}

variable "voice_id" {
  description = "Amazon Polly voice ID for spoken responses."
  type        = string
  default     = "Amy"
}

variable "alias_name" {
  description = "Bot alias to create via CLI (no native resource — see ADR 0005)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags applied to the bot (Lex tags are set only at creation)."
  type        = map(string)
}
