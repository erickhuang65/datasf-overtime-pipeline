-- Q1: employees with unusually high overtime.
-- Rule: flag when payroll hours exceed the job's normal hours (median for the same
-- job code and fiscal year, from Permanent Civil Service records) by more than
-- var('ot_extra_hours_threshold') hours (default 1,040 = 20 extra hours/week).


with fiscal as (

    select * from {{ ref('int_compensation__fiscal') }}

),

-- Step 1: each job's normal hours per fiscal year, from permanent staff only
job_baseline as (
    select
        job_code,
        fiscal_year,
        median (payroll_hours) as job_median_hours,
        count(payroll_hours) as job_peer_count -- counts non-null hours only
    from fiscal
    where
        employment_type = 'Permanent Civil Service'
    group by
        job_code,
        fiscal_year
),

-- Step 2: attach the baseline to every record (all employment types)


with_baseline as (

    select
        f.*,
        b.job_median_hours,
        coalesce(b.job_peer_count, 0) as job_peer_count,
        case
            when coalesce(b.job_peer_count, 0) >= {{ var('min_job_peers') }}
                then b.job_median_hours
            else {{ var('fallback_annual_hours') }}
        end as baseline_hours,
        case
            when coalesce(b.job_peer_count, 0) >= {{ var('min_job_peers') }}
                then 'job_median'
            else 'fallback'
        end as baseline_source
    from fiscal f
    left join job_baseline b
        on  f.job_code    = b.job_code
        and f.fiscal_year = b.fiscal_year

),

-- Step 3: compare each record with its baseline
compared as (
    select
        *,
        payroll_hours - baseline_hours as hours_above_norm
    from with_baseline
)


select
    record_id,
    fiscal_year,
    has_detail_fields,

    employee_name,
    coalesce(employment_type, 'Not reported')   as employment_type,
    coalesce(department_code, 'UNKNOWN')        as department_code,
    coalesce(department_name, 'Unknown')        as department_name,
    job_family,
    job_code,
    job_title,

    salaries,
    overtime,
    other_salaries,
    total_salary,
    round(overtime / nullif(salaries, 0), 2)    as ot_to_salary_ratio,

    payroll_hours,
    job_median_hours,
    job_peer_count,
    baseline_hours,
    baseline_source,
    hours_above_norm,

    case
        when payroll_hours is null then null    -- hours not reported (pre-2017)
        else hours_above_norm > {{ var('ot_extra_hours_threshold') }}
    end                                         as is_unusually_high_ot,

    case
        when payroll_hours is null then 'Hours not reported'
        when hours_above_norm > {{ var('ot_extra_hours_threshold') }} then 'Unusually high'
        else 'Within normal range'
    end                                         as overtime_flag_label

from compared