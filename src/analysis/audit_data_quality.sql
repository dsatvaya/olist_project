SELECT
    order_status,
    count(*) as count
from orders
group by 1
order by 2 Desc;

SELECT * from customers limit 10;


-- 1. The "Sao Paulo" Problem
-- Check for variations of the same city name (Capitalization/Accents)
SELECT 
    UPPER(TRIM(customer_city)) as standardized_city,
    COUNT(DISTINCT customer_city) as variations_count,
    STRING_AGG(DISTINCT customer_city, ', ' ORDER BY customer_city) as examples
FROM customers
GROUP BY 1
HAVING COUNT(DISTINCT customer_city) > 1
ORDER BY 2 DESC
LIMIT 5;

-- 2. The "Ghost" Categories
-- Find products linked to categories that have no English translation
SELECT 
    p.product_category_name as original_category,
    COUNT(*) as affected_products
FROM products p
LEFT JOIN product_category_translation t 
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- 3. Payment Precision Check
-- Ensure no payment values look suspicious (e.g., negative or zero)
SELECT 
    payment_value,
    COUNT(*) 
FROM order_payments
WHERE payment_value <= 0
GROUP BY 1;


SELECT 
    customer_city, 
    COUNT(*) as count
FROM customers
WHERE customer_city ILIKE 's%o paulo' -- ILIKE ignores case, % captures 'a' or 'ã'
GROUP BY 1
ORDER BY 2 DESC;




-- 1. Confirm the dirt in Geolocation
SELECT 
    geolocation_city, 
    COUNT(*) 
FROM geolocation
--WHERE geolocation_city ILIKE 's%o paulo'
GROUP BY 1
ORDER BY 1 DESC,2 DESC;

-- 2. The "Mismatch" Test
-- How many customers live in a city that Geolocation doesn't recognize?
-- If this number is high, our "Map" reports will be broken.
SELECT 
    COUNT(*) as orphaned_customers
FROM customers c
LEFT JOIN geolocation g 
    -- Try to join strictly by Zip Code first (Best Practice)
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;