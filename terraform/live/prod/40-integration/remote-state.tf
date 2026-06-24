# Network (private subnets + Lambda SG) from 10-network.
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/10-network/terraform.tfstate"
    region = "eu-west-2"
  }
}

# CMKs (logs, sns) from 15-security-foundation.
data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/15-security-foundation/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Connect instance ARN from 20-connect-core (EventBridge source filter).
data "terraform_remote_state" "connect_core" {
  backend = "s3"

  config = {
    bucket = "connect-customer-terraform-github-actions"
    key    = "prod/20-connect-core/terraform.tfstate"
    region = "eu-west-2"
  }
}
