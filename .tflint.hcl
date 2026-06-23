# TFLint configuration for the Amazon Connect platform.
# Plugins pinned per SPEC §15 (no floating versions).

config {
  call_module_type = "local"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.42.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # deep_check stays OFF: it calls the live AWS API, but the lint stage runs with no
  # credentials (only plan/apply assume the OIDC role — SPEC §12). Enabling it here
  # fails every directory with "no valid credential sources". Deep checks, if wanted,
  # belong in a credentialed job, not the credential-less lint gate.
  deep_check = false
}

# Enforce the standard tag set required by CLAUDE.md and SPEC §3.
rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "Project",
    "ManagedBy",
    "Owner",
    "CostCentre",
    "DataClassification",
  ]
  # Tag-only and global resources that do not accept the full tag set.
  exclude = [
    "aws_iam_openid_connect_provider",
  ]
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}
