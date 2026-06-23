# Standard tag set required by SPEC §3 and CLAUDE.md:
# owner, environment, cost-centre, data-classification, project, managed-by=terraform.
# This module owns no resources — it only computes the canonical tag map.

locals {
  standard_tags = {
    Project            = var.project
    Environment        = var.environment
    ManagedBy          = "terraform"
    Owner              = var.owner
    CostCentre         = var.cost_centre
    DataClassification = var.data_classification
  }

  tags = merge(local.standard_tags, var.extra_tags)
}
