# ADR 0002 — Two OIDC roles to satisfy both the strict apply trust and PR plans

**Status:** accepted

## Context

SPEC §12 mandates a GitHub OIDC trust policy whose `sub` condition is
`repo:hmbpos10/dev-aws-customer-connect-cedar:ref:refs/heads/main` — i.e. only workflows
on `main` may assume the role. CLAUDE.md, however, requires PR plans on feature branches
(via a read-only role) and lists `feature/**` as a push branch. A `pull_request` run from
a feature branch presents `sub = repo:…:pull_request` or `…:ref:refs/heads/feature/*`,
**neither of which matches `refs/heads/main`** — so a single main-only role makes PR plans
impossible.

## Decision

Provision **two roles** in `00-bootstrap`:

| Role                             | Permissions | Trust `sub` (StringLike)                                                               |
| -------------------------------- | ----------- | -------------------------------------------------------------------------------------- |
| `TF_APPLY_ROLE_ARN` (privileged) | apply       | `repo:hmbpos10/dev-aws-customer-connect-cedar:ref:refs/heads/main` (verbatim SPEC §12) |
| `TF_PLAN_ROLE_ARN` (read-only)   | plan / read | `repo:…:pull_request`, `repo:…:ref:refs/heads/feature/*`                               |

The apply path keeps SPEC §12 unchanged. The read-only plan path widens trust only enough
for PR plans, and grants no mutating permissions.

## Consequences

- Satisfies both documents without weakening the apply gate.
- The read-only role's permission policy must genuinely exclude writes — the trust
  widening is safe only because the role cannot mutate infrastructure.
- Confirm the repo owner is `hmbpos10` (SPEC §12 trust policy) before bootstrapping.
