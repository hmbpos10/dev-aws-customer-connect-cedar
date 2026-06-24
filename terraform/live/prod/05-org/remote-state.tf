# Org root ID comes from the landing-zone layer.
data "terraform_remote_state" "landing_zone" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/02-landing-zone/terraform.tfstate"
    region = "eu-west-2"
  }
}
