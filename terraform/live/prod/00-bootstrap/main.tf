module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "internal"
  extra_tags          = { Layer = "00-bootstrap" }
}

locals {
  # OIDC subjects. The privileged (apply) role is restricted to main exactly as SPEC §12
  # requires; the read-only (plan) role is widened to PRs and feature branches so PR plans
  # can assume a role at all (ADR 0002).
  repo      = "repo:${var.github_org}/${var.github_repo}"
  apply_sub = "${local.repo}:ref:refs/heads/main"
  plan_subs = [
    "${local.repo}:pull_request",
    "${local.repo}:ref:refs/heads/feature/*",
  ]
}

# --- Remote state backend (S3 + DynamoDB lock, ADR 0004) ------------------------------

module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.14.0"

  bucket        = var.state_bucket_name
  force_destroy = false

  # Block all public access.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  # Reclaim storage from failed multipart uploads (CKV_AWS_300).
  lifecycle_rule = [
    {
      id                                     = "abort-incomplete-multipart"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  tags = module.tags.tags
}

resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = module.tags.tags
}

# --- GitHub OIDC provider -------------------------------------------------------------
# Modern AWS validates GitHub's OIDC against its TLS chain; no thumbprint pinning needed.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # thumbprint_list omitted: for GitHub, AWS validates against its trusted-CA library and
  # ignores any configured thumbprint (provider docs).

  tags = module.tags.tags
}

# --- CI roles (two roles, two trust policies — ADR 0002) ------------------------------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.plan_subs
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Verbatim SPEC §12: only workflows on main may assume the privileged role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.apply_sub]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "connect-ci-terraform-plan"
  description          = "Read-only role for PR/feature-branch terraform plan (OIDC)."
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600

  tags = module.tags.tags
}

resource "aws_iam_role" "apply" {
  name                 = "connect-ci-terraform-apply"
  description          = "Privileged role for terraform apply on main only (OIDC)."
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600

  tags = module.tags.tags
}

# Read-only role: ReadOnlyAccess plus the state-backend access plan needs.
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid    = "StateBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      module.state_bucket.s3_bucket_arn,
      "${module.state_bucket.s3_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "StateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [aws_dynamodb_table.locks.arn]
  }
}

resource "aws_iam_policy" "state_access" {
  name        = "connect-ci-terraform-state-access"
  description = "S3 + DynamoDB access for Terraform remote state."
  policy      = data.aws_iam_policy_document.state_access.json

  tags = module.tags.tags
}

resource "aws_iam_role_policy_attachment" "plan_state" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.state_access.arn
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.state_access.arn
}

# The privileged apply role gets NO broad provisioning policy: downstream layers provision
# by assuming a cross-account Terraform execution role (providers.tf in each layer), so the
# only privilege beyond ReadOnlyAccess + state access is sts:AssumeRole into those roles.
# That grant lives in iam-ci-assume.tf, gated on var.terraform_execution_role_arns.
# Least privilege over blanket Admin (SPEC §3, §9; ADR 0002).
