-- Q2: salary and overtime by department, per fiscal year.
-- Answers: which departments have the most overtime in total, and per employee.
-- Grain: one row per department per fiscal year. Contains no individual-level data.


with records as (

    select * from {{ ref('fct_employee_overtime') }}

),

-- Department names changed over time; use the most recent name for each code
latest_names as (
    select
        department_code,
        department_name
    from records qualify row_number() over (
            partition by
                department_code
            order by fiscal_year desc, department_name
        ) = 1
)

select
    r.fiscal_year,
    r.department_code,
    n.department_name,
    count(*) as employee_records,
    count_if (r.overtime > 0) as employees_with_ot,
    sum(r.salaries) as total_salaries,
    sum(r.overtime) as total_overtime,
    round(sum(r.overtime) / count(*), 2) as overtime_per_employee,
    round(
        sum(r.overtime) / nullif(sum(r.salaries), 0) * 100,
        2
    ) as overtime_pct_of_salary,
    count_if (r.is_unusually_high_ot) as flagged_records,
    round(
        count_if (r.is_unusually_high_ot) / count(*) * 100,
        2
    ) as pct_flagged
from records r
    left join latest_names n on r.department_code = n.department_code
group by
    r.fiscal_year,
    r.department_code,
    n.department_name