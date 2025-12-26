SELECT 
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') as month,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(oi.price) as total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1
limit 10;