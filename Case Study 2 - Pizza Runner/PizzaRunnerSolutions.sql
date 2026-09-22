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

SELECT * FROM #customer_orders_cleaned

-- runner_orders

SELECT 
order_id,
runner_id,
COALESCE(NULLIF(pickup_time, 'null'), NULL) AS pickup_time_,
CAST(COALESCE(NULLIF(REPLACE(distance, 'km', ''),'null'), NULL) AS DECIMAL(10,2)) AS distance,
CAST(COALESCE(NULLIF(REPLACE(REPLACE(REPLACE(duration, 'mins', ''),'minutes', ''),'minute', ''),'NULL'), NULL) AS DECIMAL(10,2)) AS duration,
COALESCE(NULLIF(NULLIF(cancellation, 'null'),''), NULL) AS cancellation
INTO #runner_orders_cleaned
FROM runner_orders

-- make pizza details
SELECT 
r.pizza_id, 
TRIM(s.value) AS topping_id,
t.topping_name
INTO #pizza_details
FROM pizza_recipes r
CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR(MAX)), ',') AS s
LEFT JOIN pizza_toppings AS t ON TRIM(s.value) = t.topping_id

--A. Pizza Metrics
--How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered FROM #customer_orders_cleaned
--14

--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) FROM customer_orders
-- 10

--How many successful orders were delivered by each runner?
SELECT COUNT(*) FROM runner_orders WHERE distance != 'null' AND duration != 'null'
-- 8

--How many of each type of pizza was delivered?


--How many Vegetarian and Meatlovers were ordered by each customer?
--What was the maximum number of pizzas delivered in a single order?
--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
--How many pizzas were delivered that had both exclusions and extras?
--What was the total volume of pizzas ordered for each hour of the day?
--What was the volume of orders for each day of the week?

--B. Runner and Customer Experience
--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--Is there any relationship between the number of pizzas and how long the order takes to prepare?
--What was the average distance travelled for each customer?
--What was the difference between the longest and shortest delivery times for all orders?
--What was the average speed for each runner for each delivery and do you notice any trend for these values?
--What is the successful delivery percentage for each runner?

--C. Ingredient Optimisation
--What are the standard ingredients for each pizza?
--What was the most commonly added extra?
--What was the most common exclusion?
--Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?