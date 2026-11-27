# VPC layout (expects a /16):
#   public   /24  - load balancers only (tagged for Kubernetes ELB discovery)
#   private  /20  - EKS nodes, outbound internet through NAT
#   database /24  - RDS, own route table with NO route to the internet or NAT
#
# Cost choices: one shared NAT gateway by default (single_nat_gateway) and a
# free S3 gateway endpoint so ECR image layers do not flow through the NAT.

locals {
  private_subnets  = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets   = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, 200 + i)]
  database_subnets = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, 210 + i)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.9"

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  # Isolated database tier: dedicated route table, no NAT/IGW route.
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_egress_only_igw  = false
  map_public_ip_on_launch = false

  # Lock down the default security group (no ingress, no egress rules).
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}

# Free gateway endpoint: image layers from ECR are stored in S3.
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.9"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.name}-s3" }
    }
  }

  tags = var.tags
}

# Optional: VPC flow logs to CloudWatch (off by default, it costs money).
module "flow_log" {
  count   = var.enable_flow_logs ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "~> 6.9"

  name   = var.name
  vpc_id = module.vpc.vpc_id

  cloudwatch_log_group_retention_in_days = var.flow_log_retention_days

  tags = var.tags
}
