# lambda-fn

VPC-attached Lambda with reserved concurrency, a dead-letter queue, CMK-encrypted
environment variables, and a published named alias (SPEC §7). Thin wrapper over
[`terraform-aws-modules/lambda`](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws)
`8.8.0`, so every function gets its **own** least-privilege execution role
(one role per function — SPEC §7, §9).

## Usage

```hcl
module "router" {
  source = "../../../modules/lambda-fn"

  function_name = "contact-router"
  handler       = "app.handler"
  runtime       = "python3.11"
  source_path   = "${path.module}/src/contact-router"

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_sg.security_group_id]

  dead_letter_target_arn = module.router_dlq.queue_arn
  kms_key_arn            = module.logs_cmk.key_arn

  tags = module.tags.tags
}
```

## Notes

- `source_path` is packaged by the underlying module; for CI builds prefer a prebuilt
  artifact pattern.
- Single prod environment → only a `prod` alias is published (SPEC §7's dev/stg/prod
  reconciled per ADR; CLAUDE.md ignores non-prod scaffolding).
