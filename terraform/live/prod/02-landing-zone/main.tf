data "aws_region" "current" {}

module "tags" {
  source = "../../../modules/tagging"

  owner               = var.owner
  cost_centre         = var.cost_centre
  data_classification = "internal"
  extra_tags          = { Layer = "02-landing-zone" }
}

# AWS Control Tower landing zone (ADR 0001). Created from the management account.
# The manifest references PRE-EXISTING log/audit accounts and a CMK — those are inputs,
# not created here. First-time creation is slow and only partially idempotent.
resource "aws_controltower_landing_zone" "this" {
  manifest_json = templatefile("${path.module}/landing-zone-manifest.json.tftpl", {
    governed_regions    = jsonencode(var.governed_regions)
    logging_account_id  = var.logging_account_id
    security_account_id = var.security_account_id
    kms_key_arn         = var.kms_key_arn
  })

  version = var.landing_zone_version

  tags = module.tags.tags
}

# Region-deny guardrail applied to the org root. Control Tower controls target an OU ARN;
# here we use the root via the organization data source.
data "aws_organizations_organization" "this" {}

resource "aws_controltower_control" "region_deny" {
  count = var.region_deny_control ? 1 : 0

  control_identifier = "arn:aws:controltower:${data.aws_region.current.region}::control/AWS-GR_REGION_DENY"
  target_identifier  = data.aws_organizations_organization.this.roots[0].arn

  parameters {
    key   = "AllowedRegions"
    value = jsonencode(var.governed_regions)
  }

  depends_on = [aws_controltower_landing_zone.this]
}
