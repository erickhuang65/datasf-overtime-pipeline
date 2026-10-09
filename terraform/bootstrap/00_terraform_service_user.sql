-- One-time bootstrap: run manually in Snowsight as ACCOUNTADMIN
-- before the first terraform apply. Terraform cannot create the
-- user it authenticates as. Replace the placeholder with your public key.

USE ROLE ACCOUNTADMIN;

CREATE USER TERRAFORM_SVC
    TYPE = SERVICE
    COMMENT = 'Service user for Terraforming Snowflake'
    DEFAULT_ROLE = SYSADMIN
    RSA_PUBLIC_KEY = '<RSA_PUBLIC_KEY_HERE>';

GRANT ROLE SYSADMIN TO USER TERRAFORM_SVC;

GRANT ROLE SECURITYADMIN TO USER TERRAFORM_SVC;