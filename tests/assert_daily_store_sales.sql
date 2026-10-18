with expected as (

    select
        order_date,
        store_id,
        count(*) as order_count,
        count(distinct customer_id) as purchasing_customers,
        sum(item_count) as items_sold,
        sum(subtotal_cents) as sales_cents,
        sum(tax_paid_cents) as tax_cents,
        sum(order_total_cents) as total_cents
    from {{ ref('int_orders_enriched') }}
    group by order_date, store_id

),

actual as (

    select
        *,
        count(*) over (
            partition by order_date, store_id
        ) as rows_per_store_day
    from {{ ref('mart_daily_store_sales') }}

)

select
    coalesce(e.order_date, a.order_date) as order_date,
    coalesce(e.store_id, a.store_id) as store_id
from expected as e
full outer join actual as a
    on e.order_date = a.order_date
    and e.store_id = a.store_id
where
    e.store_id is null
    or a.store_id is null
    or a.rows_per_store_day <> 1
    or a.store_name is null
    or e.order_count is distinct from a.order_count
    or e.purchasing_customers is distinct from a.purchasing_customers
    or e.items_sold is distinct from a.items_sold
    or e.sales_cents is distinct from (a.sales_before_tax * 100)
    or e.tax_cents is distinct from (a.tax_collected * 100)
    or e.total_cents is distinct from (a.total_order_value * 100)
    or a.average_order_value is distinct from
        cast(
            e.total_cents / 100.0 / nullif(e.order_count, 0)
            as number(18, 2)
        )