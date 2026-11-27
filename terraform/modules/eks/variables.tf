variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version (check EKS standard support dates before changing)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the nodes and control plane ENIs."
  type        = list(string)
}

variable "api_allowed_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint, e.g. [\"203.0.113.10/32\"]."
  type        = list(string)

  validation {
    condition     = length(var.api_allowed_cidrs) > 0 && alltrue([for c in var.api_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Provide at least one valid CIDR."
  }

  validation {
    condition     = !contains(var.api_allowed_cidrs, "0.0.0.0/0")
    error_message = "0.0.0.0/0 would expose the Kubernetes API to the whole internet. Use your own IP/32."
  }
}

variable "node_instance_types" {
  description = "Several similar types improve Spot availability."
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "node_capacity_type" {
  description = "SPOT (cheap, can be interrupted) or ON_DEMAND."
  type        = string
  default     = "SPOT"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "node_capacity_type must be SPOT or ON_DEMAND."
  }
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
  description = "Only used at creation; later changes are ignored by the module."
  type        = number
  default     = 2
}

variable "node_disk_size_gb" {
  type    = number
  default = 20
}

variable "log_retention_days" {
  description = "Retention for control plane logs in CloudWatch."
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
