{{ config(materialized='view') }}

select
    cast(id as varchar) as order_id,
    cast(customer as varchar) as customer_id,
    cast(store_id as varchar) as store_id,
    cast(ordered_at as timestamp_ntz) as ordered_at,
    cast(ordered_at as date) as order_date,
    cast(subtotal as number(18, 0)) as subtotal_cents,
    cast(tax_paid as number(18, 0)) as tax_paid_cents,
    cast(order_total as number(18, 0)) as order_total_cents,
    cast(subtotal / 100.0 as number(18, 2)) as subtotal,
    cast(tax_paid / 100.0 as number(18, 2)) as tax_paid,
    cast(order_total / 100.0 as number(18, 2)) as order_total
from {{ source('retail_raw', 'orders') }}