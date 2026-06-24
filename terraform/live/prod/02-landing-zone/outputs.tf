output "landing_zone_id" {
  description = "Identifier of the Control Tower landing zone."
  value       = aws_controltower_landing_zone.this.id
}

output "landing_zone_arn" {
  description = "ARN of the Control Tower landing zone."
  value       = aws_controltower_landing_zone.this.arn
}

output "organization_root_id" {
  description = "Org root ID (consumed by 05-org for OU placement)."
  value       = data.aws_organizations_organization.this.roots[0].id
}
