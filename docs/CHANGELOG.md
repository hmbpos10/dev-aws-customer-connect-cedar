# Changelog

All notable changes to this repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- Repo scaffolding: `.pre-commit-config.yaml`, `.tflint.hcl`, `.checkov.yaml`.
- GitHub Actions workflows: `terraform.yml` (dual-role OIDC plan/apply),
  `lint-test.yml`, `security-review.yml`.
- Architecture docs and ADRs (`docs/`, `docs/adr/`).
- Layered Terraform foundation (Phases 0–2): `00-bootstrap` through `40-integration`.
- `15-security-foundation` layer: six domain CMKs (recordings, dynamodb, kinesis, logs,
  sns, secrets), workload IAM permission boundary, Secrets Manager-backed Managed AD with
  a generated admin password, and IAM Identity Center permission sets.
- `20-connect-core` layer: `hearts-and-bunnies` instance (EXISTING_DIRECTORY auth),
  three segregated CMK-encrypted storage buckets (recordings/transcripts/exports) with
  Object Lock, routing (hours/queue/routing profile), least-privilege security profiles
  and agent hierarchy, and a templated inbound contact flow.
- `30-ai-language` layer: Lex V2 bot (bot/locale/version + intent, alias and Connect
  association via CLI — provider gaps), scoped Lex execution role, custom Connect
  vocabulary, and Polly lexicons via CLI.
- `40-integration` layer: SQS contact-events queue + DLQ (CMK), CMK-encrypted SNS alerts
  topic, VPC-attached contact-events Lambda with its own role, EventBridge rule routing
  Connect contact events to SQS, and a Step Functions orchestrator.
- `lambda-fn` module: added `role_name` output for attaching extra inline policies.
- Shared modules: `kms-cmk`, `tagging`, `account-provider`, `connect-instance`,
  `connect-routing`, `connect-security`, `connect-contact-flow`, `lex-bot`, `lambda-fn`.
