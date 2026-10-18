with source_totals as (

    select
        count(*) as order_count,
        sum(subtotal_cents) as subtotal_cents,
        sum(tax_paid_cents) as tax_paid_cents,
        sum(order_total_cents) as order_total_cents
    from {{ ref('stg_orders') }}

),

model_totals as (

    select
        count(*) as order_count,
        count(distinct order_id) as unique_orders,
        sum(subtotal_cents) as subtotal_cents,
        sum(tax_paid_cents) as tax_paid_cents,
        sum(order_total_cents) as order_total_cents
    from {{ ref('int_orders_enriched') }}

)

select
    s.order_count as source_orders,
    m.order_count as model_orders,
    m.unique_orders
from source_totals as s
cross join model_totals as m
where
    s.order_count <> m.order_count
    or m.order_count <> m.unique_orders
    or s.subtotal_cents is distinct from m.subtotal_cents
    or s.tax_paid_cents is distinct from m.tax_paid_cents
    or s.order_total_cents is distinct from m.order_total_cents