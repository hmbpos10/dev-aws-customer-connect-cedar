# ADR 0001 — Control Tower landing zone and account vending in Terraform

**Status:** accepted

## Context

SPEC §4 (Zone 0) marks Control Tower, the org, accounts, and SCPs as `TF`. The
management account is in scope for this build. The Terraform AWS provider does expose
`aws_controltower_landing_zone`, `aws_controltower_control`, `aws_organizations_*`, and
`aws_servicecatalog_provisioned_product` (verified against provider docs at build time).

## Decision

- A dedicated **`02-landing-zone`** layer (management-account provider) manages
  `aws_controltower_landing_zone` (manifest + version) and `aws_controltower_control`
  guardrails. Isolated in its own state because the landing zone changes rarely and is
  catastrophic to break.
- **`05-org`** manages OUs, SCPs, and **member-account vending via Account Factory**
  (`aws_servicecatalog_provisioned_product` against the Account Factory product) so the
  Connect / logging / security / shared-services accounts are Control-Tower-enrolled with
  baselines and guardrails applied.

## Consequences / caveats

- First-time landing-zone creation via `aws_controltower_landing_zone` is heavyweight,
  slow, and only partially idempotent. The manifest references **pre-existing** log and
  audit accounts and a KMS key — those are inputs, not created by this layer.
- Account Factory vending through Service Catalog is `TF±`: the provisioned-product
  wiring (artifact/product IDs, provisioning parameters) is fiddly and version-sensitive.
- At larger scale, AWS recommends **Account Factory for Terraform (AFT)** as a dedicated
  framework rather than raw resources. Noted as a future migration option.
