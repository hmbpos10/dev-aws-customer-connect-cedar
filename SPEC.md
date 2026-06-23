This spec reflects what many large enterprises would consider a production-grade AWS-native contact centre platform: governed by Control Tower, secured through Security Hub, GuardDuty, Inspector, and Macie, audited via CloudTrail, observable through CloudWatch, enriched with AI services such as Lex, Polly, and Transcribe, integrated through Lambda and event-driven services, streamed through Kinesis and Firehose, analyzed in a centralized data lake, and retained under long-term compliance controls.

---

# Amazon Connect Customer Platform — Build Specification

## 1. Objective

Provision a secure, highly-available, low-blast-radius Amazon Connect contact-centre platform **entirely as code** using Terraform. Amazon Connect is the hub; every adjacent service is engineer-configured, IAM-scoped, and encrypted with customer-managed keys (CMKs). No production resource is created by clicking in the console.

Claude Code operates here in **plan mode**, producing Terraform to build the architecture described below. Treat each section as a set of resources to design, not free-form prose.

## 2. Customer & Environment Parameters

| Parameter              | Value                                                                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Connect instances      | **One** customer instance                                                                                                                                                      |
| Connect instance alias | **`hearts-and-bunnies`**                                                                                                                                                       |
| Primary target region  | **`eu-west-2`** (London)                                                                                                                                                       |
| Deployment model       | Multi-account, multi-region (DR region defined in Zone 5)                                                                                                                      |
| Execution context      | Claude Code runs from the locally cloned GitHub repo `dev-aws-customer-connect-cedar`, which contains the repo settings files and a `CLAUDE.md` that references this `SPEC.md` |
| Active tooling         | `antonbabenko/terraform-skill/` is installed and activated inside Claude Code — use its conventions for module structure, validation, and provider hygiene                     |

## 3. Global Constraints

- **No console clicks** for any production resource. Everything is Terraform-native unless explicitly flagged otherwise in the coverage column.
- **Zero long-lived credentials.** CI authenticates to AWS via GitHub OIDC (Section 11). Human access via IAM Identity Center only — no IAM users.
- **CMK everywhere.** Recordings, DynamoDB, Kinesis, logs, SNS topics, and CloudWatch Logs are encrypted with customer-managed KMS keys.
- **PII/PCI redaction** on transcripts and recordings.
- **Least privilege** throughout: one IAM role per Lambda; permission boundaries; custom (non-blanket-Admin) Connect security profiles.
- **Blast-radius isolation** at the account boundary, enforced with SCPs plus layered Terraform state.
- All resources tagged (owner, environment, cost-centre, data-classification) and deployed to `eu-west-2` unless the resource is intentionally global or DR-region.

### Terraform coverage legend

| Marker | Meaning                                                                                   |
| ------ | ----------------------------------------------------------------------------------------- |
| `TF`   | Terraform-native — clean AWS provider resource coverage                                   |
| `TF±`  | Partial coverage — provider gaps; expect `null_resource` + CLI, templating, or SDK calls  |
| `CLI`  | API/CLI/templated — no first-class resource; provision via templated JSON or scripted CLI |

> Before committing to a pure-IaC approach for any `TF±` / `CLI` service, verify the current Terraform AWS provider changelog. See Section 13.

---

## 4. Zone 0 — Landing Zone & Network Foundation

_Provisioned before Connect exists._

### Account structure (blast radius)

| ID  | Resource                          | Notes                                                    | Coverage |
| --- | --------------------------------- | -------------------------------------------------------- | -------- |
| OU  | AWS Organizations + Control Tower | Dedicated contact-centre OU, guardrails, account vending | `TF`     |
| ×4  | Separate accounts                 | Connect · logging · security · shared-services           | `TF`     |
| SCP | Service Control Policies          | Deny CloudTrail delete, restrict regions, cap actions    | `TF`     |

### VPC & private connectivity

| ID  | Resource                        | Notes                                                          | Coverage |
| --- | ------------------------------- | -------------------------------------------------------------- | -------- |
| VPC | VPC + private subnets           | Lambda/RDS run private — never public                          | `TF`     |
| PL  | VPC endpoints / PrivateLink     | S3, DynamoDB, Secrets Manager, Kinesis off the public internet | `TF`     |
| FL  | VPC Flow Logs → central account | SGs least-privilege; DNS Firewall on egress                    | `TF`     |

### Identity federation

| ID   | Resource                 | Notes                                                  | Coverage |
| ---- | ------------------------ | ------------------------------------------------------ | -------- |
| SSO  | IAM Identity Center      | Engineer/admin access — no IAM users                   | `TF`     |
| AD   | Directory Service / SAML | Agent auth via Managed AD or external IdP              | `TF`     |
| OIDC | GitHub OIDC provider     | Keyless CI→AWS, scoped by repo/branch/env (Section 11) | `TF`     |

### Customer contact entry channels

| Channel                | Detail                                    | Direction          |
| ---------------------- | ----------------------------------------- | ------------------ |
| 📞 Voice (PSTN)        | Claimed DID / toll-free or ported numbers | Inbound + outbound |
| 💬 Chat / Web / Mobile | Connect chat widget & APIs                | Async + live       |
| 📲 SMS                 | via Pinpoint / End User Messaging         | 2-way              |
| 🔁 Outbound campaigns  | Predictive / progressive dialler          | Kinesis + Lambda   |

---

## 5. Zone 1 — Amazon Connect Core (the hub)

_AWS-managed HA across AZs — there is no AZ to choose (see Section 12)._

### Instance & telephony

| ID  | Resource                                | Notes                                                             | Coverage |
| --- | --------------------------------------- | ----------------------------------------------------------------- | -------- |
| CC  | Connect instance (`hearts-and-bunnies`) | SAML/Directory auth — not default admin                           | `TF`     |
| #   | Phone numbers                           | Claimed/ported; region-specific to `eu-west-2` (DR consideration) | `TF`     |

### Routing & logic

| ID  | Resource                          | Notes                              | Coverage |
| --- | --------------------------------- | ---------------------------------- | -------- |
| IVR | Contact flows                     | Modular, versioned, templated JSON | `CLI`    |
| Q   | Queues · routing profiles · hours | Least-privilege queue assignment   | `TF`     |

### Agent & access

| ID  | Resource          | Notes                                         | Coverage |
| --- | ----------------- | --------------------------------------------- | -------- |
| SP  | Security profiles | Custom least-privilege, **not** blanket Admin | `TF`     |
| HR  | Agent hierarchy   | Mirrors org for reporting isolation           | `TF`     |

---

## 6. Zone 2 — AI & Language

_Attached to contact flows._

| ID  | Resource                  | Notes                                            | Coverage |
| --- | ------------------------- | ------------------------------------------------ | -------- |
| Lx  | Amazon Lex V2             | Intent/slot NLU; bot versions + aliases per env  | `TF`     |
| Po  | Amazon Polly              | TTS + SSML; custom lexicons for brand terms      | `TF±`    |
| Tr  | Transcribe / Contact Lens | Real-time transcription, sentiment, custom vocab | `TF±`    |
| CL  | Contact Lens redaction    | PCI/PII stripped from transcripts + recordings   | `TF±`    |

---

## 7. Zone 3 — Compute & Integration (the glue)

_One IAM role per function._

| ID  | Resource       | Notes                                                         | Coverage |
| --- | -------------- | ------------------------------------------------------------- | -------- |
| λ   | AWS Lambda     | VPC-attached; reserved concurrency; DLQ; aliases dev/stg/prod | `TF`     |
| SF  | Step Functions | Complex orchestration kept out of Lambda                      | `TF`     |
| EB  | EventBridge    | Connect events → downstream triggers                          | `TF`     |
| SNS | SNS            | Alerts & fan-out; CMK-encrypted topics                        | `TF`     |
| SQS | SQS + DLQs     | Decouple Lambda from events; retry handling                   | `TF`     |
| Pin | Pinpoint       | Outbound SMS/email; channels in TF, campaigns via API         | `TF±`    |

---

## 8. Zone 4 — Data, Storage & Analytics Pipeline

_CMK-encrypted at rest throughout._

### Operational stores

| ID  | Resource             | Notes                                                          | Coverage |
| --- | -------------------- | -------------------------------------------------------------- | -------- |
| DDB | DynamoDB             | Session/contact state; PITR; CMK; on-demand                    | `TF`     |
| RDS | Aurora Serverless v2 | Multi-AZ, private subnet, encrypted (accessed via Lambda only) | `TF`     |

### Recordings & archive

| ID  | Resource                | Notes                                                                 | Coverage |
| --- | ----------------------- | --------------------------------------------------------------------- | -------- |
| S3  | S3 — segregated buckets | Recordings/transcripts/exports; versioning; Block Public; Object Lock | `TF`     |
| GL  | Glacier / Deep Archive  | S3 lifecycle transitions — **not** a standalone vault                 | `TF`     |

### Analytics & BI

| ID  | Resource              | Notes                                       | Coverage |
| --- | --------------------- | ------------------------------------------- | -------- |
| Gl  | Glue + Lake Formation | Crawlers, Data Catalog, fine-grained access | `TF`     |
| At  | Athena + QuickSight   | Query CTRs/transcripts; exec dashboards     | `TF`     |

### Streaming pipeline

Connect CTRs / agent events (streaming enabled in instance settings) →
**Kinesis Data Streams** (real-time contact trace records) →
**Kinesis Firehose** (buffer + deliver) →
**S3 data lake** (partitioned, CMK-encrypted) →
**Glue → Athena → QuickSight** (ETL, ad-hoc query, dashboards).

---

## 9. Cross-cutting Security & Governance

_Spans every account and service. None are optional in a production, regulated contact centre._

| Resource                     | Notes                                    | Coverage |
| ---------------------------- | ---------------------------------------- | -------- |
| IAM                          | Role-per-Lambda, permission boundaries   | `TF`     |
| KMS                          | CMKs — recordings · DDB · Kinesis · logs | `TF`     |
| Secrets Manager              | Secret storage; rotation                 | `TF`     |
| CloudTrail → central logging | S3, log-file validation on               | `TF`     |
| GuardDuty + Security Hub     | Threat detection + posture               | `TF`     |
| Macie                        | PII scan on recording buckets            | `TF`     |
| Inspector v2                 | Lambda + ECR scanning                    | `TF`     |
| AWS Config                   | Conformance packs                        | `TF`     |
| WAF                          | On any exposed API / CloudFront          | `TF`     |

---

## 10. Cross-cutting Observability & Operations

_Metrics and alarms live beside the resources they watch; central dashboards and tracing aggregate the whole._

| Resource        | Notes                                                             | Coverage |
| --------------- | ----------------------------------------------------------------- | -------- |
| CloudWatch      | Alarms on queue depth, Lambda errors, concurrency, service limits | `TF`     |
| CloudWatch Logs | KMS-encrypted, retention set                                      | `TF`     |
| X-Ray           | Distributed tracing across Lambda chains                          | `TF`     |
| Synthetics      | Canaries on contact-flow logic                                    | `TF`     |
| AWS Backup      | DDB · RDS · S3 policy                                             | `TF`     |

---

## 11. Zone 5 — Resilience & Disaster Recovery

_Multi-region is the real HA lever for Connect._

### Region failover

| ID  | Resource                   | Notes                                      | Coverage |
| --- | -------------------------- | ------------------------------------------ | -------- |
| CC2 | Secondary Connect instance | Warm/hot standby in 2nd region per RTO/RPO | `TF`     |
| R53 | Route 53 health checks     | Failover routing for inbound numbers       | `TF`     |

### Data replication

| ID  | Resource                    | Notes                               | Coverage |
| --- | --------------------------- | ----------------------------------- | -------- |
| CRR | S3 Cross-Region Replication | Recordings/transcripts to DR region | `TF`     |
| GT  | DynamoDB Global Tables      | Multi-region session state          | `TF`     |

### Validation

| ID  | Resource                  | Notes                                   | Coverage |
| --- | ------------------------- | --------------------------------------- | -------- |
| FIS | Fault Injection Simulator | Test resilience assumptions pre-go-live | `TF`     |
| DR  | DR runbook + game days    | Documented, rehearsed failover          | `CLI`    |

---

## 12. Delivery IaC Pipeline

_No production resource is clicked in the console. Layered state keeps a contact-flow change from ever touching networking._

1. **pre-commit** — install https://github.com/antonbabenko/pre-commit-terraform
   use tools / hooks:

terraform_fmt tflint tfsec trivy checkov terrascan infracost tfupdate minamijoyo/hcledit/hcledit jq gitleaks

2. **PR → GitHub Actions** — `plan` via the **read-only OIDC role**; plan posted to the PR
3. **Review + environment gate** — required reviewers on prod
4. **main → apply** — **privileged OIDC role**; the saved plan applied exactly
5. **Remote state** — S3 + DynamoDB lock; per-env, per-concern

### GitHub OIDC trust policy

The CI workflows authenticate to AWS with no long-lived credentials. **Only workflows running on the `main` branch of `dev-aws-customer-connect-cedar` may assume the role.** Use this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::679289103098:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:hmbpos10/dev-aws-customer-connect-cedar:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

---

## 13. Design Rationale (must hold across the build)

**Why no AZ selection for Connect.** Connect is managed SaaS — AWS handles AZ redundancy internally. You cannot place an instance in an AZ; the real availability lever is **multi-region DR** (Zone 5), not AZ spread.

**Blast-radius design.** Isolation is enforced at the **account boundary** with SCPs, plus layered Terraform state. A failed apply or compromised credential is contained to one account and one state file.

**Connect is a hub, not a product install.** Connect ships voice/chat/IVR/agent UI. Every other service here is engineer-added, IAM-scoped, and CMK-encrypted. A production build typically wires 25+ services across the 4 accounts.

---

## 14. Terraform Friction Points to Verify

- **Mature (low risk):** DynamoDB, SNS, Inspector, CloudTrail, CloudWatch, Glacier-via-lifecycle.
- **Watch (verify provider coverage before committing to pure IaC):**
  - `aws_connect_rule` (Contact Lens)
  - Polly lexicons — likely `null_resource` + CLI
  - Pinpoint campaigns — API/SDK
  - Contact-flow JSON — templated

For every `TF±` / `CLI` service, check the current Terraform AWS provider changelog and document the chosen provisioning mechanism in the module before applying.

## 15. Reference Sources

CLAUDE.md and this spec must agree on where the authoritative truth lives. The Registry's module _browse_ page (`https://registry.terraform.io/browse/modules?provider=aws`) is for discovery only — it is paginated, popularity-ranked, JS-rendered, and not authoritative for any module's interface or for provider coverage. Anchor against the stable sources below instead.

### Authoritative anchors

| Purpose                                                                              | URL                                                                          |
| ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| AWS provider — resource & argument reference (use to confirm `TF±` / `CLI` coverage) | `https://registry.terraform.io/providers/hashicorp/aws/latest/docs`          |
| AWS provider — CHANGELOG (Section 14 requires verifying `TF±` services here)         | `https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md` |
| `terraform-aws-modules` collection (Registry namespace)                              | `https://registry.terraform.io/namespaces/terraform-aws-modules`             |
| `terraform-aws-modules` source (GitHub org)                                          | `https://github.com/terraform-aws-modules`                                   |
| Module discovery (fallback only)                                                     | `https://registry.terraform.io/browse/modules?provider=aws`                  |

The active `antonbabenko/terraform-skill` already encodes conventions for the `terraform-aws-modules` family (Anton Babenko maintains that collection) — treat the skill and that module family as the primary source; use the browse page only when a needed module isn't already known.

### Module strategy

- **Prefer pinned community modules** from `terraform-aws-modules` for the standard primitives. Clear candidates for this build: `vpc`, `iam`, `kms`, `security-group`, `s3-bucket`, `lambda`, `dynamodb-table`, `rds-aurora`, `step-functions`, `eventbridge`, `sns`, `sqs`.
- **Pin every module to a specific released version** (`version = "x.y.z"`) resolved against the Registry at build time — do not float to latest, and do not hardcode a version from memory; verify the current release on the module's Registry page first.
- **Use native provider resources** (no community module) for services that lack a maintained module — including Amazon Connect itself, Lex V2, Polly, Transcribe / Contact Lens, Kinesis Data Streams / Firehose, Glue, Athena, QuickSight, Macie, GuardDuty, Security Hub, Config, and WAF. Verify each against the provider docs anchor above.
- **Constrain `WebFetch`** in the repo settings to the provider-docs and Registry domains so Claude Code reaches for the reference pages rather than scraping the dynamic browse list.

## 16. Definition of Done

- Single Connect instance with alias `hearts-and-bunnies` provisioned in `eu-west-2`.
- All zones (0–5) plus both cross-cutting layers expressed as Terraform, organised per-env and per-concern with remote state + locking.
- No IAM users; CI assumes role via the OIDC trust policy above, restricted to `main` of `dev-aws-customer-connect-cedar`.
- CMK encryption on recordings, DDB, Kinesis, logs, SNS, CloudWatch Logs.
- `pre-commit` (fmt/validate/tflint/checkov/trivy/gitleaks) passes clean.
- All `TF±` / `CLI` services have a documented, verified provisioning approach.
- Every community module is pinned to a specific released version verified against the Registry; services without a module use native provider resources.
- DR region wired (secondary Connect, Route 53 failover, S3 CRR, DynamoDB Global Tables) with a rehearsed runbook.
