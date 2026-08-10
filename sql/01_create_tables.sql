-- Create the project schema

CREATE SCHEMA IF NOT EXISTS olist;

-- Use the olist schema for the current session

SET search_path TO olist;

-- 1. Customers table

CREATE TABLE IF NOT EXISTS olist.customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

-- 2. Orders table

CREATE TABLE IF NOT EXISTS olist.orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 3. Order payments table

CREATE TABLE IF NOT EXISTS olist.order_payments (
    order_id TEXT NOT NULL,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC(12, 2)
);

-- 4. Order items table

CREATE TABLE IF NOT EXISTS olist.order_items (
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2),
    freight_value NUMERIC(12, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 5. Products table

CREATE TABLE IF NOT EXISTS olist.products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- 6. Sellers table

CREATE TABLE IF NOT EXISTS olist.sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

-- 7. Order reviews table

CREATE TABLE IF NOT EXISTS olist.order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- 8. Product category translation table

CREATE TABLE IF NOT EXISTS olist.product_category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

-- 9. Geolocation table

CREATE TABLE IF NOT EXISTS olist.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city TEXT,
    geolocation_state TEXT
);