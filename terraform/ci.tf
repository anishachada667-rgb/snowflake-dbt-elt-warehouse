locals {
  dbt_ci_public_key = join("", [
    for line in split("\n", trimspace(file("${path.module}/../.keys/dbt_ci_key.pub"))) :
    trimspace(line) if !startswith(trimspace(line), "-----")
  ])
}

resource "snowflake_account_role" "ci" {
  name    = "RETAIL_CI"
  comment = "Role for isolated GitHub Actions dbt builds"
}

resource "snowflake_database" "ci" {
  name    = "RETAIL_ANALYTICS_CI"
  comment = "Isolated database for dbt pull request builds"
}

resource "snowflake_service_user" "dbt_ci" {
  name              = "RETAIL_DBT_CI_USER"
  login_name        = "RETAIL_DBT_CI_USER"
  default_role      = snowflake_account_role.ci.name
  default_warehouse = snowflake_warehouse.elt.name
  rsa_public_key    = local.dbt_ci_public_key
}

resource "snowflake_grant_account_role" "ci_user_role" {
  role_name = snowflake_account_role.ci.name
  user_name = snowflake_service_user.dbt_ci.name
}

resource "snowflake_grant_privileges_to_account_role" "ci_warehouse" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.elt.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_source_database" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.retail.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_raw_schema" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.layers["RAW"].fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_raw_tables" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.layers["RAW"].fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_future_raw_tables" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.layers["RAW"].fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_build_database" {
  account_role_name = snowflake_account_role.ci.fully_qualified_name
  privileges        = ["USAGE", "CREATE SCHEMA"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.ci.fully_qualified_name
  }
}
