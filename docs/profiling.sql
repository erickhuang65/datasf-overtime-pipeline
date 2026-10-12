USE WAREHOUSE TRANSFORM_WH_DEV;

USE SCHEMA RAW_DEV.PAYROLL;

-- Step 1: departments ranked by total overtime pay, 2017 to 2026
-- WITH
--     dept_year AS (
--         SELECT year, department_code, SUM(
--                 TRY_TO_NUMBER (overtime, 38, 2)
--             ) AS total_ot
--         FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
--         WHERE
--             year_type = 'Fiscal'
--             AND year >= '2017'
--         GROUP BY
--             year,
--             department_code
--     )
-- SELECT
--     year,
--     department_code,
--     ROUND(total_ot) AS total_ot,
--     RANK() OVER (
--         PARTITION BY
--             year
--         ORDER BY total_ot DESC
--     ) AS rank_in_year
-- FROM dept_year QUALIFY rank_in_year <= 5
-- ORDER BY year, rank_in_year
-- LIMIT 10;

WITH
    base AS (
        SELECT
            department_code,
            job_code,
            job,
            TRY_TO_NUMBER (overtime, 38, 2) AS overtime,
            TRY_TO_NUMBER (hours, 38, 2) AS hours
        FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
        WHERE
            year_type = 'Fiscal'
            AND year >= '2017'
            AND department_code IN ('POL', 'MTA', 'FIR')
            AND employment_type = 'Permanent Civil Service'
    ),
    jobs AS (
        SELECT
            department_code,
            job_code,
            MAX(job) AS job_title,
            COUNT(*) AS records,
            ROUND(SUM(overtime)) AS total_ot,
            ROUND(
                PERCENTILE_CONT (0.50) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p50_hours,
            ROUND(
                PERCENTILE_CONT (0.90) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p90_hours,
            MAX(hours) AS max_hours
        FROM base
        GROUP BY
            department_code,
            job_code
    ),
    top_jobs AS (
        SELECT *
        FROM jobs QUALIFY RANK() OVER (
                PARTITION BY
                    department_code
                ORDER BY total_ot DESC
            ) <= 5
    )
SELECT
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.p50_hours + 780 AS median_plus_780,
    t.max_hours,
    COUNT_IF (b.hours > t.p90_hours) AS above_p90,
    ROUND(
        above_p90 / t.records * 100,
        1
    ) AS pct_above_p90,
    COUNT_IF (b.hours > t.p50_hours + 780) AS above_median_plus_780,
    ROUND(
        above_median_plus_780 / t.records * 100,
        1
    ) AS pct_above_median_plus_780
FROM top_jobs t
    JOIN base b ON b.department_code = t.department_code
    AND b.job_code = t.job_code
GROUP BY
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.max_hours
ORDER BY t.max_hours DESC;

WITH
    base AS (
        SELECT
            department_code,
            job_code,
            job,
            TRY_TO_NUMBER (overtime, 38, 2) AS overtime,
            TRY_TO_NUMBER (hours, 38, 2) AS hours
        FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
        WHERE
            year_type = 'Fiscal'
            AND year >= '2017'
            AND department_code IN ('POL', 'MTA', 'FIR')
            AND employment_type = 'Permanent Civil Service'
    ),
    jobs AS (
        SELECT
            department_code,
            job_code,
            MAX(job) AS job_title,
            COUNT(*) AS records,
            ROUND(SUM(overtime)) AS total_ot,
            ROUND(
                PERCENTILE_CONT (0.50) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p50_hours,
            ROUND(
                PERCENTILE_CONT (0.90) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p90_hours,
            MAX(hours) AS max_hours
        FROM base
        GROUP BY
            department_code,
            job_code
    ),
    top_jobs AS (
        SELECT *
        FROM jobs QUALIFY RANK() OVER (
                PARTITION BY
                    department_code
                ORDER BY total_ot DESC
            ) <= 5
    )
SELECT
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.p50_hours + 1040 AS median_plus_1040,
    t.max_hours,
    COUNT_IF (b.hours > t.p90_hours) AS above_p90,
    ROUND(
        above_p90 / t.records * 100,
        1
    ) AS pct_above_p90,
    COUNT_IF (b.hours > t.p50_hours + 1040) AS above_median_plus_1040,
    ROUND(
        above_median_plus_1040 / t.records * 100,
        1
    ) AS pct_above_median_plus_1040
FROM top_jobs t
    JOIN base b ON b.department_code = t.department_code
    AND b.job_code = t.job_code
GROUP BY
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.max_hours
ORDER BY t.max_hours DESC;

WITH
    base AS (
        SELECT
            department_code,
            job_code,
            job,
            TRY_TO_NUMBER (overtime, 38, 2) AS overtime,
            TRY_TO_NUMBER (hours, 38, 2) AS hours
        FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
        WHERE
            year_type = 'Fiscal'
            AND year >= '2017'
            AND department_code IN ('POL', 'MTA', 'FIR')
            AND employment_type = 'Permanent Civil Service'
    ),
    jobs AS (
        SELECT
            department_code,
            job_code,
            MAX(job) AS job_title,
            COUNT(*) AS records,
            ROUND(SUM(overtime)) AS total_ot,
            ROUND(
                PERCENTILE_CONT (0.50) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p50_hours,
            ROUND(
                PERCENTILE_CONT (0.90) WITHIN GROUP (
                    ORDER BY hours
                )
            ) AS p90_hours,
            MAX(hours) AS max_hours
        FROM base
        GROUP BY
            department_code,
            job_code
    ),
    top_jobs AS (
        SELECT *
        FROM jobs QUALIFY RANK() OVER (
                PARTITION BY
                    department_code
                ORDER BY total_ot DESC
            ) <= 5
    )
SELECT
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.p50_hours + 1300 AS median_plus_1300,
    t.max_hours,
    COUNT_IF (b.hours > t.p90_hours) AS above_p90,
    ROUND(
        above_p90 / t.records * 100,
        1
    ) AS pct_above_p90,
    COUNT_IF (b.hours > t.p50_hours + 1300) AS above_median_plus_1300,
    ROUND(
        above_median_plus_1300 / t.records * 100,
        1
    ) AS pct_above_median_plus_1300
FROM top_jobs t
    JOIN base b ON b.department_code = t.department_code
    AND b.job_code = t.job_code
GROUP BY
    t.department_code,
    t.job_code,
    t.job_title,
    t.records,
    t.p50_hours,
    t.p90_hours,
    t.max_hours
ORDER BY t.max_hours DESC;

SELECT employment_type, COUNT(*)
FROM RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION
WHERE
    year >= '2017'
GROUP BY
    1
ORDER BY 2 DESC;