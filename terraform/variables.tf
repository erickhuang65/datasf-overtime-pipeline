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

variable "loader_rsa_public_key" {
  type        = string
  description = "Public key for the loader service user (single line, no header/footer)"
}

variable "human_user_name" {
  description = "Your own Snowflake login. Audience roles are granted to it so you can demo each role. Leave null in prod."
  type        = string
  default     = null
}