variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "connect_account_role_arn" {
  description = "Execution role ARN to assume in the Connect account."
  type        = string
}

variable "bot_name" {
  description = "Lex V2 bot name."
  type        = string
  default     = "hearts-and-bunnies-support"
}

variable "bot_alias_name" {
  description = "Lex V2 bot alias (created via CLI — no native resource, ADR 0005)."
  type        = string
  default     = "prod"
}

variable "locale_id" {
  description = "Bot locale (London deployment)."
  type        = string
  default     = "en_GB"
}

variable "voice_id" {
  description = "Amazon Polly voice for spoken bot responses."
  type        = string
  default     = "Amy"
}

variable "polly_lexicons" {
  description = "Polly pronunciation lexicons keyed by name. content is PLS XML; pushed via CLI (no native resource — ADR 0005)."
  type = map(object({
    content = string
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
