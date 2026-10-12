-- Q1 answer queries (FY2026). Run in Snowsight or compile with `dbt compile`.

-- 1. Headline: how many records are flagged
select
    count(*)                                     as records,
    count_if(is_unusually_high_ot)               as flagged,
    round(flagged / records * 100, 2)            as pct_flagged
from {{ ref('fct_employee_overtime') }}
where fiscal_year = 2026;

-- 2. Where: flagged records by department
select
    department_code,
    department_name,
    count(*)                                     as records,
    count_if(is_unusually_high_ot)               as flagged,
    round(flagged / records * 100, 2)            as pct_flagged
from {{ ref('fct_employee_overtime') }}
where fiscal_year = 2026
group by 1, 2
having flagged > 0
order by flagged desc;

-- 3. Who: top 20 records furthest above their job's norm
select
    employee_name,
    department_code,
    job_title,
    payroll_hours,
    baseline_hours,
    hours_above_norm,
    overtime,
    salaries
from {{ ref('fct_employee_overtime') }}
where fiscal_year = 2026
  and is_unusually_high_ot
order by hours_above_norm desc
limit 20;