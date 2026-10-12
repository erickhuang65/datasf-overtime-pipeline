
| Layer | Object | What it does |
|---|---|---|
| Raw | `RAW_DEV.PAYROLL.EMPLOYEE_COMPENSATION` | Source file loaded as-is: all columns text, plus lineage columns (source file, row number, load time). 1,180,053 rows |
| Staging | `stg_payroll__employee_compensation` | Types and renames columns; keeps **both** Fiscal and Calendar rows; adds a surrogate key |
| Intermediate | `int_compensation__fiscal` | Keeps **Fiscal-year rows only** (590,892) to avoid double counting |
| Mart (Q1) | `fct_employee_overtime` | One row per record, with the unusually-high-overtime flag |
| Mart (Q2) | `agg_department_overtime` | One row per department per fiscal year: totals and per-employee overtime |

Infrastructure (warehouse, databases, schemas, roles, service users, grants) is defined in
`terraform/`. Raw loading scripts are in `ingestion/`. Data profiling behind the design
decisions is in `docs/profiling.sql`.

## How to run

**Prerequisites:** Snowflake account, Terraform, Snowflake CLI (`snow`), Python with dbt-snowflake,
key-pair auth set up for the service users (see `terraform/bootstrap/`).

```bash
# 1. Infrastructure
cd terraform
terraform init
terraform apply -var-file=envs/dev.tfvars

# 2. Load raw data
snow sql -f ingestion/01_create_raw_objects.sql -c loader
snow stage copy data/employee_compensation.csv @RAW_DEV.PAYROLL.PAYROLL_STAGE -c loader
snow sql -f ingestion/02_copy_into_raw.sql -c loader

# 3. Transform and test
cd dbt
dbt deps
dbt build                 # builds all models and runs all tests
dbt docs generate && dbt docs serve   # browse model and column documentation
```

A dbt profile is required at `~/.dbt/profiles.yml` (not committed).

## Main transformations

**Staging**
- Converts all money columns to `NUMBER(38,2)` and hours to a number (text in raw).
- Renames columns for clarity (e.g. `year` → `pay_year`, `hours` → `payroll_hours`).
- `record_id`: surrogate key from source file + row number (the source has no employee ID).
- `has_detail_fields`: true from 2017, when names, hours and employment type are reported.

**Intermediate**
- Filters to Fiscal-year rows. The source repeats the same pay under Calendar years;
  mixing both would double count. `pay_year` becomes `fiscal_year`.

**Q1: `fct_employee_overtime`**
- **Rule:** a record is flagged when payroll hours exceed the **median hours for the same
  job code and fiscal year** by more than **1,040 hours** (20 extra hours/week).
- The median comes from Permanent Civil Service records; jobs with fewer than 20 such
  records use 2,080 hours (a standard full-time year) as the baseline.
- Every record is evaluated, including temporary and exempt staff.
- Columns explain each flag: `job_median_hours`, `baseline_hours`, `baseline_source`,
  `hours_above_norm`. `overtime_flag_label` gives a text version for dashboards.
- Thresholds are dbt variables in `dbt_project.yml`: `ot_extra_hours_threshold` (1040),
  `min_job_peers` (20), `fallback_annual_hours` (2080).

**Q2: `agg_department_overtime`**
- Per department and fiscal year: record count, total salaries, total overtime,
  overtime per employee, overtime as % of salary, flagged records.
- Uses the most recent name for each department code.
- Contains no individual-level data.

## Tests

- **Staging:** unique/not-null key; accepted values for year type and employment type;
  not-null checks scoped to years where fields are reported; warnings for known data issues.
- **Marts:** row count of the Q1 mart equals the intermediate model (no records lost or
  duplicated); flag values; one row per department per year.
- **Expected warnings** (known data issues, tracked on every run, don't block the build):
  93 negative overtime rows, 191 negative salary rows, 2 records with no department.

## Assumptions

- **Fiscal years** (July–June) are the analysis basis; FY2026 is the latest complete year.
- **One record = one unit.** There is no employee ID; the same name can be two people,
  so records are not merged by name. Record counts are used as headcount.
- **`payroll_hours` = hours recorded in payroll**, not verified hours worked. It can include
  paid leave and other paid credits.
- **Negative amounts** are payroll adjustments and are kept as-is.
- **Missing values are not invented.** Nulls stay null in staging and are labeled
  ('Not reported', 'UNKNOWN') in the marts.

## Limitations

- **Before 2017**, the source has no names (numeric IDs), hours or employment type.
  The overtime flag is null for those years; dollar totals are still available.
- **Small jobs** (fewer than 20 permanent records, ~26% of records) fall back to a 2,080-hour
  baseline, which overstates `hours_above_norm` for small jobs on longer schedules
  (e.g. Senior Deputy Sheriff). Planned fix: fall back to the job-family median, with a
  2,080-hour floor.
- **Part-time and temporary staff** are compared against the full-time norm for their job,
  so heavy overtime relative to a part-time schedule isn't detected.
- **Department codes changed over time** (e.g. DSS→HSA, ECD→DEM in 2018), which affects
  multi-year trends for those departments.
- **Loading is manual.** A daily scheduled load is designed but not built.
- **Prod is defined, not deployed.** Section 2 access policies and CI are designed, not built
  (see sections below).

## Where to find more detail

- **Column-level documentation:** `dbt/models/**/_*.yml` or `dbt docs serve`
- **Profiling and design evidence:** `docs/profiling.sql`
- **Answer queries for Q1/Q2:** `dbt/analyses/`


Section 2: Access control (design)
Requirements
Audience	May see
Public	Department-level aggregates only
Leadership	Individual rows, with names masked (e.g. J*** D***)
Department heads	Unmasked rows, for their own department only
Approach

All audiences query the same two mart tables. Access is enforced by Snowflake at query time with roles, grants, a masking policy and a row access policy. No tables are duplicated per audience, and the rules apply in every tool that queries the data.

Implementation steps

1. Roles (Terraform: deployed ✅)
terraform/access.tf creates one role per audience: PUBLIC_READER_<ENV>, LEADERSHIP_<ENV>, and one DEPT_HEAD_<DEPT>_<ENV> per department (Police and Fire for the demo). Each role gets warehouse usage and database usage, and rolls up to SYSADMIN. No audience role has access to the RAW database.

2. Table grants (dbt grants: config: designed)

agg_department_overtime → Public, Leadership
fct_employee_overtime → Leadership, department heads

Public never receives access to the fact table, so it can’t see individual records. dbt reapplies grants on every build.

3. Mapping table (dbt seed: designed)
seeds/dept_head_map.csv maps each department-head role to a department code (DEPT_HEAD_POL → POL). It’s versioned in git, so every access change goes through a pull request. In production this mapping would come from the identity provider.

4. Masking policy (designed)
On employee_name: department-head roles see the real name; all other roles see the masked form (John Doe → J*** D***). Pre-2017 numeric IDs are masked the same way.

5. Row access policy (designed)
On department_code: Leadership (and dbt’s own role) see all rows; a department head sees only rows whose department matches their role in the mapping table; any other role sees none.

6. Attaching the policies (dbt post-hook: designed)
dbt rebuilds the fact table with CREATE OR REPLACE, which drops attached policies. A post-hook on fct_employee_overtime reattaches both policies immediately after every build, so the table is never left unprotected.

Result: the same query, different answers
Role	SELECT employee_name, department_code ... FROM fct_employee_overtime
Public	Access denied
Leadership	All departments, names masked
Police head	Police rows only, real names
Notes
Masking and row access policies require Snowflake Enterprise edition. On Standard, the fallback is secure views per audience.
Policy code is included below for reference: (add the two create ... policy statements here when writing the README).