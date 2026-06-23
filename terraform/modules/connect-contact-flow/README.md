# connect-contact-flow

Provisions Amazon Connect contact flows from **templated JSON** (SPEC §5 marks IVR/flows
as `CLI` — templated; see ADR 0005). Flow definitions are `.tftpl` files in the
caller; `templatefile()` injects runtime references (queue ARNs, Lex bot aliases) so flows
are never hardcoded inline. `jq` validates the rendered JSON in pre-commit. (The plain
`.tftpl` extension — not `.json.tftpl` — keeps Checkov's JSON parser from choking on the
unrendered `${...}` interpolation.)

## Usage

```hcl
module "contact_flows" {
  source      = "../../../modules/connect-contact-flow"
  instance_id = module.connect.instance_id

  contact_flows = {
    "inbound-main" = {
      description   = "Main inbound IVR"
      template_path = "${path.module}/contact-flows/inbound-main.tftpl"
      template_vars = {
        support_queue_arn = module.routing.queue_arns["general-support"]
      }
    }
  }

  tags = module.tags.tags
}
```

## Notes

- Template files belong under a `contact-flows/` directory so the pre-commit `jq` hook
  picks them up.
- Flow JSON must conform to the Amazon Connect Contact Flow Language.
