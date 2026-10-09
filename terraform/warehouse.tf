resource "snowflake_warehouse" "transform" {
  name                = "TRANSFORM_WH_${local.env}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  initially_suspended = true
  comment             = "Compute for loading and dbt transformations"
}