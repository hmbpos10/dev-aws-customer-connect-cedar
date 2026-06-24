# CMKs and the Managed AD directory come from 15-security-foundation.
data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/15-security-foundation/terraform.tfstate"
    region = "eu-west-2"
  }
}
