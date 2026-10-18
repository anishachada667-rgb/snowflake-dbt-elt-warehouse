{{ config(materialized='view') }}

select
    cast(id as varchar) as store_id,
    trim(cast(name as varchar)) as store_name,
    cast(opened_at as timestamp_ntz) as opened_at,
    cast(tax_rate as number(10, 6)) as tax_rate
from {{ source('retail_raw', 'stores') }}