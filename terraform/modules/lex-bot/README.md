# lex-bot

Amazon Lex V2 bot (SPEC §6) — native `aws_lexv2models_bot` + `_bot_locale` + `_bot_version`.

**Provider gap:** there is no `aws_lexv2models_bot_alias` resource (provider ships bot,
bot_locale, bot_version, intent, slot, slot_type only — verified at build time). The alias
is created/updated via the AWS CLI in a `null_resource`, keyed to the published bot version
(see ADR 0005). Intents/slots are attached separately via `aws_lexv2models_intent` /
`aws_lexv2models_slot` against the DRAFT version before the version is published.

## Usage

```hcl
module "support_bot" {
  source = "../../../modules/lex-bot"

  name      = "hearts-and-bunnies-support"
  role_arn  = aws_iam_role.lex.arn
  locale_id = "en_GB"
  voice_id  = "Amy"
  alias_name = "prod"

  tags = module.tags.tags
}
```

## Notes

- The `null_resource` alias requires AWS CLI v2 on the apply runner.
- `aws_lexv2models_bot` exports only `id` (no `arn`).
- Lex tags are applied at creation only.
