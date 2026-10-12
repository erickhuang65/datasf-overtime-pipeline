# ---------------------------------------------------------------------------
# Section 2: audience roles for the overtime dashboard
#   PUBLIC_READER : department aggregates only
#   LEADERSHIP    : all rows, names masked
#   DEPT_HEAD_*   : own department's rows only, names unmasked
# Table-level SELECT grants and the policies themselves are managed by dbt.
# ---------------------------------------------------------------------------

locals {
  audience_roles = {
    public_reader = "PUBLIC_READER_${local.env}"
    leadership    = "LEADERSHIP_${local.env}"
    dept_head_pol = "DEPT_HEAD_POL_${local.env}"
    dept_head_fir = "DEPT_HEAD_FIR_${local.env}"
  }
}

resource "snowflake_account_role" "audience" {
  provider = snowflake.securityadmin
  for_each = local.audience_roles
  name     = each.value
  comment  = "Overtime dashboard audience role: ${each.key}"
}

# Standard role hierarchy: custom roles roll up to SYSADMIN
resource "snowflake_grant_account_role" "audience_to_sysadmin" {
  provider         = snowflake.securityadmin
  for_each         = snowflake_account_role.audience
  role_name        = each.value.name
  parent_role_name = "SYSADMIN"
}

# Demo only: grant the audience roles to your own user (skipped when null)
resource "snowflake_grant_account_role" "audience_to_human" {
  provider  = snowflake.securityadmin
  for_each  = var.human_user_name == null ? {} : snowflake_account_role.audience
  role_name = each.value.name
  user_name = var.human_user_name
}

# Every audience needs a warehouse to run queries
resource "snowflake_grant_privileges_to_account_role" "audience_warehouse" {
  provider          = snowflake.securityadmin
  for_each          = snowflake_account_role.audience
  account_role_name = each.value.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.transform.name
  }
}

# ...and access to the ANALYTICS database (schema/table access is granted by dbt)
resource "snowflake_grant_privileges_to_account_role" "audience_database" {
  provider          = snowflake.securityadmin
  for_each          = snowflake_account_role.audience
  account_role_name = each.value.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}

# dbt (TRANSFORMER) creates the mapping table and the policies in GOVERNANCE
resource "snowflake_grant_privileges_to_account_role" "transformer_governance" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE MASKING POLICY", "CREATE ROW ACCESS POLICY"]
  on_schema {
    schema_name = snowflake_schema.governance.fully_qualified_name
  }
}