# 00-bootstrap is the chicken-and-egg layer: it CREATES the state bucket and lock table.
# Bootstrap it with local state, then uncomment this block and run
# `terraform init -migrate-state` to move state into S3 (one-time manual step, ADR 0004).
#
terraform {
  backend "s3" {
    bucket       = "connect-customer-terraform-github-actions"
    key          = "prod/00-bootstrap/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
