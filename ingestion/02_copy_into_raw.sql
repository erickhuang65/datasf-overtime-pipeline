-- Loads every not-yet-loaded file from the stage into the raw table.
-- Run: snow sql -f ingestion/02_copy_into_raw.sql -c loader

USE ROLE LOADER_DEV;

USE WAREHOUSE TRANSFORM_WH_DEV;

USE SCHEMA RAW_DEV.PAYROLL;

COPY INTO EMPLOYEE_COMPENSATION (
    organization_group_code,
    job_family_code,
    job_code,
    year_type,
    year,
    organization_group,
    department_code,
    department,
    union_code,
    union_name,
    job_family,
    job,
    employee_name,
    salaries,
    overtime,
    other_salaries,
    total_salary,
    retirement,
    health_and_dental,
    other_benefits,
    total_benefits,
    total_compensation,
    hours,
    employment_type,
    source_data_as_of,
    source_data_loaded_at,
    _source_file,
    _source_row_number
)
FROM (
        SELECT
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
        FROM @PAYROLL_STAGE
    ) FILE_FORMAT = (
        FORMAT_NAME = 'CSV_WITH_HEADER'
    ) ON_ERROR = 'ABORT_STATEMENT';

-- Reconciliation: rows loaded per file
SELECT
    _source_file,
    COUNT(*) AS rows_loaded,
    MAX(_etl_loaded_at) AS loaded_at
FROM EMPLOYEE_COMPENSATION
GROUP BY
    _source_file
ORDER BY loaded_at DESC;