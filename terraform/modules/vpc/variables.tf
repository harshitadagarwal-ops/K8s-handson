variable "name" {
  description = "Name prefix for the VPC and its resources."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR. The subnet math in main.tf expects a /16."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr, 0)) && endswith(var.cidr, "/16")
    error_message = "cidr must be a valid IPv4 /16 block."
  }
}

variable "azs" {
  description = "Availability zones to use (at least 2, RDS needs two)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two availability zones."
  }
}

variable "cluster_name" {
  description = "EKS cluster name, used for the Kubernetes subnet discovery tags."
  type        = string
}

variable "single_nat_gateway" {
  description = "true = one shared NAT gateway (cheap, single point of failure). false = one per AZ."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for flow logs."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Extra tags for all resources."
  type        = map(string)
  default     = {}
}
