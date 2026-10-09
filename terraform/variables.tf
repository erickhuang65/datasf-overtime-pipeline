variable "environment" {
  type        = string
  description = "Deployment environment: dev or prod"
}

variable "warehouse_size" {
  type    = string
  default = "XSMALL"
}

locals {
  env = upper(var.environment)
}