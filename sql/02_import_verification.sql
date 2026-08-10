-- 1. Verify customers import

SELECT
    COUNT(*) AS customer_rows
FROM olist.customers;

SELECT *
FROM olist.customers
LIMIT 10;

-- 2. Verify orders import

SELECT
    COUNT(*) AS order_rows
FROM olist.orders;

SELECT *
FROM olist.orders
LIMIT 10;

-- 3. Check order statuses

SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM olist.orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- 4. Verify order payments import

SELECT
    COUNT(*) AS payment_rows
FROM olist.order_payments;

SELECT *
FROM olist.order_payments
LIMIT 10;

-- 5. Find orders with multiple payment records

SELECT
    order_id,
    COUNT(*) AS payment_records
FROM olist.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_records DESC
LIMIT 20;

-- 6. Check payment types and values

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist.order_payments
GROUP BY payment_type
ORDER BY payment_records DESC;

-- 7. Test customers, orders, and payments join

SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_type,
    p.payment_value
FROM olist.customers AS c
INNER JOIN olist.orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN olist.order_payments AS p
    ON o.order_id = p.order_id
LIMIT 20;

-- 8. Check for orders without matching customers
-- Expected result: 0

SELECT
    COUNT(*) AS orders_without_customer
FROM olist.orders AS o
LEFT JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 9. Check for payments without matching orders
-- Expected result: 0

SELECT
    COUNT(*) AS payments_without_order
FROM olist.order_payments AS p
LEFT JOIN olist.orders AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 10. Verify order items import

SELECT COUNT(*) AS order_item_rows
FROM olist.order_items;

SELECT *
FROM olist.order_items
LIMIT 10;

-- 11. Find orders with multiple items

SELECT
    order_id,
    COUNT(*) AS number_of_items
FROM olist.order_items
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY number_of_items DESC
LIMIT 20;

-- 12. Verify products import

SELECT COUNT(*) AS product_rows
FROM olist.products;

SELECT *
FROM olist.products
LIMIT 10;

-- 13. Check for missing product category

SELECT COUNT(*) AS missing_product_categories
FROM olist.products
WHERE product_category_name IS NULL;

-- 14. Verify sellers import

SELECT COUNT(*) AS seller_rows
FROM olist.sellers;

SELECT *
FROM olist.sellers
LIMIT 10;

-- 15. Verify product category translation import

SELECT COUNT(*) AS category_translation_rows
FROM olist.product_category_translation;

SELECT *
FROM olist.product_category_translation
LIMIT 20;

-- 16. Verify order reviews import

SELECT COUNT(*) AS review_rows
FROM olist.order_reviews;

SELECT *
FROM olist.order_reviews
LIMIT 10;

-- 17. Check the review score distribution

SELECT
    review_score,
    COUNT(*) AS number_of_reviews
FROM olist.order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 18. Verify geolocation import

SELECT COUNT(*) AS geolocation_rows
FROM olist.geolocation;

SELECT *
FROM olist.geolocation
LIMIT 10;

-- 19. Find ZIP prefixes with multiple geolocation records

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS location_records
FROM olist.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY location_records DESC
LIMIT 20;

-- 20. Check row counts for all tables

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM olist.customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM olist.orders

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM olist.order_payments

UNION ALL

SELECT 'order_items', COUNT(*)
FROM olist.order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM olist.products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM olist.sellers

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM olist.order_reviews

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM olist.product_category_translation

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM olist.geolocation

ORDER BY table_name;