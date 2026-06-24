# The landing zone is managed from the ORG MANAGEMENT account.
provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.management_account_role_arn
  }

  default_tags {
    tags = module.tags.tags
  }
}
