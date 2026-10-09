# Compute
resource "snowflake_grant_privileges_to_account_role" "transformer_wh" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.transform.name
  }
}

# Read raw
resource "snowflake_grant_privileges_to_account_role" "transformer_raw_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.payroll.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.payroll.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.payroll.fully_qualified_name
    }
  }
}

# Build in analytics
resource "snowflake_grant_privileges_to_account_role" "transformer_analytics_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}