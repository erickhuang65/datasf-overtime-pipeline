
with source as (

    select * from {{ source('payroll', 'employee_compensation') }}

),

typed as (

    select
        -- keys & lineage
        md5(_source_file || '-' || _source_row_number::varchar)   as record_id,
        _source_file                                               as source_file,
        _source_row_number                                         as source_row_number,
        _etl_loaded_at                                             as etl_loaded_at,

-- period
trim(year_type) as year_type, try_to_number (year) as pay_year,

-- organization
trim(organization_group_code) as organization_group_code,
trim(organization_group) as organization_group,
trim(department_code) as department_code,
trim(department) as department_name,
trim(union_code) as union_code,
trim(union_name) as union_name,
trim(job_family_code) as job_family_code,
trim(job_family) as job_family,
trim(job_code) as job_code,
trim(job) as job_title,

-- person
trim(employee_name) as employee_name,
trim(employment_type) as employment_type,

-- pay (dollars, cents kept)
try_to_number (salaries, 38, 2) as salaries,
try_to_number (overtime, 38, 2) as overtime,
try_to_number (other_salaries, 38, 2) as other_salaries,
try_to_number (total_salary, 38, 2) as total_salary,
try_to_number (retirement, 38, 2) as retirement,
try_to_number (health_and_dental, 38, 2) as health_and_dental,
try_to_number (other_benefits, 38, 2) as other_benefits,
try_to_number (total_benefits, 38, 2) as total_benefits,
try_to_number (total_compensation, 38, 2) as total_compensation,

-- hours (payroll hours, not verified as hours worked)
try_to_number (hours, 38, 2) as payroll_hours,

-- source metadata


try_to_timestamp(source_data_as_of, 'MM/DD/YYYY HH12:MI:SS AM')     as source_data_as_of,
        try_to_timestamp(source_data_loaded_at, 'YYYY/MM/DD HH12:MI:SS AM') as source_data_loaded_at

    from source

)

select
    *,
    pay_year >= 2017 as has_detail_fields -- names, hours, employment type reported from 2017
from typed