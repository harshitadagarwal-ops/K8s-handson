output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_registry" {
  description = "Registry host to docker login to."
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ecr_backend_repo" {
  value = module.ecr.repository_urls["backend"]
}

output "ecr_frontend_repo" {
  value = module.ecr.repository_urls["frontend"]
}

output "rds_address" {
  value = module.rds.address
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_secret_arn" {
  description = "Secrets Manager secret with the generated DB username/password."
  value       = module.rds.master_user_secret_arn
}

data "aws_caller_identity" "current" {}
