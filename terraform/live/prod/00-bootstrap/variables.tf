variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform state (CLAUDE.md backend)."
  type        = string
  default     = "connect-customer-terraform-github-actions"
}

variable "lock_table_name" {
  description = "DynamoDB table for state locking (ADR 0004)."
  type        = string
  default     = "connect-customer-terraform-locks"
}

variable "github_org" {
  description = "GitHub org/owner that hosts the repo (SPEC §12 trust policy)."
  type        = string
  default     = "hmbpos10"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "dev-aws-customer-connect-cedar"
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

variable "terraform_execution_role_arns" {
  description = <<-EOT
    Cross-account Terraform execution role ARNs the CI plan/apply roles may assume
    (the connect_account_role_arn / management_account_role_arn each downstream layer
    assumes in providers.tf). Empty = grant nothing yet; populate once the member-account
    execution roles exist, then re-apply this layer. Scope to exact role ARNs, never "*".
  EOT
  type        = list(string)
  default     = []
}
