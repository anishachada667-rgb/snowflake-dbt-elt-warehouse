{{ config(materialized='table') }}

with daily_sales as (

    select
        order_date,
        store_id,
        count(*) as order_count,
        count(distinct customer_id) as purchasing_customers,
        sum(item_count) as items_sold,
        sum(subtotal_cents) as sales_before_tax_cents,
        sum(tax_paid_cents) as tax_collected_cents,
        sum(order_total_cents) as total_order_value_cents
    from {{ ref('int_orders_enriched') }}
    group by
        order_date,
        store_id

)

select
    d.order_date,
    d.store_id,
    s.store_name,
    d.order_count,
    d.purchasing_customers,
    d.items_sold,
    cast(d.sales_before_tax_cents / 100.0 as number(18, 2))
        as sales_before_tax,
    cast(d.tax_collected_cents / 100.0 as number(18, 2))
        as tax_collected,
    cast(d.total_order_value_cents / 100.0 as number(18, 2))
        as total_order_value,
    cast(
        d.total_order_value_cents / 100.0
        / nullif(d.order_count, 0)
        as number(18, 2)
    ) as average_order_value
from daily_sales as d
left join {{ ref('stg_stores') }} as s
    on d.store_id = s.store_id