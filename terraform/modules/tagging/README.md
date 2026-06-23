# tagging

Computes the canonical tag map required by SPEC §3 and CLAUDE.md
(`Project`, `Environment`, `ManagedBy`, `Owner`, `CostCentre`, `DataClassification`),
merged with any caller-supplied `extra_tags`. Owns no resources.

## Usage

```hcl
module "tags" {
  source = "../../../modules/tagging"

  owner               = "contact-centre-platform"
  cost_centre         = "CC-1234"
  data_classification = "confidential"
  extra_tags          = { Layer = "10-network" }
}

# module.tags.tags -> map for `tags = ...` / `default_tags`
```
