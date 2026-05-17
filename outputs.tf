##############################################################
# outputs.tf  –  Root outputs
##############################################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — use this to test traffic"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "Full HTTP URL to paste into your browser"
  value       = "http://${module.alb.alb_dns_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = module.networking.public_subnet_ids
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}
