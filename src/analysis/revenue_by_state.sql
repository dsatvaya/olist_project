SELECT
    c.state,
    count(DISTINCT fo.order_id) as total_orders,
    TO_CHAR(sum(o.price), 'FM$999,999,999.00') as total_revenue,
    TO_CHAR(sum(o.freight_value), 'FM$999,999,999.00') as total_freight
FROM fact_orders fo
JOIN dim_customers c ON fo.customer_id = c.customer_id
JOIN order_items o ON fo.order_id = o.order_id
GROUP BY 1
ORDER BY sum(o.price) DESC
limit 10;





SELECT
    s.state as seller_state,
    count(DISTINCT fo.order_id) as total_orders,
    TO_CHAR(sum(o.price), 'FM$999,999,999.00') as total_revenue,
    TO_CHAR(sum(o.freight_value), 'FM$999,999,999.00') as total_freight
FROM fact_orders fo
join order_items o ON fo.order_id = o.order_id
JOIN dim_sellers s ON o.seller_id = s.seller_id
join dim_customers c ON fo.customer_id = c.customer_id
WHERE c.state = 'SP'
GROUP BY 1
ORDER BY sum(o.price) DESC 
limit 5;




