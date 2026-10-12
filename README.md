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