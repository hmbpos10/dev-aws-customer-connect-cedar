# Primary provider is the CONNECT account: CMKs, IAM permission boundary, Secrets
# Manager, and the Managed AD directory all live alongside the workloads they protect.
provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.connect_account_role_arn
  }

  default_tags {
    tags = module.tags.tags
  }
}

# IAM Identity Center is an organization-level service administered from the MANAGEMENT
# account (or its delegated admin). Permission sets are created through this aliased
# provider; the SSO instance itself is discovered, never created here.
provider "aws" {
  alias  = "management"
  region = var.region

  assume_role {
    role_arn = var.management_account_role_arn
  }

  default_tags {
    tags = module.tags.tags
  }
}
