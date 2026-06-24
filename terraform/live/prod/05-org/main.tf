module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "internal"
  extra_tags          = { Layer = "05-org" }
}

locals {
  root_id = data.terraform_remote_state.landing_zone.outputs.organization_root_id
}

# Dedicated contact-centre OU (SPEC §4).
resource "aws_organizations_organizational_unit" "contact_centre" {
  name      = var.contact_centre_ou_name
  parent_id = local.root_id

  tags = module.tags.tags
}

# --- Service Control Policy (SPEC §4: deny CloudTrail delete, restrict regions) -------

data "aws_iam_policy_document" "scp" {
  # Prevent disabling/deleting the audit trail.
  statement {
    sid    = "DenyCloudTrailTampering"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "cloudtrail:UpdateTrail",
    ]
    resources = ["*"]
  }

  # Restrict to eu-west-2 (and a DR region later); global services excepted.
  statement {
    sid    = "RestrictRegions"
    effect = "Deny"
    not_actions = [
      "iam:*",
      "organizations:*",
      "sts:*",
      "cloudfront:*",
      "route53:*",
      "waf:*",
      "wafv2:*",
      "support:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-west-2"]
    }
  }
}

resource "aws_organizations_policy" "contact_centre_scp" {
  name        = "contact-centre-guardrails"
  description = "Deny CloudTrail tampering and restrict to eu-west-2 (SPEC §4)."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp.json

  tags = module.tags.tags
}

resource "aws_organizations_policy_attachment" "contact_centre_scp" {
  policy_id = aws_organizations_policy.contact_centre_scp.id
  target_id = aws_organizations_organizational_unit.contact_centre.id
}

# --- Account Factory vending (CT-enrolled member accounts — ADR 0001) -----------------
# Vended through the Service Catalog Account Factory product so accounts inherit CT
# baselines/guardrails (unlike raw aws_organizations_account). product_name and the
# provisioning parameters are the documented Account Factory contract.

resource "aws_servicecatalog_provisioned_product" "account" {
  for_each = var.vended_accounts

  name                       = each.value.account_name
  product_name               = "AWS Control Tower Account Factory"
  provisioning_artifact_name = "AWS Control Tower Account Factory"
  path_id                    = var.account_factory_path_id

  provisioning_parameters {
    key   = "AccountName"
    value = each.value.account_name
  }
  provisioning_parameters {
    key   = "AccountEmail"
    value = each.value.account_email
  }
  provisioning_parameters {
    key   = "SSOUserEmail"
    value = each.value.sso_user_email
  }
  provisioning_parameters {
    key   = "SSOUserFirstName"
    value = each.value.sso_user_first_name
  }
  provisioning_parameters {
    key   = "SSOUserLastName"
    value = each.value.sso_user_last_name
  }
  provisioning_parameters {
    key   = "ManagedOrganizationalUnit"
    value = each.value.organizational_unit
  }

  tags = module.tags.tags
}
