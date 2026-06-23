# ADR 0005 — Provisioning mechanisms for TF± / CLI services

**Status:** accepted

## Context

SPEC §6, §7, §14, §16 require a documented, verified provisioning approach for every
service the provider does not cleanly cover. tfsec/Trivy overlap is also recorded here.

## Decisions

| Service                         | Coverage | Mechanism                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Contact-flow JSON               | `CLI`    | `aws_connect_contact_flow` with `content` from `templatefile()` (`modules/connect-contact-flow`). Flow JSON is templated, not authored inline; `jq` validates in pre-commit.                                                                                                                                                                                              |
| Polly lexicons                  | `TF±`    | No resource. `null_resource` + `local-exec` calling `aws polly put-lexicon`, keyed by a content-hash trigger so changes re-apply idempotently.                                                                                                                                                                                                                            |
| Contact Lens / Transcribe rules | `CLI`    | `aws_connect_rule` **does not exist** in the provider (verified at build time — the directory listing ships no such resource). Contact Lens redaction/analytics is configured in the contact flow's recording-and-analytics block (`20-connect-core`), not as a standalone resource. Custom recognition terms use the native `aws_connect_vocabulary` (`30-ai-language`). |
| Lex V2 bot **alias**            | `TF±`    | No `aws_lexv2models_bot_alias` resource exists (provider ships bot, bot_locale, bot_version, intent, slot, slot_type only — verified at build time). The `lex-bot` module creates the bot, locale, and version; the alias is created via `null_resource` + `aws lexv2-models create-bot-alias`/`update-bot-alias`, keyed to the bot_version.                              |
| Lex V2 **Connect association**  | `TF±`    | `aws_connect_bot_association` supports **Lex V1 only** (verified at build time). The V2 bot→instance association is created via `null_resource` + `aws connect associate-bot --lex-v2-bot`, keyed to the published bot version (`30-ai-language`).                                                                                                                        |
| Pinpoint campaigns              | `TF±`    | Channels (`aws_pinpoint_*`) in Terraform; campaigns created out of band via API/SDK and documented.                                                                                                                                                                                                                                                                       |
| DR runbook + game days          | `CLI`    | Documentation only (deferred to Zone 5).                                                                                                                                                                                                                                                                                                                                  |

### tfsec + Trivy overlap

tfsec is deprecated in favour of Trivy, but SPEC §12 lists both. Both run in pre-commit
and `lint-test.yml` to satisfy the spec literally; the redundancy is intentional and may
be removed once the spec is revised.

**Trivy is non-blocking in CI.** Trivy's Terraform adapter panics
(`panic: value is null` in `adaptDefaultTags` → `AsMapValue`) while parsing our provider
`default_tags = module.tags.tags` blocks — it cannot resolve the module-output map during
static adaptation and crashes _before_ scanning. Reproduced on Trivy 0.65.0 and 0.70.0; no
upstream fix identified. Because this is a scanner bug (not a finding in our code) and
**Checkov already passes clean over the same Terraform**, the Trivy step is marked
`continue-on-error: true`: it still runs and surfaces output, but its crash does not gate
the PR. Remove the flag once Trivy fixes the `default_tags` panic.

## Consequences

- `null_resource` + CLI breaks pure-IaC drift detection for Polly lexicons; the trigger
  hash limits but does not eliminate this. Acceptable given no native resource exists.
