# EKS cluster with one managed node group.
#
# Security:
#   - nodes live in private subnets only
#   - public API endpoint limited to api_allowed_cidrs (private endpoint also on)
#   - Kubernetes Secrets encrypted with a customer-managed KMS key (module default)
#   - control plane audit/api/authenticator logs on
#   - IMDSv2 required on nodes, hop limit 1 (pods cannot reach node credentials)
#   - encrypted gp3 node volumes
#   - access via EKS access entries; the identity running Terraform becomes admin
#
# Cost:
#   - Spot nodes by default, small gp3 disks, 7-day log retention
#   - only the add-ons the app needs (coredns, kube-proxy, vpc-cni)

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.api_allowed_cidrs

  enable_cluster_creator_admin_permissions = true

  enabled_log_types                      = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size_gb
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = var.tags
}
