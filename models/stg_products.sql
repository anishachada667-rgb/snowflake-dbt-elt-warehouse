{{ config(materialized='view') }}

select
    cast(sku as varchar) as product_sku,
    trim(cast(name as varchar)) as product_name,
    lower(trim(cast(type as varchar))) as product_type,
    cast(price as number(18, 0)) as price_cents,
    cast(price / 100.0 as number(18, 2)) as price,
    cast(description as varchar) as product_description
from {{ source('retail_raw', 'products') }}