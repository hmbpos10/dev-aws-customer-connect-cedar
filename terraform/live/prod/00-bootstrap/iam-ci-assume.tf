# --- Cross-account execution access (the deferred scoped policy, ADR 0002 / SPEC §9) ---
#
# Downstream layers (02+) never provision in THIS (CI) account. Each assumes a Terraform
# execution role in its target member account via `assume_role` in its providers.tf
# (var.connect_account_role_arn / var.management_account_role_arn). So the CI plan/apply
# roles need exactly ONE privilege beyond ReadOnlyAccess + state-backend access:
# sts:AssumeRole into those execution roles. The provisioning permissions themselves live
# on the execution roles, capped by the connect-workload-permission-boundary
# (15-security-foundation). The CI roles stay thin entry points, not account admins.
#
# Granting this to BOTH roles is deliberate: the layers expose a single execution-role var
# per layer, so plan and apply assume the same target role. The read-only guarantee on the
# plan path comes from `terraform plan` not mutating, plus the trust-policy gating (plan =
# PRs/feature branches, apply = main only) and the `production` environment reviewer gate —
# not from a narrower downstream role. Splitting into dedicated read-only execution roles
# for the plan path is the future hardening; see docs/adr/0002-oidc-dual-role.md.
#
# Empty list (the default) creates nothing — the member-account execution roles may not
# exist at first bootstrap (they are vended with the accounts). Populate
# terraform_execution_role_arns once they do, then re-apply this layer.

data "aws_iam_policy_document" "assume_execution_roles" {
  count = length(var.terraform_execution_role_arns) > 0 ? 1 : 0

  statement {
    sid       = "AssumeTerraformExecutionRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.terraform_execution_role_arns
  }
}

resource "aws_iam_policy" "assume_execution_roles" {
  count       = length(var.terraform_execution_role_arns) > 0 ? 1 : 0
  name        = "connect-ci-assume-execution-roles"
  description = "Lets the CI plan/apply roles assume cross-account Terraform execution roles."
  policy      = data.aws_iam_policy_document.assume_execution_roles[0].json

  tags = module.tags.tags
}

resource "aws_iam_role_policy_attachment" "apply_assume_execution" {
  count      = length(var.terraform_execution_role_arns) > 0 ? 1 : 0
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.assume_execution_roles[0].arn
}

resource "aws_iam_role_policy_attachment" "plan_assume_execution" {
  count      = length(var.terraform_execution_role_arns) > 0 ? 1 : 0
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.assume_execution_roles[0].arn
}
