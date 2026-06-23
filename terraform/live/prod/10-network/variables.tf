variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "eu-west-2"
}

variable "connect_account_role_arn" {
  description = "Execution role ARN to assume in the Connect account."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the platform VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across (eu-west-2 has 3)."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.40.0.0/20", "10.40.16.0/20", "10.40.32.0/20"]
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
