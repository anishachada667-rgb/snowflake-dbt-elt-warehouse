# Snowflake Retail Analytics ELT Warehouse

An end-to-end retail ELT project using Airbyte, Snowflake, dbt Cloud, Terraform, and GitHub Actions.

## Business problem

Retail reporting requires consistent data across orders, order items, customers, products, and stores. Joining these datasets incorrectly can duplicate order totals, while full reloads of analytical tables can rewrite unchanged records. Overwriting customer details also removes the history needed to understand changes.

This project demonstrates how to centralize retail data, build tested reporting models, update changed orders, preserve customer history, and validate code before merging it.

## Architecture

- **Airbyte:** Loads five public CSV datasets into Snowflake RAW tables.
- **Snowflake:** Stores raw data and analytical models.
- **dbt Cloud:** Builds staging views, an intermediate model, an incremental order fact table, a daily store sales mart, and a customer snapshot.
- **Terraform:** Creates Snowflake databases, schemas, compute, service users, roles, and grants.
- **GitHub Actions:** Builds and tests dbt changes in an isolated CI database for pull requests.

Development models currently run in `RETAIL_ANALYTICS.DBT_ACHADA`. CI models run in a separate database, `RETAIL_ANALYTICS_CI`, using a schema associated with the pull request.

## Dataset

This project uses dbt Labs’ public, synthetic Jaffle Shop dataset.

| Dataset | Loaded records |
|---|---:|
| Orders | 2,088,006 |
| Order items | 3,024,215 |
| Customers | 3,102 |
| Products | 10 |
| Stores | 6 |
| **Total** | **5,115,339** |

These are simulated retail records, not production company data.

## Data models

| Model | Purpose |
|---|---|
| `stg_customers` | Standardizes customer IDs and names |
| `stg_products` | Standardizes products and converts prices from cents |
| `stg_stores` | Standardizes store details |
| `stg_orders` | Standardizes order dates, keys, and monetary values |
| `stg_order_items` | Standardizes order-item relationships |
| `int_orders_enriched` | Aggregates items to order grain before joining orders |
| `fct_orders` | Maintains one record per order using incremental merges |
| `mart_daily_store_sales` | Summarizes daily sales and order activity by store |
| `snap_customers` | Preserves customer name changes using SCD Type 2 |

Aggregating order items before joining them to orders prevents order-level amounts from being multiplied by the number of items.

## Incremental processing

The order fact model uses a record hash to identify new or changed records and a merge keyed by `order_id`.

- Unchanged records are excluded from the merge input.
- Existing orders can be updated, including orders with older order dates.
- A controlled source update verified that a changed order reached the fact table.
- The test change was restored after verification.

This approach scans the source model to detect changes; it is not a watermark-based extraction strategy. Source deletions are not currently propagated to the order fact table.

## Customer history

The customer snapshot uses a check strategy on `customer_name`.

When a name changes, dbt closes the previous version and creates a new current version. A controlled name change and restoration demonstrated historical and current records.

Snapshot history begins when the project starts capturing changes. It does not reconstruct changes that happened before the first snapshot.

## Data quality

The project contains **40 data tests**, covering:

- Unique and non-null identifiers.
- Relationships between orders, customers, stores, products, and order items.
- Reconciliation of order counts and monetary totals.
- Daily store sales consistency.
- Exactly one current customer version and valid, non-overlapping history intervals.

The verified build on `main` completed with:

| Resource | Count |
|---|---:|
| Models | 8 |
| Data tests | 40 |
| Snapshot | 1 |
| **Successful build tasks** | **49** |
| Warnings | 0 |
| Errors | 0 |

An observed development build completed in **9.8 seconds**. This is a single measured run, not a performance benchmark.

## Pull request CI

GitHub Actions runs on pull requests targeting `main`.

The workflow:

1. Checks out the project and installs dbt Snowflake.
2. Configures key-pair authentication using repository secrets.
3. Checks the Snowflake connection.
4. Installs dbt dependencies.
5. Runs `dbt build`.
6. Reruns the incremental order model and its selected tests.
7. Removes temporary credential files.

CI uses a dedicated Snowflake service user and role. It reads the shared RAW tables and builds models in an isolated CI database.

The updated workflow uses Node.js 24-compatible actions and an Ubuntu 24.04 runner. The pull request passed CI and was merged into `main`.

## Infrastructure and access

Terraform manages:

- An X-Small warehouse with 60-second auto-suspend.
- The retail database and layer schemas.
- Loader, transformer, and analyst roles.
- Airbyte and dbt service users.
- Database, schema, warehouse, and table permissions.
- A separate CI database, role, and user.

Private keys, passphrases, Terraform state, and local environment files are excluded from Git.

## Run the project

### 1. Provision Snowflake infrastructure

Review the account settings and public-key file references in `terraform/`.

Generate the required key pairs using the scripts in `scripts/`. Register the Terraform administrator public key with the intended Snowflake user.

From the repository root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

Enter the encrypted Terraform key passphrase when prompted.

### 2. Configure Airbyte

Create five HTTPS CSV sources using this public dataset location:

https://dbt-tutorial-public.s3.us-west-2.amazonaws.com/long_term_dataset/

Use the files:

- `raw_orders.csv`
- `raw_items.csv`
- `raw_customers.csv`
- `raw_products.csv`
- `raw_stores.csv`

Configure the Snowflake destination with the loader service user and its key pair. Map the datasets to:

- `RAW_ORDERS`
- `RAW_ORDER_ITEMS`
- `RAW_CUSTOMERS`
- `RAW_PRODUCTS`
- `RAW_STORES`

The demonstration uses manual full-refresh overwrite connections.

### 3. Configure dbt Cloud

Connect this repository to dbt Cloud and configure the Snowflake development connection with:

- The retail database.
- The project warehouse.
- The transformer role.
- The development service user and encrypted private key.
- A personal development schema.

Run:

```text
dbt deps
dbt build
```

### 4. Configure CI secrets

Add these GitHub repository Actions secrets:

- `SNOWFLAKE_CI_PRIVATE_KEY`
- `SNOWFLAKE_CI_KEY_PASSPHRASE`

The private-key secret must contain the complete encrypted PEM key. Use the corresponding passphrase for the second secret.

Review the account and service-user settings in `.github/workflows/dbt-ci.yml` before running CI in another Snowflake account.

## Screenshots

### Airbyte ingestion
![Airbyte orders sync](screenshots/airbyte_orders_sync_success.png)

### Snowflake infrastructure
![Snowflake schemas](screenshots/snowflake_schemas.png)

### Customer validation
![Customer validation](screenshots/snowflake_customers_validation.png)

### Successful dbt build
![dbt build on main](screenshots/dbt_build_success.png)

### Order fact validation
![Order fact validation](screenshots/snowflake_orders_validation.png)

### Customer history
![Customer SCD Type 2 history](screenshots/customer_scd_history.png)

### GitHub Actions CI
![Successful pull request CI](screenshots/github_actions_ci_success.png)

## Limitations and future improvements

- The source consists of static public CSV files.
- Airbyte ingestion uses full refresh; incremental processing occurs in the dbt order fact model.
- Incremental change detection still scans the source model.
- Order fact deletions and snapshot hard deletes are not implemented.
- Catalog prices represent the available product data, not a historical transaction-price ledger.
- Development models share a personal schema; dedicated deployment schemas and a scheduled deployment job are future improvements.
- CI schemas currently remain after runs; automated cleanup is a future improvement.
- Additional improvements include source freshness checks, dependency version pinning, and business dashboards.

## Cost management

The warehouse uses X-Small compute and auto-suspends after 60 seconds of inactivity. Queries and CI runs can resume it.

Airbyte, dbt Cloud, and Snowflake trial or subscription limits should be reviewed separately. Disable schedules and suspend compute when the project is not in use.

## Author

Anisha Reddy Chada