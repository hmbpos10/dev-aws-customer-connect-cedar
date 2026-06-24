terraform {
  backend "s3" {
    bucket         = "connect-customer-terraform-github-actions"
    key            = "prod/30-ai-language/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "connect-customer-terraform-locks"
    encrypt        = true
  }
}
