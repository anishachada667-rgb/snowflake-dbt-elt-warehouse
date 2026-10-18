locals {
  dbt_dev_public_key = join("", [
    for line in split("\n", trimspace(file("${path.module}/../.keys/dbt_dev_key.pub"))) :
    trimspace(line) if !startswith(trimspace(line), "-----")
  ])
}

resource "snowflake_service_user" "dbt_dev" {
  name              = "RETAIL_DBT_DEV_USER"
  login_name        = "RETAIL_DBT_DEV_USER"
  default_role      = snowflake_account_role.project["RETAIL_TRANSFORMER"].name
  default_warehouse = snowflake_warehouse.elt.name
  rsa_public_key    = local.dbt_dev_public_key
  comment           = "Dedicated dbt development connection user managed by Terraform"
}

resource "snowflake_grant_account_role" "dbt_dev_transformer" {
  role_name = snowflake_account_role.project["RETAIL_TRANSFORMER"].name
  user_name = snowflake_service_user.dbt_dev.name
}

resource "snowflake_grant_privileges_to_account_role" "transformer_create_schema" {
  account_role_name = snowflake_account_role.project["RETAIL_TRANSFORMER"].fully_qualified_name
  privileges        = ["CREATE SCHEMA"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.retail.fully_qualified_name
  }
}
