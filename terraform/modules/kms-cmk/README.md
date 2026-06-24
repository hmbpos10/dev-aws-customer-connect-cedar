# kms-cmk

Standardised customer-managed KMS key — a thin wrapper over
[`terraform-aws-modules/kms`](https://registry.terraform.io/modules/terraform-aws-modules/kms/aws)
`4.2.0`. Every CMK in the platform (recordings, DynamoDB, Kinesis, logs, SNS, CloudWatch
Logs — SPEC §3) is created through this module so rotation, a scoped key policy, and an
alias are applied consistently.

## Usage

```hcl
module "recordings_cmk" {
  source = "../../../modules/kms-cmk"

  alias_name         = "connect/recordings"   # bare name; module adds the alias/ prefix
  description        = "CMK for Connect call recordings"
  service_principals = ["connect.amazonaws.com"]
  key_users          = [var.connect_service_role_arn]
  tags               = module.tags.tags
}
```

## Notes

- Pass `alias_name` **without** the `alias/` prefix — the underlying module adds it.
- Rotation is on by default (`enable_key_rotation = true`).
