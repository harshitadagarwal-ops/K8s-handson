data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  cidr               = var.vpc_cidr
  azs                = local.azs
  cluster_name       = local.name
  single_nat_gateway = var.single_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  api_allowed_cidrs  = var.api_allowed_cidrs

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  log_retention_days  = var.log_retention_days
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix  = local.name
  force_delete = var.ecr_force_delete
}

module "rds" {
  source = "../../modules/rds"

  name                      = local.name
  vpc_id                    = module.vpc.vpc_id
  db_subnet_group_name      = module.vpc.database_subnet_group_name
  allowed_security_group_id = module.eks.node_security_group_id

  instance_class      = var.db_instance_class
  multi_az            = var.db_multi_az
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot
}
