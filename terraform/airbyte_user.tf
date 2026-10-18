locals {
  airbyte_public_key = join("", [
    for line in split("\n", trimspace(file("${path.module}/../.keys/airbyte_key.pub"))) :
    trimspace(line)
    if !startswith(trimspace(line), "-----")
  ])
}

resource "snowflake_service_user" "airbyte" {
  name              = "RETAIL_AIRBYTE_USER"
  login_name        = "RETAIL_AIRBYTE_USER"
  default_role      = snowflake_account_role.project["RETAIL_LOADER"].name
  default_warehouse = snowflake_warehouse.elt.name
  rsa_public_key    = local.airbyte_public_key
  comment           = "Dedicated Airbyte ingestion user managed by Terraform"
}

resource "snowflake_grant_account_role" "airbyte_loader" {
  role_name = snowflake_account_role.project["RETAIL_LOADER"].name
  user_name = snowflake_service_user.airbyte.name
}
