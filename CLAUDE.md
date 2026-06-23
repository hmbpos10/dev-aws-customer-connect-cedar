# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **STALE REFERENCES — cleanup needed.** The `flask-app/` sections below (Python env,
> Flask testing, `deploy.yml`) describe a component that does not exist in SPEC.md and is
> out of scope for the Connect platform build. They appear to be template boilerplate.
> The `deploy.yml` workflow is intentionally **not** created. Remove these sections once
> confirmed. See docs/adr — flask-app is excluded from Phases 0–2.

## Project: set up production-ready Amazon Connect Customer

Provisions an Amazon Connect Customer inside a robust production-ready AWS environment, i.e. Control Tower Landing Zone Organization using IaC, Terraform, OIDC, GithActions.
Environment is production.

Full scope of the Amazon Connect Customer setup found in SPEC.md

Build context

This repository provisions the Amazon Connect customer platform defined in SPEC.md — read SPEC.md first; it is the source of truth for scope, zones, and acceptance criteria. Target region is eu-west-2; there is one Connect instance with alias hearts-and-bunnies. The antonbabenko/terraform-skill is active — defer to its conventions for module structure, validation, and provider hygiene.

Operating mode — plan only

Claude Code runs in plan mode. Produce Terraform and terraform plan output for review; do not apply changes.

Run locally: terraform fmt, terraform validate, terraform plan, tflint, git status, git diff. These are pre-approved in settings.json.
Never run locally: terraform apply, terraform destroy, terraform import, or terraform state mutations. These are gated to ask in settings.json, and the -auto-approve variants are hard-denied. Treat them as a safety net, not the intended apply route.
Applies happen only in CI. On the main branch of hmbpos10/dev-aws-customer-connect-cedar, GitHub Actions assumes the privileged OIDC role (AWS account 679289103098) and applies the exact saved plan. Pull requests run plan via the read-only OIDC role and post it to the PR. Do not attempt to circumvent this from the local session.
Do not read state or secrets. Terraform state files, .env, and secrets/\*\* are denied in settings.json — do not work around those rules.

Reference sources (authoritative)

Anchor against these. The module browse page is for discovery only and is not authoritative — prefer the specific module's Registry page and the provider docs.

AWS provider — resource & argument reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
AWS provider — CHANGELOG (verify any TF± / CLI service here before relying on pure IaC): https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md
terraform-aws-modules collection: https://registry.terraform.io/namespaces/terraform-aws-modules and https://github.com/terraform-aws-modules
Discovery fallback only: https://registry.terraform.io/browse/modules?provider=aws

These domains (registry.terraform.io, github.com, raw.githubusercontent.com) are allow-listed for WebFetch in settings.json, so fetches to them don't prompt. Note that WebFetch filtering is domain-level, not path-level — allowing registry.terraform.io necessarily allows the browse page too. "Prefer docs over browse" is therefore a rule to follow here in CLAUDE.md, not something the settings file can enforce.

Module strategy

Prefer pinned terraform-aws-modules for standard primitives: vpc, iam, kms, security-group, s3-bucket, lambda, dynamodb-table, rds-aurora, step-functions, eventbridge, sns, sqs.
Pin every module to a specific released version (version = "x.y.z") verified against its Registry page at build time. Do not float to latest, and do not hardcode a version from memory.
Use native provider resources (no community module) for services lacking a maintained one — Amazon Connect itself, Lex V2, Polly, Transcribe / Contact Lens, Kinesis Data Streams / Firehose, Glue, Athena, QuickSight, Macie, GuardDuty, Security Hub, Config, WAF — and verify each against the provider docs above.

## Infrastructure Repo Rules

## When guidance from the terraform-skill plugin conflicts with this file, this file wins. Treat the existing CI/CD workflows, the S3 state backend, and the plan→saved-plan apply flow defined here as fixed — do not regenerate, restructure, or migrate them based on skill suggestions. This repo is a single production environment; ignore multi-environment (staging/dev) scaffolding unless explicitly requested.

## Safety (Non-negotiable)

- Never run `terraform apply` without `terraform plan` first
- Never run `terraform destroy` without explicit user confirmation
- Never run `terraform state rm` or `terraform state mv` without confirmation
- Never hardcode credentials, API keys, or passwords in any file
- Never modify state file directly
- Never hardcode AWS account IDs - use `data.aws_caller_identity`
- Never create IAM policies with `*` actions without a comment explaining why

## Terraform

- State files are in remote backend S3 (`connect-customer-terraform-github-actions` bucket)
- Run `terraform validate` after every .tf change
- Tag all resources: environment, project, managed-by=terraform
- Always plan with `-out=tfplan` and apply from the saved plan; authoritative over any alternative apply pattern the skill describes

## Git

- Create draft PRs
- Once pull request reviewed, approved, and merged to main delete feature branch remotely and locally

## GitHub Actions

- Include `workflow_dispatch` trigger in every workflow file
- Linting and security scanning workflow (`lint-test.yml`) uses TFLint, Checkov, Trivy, Prettier, Ruff, Black, Bandit
- Security review workflow (`security-review.yml`) runs Claude Code AI review on PRs targeting `main` or `feature/**`
- All GitHub Actions workflow files must include "feature/\*\*" as a Push branch
- Use OpenID Connect (OIDC) to avoid storing AWS credentials (access keys) in GitHub Secrets

## Python

### Environment

- Python 3.11+
- Virtual environment using venv
- Type hints for all function signatures

### Code Style

- Follow PEP 8 style guidelines
- Use type hints for function parameters and return types
- Use dataclasses or Pydantic for data models
- Prefer f-strings for string formatting
- Use pathlib for file paths

### Conventions

- Use snake_case for variables and functions
- Use PascalCase for classes
- Use UPPER_CASE for constants
- Keep functions small and focused
- Write docstrings for public functions

### Testing

```bash
cd flask-app && pytest                               # run all tests
cd flask-app && pytest test_app.py::test_health -v   # run a single test
```

## Key commands

### Terraform (run from `terraform/`)

```bash
# If S3 backend credential errors occur, export credentials first:
eval $(aws configure export-credentials --format env)

terraform init
terraform validate
terraform fmt -check
terraform plan -out=tfplan -var="github_org=hmbpos10"
terraform apply -auto-approve tfplan
```

### Flask app (run from `flask-app/`)

```bash
pip3 install -r requirements-dev.txt   # includes pytest + pytest-flask
python app.py                          # runs on http://localhost:5000
```

> **Note:** `deploy.yml` triggers on `**.tf*` file changes or changes to `.github/workflows/deploy.yml` itself. Flask app changes require a manual trigger: `gh workflow run deploy.yml --ref main`

## Key directories

- `terraform/` # AWS infrastructure
- `.github/workflows/` # CI/CD pipelines (terraform.yml, deploy.yml, lint-test.yml, security-review.yml)
- `docs/` # Project documentation (ARCHITECTURE.md CHANGELOG.md)
