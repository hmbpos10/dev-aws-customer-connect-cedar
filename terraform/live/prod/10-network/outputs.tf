output "vpc_id" {
  description = "ID of the platform VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (Lambda/RDS attach here)."
  value       = module.vpc.private_subnets
}

output "lambda_security_group_id" {
  description = "Egress-only security group for VPC-attached Lambda."
  value       = module.lambda_sg.security_group_id
}

output "endpoints_security_group_id" {
  description = "Security group fronting the interface VPC endpoints."
  value       = module.endpoints_sg.security_group_id
}
