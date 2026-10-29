USE pizza_runner

-- Preprocessing and Cleaning
-- customer_orders

SELECT
order_id,
customer_id,
pizza_id,
COALESCE(NULLIF(exclusions, 'NULL'), ' ') AS exclusions,
COALESCE(NULLIF(extras, 'NULL'), ' ') AS extras,
order_time
INTO #customer_orders_cleaned
FROM customer_orders


-- runner_orders

SELECT 
order_id,
runner_id,
COALESCE(NULLIF(pickup_time, 'null'), NULL) AS pickup_time,
CAST(COALESCE(NULLIF(REPLACE(distance, 'km', ''),'null'), NULL) AS DECIMAL(10,2)) AS distance,
CAST(COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(duration, 'mins', ''),'minutes', ''),'minute', ''),'NULL'), NULL) AS DECIMAL(10,2)) AS duration,
COALESCE(NULLIF(NULLIF(cancellation, 'null'),''), NULL) AS cancellation
INTO #runner_orders_cleaned
FROM runner_orders

--A. Pizza Metrics
--How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered FROM #customer_orders_cleaned
--14

--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders FROM #customer_orders_cleaned
-- 10

--How many successful orders were delivered by each runner?
SELECT COUNT(*) AS successful_deliveries FROM #runner_orders_cleaned WHERE cancellation IS NULL
-- 8

--How many of each type of pizza was delivered?
SELECT 
	CAST(p.pizza_name AS VARCHAR(20)) AS pizza_name,
	COUNT(*) AS pizzas_delivered
FROM #runner_orders_cleaned as ro 
JOIN #customer_orders_cleaned as co 
ON ro.order_id = co.order_id
JOIN pizza_names as p 
ON co.pizza_id = p.pizza_id
WHERE cancellation IS NULL
GROUP BY CAST(p.pizza_name AS VARCHAR(20))

--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    customer_id,
    COUNT(CASE WHEN CAST(p.pizza_name AS VARCHAR(20)) = 'Meatlovers' THEN 1 END) AS Meatlovers,
    COUNT(CASE WHEN CAST(p.pizza_name AS VARCHAR(20)) = 'Vegetarian' THEN 1 END) AS Vegetarian
FROM #customer_orders_cleaned AS co
JOIN pizza_names as p 
ON co.pizza_id = p.pizza_id
GROUP BY customer_id


--What was the maximum number of pizzas delivered in a single order?
SELECT TOP 1
	co.order_id,
	COUNT(*) AS pizzas_per_order
FROM #customer_orders_cleaned AS co
JOIN #runner_orders_cleaned AS ro
ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizzas_per_order DESC

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	customer_id,
	COUNT(CASE WHEN exclusions != '' OR extras != '' THEN 1 END) AS with_changes,
	COUNT(CASE WHEN exclusions = '' AND extras = '' THEN 1 END) AS no_changes
FROM #customer_orders_cleaned AS co
JOIN #runner_orders_cleaned AS ro
ON co.order_id = ro.order_id
WHERE cancellation IS NULL
GROUP BY customer_id

--How many pizzas were delivered that had both exclusions and extras?
SELECT
	COUNT(*) AS count
FROM #customer_orders_cleaned AS co
JOIN #runner_orders_cleaned AS ro
ON co.order_id = ro.order_id
WHERE 
	cancellation IS NULL AND
	exclusions != '' AND
	extras != ''

--What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	DATEPART(hour, order_time) AS hour_ordered,
	COUNT(*) AS pizzas_ordered
FROM #customer_orders_cleaned
GROUP BY DATEPART(hour, order_time) 

--What was the volume of orders for each day of the week?
SELECT 
	DATENAME(weekday, order_time) AS day_of_week,
	COUNT(*) AS pizzas_ordered
FROM #customer_orders_cleaned
GROUP BY DATENAME(weekday, order_time), DATEPART(weekday, order_time)
ORDER BY DATEPART(weekday, order_time) 


--B. Runner and Customer Experience
--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
    DATEDIFF(day, '2021-01-01', registration_date) / 7 + 1 AS week_number,
    COUNT(*) AS runners_signedup
FROM runners
WHERE registration_date >= '2021-01-01'
GROUP BY DATEDIFF(day, '2021-01-01', registration_date) / 7 + 1


--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH customer_orders_cte AS (
    SELECT
        order_id,
        MIN(order_time) AS order_time
    FROM #customer_orders_cleaned
    GROUP BY order_id
)
SELECT
	r.runner_id,
    AVG(DATEDIFF(
        MINUTE, co.order_time, ro.pickup_time)
        ) AS avg_pickup_time
FROM runners AS r
LEFT JOIN #runner_orders_cleaned AS ro
ON r.runner_id = ro.runner_id
LEFT JOIN customer_orders_cte AS co
ON ro.order_id = co.order_id
WHERE cancellation IS NULL
GROUP BY r.runner_id



--Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_cte AS (
SELECT 
    co.order_id, 
    COUNT(co.order_id) AS pizza_order, 
    order_time, 
    pickup_time, 
    DATEDIFF(MINUTE, order_time, pickup_time) AS prep_time
  FROM #customer_orders_cleaned AS co
  JOIN #runner_orders_cleaned AS ro
    ON co.order_id = ro.order_id
  WHERE cancellation IS NULL
  GROUP BY co.order_id, order_time, pickup_time
  )
SELECT 
  pizza_order, 
  AVG(prep_time) AS avg_prep_time_minutes
FROM prep_time_cte
GROUP BY pizza_order

--What was the average distance travelled for each customer?
WITH order_distances AS (
    SELECT DISTINCT
        co.customer_id,
        co.order_id,
        distance
    FROM #customer_orders_cleaned AS co
    JOIN #runner_orders_cleaned AS ro
        ON co.order_id = ro.order_id
    WHERE cancellation IS NULL
)
SELECT
    customer_id,
    ROUND(AVG(distance), 2) AS avg_distance
FROM order_distances
GROUP BY customer_id
ORDER BY customer_id

--What was the difference between the longest and shortest delivery times for all orders?
WITH delivery_times_cte AS (
    SELECT
        order_id,
        duration
    FROM #runner_orders_cleaned
    WHERE cancellation IS NULL
)
SELECT
    MIN(duration) AS shortest_delivery,
    MAX(duration) AS longest_delivery,
	MAX(duration) - MIN(duration) AS difference
FROM delivery_times_cte

--What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH runner_speed_cte AS (
    SELECT DISTINCT
        runner_id,
        co.order_id,
        duration,
        distance
    FROM #runner_orders_cleaned AS ro
    JOIN #customer_orders_cleaned AS co
        ON co.order_id = ro.order_id
    WHERE cancellation IS NULL
)
SELECT
    runner_id,
    order_id,
    ROUND(
        CAST(distance AS FLOAT) / NULLIF(
            CAST(duration AS FLOAT), 0) * 60,
        2
    ) AS speed_kmh
FROM runner_speed_cte
ORDER BY runner_id, order_id

--What is the successful delivery percentage for each runner?
WITH success_count_cte AS (
SELECT
    r.runner_id,
    CAST(SUM(CASE 
            WHEN co.order_id IS NOT NULL AND cancellation IS NULL 
            THEN 1 ELSE 0 END) 
            AS FLOAT) AS success,
    CAST(SUM(CASE 
            WHEN co.order_id IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) AS assigned_deliveries
FROM #runner_orders_cleaned AS ro
JOIN #customer_orders_cleaned AS co
ON ro.order_id = co.order_id
RIGHT JOIN runners AS r
ON ro.runner_id = r.runner_id
GROUP BY r.runner_id
)
SELECT
    *,
    ROUND((success /NULLIF(assigned_deliveries, 0)) * 100 , 2) AS success_perc
FROM success_count_cte 


--C. Ingredient Optimisation
--What are the standard ingredients for each pizza?

SELECT
    CAST(pizza_name AS VARCHAR(MAX)) AS pizza_name,
    STRING_AGG(CAST(topping_name AS VARCHAR(MAX)), ', ') AS ingredients
FROM pizza_recipes r
CROSS APPLY STRING_SPLIT(CAST(r.toppings AS VARCHAR(MAX)), ',') s
JOIN pizza_names pn ON pn.pizza_id = r.pizza_id
LEFT JOIN pizza_toppings t 
    ON TRIM(s.value) = t.topping_id
GROUP BY pn.pizza_id, CAST(pizza_name AS VARCHAR(MAX))


--What was the most commonly added extra?
WITH extras_cte AS(
    SELECT 
        order_id,
        topping_name
    FROM #customer_orders_cleaned c
    CROSS APPLY STRING_SPLIT(extras, ',') AS s
    JOIN pizza_toppings AS t 
        ON TRIM(s.value) = t.topping_id
)
SELECT TOP 1
    CAST(topping_name AS VARCHAR(MAX)) AS topping_name,
    COUNT(*) AS count
FROM extras_cte
GROUP BY CAST(topping_name AS VARCHAR(MAX))
ORDER BY count DESC

--What was the most common exclusion?
WITH exclusions_cte AS(
    SELECT 
        order_id,
        topping_name
    FROM #customer_orders_cleaned c
    CROSS APPLY STRING_SPLIT(exclusions, ',') AS s
    JOIN pizza_toppings AS t 
        ON TRIM(s.value) = t.topping_id
)
SELECT TOP 1
    CAST(topping_name AS VARCHAR(MAX)) AS topping_name,
    COUNT(*) AS count
FROM exclusions_cte 
GROUP BY CAST(topping_name AS VARCHAR(MAX))
ORDER BY count DESC

--Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH orders AS (
    SELECT *,
        ROW_NUMBER() OVER (
            ORDER BY order_id, customer_id, pizza_id,
                     order_time, exclusions, extras
        ) AS row_id
    FROM #customer_orders_cleaned
),
extras_cte AS (
    SELECT
        o.row_id,
        STRING_AGG(CAST(t.topping_name AS VARCHAR(MAX)), ', ') AS extras
    FROM orders o
    CROSS APPLY STRING_SPLIT(o.extras, ',') s
    JOIN pizza_toppings t
        ON TRY_CAST(TRIM(s.value) AS INT) = t.topping_id
    GROUP BY o.row_id
),
exclusions_cte AS (
    SELECT
        o.row_id,
        STRING_AGG(CAST(t.topping_name AS VARCHAR(MAX)), ', ') AS exclusions
    FROM orders o
    CROSS APPLY STRING_SPLIT(o.exclusions, ',') s
    JOIN pizza_toppings t
        ON TRY_CAST(TRIM(s.value) AS INT) = t.topping_id
    GROUP BY o.row_id
)
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.order_time,
    CONCAT(
        pn.pizza_name,
        CASE WHEN excl.exclusions IS NOT NULL
            THEN ' - Exclude ' + excl.exclusions ELSE '' END,
        CASE WHEN extra.extras IS NOT NULL
            THEN ' - Extra ' + extra.extras ELSE '' END
    ) AS order_details
FROM orders o
LEFT JOIN extras_cte extra
    ON o.row_id = extra.row_id
LEFT JOIN exclusions_cte excl
    ON o.row_id = excl.row_id
JOIN pizza_names pn
    ON o.pizza_id = pn.pizza_id
ORDER BY o.row_id


--Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table.

WITH orders AS (
    SELECT *,
        ROW_NUMBER() OVER (
            ORDER BY order_id, customer_id, pizza_id,
                     order_time, exclusions, extras
        ) AS row_id
    FROM #customer_orders_cleaned
),
pizza_recipes_cte AS (
    SELECT
        pn.pizza_id,
        CAST(pn.pizza_name AS VARCHAR(MAX)) AS pizza_name,
        TRIM(s.value) AS topping_id,
        CAST(t.topping_name AS VARCHAR(MAX)) AS topping_name
    FROM pizza_recipes r
    CROSS APPLY STRING_SPLIT(
        CAST(r.toppings AS VARCHAR(MAX)), ','
    ) s
    JOIN pizza_names pn
        ON pn.pizza_id = r.pizza_id
    JOIN pizza_toppings t
        ON TRIM(s.value) = t.topping_id
),
all_ingredients AS (
    SELECT
        co.order_id,
        co.customer_id,
        co.pizza_id,
        co.row_id,
        CAST(pr.pizza_name AS VARCHAR(MAX)) AS pizza_name,
        CAST(pr.topping_name AS VARCHAR(MAX)) AS topping_name
    FROM orders co
    JOIN pizza_recipes_cte pr
        ON co.pizza_id = pr.pizza_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM STRING_SPLIT(
            COALESCE(CAST(co.exclusions AS VARCHAR(MAX)), ''), ','
        ) e
        WHERE TRIM(e.value) = pr.topping_id
    )

    UNION ALL

    SELECT
        co.order_id,
        co.customer_id,
        co.pizza_id,
        co.row_id,
        CAST(pn.pizza_name AS VARCHAR(MAX)) AS pizza_name,
        CAST(t.topping_name AS VARCHAR(MAX)) AS topping_name
    FROM orders co
    CROSS APPLY STRING_SPLIT(
        COALESCE(CAST(co.extras AS VARCHAR(MAX)), ''), ','
    ) s
    JOIN pizza_toppings t
        ON TRIM(s.value) = t.topping_id
    JOIN pizza_names pn
        ON co.pizza_id = pn.pizza_id
    WHERE TRIM(s.value) <> ''
)
SELECT
    row_id,
    order_id,
    customer_id,
    CAST(pizza_name AS VARCHAR(MAX)) AS pizza_name,
    STRING_AGG(
        CAST(topping_name AS VARCHAR(MAX)), ', '
    ) WITHIN GROUP (
        ORDER BY CAST(topping_name AS VARCHAR(MAX))
    ) AS ingredients
FROM all_ingredients
GROUP BY
    order_id,
    customer_id,
    pizza_id,
    row_id,
    CAST(pizza_name AS VARCHAR(MAX))
ORDER BY
    row_id, order_id



--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH orders AS (
    SELECT *,
        ROW_NUMBER() OVER (
            ORDER BY order_id, customer_id, pizza_id,
                     order_time, exclusions, extras
        ) AS row_id
    FROM #customer_orders_cleaned co
    WHERE EXISTS (
        SELECT 1
        FROM #runner_orders_cleaned ro
        WHERE ro.order_id = co.order_id
          AND ro.cancellation IS NULL
    )
),
all_ingredients AS (
    SELECT
        co.row_id,
        CAST(t.topping_name AS VARCHAR(MAX)) AS topping_name
    FROM orders co
    JOIN pizza_recipes r
        ON co.pizza_id = r.pizza_id
    CROSS APPLY STRING_SPLIT(
        CAST(r.toppings AS VARCHAR(MAX)), ','
    ) s
    JOIN pizza_toppings t
        ON TRY_CAST(TRIM(s.value) AS INT) = t.topping_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM STRING_SPLIT(
            COALESCE(CAST(co.exclusions AS VARCHAR(MAX)), ''), ','
        ) e
        WHERE TRY_CAST(TRIM(e.value) AS INT) = t.topping_id
    )

    UNION ALL

    SELECT
        co.row_id,
        CAST(t.topping_name AS VARCHAR(MAX)) AS topping_name
    FROM orders co
    CROSS APPLY STRING_SPLIT(
        COALESCE(CAST(co.extras AS VARCHAR(MAX)), ''), ','
    ) s
    JOIN pizza_toppings t
        ON TRY_CAST(TRIM(s.value) AS INT) = t.topping_id
)
SELECT
    topping_name AS ingredient,
    COUNT(*) AS use_count
FROM all_ingredients
GROUP BY topping_name
ORDER BY use_count DESC, ingredient

--D. Pricing and Ratings

--If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
    SUM(CASE 
        WHEN pizza_id = 1 THEN 12
        ELSE 10
    END) AS total_revenue
FROM #customer_orders_cleaned AS co
JOIN #runner_orders_cleaned AS ro
ON co.order_id = ro.order_id
WHERE cancellation IS NULL


-- What if there was an additional $1 charge for any pizza extras?
WITH pizza_prices_cte AS (
    SELECT 
    ro.order_id,
    SUM(CASE 
        WHEN pizza_name LIKE 'Meatlovers' THEN 12
        ELSE 10
    END) AS price
    FROM #runner_orders_cleaned as ro 
    JOIN #customer_orders_cleaned as co 
    ON ro.order_id = co.order_id
    JOIN pizza_names AS p 
    ON co.pizza_id = p.pizza_id
    WHERE cancellation iS NULL
    GROUP BY ro.order_id
), extras_cte AS (
    SELECT 
        order_id,
        COUNT(*) AS extra_charge
    FROM #customer_orders_cleaned
    CROSS APPLY STRING_SPLIT(extras, ',') AS s
    WHERE TRIM(extras) <> ''
    GROUP BY order_id
)
SELECT
    SUM(price) + SUM(extra_charge) AS revenue
FROM pizza_prices_cte  AS p
LEFT JOIN extras_cte AS e
ON p.order_id = e.order_id



-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset - generate a schema for this new table and insert your own 
-- data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS #ratings;
CREATE TABLE #ratings (
    rating_id INTEGER,
    customer_id INTEGER,
    order_id INTEGER,
    runner_id INTEGER,
    rating INTEGER
)

INSERT INTO #ratings 
    (rating_id, customer_id, order_id, runner_id, rating )
    VALUES
    (1, 101, 1, 1, 4),
    (2, 101, 2, 1, 5),
    (3, 102, 3, 1, 4),
    (4, 103, 4, 2, 3),
    (5, 104, 5, 3, 5),
    (6, 105, 7, 2, 5),
    (7, 102, 8, 2, 4),
    (8, 104, 10, 1, 5)

SELECT * FROM #ratings


-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
SELECT
    ro.order_id,
    co.customer_id,
    ro.runner_id,
    rating,
    co.order_time,
    ro.pickup_time,
    DATEDIFF(minute, co.order_time, ro.pickup_time) AS waiting_time,
    ro.duration,
    ROUND(
        CAST(distance AS FLOAT) / NULLIF(
            CAST(duration AS FLOAT), 0) * 60,
        2
    ) AS speed_kmh,
    COUNT(pizza_id) AS pizza_count
FROM #runner_orders_cleaned AS ro
JOIN #customer_orders_cleaned AS co
ON co.order_id = ro.order_id
LEFT JOIN #ratings AS r
ON r.order_id = ro.order_id
GROUP BY ro.order_id, co.customer_id, 
        ro.runner_id,rating, order_time, 
        pickup_time, duration, distance


--

WITH runner_payment_cte AS(
    SELECT
        SUM(distance * 0.30) AS payment
    FROM #runner_orders_cleaned
), revenue_cte AS(
    SELECT 
        SUM(CASE 
            WHEN pizza_id = 1 THEN 12
            ELSE 10
        END) AS total_revenue
    FROM #customer_orders_cleaned AS co
    JOIN #runner_orders_cleaned AS ro
    ON co.order_id = ro.order_id
    WHERE cancellation IS NULL
) SELECT
    total_revenue - payment AS final_revenue
    FROM runner_payment_cte
    CROSS JOIN revenue_cte