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



variable "dbt_rsa_public_key" {
  type        = string
  description = "Public key for the dbt service user (single line, no header/footer)"
}