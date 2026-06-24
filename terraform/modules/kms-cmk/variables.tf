variable "alias_name" {
  description = "Alias for the CMK, without the 'alias/' prefix (e.g. 'connect/recordings')."
  type        = string
}

variable "description" {
  description = "Human-readable description of what the key protects."
  type        = string
}

variable "service_principals" {
  description = "AWS service principals granted use of the key via the key policy (e.g. connect.amazonaws.com, logs.eu-west-2.amazonaws.com)."
  type        = list(string)
  default     = []
}

variable "key_administrators" {
  description = "IAM ARNs allowed to administer (not use) the key."
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "IAM ARNs allowed to use the key for crypto operations."
  type        = list(string)
  default     = []
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Waiting period before key deletion completes."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to the key and alias."
  type        = map(string)
}
