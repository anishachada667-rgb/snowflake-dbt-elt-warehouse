resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each = snowflake_account_role.project

  account_role_name = each.value.fully_qualified_name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.elt.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each = snowflake_account_role.project

  account_role_name = each.value.fully_qualified_name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.retail.fully_qualified_name
  }
}

locals {
  schema_access = {
    loader_raw = {
      role       = "RETAIL_LOADER"
      schema     = "RAW"
      privileges = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE FILE FORMAT"]
    }
    transformer_raw = {
      role       = "RETAIL_TRANSFORMER"
      schema     = "RAW"
      privileges = ["USAGE"]
    }
    transformer_staging = {
      role       = "RETAIL_TRANSFORMER"
      schema     = "STAGING"
      privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
    }
    transformer_intermediate = {
      role       = "RETAIL_TRANSFORMER"
      schema     = "INTERMEDIATE"
      privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
    }
    transformer_marts = {
      role       = "RETAIL_TRANSFORMER"
      schema     = "MARTS"
      privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
    }
    transformer_snapshots = {
      role       = "RETAIL_TRANSFORMER"
      schema     = "SNAPSHOTS"
      privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
    }
    analyst_marts = {
      role       = "RETAIL_ANALYST"
      schema     = "MARTS"
      privileges = ["USAGE"]
    }
  }

  future_read_access = {
    transformer_raw_tables = {
      role = "RETAIL_TRANSFORMER", schema = "RAW", objects = "TABLES"
    }
    transformer_raw_views = {
      role = "RETAIL_TRANSFORMER", schema = "RAW", objects = "VIEWS"
    }
    analyst_mart_tables = {
      role = "RETAIL_ANALYST", schema = "MARTS", objects = "TABLES"
    }
    analyst_mart_views = {
      role = "RETAIL_ANALYST", schema = "MARTS", objects = "VIEWS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_access" {
  for_each = local.schema_access

  account_role_name = snowflake_account_role.project[each.value.role].fully_qualified_name
  privileges        = each.value.privileges

  on_schema {
    schema_name = snowflake_schema.layers[each.value.schema].fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "future_reads" {
  for_each = local.future_read_access

  account_role_name = snowflake_account_role.project[each.value.role].fully_qualified_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = each.value.objects
      in_schema          = snowflake_schema.layers[each.value.schema].fully_qualified_name
    }
  }
}
