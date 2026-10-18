{% snapshot snap_customers %}

{{
    config(
        target_schema=target.schema,
        unique_key='customer_id',
        strategy='check',
        check_cols=['customer_name']
    )
}}

select
    customer_id,
    customer_name
from {{ ref('stg_customers') }}

{% endsnapshot %}