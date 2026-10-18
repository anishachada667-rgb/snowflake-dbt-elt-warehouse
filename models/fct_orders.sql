{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_id',
        on_schema_change='fail'
    )
}}

with prepared as (

    select
        *,
        hash(
            order_id,
            customer_id,
            store_id,
            ordered_at,
            order_date,
            subtotal_cents,
            tax_paid_cents,
            order_total_cents,
            subtotal,
            tax_paid,
            order_total,
            item_count,
            distinct_product_count,
            catalog_item_total_cents
        ) as record_hash
    from {{ ref('int_orders_enriched') }}

)

select
    p.*,
    current_timestamp() as warehouse_updated_at
from prepared as p

{% if is_incremental() %}

left join {{ this }} as existing
    on p.order_id = existing.order_id
where
    existing.order_id is null
    or p.record_hash is distinct from existing.record_hash

{% endif %}