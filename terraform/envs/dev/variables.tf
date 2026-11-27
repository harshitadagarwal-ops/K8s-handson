variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "k8s-demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

# ---- Required, no default on purpose -------------------------------------

variable "api_allowed_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes API, e.g. [\"203.0.113.10/32\"]. Find yours with: curl https://checkip.amazonaws.com"
  type        = list(string)
}

# ---- Network --------------------------------------------------------------

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheap) instead of one per AZ."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  type    = bool
  default = false
}

# ---- EKS ------------------------------------------------------------------

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3a.large"]
}

variable "node_capacity_type" {
  description = "SPOT or ON_DEMAND. Use ON_DEMAND on the day of a live demo."
  type        = string
  default     = "SPOT"
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "log_retention_days" {
  type    = number
  default = 7
}

# ---- RDS ------------------------------------------------------------------

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  description = "Set true for anything you care about. false lets terraform destroy remove the demo database."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

# ---- ECR ------------------------------------------------------------------

variable "ecr_force_delete" {
  description = "Allow destroy to delete repositories that still contain images."
  type        = bool
  default     = true
}
