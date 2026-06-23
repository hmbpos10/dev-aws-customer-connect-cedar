# AI/language services live in the CONNECT account, attached to the instance.
provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.connect_account_role_arn
  }

  default_tags {
    tags = module.tags.tags
  }
}
