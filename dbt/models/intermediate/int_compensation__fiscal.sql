-- Fiscal-year records only. Calendar rows duplicate the same pay,
-- so every downstream model builds on this to avoid double counting.


select
    record_id,
    pay_year                as fiscal_year,
    has_detail_fields,

    organization_group_code,
    organization_group,
    department_code,
    department_name,
    job_family_code,
    job_family,
    job_code,
    job_title,
    union_code,
    union_name,

    employee_name,
    employment_type,

    salaries,
    overtime,
    other_salaries,
    total_salary,
    total_benefits,
    total_compensation,
    payroll_hours

from {{ ref('stg_payroll__employee_compensation') }}
where year_type = 'Fiscal'