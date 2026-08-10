-- 1. Check for duplicate customer_id values

SELECT
    customer_id,
    COUNT(*) AS record_count
FROM olist.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2. Check for duplicate order_id values

SELECT
    order_id,
    COUNT(*) AS record_count
FROM olist.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Check for duplicate order-item combinations

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS record_count
FROM olist.order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

-- 4. Check missing values in customers

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS missing_unique_id,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS missing_zip_code,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS missing_state
FROM olist.customers;

-- 5. Check missing values in orders

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS missing_order_status,
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_timestamp,
    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_timestamp,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_date,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_customer_delivery_date,
    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery_date
FROM olist.orders;

-- 6. Investigate missing delivery dates by order status

SELECT
    order_status,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates
FROM olist.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 7. Check delivered orders without a customer delivery date

SELECT
    COUNT(*) AS delivered_orders_without_delivery_date
FROM olist.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 8. Check missing values in order payments

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (
        WHERE payment_sequential IS NULL
    ) AS missing_payment_sequence,
    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_type,
    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS missing_installments,
    COUNT(*) FILTER (
        WHERE payment_value IS NULL
    ) AS missing_payment_value
FROM olist.order_payments;

-- 9. Check zero or negative payment values

SELECT
    COUNT(*) AS invalid_payment_records
FROM olist.order_payments
WHERE payment_value <= 0;

SELECT *
FROM olist.order_payments
WHERE payment_value <= 0
ORDER BY payment_value;

-- 10. Check unusual installment values

SELECT
    MIN(payment_installments) AS minimum_installments,
    MAX(payment_installments) AS maximum_installments,
    ROUND(AVG(payment_installments), 2) AS average_installments
FROM olist.order_payments;

-- Check zero installments

SELECT
    COUNT(*) AS zero_installment_records
FROM olist.order_payments
WHERE payment_installments = 0;

-- 11. Check orders without matching customers

SELECT
    COUNT(*) AS orders_without_matching_customer
FROM olist.orders AS o
LEFT JOIN olist.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 12. Check payment records without matching orders

SELECT
    COUNT(*) AS payments_without_matching_order
FROM olist.order_payments AS p
LEFT JOIN olist.orders AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 13. Check orders without payment records

SELECT
    COUNT(*) AS orders_without_payments
FROM olist.orders AS o
LEFT JOIN olist.order_payments AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

-- Preview the affected orders

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist.orders AS o
LEFT JOIN olist.order_payments AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL
ORDER BY o.order_purchase_timestamp
LIMIT 20;

-- 14. Check orders without order-item records

SELECT
    COUNT(*) AS orders_without_items
FROM olist.orders AS o
LEFT JOIN olist.order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- Preview

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist.orders AS o
LEFT JOIN olist.order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
ORDER BY o.order_purchase_timestamp
LIMIT 20;

-- 15. Check order items without matching products

SELECT
    COUNT(*) AS items_without_matching_product
FROM olist.order_items AS oi
LEFT JOIN olist.products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 16. Check order items without matching sellers

SELECT
    COUNT(*) AS items_without_matching_seller
FROM olist.order_items AS oi
LEFT JOIN olist.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 17. Check the purchase date range

SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM olist.orders;

-- 18. Check deliveries occurring before purchases

SELECT
    COUNT(*) AS delivery_before_purchase_records
FROM olist.orders
WHERE order_delivered_customer_date
      < order_purchase_timestamp;

-- 19. Check approvals occurring before purchases

SELECT
    COUNT(*) AS approval_before_purchase_records
FROM olist.orders
WHERE order_approved_at
      < order_purchase_timestamp;

-- 20. Check carrier dates occurring before purchases

SELECT
    COUNT(*) AS carrier_before_purchase_records
FROM olist.orders
WHERE order_delivered_carrier_date
      < order_purchase_timestamp;

-- 21. Check order status counts and percentages

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders
FROM olist.orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 22. Count delivered orders

SELECT
    COUNT(*) AS delivered_orders
FROM olist.orders
WHERE order_status = 'delivered';

-- 23. Check delivered orders without payment records

SELECT
    COUNT(*) AS delivered_orders_without_payment
FROM olist.orders AS o
LEFT JOIN olist.order_payments AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND p.order_id IS NULL;

-- 24. Compare customer IDs and unique customer IDs

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers
FROM olist.customers;

-- 25. Find customers connected to multiple customer_id values

SELECT
    customer_unique_id,
    COUNT(DISTINCT customer_id) AS customer_id_count
FROM olist.customers
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY customer_id_count DESC
LIMIT 20;

-- 26. Examine delivered order frequency per unique customer

SELECT
    order_frequency,
    COUNT(*) AS customer_count
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_frequency
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_frequency
GROUP BY order_frequency
ORDER BY order_frequency;

-- 27. Count orders with multiple payment records

SELECT
    COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT
        order_id
    FROM olist.order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS multiple_payment_orders;

-- 28. Preview one payment total per order

SELECT
    order_id,
    SUM(payment_value) AS total_order_payment,
    COUNT(*) AS payment_record_count
FROM olist.order_payments
GROUP BY order_id
ORDER BY payment_record_count DESC
LIMIT 20;