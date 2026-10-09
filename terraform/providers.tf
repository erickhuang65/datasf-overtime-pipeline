terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
  }
}

locals {
  organization_name = "ESFRBJT"
  account_name      = "WL05287"
}

provider "snowflake" {
  organization_name = local.organization_name
  account_name      = local.account_name
  user              = "TERRAFORM_SVC"
  role              = "SYSADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(pathexpand("~/.ssh/snowflake_tf_snow_key.p8"))
}

provider "snowflake" {
  alias             = "securityadmin"
  organization_name = local.organization_name
  account_name      = local.account_name
  user              = "TERRAFORM_SVC"
  role              = "SECURITYADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(pathexpand("~/.ssh/snowflake_tf_snow_key.p8"))
}