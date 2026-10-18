resource "snowflake_schema" "layers" {
  for_each = toset([
    "RAW",
    "STAGING",
    "INTERMEDIATE",
    "MARTS",
    "SNAPSHOTS"
  ])

  database = snowflake_database.retail.name
  name     = each.value
  comment  = "Retail ELT ${each.value} layer managed by Terraform"
}

resource "snowflake_account_role" "project" {
  for_each = toset([
    "RETAIL_LOADER",
    "RETAIL_TRANSFORMER",
    "RETAIL_ANALYST"
  ])

  name    = each.value
  comment = "Retail ELT project role managed by Terraform"
}

resource "snowflake_grant_account_role" "sysadmin" {
  for_each = snowflake_account_role.project

  role_name        = each.value.name
  parent_role_name = "SYSADMIN"
}
