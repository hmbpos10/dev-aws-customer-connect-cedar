output "contact_centre_ou_id" {
  description = "ID of the dedicated contact-centre OU."
  value       = aws_organizations_organizational_unit.contact_centre.id
}

output "scp_id" {
  description = "ID of the contact-centre guardrail SCP."
  value       = aws_organizations_policy.contact_centre_scp.id
}

output "vended_account_ids" {
  description = "Map of logical account name -> provisioned-product ID for the vended accounts."
  value       = { for k, v in aws_servicecatalog_provisioned_product.account : k => v.id }
}
