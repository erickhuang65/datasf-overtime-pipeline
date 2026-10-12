-- Creates the raw-layer objects owned by the loader role.
-- Run: snow sql -f ingestion/01_create_raw_objects.sql -c loader

USE ROLE LOADER_DEV;
USE WAREHOUSE TRANSFORM_WH_DEV;
USE SCHEMA RAW_DEV.PAYROLL;

CREATE FILE FORMAT IF NOT EXISTS CSV_WITH_HEADER
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('')
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE STAGE IF NOT EXISTS PAYROLL_STAGE
  FILE_FORMAT = CSV_WITH_HEADER;

-- All source columns are VARCHAR in raw; staging casts types.
CREATE TABLE IF NOT EXISTS EMPLOYEE_COMPENSATION (
  organization_group_code VARCHAR,
  job_family_code         VARCHAR,
  job_code                VARCHAR,
  year_type               VARCHAR,
  year                    VARCHAR,
  organization_group      VARCHAR,
  department_code         VARCHAR,
  department              VARCHAR,
  union_code              VARCHAR,
  union_name              VARCHAR,   -- source header "Union" (reserved word)
  job_family              VARCHAR,
  job                     VARCHAR,
  employee_name           VARCHAR,
  salaries                VARCHAR,
  overtime                VARCHAR,
  other_salaries          VARCHAR,
  total_salary            VARCHAR,
  retirement              VARCHAR,
  health_and_dental       VARCHAR,
  other_benefits          VARCHAR,
  total_benefits          VARCHAR,
  total_compensation      VARCHAR,
  hours                   VARCHAR,
  employment_type         VARCHAR,
  source_data_as_of       VARCHAR,
  source_data_loaded_at   VARCHAR,
  _source_file            VARCHAR,
  _source_row_number      NUMBER,
  _etl_loaded_at          TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);
