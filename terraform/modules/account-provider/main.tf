# Computes the canonical cross-account assume-role ARNs for each logical account.
# Terraform modules must NOT declare providers on a caller's behalf (it breaks
# provider configuration and removal), so this helper only derives the role ARNs;
# each layer wires them into its own `provider "aws" { assume_role { ... } }` blocks.

locals {
  role_arns = {
    for name, id in var.account_ids :
    name => "arn:aws:iam::${id}:role/${var.execution_role_name}"
  }
}
