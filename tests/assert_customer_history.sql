with history as (

    select *
    from {{ ref('snap_customers') }}

),

current_versions as (

    select
        customer_id,
        customer_name,
        count(*) over (
            partition by customer_id
        ) as current_count
    from history
    where dbt_valid_to is null

),

current_errors as (

    select
        coalesce(c.customer_id, s.customer_id) as customer_id,
        'Current version missing, duplicated, or mismatched' as issue
    from {{ ref('stg_customers') }} as c
    full outer join current_versions as s
        on c.customer_id = s.customer_id
    where
        c.customer_id is null
        or s.customer_id is null
        or s.current_count <> 1
        or c.customer_name is distinct from s.customer_name

),

ordered_history as (

    select
        *,
        row_number() over (
            partition by customer_id
            order by dbt_valid_from, dbt_scd_id
        ) as version_number,
        lag(dbt_valid_to) over (
            partition by customer_id
            order by dbt_valid_from, dbt_scd_id
        ) as previous_valid_to
    from history

),

history_errors as (

    select
        customer_id,
        'Invalid or overlapping history dates' as issue
    from ordered_history
    where
        customer_id is null
        or dbt_valid_from is null
        or (
            dbt_valid_to is not null
            and dbt_valid_to <= dbt_valid_from
        )
        or (
            version_number > 1
            and (
                previous_valid_to is null
                or previous_valid_to > dbt_valid_from
            )
        )

)

select * from current_errors
union all
select * from history_errors