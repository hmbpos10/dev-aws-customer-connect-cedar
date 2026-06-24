# Production variable values for 00-bootstrap. Committed (auto-loaded by terraform).
# Non-secret identifiers only — NEVER put passwords/keys here.
# >>> REPLACE the CHANGE-ME placeholder with the real value before this plans clean. <<<

cost_centre = "CC-0001"

# Cross-account execution roles the CI plan/apply roles may assume (empty until the
# member-account execution roles exist). Uncomment + fill once vended:
# terraform_execution_role_arns = [
#   "arn:aws:iam::CHANGE-ME-CONNECT-ACCT:role/TerraformExecution",
#   "arn:aws:iam::CHANGE-ME-MGMT-ACCT:role/TerraformExecution",
# ]
