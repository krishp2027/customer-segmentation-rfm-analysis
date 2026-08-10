-- 1. Find the latest delivered purchase date

SELECT
    MAX(order_purchase_timestamp) AS latest_delivered_purchase
FROM olist.orders
WHERE order_status = 'delivered';

-- 2. Create the RFM analysis date

SELECT
    MAX(order_purchase_timestamp)::DATE + 1 AS analysis_date
FROM olist.orders
WHERE order_status = 'delivered';

-- 3. Aggregate multiple payment records into one total per order

SELECT
    order_id,
    ROUND(SUM(payment_value), 2) AS total_order_payment,
    COUNT(*) AS payment_record_count
FROM olist.order_payments
GROUP BY order_id
ORDER BY payment_record_count DESC
LIMIT 20;

-- 4. Preview the order-level payment summary using a CTE

WITH payment_summary AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
)

SELECT *
FROM payment_summary
LIMIT 20;

-- 5. Build a clean delivered-order dataset

WITH payment_summary AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
)

SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_purchase_timestamp,
    ps.total_order_payment
FROM olist.customers AS c
INNER JOIN olist.orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN payment_summary AS ps
    ON o.order_id = ps.order_id
WHERE o.order_status = 'delivered'
LIMIT 20;

-- 6. Compare delivered orders before and after joining payments

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
),

delivered_order_data AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        ps.total_order_payment
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN payment_summary AS ps
        ON o.order_id = ps.order_id
    WHERE o.order_status = 'delivered'
)

SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM delivered_order_data;

-- 7. Calculate customer-level RFM metrics

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
),

delivered_order_data AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_purchase_timestamp,
        ps.total_order_payment
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN payment_summary AS ps
        ON o.order_id = ps.order_id
    WHERE o.order_status = 'delivered'
),

analysis_date AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE + 1 AS rfm_analysis_date
    FROM delivered_order_data
)

SELECT
    d.customer_unique_id,
    MAX(d.order_purchase_timestamp)::DATE AS last_order_date,
    a.rfm_analysis_date,
    a.rfm_analysis_date
        - MAX(d.order_purchase_timestamp)::DATE AS recency_days,
    COUNT(DISTINCT d.order_id) AS frequency,
    ROUND(SUM(d.total_order_payment), 2) AS monetary
FROM delivered_order_data AS d
CROSS JOIN analysis_date AS a
GROUP BY
    d.customer_unique_id,
    a.rfm_analysis_date
ORDER BY monetary DESC
LIMIT 20;

-- 8. Find the latest recorded location for each customer

WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_purchase_timestamp
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)

SELECT DISTINCT ON (customer_unique_id)
    customer_unique_id,
    customer_city,
    customer_state,
    order_purchase_timestamp
FROM delivered_customer_orders
ORDER BY
    customer_unique_id,
    order_purchase_timestamp DESC
LIMIT 20;

-- 9. Combine RFM metrics with each customer's latest location

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
),

delivered_order_data AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_purchase_timestamp,
        ps.total_order_payment
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN payment_summary AS ps
        ON o.order_id = ps.order_id
    WHERE o.order_status = 'delivered'
),

analysis_date AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE + 1 AS rfm_analysis_date
    FROM delivered_order_data
),

rfm_metrics AS (
    SELECT
        d.customer_unique_id,
        MAX(d.order_purchase_timestamp)::DATE AS last_order_date,
        a.rfm_analysis_date,
        a.rfm_analysis_date
            - MAX(d.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT d.order_id) AS frequency,
        ROUND(SUM(d.total_order_payment), 2) AS monetary
    FROM delivered_order_data AS d
    CROSS JOIN analysis_date AS a
    GROUP BY
        d.customer_unique_id,
        a.rfm_analysis_date
),

latest_customer_location AS (
    SELECT DISTINCT ON (customer_unique_id)
        customer_unique_id,
        customer_city,
        customer_state
    FROM delivered_order_data
    ORDER BY
        customer_unique_id,
        order_purchase_timestamp DESC
)

SELECT
    r.customer_unique_id,
    l.customer_city,
    l.customer_state,
    r.last_order_date,
    r.rfm_analysis_date,
    r.recency_days,
    r.frequency,
    r.monetary
FROM rfm_metrics AS r
INNER JOIN latest_customer_location AS l
    ON r.customer_unique_id = l.customer_unique_id
ORDER BY r.monetary DESC
LIMIT 20;


-- 10. Create the permanent customer RFM table

DROP TABLE IF EXISTS olist.customer_rfm;

CREATE TABLE olist.customer_rfm AS

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
),

delivered_order_data AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_purchase_timestamp,
        ps.total_order_payment
    FROM olist.customers AS c
    INNER JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN payment_summary AS ps
        ON o.order_id = ps.order_id
    WHERE o.order_status = 'delivered'
),

analysis_date AS (
    SELECT
        MAX(order_purchase_timestamp)::DATE + 1 AS rfm_analysis_date
    FROM delivered_order_data
),

rfm_metrics AS (
    SELECT
        d.customer_unique_id,
        MAX(d.order_purchase_timestamp)::DATE AS last_order_date,
        a.rfm_analysis_date,
        a.rfm_analysis_date
            - MAX(d.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT d.order_id) AS frequency,
        ROUND(SUM(d.total_order_payment), 2) AS monetary
    FROM delivered_order_data AS d
    CROSS JOIN analysis_date AS a
    GROUP BY
        d.customer_unique_id,
        a.rfm_analysis_date
),

latest_customer_location AS (
    SELECT DISTINCT ON (customer_unique_id)
        customer_unique_id,
        customer_city,
        customer_state
    FROM delivered_order_data
    ORDER BY
        customer_unique_id,
        order_purchase_timestamp DESC
)

SELECT
    r.customer_unique_id,
    l.customer_city,
    l.customer_state,
    r.last_order_date,
    r.rfm_analysis_date,
    r.recency_days,
    r.frequency,
    r.monetary
FROM rfm_metrics AS r
INNER JOIN latest_customer_location AS l
    ON r.customer_unique_id = l.customer_unique_id;

-- 11. Add a primary key to the RFM table

ALTER TABLE olist.customer_rfm
ADD PRIMARY KEY (customer_unique_id);

-- 12. Count customers in the RFM table

SELECT COUNT(*) AS rfm_customer_count
FROM olist.customer_rfm;

-- Preview 
SELECT *
FROM olist.customer_rfm
LIMIT 20;

-- Check Uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist.customer_rfm;

-- 13. Check missing values in the RFM table

SELECT
    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS missing_customer_id,
    COUNT(*) FILTER (
        WHERE last_order_date IS NULL
    ) AS missing_last_order_date,
    COUNT(*) FILTER (
        WHERE recency_days IS NULL
    ) AS missing_recency,
    COUNT(*) FILTER (
        WHERE frequency IS NULL
    ) AS missing_frequency,
    COUNT(*) FILTER (
        WHERE monetary IS NULL
    ) AS missing_monetary
FROM olist.customer_rfm;

-- 14. Check invalid RFM values

SELECT
    COUNT(*) FILTER (
        WHERE recency_days < 0
    ) AS negative_recency,
    COUNT(*) FILTER (
        WHERE frequency <= 0
    ) AS invalid_frequency,
    COUNT(*) FILTER (
        WHERE monetary <= 0
    ) AS non_positive_monetary
FROM olist.customer_rfm;

-- 15. Summarize RFM metrics

SELECT
    MIN(recency_days) AS minimum_recency,
    ROUND(AVG(recency_days), 2) AS average_recency,
    MAX(recency_days) AS maximum_recency,

    MIN(frequency) AS minimum_frequency,
    ROUND(AVG(frequency), 2) AS average_frequency,
    MAX(frequency) AS maximum_frequency,

    MIN(monetary) AS minimum_monetary,
    ROUND(AVG(monetary), 2) AS average_monetary,
    MAX(monetary) AS maximum_monetary
FROM olist.customer_rfm;

-- 16. Check customer purchase frequency distribution

SELECT
    frequency,
    COUNT(*) AS customer_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_customers
FROM olist.customer_rfm
GROUP BY frequency
ORDER BY frequency;

-- 17. Calculate total customer revenue in the RFM table

SELECT
    ROUND(SUM(monetary), 2) AS total_rfm_revenue
FROM olist.customer_rfm;

-- 18. Independently calculate delivered-order revenue

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_payment
    FROM olist.order_payments
    GROUP BY order_id
)

SELECT
    ROUND(SUM(ps.total_order_payment), 2)
        AS delivered_order_revenue
FROM olist.orders AS o
INNER JOIN payment_summary AS ps
    ON o.order_id = ps.order_id
WHERE o.order_status = 'delivered';

-- 19. View highest-spending customers

SELECT
    customer_unique_id,
    customer_state,
    recency_days,
    frequency,
    monetary
FROM olist.customer_rfm
ORDER BY monetary DESC
LIMIT 20;

-- 20. View most frequent customers

SELECT
    customer_unique_id,
    customer_state,
    recency_days,
    frequency,
    monetary
FROM olist.customer_rfm
ORDER BY
    frequency DESC,
    monetary DESC
LIMIT 20;

-- 21. View most recent customers

SELECT
    customer_unique_id,
    customer_state,
    recency_days,
    frequency,
    monetary
FROM olist.customer_rfm
ORDER BY
    recency_days,
    monetary DESC
LIMIT 20;