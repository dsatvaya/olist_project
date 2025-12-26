-- 1. Clean Customers (Fix: "sao paulo" -> "Sao Paulo")
DROP VIEW IF EXISTS dim_customers CASCADE;
CREATE VIEW dim_customers AS
SELECT 
    customer_id,
    customer_unique_id,
    -- INITCAP capitalizes the first letter of each word
    INITCAP(customer_city) as city, 
    UPPER(customer_state) as state
FROM customers;

-- 2. Clean Products (Fix: The 13 Ghost Categories)
DROP VIEW IF EXISTS dim_products CASCADE;
CREATE VIEW dim_products AS
SELECT 
    p.product_id,
    -- Logic: If English name is NULL, fall back to the Portuguese name.
    -- This fixes 'pc_gamer' and 'portateis_cozinha...'
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') as category,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm
FROM products p
LEFT JOIN product_category_translation t 
    ON p.product_category_name = t.product_category_name;

-- 3. Clean Orders (Fix: Zero Payments & Junk Status)
DROP VIEW IF EXISTS fact_orders CASCADE;
CREATE VIEW fact_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    -- We join payments to filter out the $0.00 glitches
    -- (Note: Using a subquery/aggregation here to ensure 1:1 grain is safe)
    op.total_payment_value
FROM orders o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) as total_payment_value
    FROM order_payments
    GROUP BY 1
) op ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('created', 'unavailable', 'canceled')
  AND op.total_payment_value > 0; -- Filter out the 9 zero-value orders





-- 4. Clean Geolocation (The "Centroid" Logic)
-- This turns 1,000,000 dirty rows into ~4,000 unique, clean locations.
DROP VIEW IF EXISTS dim_geolocation CASCADE;
CREATE VIEW dim_geolocation AS
SELECT 
    geolocation_zip_code_prefix as zip_code,
    -- We average the coordinates to find the "center" of the zip code area
    AVG(geolocation_lat) as lat,
    AVG(geolocation_lng) as lng,
    -- We pick the "MAX" city name as a tie-breaker (usually gets the Capitalized one)
    -- INITCAP ensures it looks pretty ("Sao Paulo")
    INITCAP(MAX(geolocation_city)) as city,
    MAX(geolocation_state) as state
FROM geolocation
GROUP BY 1;




-- 5. Clean Sellers (Standardize City/State)
DROP VIEW IF EXISTS dim_sellers CASCADE;
CREATE VIEW dim_sellers AS
SELECT 
    seller_id,
    seller_zip_code_prefix,
    -- Apply same cleaning rules as Customers
    INITCAP(TRIM(seller_city)) as city,
    UPPER(TRIM(seller_state)) as state
FROM sellers;