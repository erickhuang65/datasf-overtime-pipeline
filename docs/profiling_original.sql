USE WAREHOUSE TRANSFORM_WH_DEV;

USE SCHEMA RAW_DEV.PAYROLL;

-- 1. Fiscal vs Calendar: how much duplication, and which years?
SELECT
    year_type,
    COUNT(*) AS row_count,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM employee_compensation
GROUP BY
    year_type;

-- 2. Rows per year and year type
SELECT year_type, year, COUNT(*) AS row_count
FROM employee_compensation
GROUP BY
    1,
    2
ORDER BY 1, 2;

-- 3. Nulls in key columns
SELECT
    COUNT(*) AS total_rows,
    COUNT_IF (employee_name IS NULL) AS null_name,
    COUNT_IF (department_code IS NULL) AS null_dept_code,
    COUNT_IF (department IS NULL) AS null_dept,
    COUNT_IF (overtime IS NULL) AS null_overtime,
    COUNT_IF (salaries IS NULL) AS null_salaries,
    COUNT_IF (hours IS NULL) AS null_hours
FROM employee_compensation;

-- 4. Values that won't convert to numbers, and negative amounts
SELECT
    COUNT_IF (
        overtime IS NOT NULL
        AND TRY_TO_NUMBER (overtime, 38, 2) IS NULL
    ) AS bad_overtime,
    COUNT_IF (
        salaries IS NOT NULL
        AND TRY_TO_NUMBER (salaries, 38, 2) IS NULL
    ) AS bad_salaries,
    COUNT_IF (
        TRY_TO_NUMBER (overtime, 38, 2) < 0
    ) AS negative_overtime,
    COUNT_IF (
        TRY_TO_NUMBER (salaries, 38, 2) < 0
    ) AS negative_salaries
FROM employee_compensation;

-- 5. Names vs numeric identifiers (older data)
SELECT
    COUNT_IF (
        TRY_TO_NUMBER (employee_name) IS NOT NULL
    ) AS numeric_ids,
    COUNT_IF (
        TRY_TO_NUMBER (employee_name) IS NULL
    ) AS names
FROM employee_compensation;

-- 6. Duplicates at the expected grain
SELECT COUNT(*) AS duplicate_groups
FROM (
        SELECT
            year_type, year, employee_name, department_code, job_code
        FROM employee_compensation
        GROUP BY
            1, 2, 3, 4, 5
        HAVING
            COUNT(*) > 1
    );

-- 7. Overtime distribution (latest fiscal year, people with any overtime)
SELECT
    COUNT(*) AS people_with_ot,
    APPROX_PERCENTILE (
        TRY_TO_NUMBER (overtime, 38, 2),
        0.50
    ) AS p50,
    APPROX_PERCENTILE (
        TRY_TO_NUMBER (overtime, 38, 2),
        0.90
    ) AS p90,
    APPROX_PERCENTILE (
        TRY_TO_NUMBER (overtime, 38, 2),
        0.99
    ) AS p99,
    MAX(
        TRY_TO_NUMBER (overtime, 38, 2)
    ) AS max_ot
FROM employee_compensation
WHERE
    year_type = 'Fiscal'
    AND year = (
        SELECT MAX(year)
        FROM employee_compensation
        WHERE
            year_type = 'Fiscal'
    )
    AND TRY_TO_NUMBER (overtime, 38, 2) > 0;

-- 8. Number of departments
SELECT COUNT(DISTINCT department_code) AS dept_codes, COUNT(DISTINCT department) AS dept_names
FROM employee_compensation;

-- If both year types describe the same payroll history,
-- their all-years totals should be close to each other.
SELECT
    year_type,
    SUM(
        TRY_TO_NUMBER (overtime, 38, 2)
    ) AS total_overtime,
    SUM(
        TRY_TO_NUMBER (salaries, 38, 2)
    ) AS total_salaries
FROM employee_compensation
GROUP BY
    year_type;

-- One person should appear under both year types,
-- with different but related amounts.
SELECT
    year_type,
    year,
    department,
    job,
    TRY_TO_NUMBER (salaries, 38, 2) AS salaries,
    TRY_TO_NUMBER (overtime, 38, 2) AS overtime
FROM employee_compensation
WHERE
    employee_name = 'Robert Gauci'
ORDER BY year, year_type;

SELECT
    department_code,
    COUNT(DISTINCT department) AS name_count,
    LISTAGG (DISTINCT department, '  |  ') AS names,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
WHERE
    year_type = 'Fiscal'
GROUP BY
    department_code
HAVING
    COUNT(DISTINCT department) > 1
ORDER BY name_count DESC;

SELECT
    employee_name,
    department_code,
    job,
    employment_type,
    TRY_TO_NUMBER (salaries, 38, 2) AS salaries,
    TRY_TO_NUMBER (overtime, 38, 2) AS overtime,
    TRY_TO_NUMBER (hours, 38, 2) AS hours
FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
WHERE
    year_type = 'Fiscal'
    AND year = '2026' QUALIFY COUNT(*) OVER (
        PARTITION BY
            employee_name,
            department_code,
            job
    ) > 1
ORDER BY employee_name, department_code
LIMIT 30;

SELECT
    COUNT(*) AS name_groups,
    SUM(n) AS records_in_groups,
    COUNT_IF (combined_hours > 3500) AS likely_two_people,
    COUNT_IF (combined_hours <= 3500) AS possibly_one_person
FROM (
        SELECT
            employee_name, department_code, job, COUNT(*) AS n, SUM(TRY_TO_NUMBER (hours, 38, 2)) AS combined_hours
        FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
        WHERE
            year_type = 'Fiscal'
            AND year = '2026'
        GROUP BY
            1, 2, 3
        HAVING
            COUNT(*) > 1
    );

-- Check 7: job-code group sizes, FY2026
WITH
    fy AS (
        SELECT job_code, TRY_TO_NUMBER (overtime, 38, 2) AS ot
        FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
        WHERE
            year_type = 'Fiscal'
            AND year = '2026'
    ),
    groups AS (
        SELECT
            job_code,
            COUNT(*) AS n_records,
            COUNT_IF (ot > 0) AS n_with_ot
        FROM fy
        GROUP BY
            job_code
    )
SELECT
    CASE
        WHEN n_records < 5 THEN '1: 1-4'
        WHEN n_records < 10 THEN '2: 5-9'
        WHEN n_records < 20 THEN '3: 10-19'
        WHEN n_records < 50 THEN '4: 20-49'
        ELSE '5: 50+'
    END AS group_size,
    COUNT(*) AS job_codes,
    SUM(n_records) AS records,
    SUM(n_with_ot) AS records_with_ot
FROM groups
GROUP BY
    1
ORDER BY 1;

-- Check 5: rows with no department
SELECT
    year_type,
    year,
    organization_group,
    job,
    employee_name,
    salaries,
    overtime
FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
WHERE
    department_code IS NULL
    OR department IS NULL;