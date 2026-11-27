variable "name" {
  description = "Name prefix."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "allowed_security_group_id" {
  description = "Security group allowed to connect on 3306 (the EKS node security group)."
  type        = string
}

variable "engine_version" {
  description = "MySQL 8.0 is past RDS standard support, so default to the 8.4 LTS line."
  type        = string
  default     = "8.4"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "max_allocated_storage_gb" {
  description = "Upper limit for storage autoscaling (cost guard rail)."
  type        = number
  default     = 50
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "multi_az" {
  description = "Standby replica in a second AZ. Doubles the cost; leave false for the demo."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}
