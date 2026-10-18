{{ config(materialized='view') }}

select
    cast(id as varchar) as customer_id,
    trim(cast(name as varchar)) as customer_name
from {{ source('retail_raw', 'customers') }}