resource "snowflake_account_role" "transformer" {
  provider = snowflake.securityadmin
  name     = "TRANSFORMER_${local.env}"
  comment  = "dbt: reads raw, builds analytics"
}

resource "snowflake_service_user" "dbt" {
  provider          = snowflake.securityadmin
  name              = "DBT_SVC_${local.env}"
  comment           = "Service user dbt connects as"
  default_role      = snowflake_account_role.transformer.name
  default_warehouse = snowflake_warehouse.transform.name
  rsa_public_key    = var.dbt_rsa_public_key
}

# Give the role to the dbt user
resource "snowflake_grant_account_role" "transformer_to_dbt" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.transformer.name
  user_name = snowflake_service_user.dbt.name
}

# Put the role under SYSADMIN, so admins can see what dbt builds
resource "snowflake_grant_account_role" "transformer_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.transformer.name
  parent_role_name = "SYSADMIN"
}