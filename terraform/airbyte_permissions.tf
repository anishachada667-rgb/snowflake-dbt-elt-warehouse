resource "snowflake_grant_privileges_to_account_role" "loader_create_schema" {
  account_role_name = snowflake_account_role.project["RETAIL_LOADER"].fully_qualified_name
  privileges        = ["CREATE SCHEMA"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.retail.fully_qualified_name
  }
}
