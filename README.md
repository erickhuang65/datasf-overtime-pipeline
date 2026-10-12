# SF Employee Overtime Pipeline

Loads San Francisco employee compensation data into Snowflake and models it with dbt to answer:

1. **Which employees have unusually high overtime?** → `fct_employee_overtime`
2. **Which departments have the most overtime, in total and per employee?** → `agg_department_overtime`


## Data pipeline
```
DataSF CSV ──► RAW_DEV.PAYROLL ──► STAGING ──► INTERMEDIATE ──► MARTS
               (COPY INTO)          (view)        (view)         (tables)
```

- **Infrastructure** (warehouse, databases, roles, service users, grants): `terraform/`
- **Raw load** (Snowflake CLI + `COPY INTO`): `ingestion/`
- **Transformations, tests and column docs**: `dbt/`

## Setup
 
### 1. Prerequisites
 
| Tool | Install | Used for |
|---|---|---|
| Python 3.9+ and `pip3` | [python.org](https://www.python.org/downloads/) | dbt and Snowflake CLI |
| Terraform | `brew install terraform` (macOS) or [terraform.io](https://developer.hashicorp.com/terraform/install) | Infrastructure |
| Snowflake account | Enterprise edition needed only for the Section 2 policies | Warehouse |
 
### 2. Python environment and packages
 
From the repo root:
 
```bash
# Create and activate a virtual environment
python3 -m venv venv && source venv/bin/activate
pip3 install -r requirements.txt
 
# Install dbt (with the Snowflake adapter) and the Snowflake CLI
pip3 install --upgrade pip
pip3 install dbt-snowflake snowflake-cli
 
# Verify
dbt --version                     # tested with dbt-core 1.12.5, dbt-snowflake 1.12.1
snow --version
```
```

## How to run
 
```bash
# 1. Infrastructure
cd terraform
terraform init
terraform apply -var-file=envs/dev.tfvars
cd ..
 
# 2. Load raw data (CSV from DataSF saved to data/, which is gitignored)
snow sql -f ingestion/01_create_raw_objects.sql -c loader
snow stage copy data/employee_compensation.csv @RAW_DEV.PAYROLL.PAYROLL_STAGE -c loader
snow sql -f ingestion/02_copy_into_raw.sql -c loader
 
# 3. Transform and test
cd dbt
dbt deps                              # installs dbt_utils
dbt build                             # builds all models and runs all tests
dbt docs generate && dbt docs serve   # browse model and column documentation
```

Requires a dbt profile at `~/.dbt/profiles.yml` (not committed). Column-level documentation:
`dbt docs generate && dbt docs serve`.

## Main transformations

| Model | What it does |
|---|---|
| `stg_payroll__employee_compensation` | Converts text to numbers, renames columns, adds a surrogate key (`record_id`). Keeps both Fiscal and Calendar rows |
| `int_compensation__fiscal` | Keeps Fiscal-year rows only, to avoid double counting the same pay |
| `fct_employee_overtime` (Q1) | One row per record with an unusually-high-overtime flag (rule below) |
| `agg_department_overtime` (Q2) | One row per department per fiscal year: total overtime, overtime per employee, flagged records |

**Overtime rule (Q1):** a record is flagged when payroll hours exceed the **median hours for
the same job and fiscal year** by more than **1,040 hours** (20 extra hours a week). The median
comes from Permanent Civil Service records; jobs with fewer than 20 such records use 2,080 hours
(a full-time year). Thresholds are dbt variables in `dbt_project.yml`.

**Tests:** keys, accepted values, row counts between layers, and warning-level checks for known
data issues (93 negative overtime rows, 191 negative salary rows, 2 records with no department).
These warnings are expected and don't block the build.

## Assumptions

- **Fiscal years** (July–June) are the basis of analysis; FY2026 is the latest complete year.
- **One record = one unit.** The source has no employee ID, so records aren't merged by name.
- **`payroll_hours`** is hours recorded in payroll, not verified hours worked.
- **Negative amounts** are payroll adjustments and are kept.
- **Missing values aren't invented:** they stay null and are labeled ('Not reported', 'UNKNOWN') in the marts.

## Limitations

- **Before 2017**, names, hours and employment type aren't reported, so the overtime flag is null for those years.
- **Small jobs** (fewer than 20 permanent records) use the 2,080-hour fallback, which can overstate overtime for small jobs on longer schedules.
- **Part-time and temporary staff** are compared with their job's full-time norm, so their overtime is rarely flagged.
- **Department codes changed over time** (e.g. DSS→HSA in 2018), which affects multi-year trends.
- **Loading is manual**; a daily scheduled load is designed but not built.