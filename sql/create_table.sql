
-- 1. Geolocation
DROP TABLE IF EXISTS geolocation CASCADE;
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
    -- REMOVED PK to allow duplicates/dirty data during load
);

-- 2. Customers
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5) NOT NULL,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- 3. Sellers
DROP TABLE IF EXISTS sellers CASCADE;
CREATE TABLE sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5) NOT NULL,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 4. Product Category Translation
DROP TABLE IF EXISTS product_category_translation CASCADE;
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- 5. Products
DROP TABLE IF EXISTS products CASCADE;
CREATE TABLE products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 6. Orders
DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL REFERENCES customers(customer_id),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 7. Order Items
DROP TABLE IF EXISTS order_items CASCADE;
CREATE TABLE order_items (
    order_id CHAR(32) NOT NULL REFERENCES orders(order_id),
    order_item_id INT NOT NULL,
    product_id CHAR(32) NOT NULL REFERENCES products(product_id),
    seller_id CHAR(32) NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 8. Order Payments
DROP TABLE IF EXISTS order_payments CASCADE;
CREATE TABLE order_payments (
    order_id CHAR(32) NOT NULL REFERENCES orders(order_id),
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- 9. Order Reviews
DROP TABLE IF EXISTS order_reviews CASCADE;
CREATE TABLE order_reviews (
    review_id CHAR(32),
    order_id CHAR(32) NOT NULL REFERENCES orders(order_id),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id) -- Composite Key handles duplicates better
);

-- Suggested indexes
CREATE INDEX idx_customers_zip_prefix ON customers(customer_zip_code_prefix);
CREATE INDEX idx_sellers_zip_prefix   ON sellers(seller_zip_code_prefix);
CREATE INDEX idx_orders_customer_id   ON orders(customer_id);
CREATE INDEX idx_orders_purchase_ts   ON orders(order_purchase_timestamp);
CREATE INDEX idx_order_items_product  ON order_items(product_id);
CREATE INDEX idx_order_items_seller   ON order_items(seller_id);
CREATE INDEX idx_reviews_order_id     ON order_reviews(order_id);
CREATE INDEX idx_payments_order_id    ON order_payments(order_id);