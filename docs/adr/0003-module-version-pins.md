# ADR 0003 — Pinned `terraform-aws-modules` versions

**Status:** accepted

## Context

SPEC §15 / CLAUDE.md require every community module pinned to a specific released version
verified against the Registry **at build time** — never floated, never recalled from
memory.

## Decision

Versions below were resolved from the Registry top-level `version` field on 2026-06-23.
Provider floor is driven by `eventbridge` 4.3.0 (`aws >= 6.28`), so all layers pin
`aws ~> 6.28` and `terraform >= 1.10` (S3 native lock-file era; DynamoDB lock retained per
CLAUDE.md — see [ADR 0004](0004-state-locking.md)).

| Module                                     | Version  | Used in                                        |
| ------------------------------------------ | -------- | ---------------------------------------------- |
| `terraform-aws-modules/vpc/aws`            | `6.6.1`  | 10-network                                     |
| `terraform-aws-modules/security-group/aws` | `6.0.0`  | 10-network                                     |
| `terraform-aws-modules/kms/aws`            | `4.2.0`  | 15-security-foundation (via `modules/kms-cmk`) |
| `terraform-aws-modules/iam/aws`            | `6.6.1`  | 00-bootstrap, 15-security-foundation           |
| `terraform-aws-modules/s3-bucket/aws`      | `5.14.0` | 00-bootstrap                                   |
| `terraform-aws-modules/dynamodb-table/aws` | `5.5.0`  | 00-bootstrap                                   |
| `terraform-aws-modules/lambda/aws`         | `8.8.0`  | 40-integration (via `modules/lambda-fn`)       |
| `terraform-aws-modules/step-functions/aws` | `5.1.0`  | 40-integration                                 |
| `terraform-aws-modules/eventbridge/aws`    | `4.3.0`  | 40-integration                                 |
| `terraform-aws-modules/sns/aws`            | `7.1.0`  | 40-integration                                 |
| `terraform-aws-modules/sqs/aws`            | `5.2.2`  | 40-integration                                 |
| `terraform-aws-modules/rds-aurora/aws`     | `10.2.0` | (Zone 4, deferred)                             |

## Consequences

- Re-verify on the Registry before any version bump; keep provider/runtime bumps in a
  separate PR from functional changes (skill guidance).
- `iam` v6 and `security-group` v6 changed input shapes from v5 — module wrappers target
  the v6 interface specifically.
