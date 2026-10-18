{{ config(materialized='view') }}

with item_summary as (

    select
        i.order_id,
        count(*) as item_count,
        count(distinct i.product_sku) as distinct_product_count,
        sum(p.price_cents) as catalog_item_total_cents
    from {{ ref('stg_order_items') }} as i
    left join {{ ref('stg_products') }} as p
        on i.product_sku = p.product_sku
    group by i.order_id

)

select
    o.order_id,
    o.customer_id,
    o.store_id,
    o.ordered_at,
    o.order_date,
    o.subtotal_cents,
    o.tax_paid_cents,
    o.order_total_cents,
    o.subtotal,
    o.tax_paid,
    o.order_total,
    coalesce(i.item_count, 0) as item_count,
    coalesce(i.distinct_product_count, 0) as distinct_product_count,
    i.catalog_item_total_cents
from {{ ref('stg_orders') }} as o
left join item_summary as i
    on o.order_id = i.order_id