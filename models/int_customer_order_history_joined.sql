with recursive customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

customer_orders as (

        select
        customer_id,

        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders
    from orders

    group by customer_id

),

customer_payments as (

    select
        orders.customer_id,
        sum(amount)::bigint as total_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    group by orders.customer_id

),

dup as (
    select customer_payments.*, 1 as lvl
    from customer_payments

    union all

    select customer_payments.*, dup.lvl + 1
    from dup
    join customer_payments on customer_payments.customer_id = dup.customer_id
    where dup.lvl < 8000
),

dedup as (
    select distinct customer_id, total_amount from dup
),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        dedup.total_amount as customer_lifetime_value

    from customers

    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

    left join dedup
        on  customers.customer_id = dedup.customer_id

)

select * from final
