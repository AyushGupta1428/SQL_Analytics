-- Alteration of Time and Date to suitable format 
ALTER TABLE order_events
MODIFY event_timestamp TIME;

ALTER TABLE orders
MODIFY order_date DATE;

ALTER TABLE users
MODIFY signup_date DATE;

UPDATE orders
SET promised_time_mins = SEC_TO_TIME(promised_time_mins * 60);
ALTER TABLE orders
MODIFY promised_time_mins TIME;



-- The High Value users who shopped in January with Good Experience
WITH cte AS (
    SELECT
        order_id,
        TIMEDIFF(
            MAX(CASE WHEN event_status = 'DELIVERED' THEN event_timestamp END),
            MAX(CASE WHEN event_status = 'PICKED_UP' THEN event_timestamp END)
        ) AS delivery_time
    FROM order_events
    GROUP BY order_id
    HAVING
        MAX(CASE WHEN event_status = 'DELIVERED' THEN event_timestamp END) IS NOT NULL
        AND
        MAX(CASE WHEN event_status = 'PICKED_UP' THEN event_timestamp END) IS NOT NULL
)

SELECT
    c.order_id,
    c.delivery_time,
    o.promised_time_mins,
    u.user_id,
    f.rating
FROM cte c
JOIN orders o ON c.order_id = o.order_id
JOIN users u ON o.user_id = u.user_id
LEFT JOIN feedback f
    ON o.order_id = f.order_id
    AND f.rating >= 4
    AND MONTH(o.order_date) = 1
WHERE
   c.delivery_time <= o.promised_time_mins;



-- Retention rate of happy and high value users returned to buy in February 
WITH jan_orders AS (
    SELECT DISTINCT
        u.user_id
    FROM (
        SELECT
            order_id,
            TIMEDIFF(
                MAX(CASE WHEN event_status = 'DELIVERED' THEN event_timestamp END),
                MAX(CASE WHEN event_status = 'PICKED_UP' THEN event_timestamp END)
            ) AS delivery_time
        FROM order_events
        GROUP BY order_id
        HAVING
            MAX(CASE WHEN event_status = 'DELIVERED' THEN event_timestamp END) IS NOT NULL
            AND
            MAX(CASE WHEN event_status = 'PICKED_UP' THEN event_timestamp END) IS NOT NULL
    ) c
    JOIN orders o ON c.order_id = o.order_id
    JOIN users u ON o.user_id = u.user_id
    LEFT JOIN feedback f
        ON o.order_id = f.order_id
        AND f.rating >= 4
    WHERE
        c.delivery_time <= o.promised_time_mins
        AND MONTH(o.order_date) = 1
),

feb_orders AS (
    SELECT DISTINCT
        user_id
    FROM orders
    WHERE MONTH(order_date) = 2
)

SELECT
    COUNT(DISTINCT j.user_id) AS jan_users,
    COUNT(DISTINCT f.user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT f.user_id) * 100.0 / COUNT(DISTINCT j.user_id),
        2
    ) AS retention_rate
FROM jan_orders j
LEFT JOIN feb_orders f
    ON j.user_id = f.user_id;
    


-- The average actual delivery time for the users receiving order in Minutes    
SELECT
    ROUND( AVG ( TIMESTAMPDIFF ( MINUTE, picked_up_time, delivered_time)), 2) AS avg_delivery_time_mins
FROM (
    SELECT
        order_id,
        MAX(CASE WHEN event_status = 'PICKED_UP' THEN event_timestamp END) AS picked_up_time,
        MAX(CASE WHEN event_status = 'DELIVERED' THEN event_timestamp END) AS delivered_time
    FROM order_events
    GROUP BY order_id
) t
WHERE
    picked_up_time IS NOT NULL
    AND delivered_time IS NOT NULL;
