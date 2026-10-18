terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.15.0"
    }
  }
}

variable "private_key_passphrase" {
  description = "Passphrase for the encrypted Terraform private key"
  type        = string
  sensitive   = true
}

provider "snowflake" {
  organization_name      = "AVPLMAJ"
  account_name           = "RX31979"
  user                   = "CHADAAY0908@GMAIL.COM"
  role                   = "ACCOUNTADMIN"
  authenticator          = "SNOWFLAKE_JWT"
  private_key            = file("${path.module}/../.keys/terraform_key.p8")
  private_key_passphrase = var.private_key_passphrase
}

resource "snowflake_warehouse" "elt" {
  name                         = "RETAIL_ELT_WH"
  warehouse_size               = "XSMALL"
  auto_suspend                 = 60
  auto_resume                  = "true"
  initially_suspended          = true
  statement_timeout_in_seconds = 300
  comment                      = "Compute for the retail ELT portfolio project"
}

resource "snowflake_database" "retail" {
  name    = "RETAIL_ANALYTICS"
  comment = "Retail ELT warehouse managed by Terraform"
}

