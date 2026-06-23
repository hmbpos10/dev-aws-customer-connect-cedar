# Architecture — Amazon Connect Platform (`hearts-and-bunnies`)

Production AWS-native contact centre, provisioned entirely as Terraform. Source of
truth is [`SPEC.md`](../SPEC.md). This document describes the **as-built** structure
for Phases 0–2 (foundation → Connect core → integration); Zones 4/5 and the
detective-control / observability layers are deferred.

## Layered state (blast-radius isolation)

Each layer is an independent root module with its own S3 state key
(`prod/<layer>/terraform.tfstate`) and DynamoDB lock. A change to one layer plans only
against its own state — a contact-flow edit can never touch networking (SPEC §12, §13).

```
00-bootstrap → 02-landing-zone → 05-org → 10-network ─┐
                                         → 15-security ┤→ 20-connect-core → 30-ai-language
                                                       └                  → 40-integration
```

| Layer | Account | Purpose |
|-------|---------|---------|
| `00-bootstrap` | CI + targets | State backend, GitHub OIDC provider, CI roles, per-account exec roles |
| `02-landing-zone` | management | Control Tower landing zone + guardrails |
| `05-org` | management | OUs, SCPs, Account Factory vending (CT-enrolled member accounts) |
| `10-network` | connect | VPC, private subnets, endpoints, flow logs, DNS firewall |
| `15-security-foundation` | connect + security | KMS CMKs, IAM boundaries, Secrets Manager, Identity Center, Directory |
| `20-connect-core` | connect | `hearts-and-bunnies` instance, telephony, routing, security profiles, flows |
| `30-ai-language` | connect | Lex V2, Polly lexicons, Contact Lens rules |
| `40-integration` | connect | Lambda, Step Functions, EventBridge, SNS, SQS, Pinpoint |

## Accounts (multi-account, blast radius at the account boundary)

`management`, `connect`, `logging`, `security`, `shared-services`, plus the CI account
`679289103098`. Account IDs are supplied as input variables / discovered via
`data.aws_caller_identity` — never hardcoded (CLAUDE.md). Cross-account access is via
aliased `aws` providers with `assume_role`.

## Keyless CI (GitHub OIDC, two roles)

- **Read-only plan role** — assumed on `pull_request` and on feature branches; trust
  policy permits `pull_request` / `refs/heads/feature/*`.
- **Privileged apply role** — assumed only on `main`; trust policy is the strict
  `refs/heads/main` condition from SPEC §12.

See [`adr/0002-oidc-dual-role.md`](adr/0002-oidc-dual-role.md).

## Encryption

Customer-managed KMS keys for recordings, DynamoDB, Kinesis, logs, SNS, and CloudWatch
Logs (SPEC §3). CMKs are provisioned in `15-security-foundation` via the
`modules/kms-cmk` wrapper and consumed downstream through `terraform_remote_state`.

## Module strategy

Pinned `terraform-aws-modules` for standard primitives (versions verified against the
Registry at build time — see [`adr/0003-module-version-pins.md`](adr/0003-module-version-pins.md));
native provider resources for Connect, Lex, Polly, Transcribe/Contact Lens, and the
analytics/security services that lack a maintained module.
