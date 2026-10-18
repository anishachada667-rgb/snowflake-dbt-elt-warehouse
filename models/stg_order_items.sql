{{ config(materialized='view') }}

select
    cast(id as varchar) as order_item_id,
    cast(order_id as varchar) as order_id,
    cast(sku as varchar) as product_sku
from {{ source('retail_raw', 'order_items') }}