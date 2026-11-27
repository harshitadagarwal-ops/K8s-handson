variable "name_prefix" {
  description = "Repositories are named <name_prefix>/<service>."
  type        = string
}

variable "repository_names" {
  type    = list(string)
  default = ["backend", "frontend"]
}

variable "keep_last_images" {
  type    = number
  default = 10
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repositories that still contain images."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
