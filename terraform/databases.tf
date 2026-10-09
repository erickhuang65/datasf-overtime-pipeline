resource "snowflake_database" "raw" {
  name    = "RAW_${local.env}"
  comment = "Landing zone for loaded source data"
}

resource "snowflake_schema" "payroll" {
  database = snowflake_database.raw.name
  name     = "PAYROLL"
  comment  = "Raw employee compensation data from the payroll source"
}

resource "snowflake_database" "analytics" {
  name    = "ANALYTICS_${local.env}"
  comment = "dbt-built models consumed by the dashboard"
}

resource "snowflake_schema" "governance" {
  database = snowflake_database.analytics.name
  name     = "GOVERNANCE"
  comment  = "Masking and row access policies, plus access mapping tables"
}