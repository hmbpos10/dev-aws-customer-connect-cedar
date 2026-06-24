# ADR 0004 — State backend and locking

**Status:** accepted

## Context

The active terraform-skill prefers S3 native lock-files (`use_lockfile`, TF ≥ 1.10) and no
DynamoDB table. CLAUDE.md §58 and SPEC §12.5 explicitly require "S3 + DynamoDB lock".
CLAUDE.md wins on conflict.

## Decision

- Single state bucket `connect-customer-terraform-github-actions`, per-layer key
  `prod/<layer>/terraform.tfstate`, region `eu-west-2`, `encrypt = true`.
- Locking via a **DynamoDB table** (`dynamodb_table`), created in `00-bootstrap`.
- We do **not** also set `use_lockfile`, to avoid dual-locking ambiguity; the DynamoDB
  mechanism is authoritative.

## Consequences

- `00-bootstrap` is the chicken-and-egg layer: bootstrapped with local state, then
  `terraform init -migrate-state` moves it into S3 once the bucket/table exist. This is a
  one-time manual step, not part of CI.
