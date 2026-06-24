# Connect instance ID comes from 20-connect-core.
data "terraform_remote_state" "connect_core" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/20-connect-core/terraform.tfstate"
    region = "eu-west-2"
  }
}
