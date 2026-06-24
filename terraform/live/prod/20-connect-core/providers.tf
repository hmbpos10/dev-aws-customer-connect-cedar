# Connect core lives in the CONNECT account.
provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.connect_account_role_arn
  }

  default_tags {
    tags = module.tags.tags
  }
}
