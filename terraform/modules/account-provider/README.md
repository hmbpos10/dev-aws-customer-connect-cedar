# account-provider

Derives the cross-account `assume_role` ARNs for each logical account
(`management`, `connect`, `logging`, `security`, `shared`). Modules must not declare
providers for callers, so this helper only computes ARNs; each layer wires them into its
own provider blocks.

## Usage

```hcl
module "accounts" {
  source      = "../../../modules/account-provider"
  account_ids = var.account_ids   # { management = "1111...", connect = "2222...", ... }
}

provider "aws" {
  region = "eu-west-2"
  assume_role { role_arn = module.accounts.role_arns["connect"] }
}
```
