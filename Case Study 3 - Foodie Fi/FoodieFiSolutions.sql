USE foodie_fi

-- Customer Journey
SELECT
    s.customer_id,
    p.plan_name,
    s.start_date
INTO #customer_sample
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)

SELECT *
FROM #customer_sample   
ORDER BY customer_id, start_date


--B. Data Analysis Questions
--How many customers has Foodie-Fi ever had?
SELECT
    COUNT(DISTINCT customer_id) AS total_customer_count
FROM subscriptions

--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT
    DATENAME(month, DATETRUNC(month, start_date)) AS trial_start_month,
    COUNT(*) AS count
FROM subscriptions
WHERE
    plan_id = 0
GROUP BY DATETRUNC(month, start_date)
ORDER BY DATETRUNC(month, start_date) ASC

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    plan_name,
    COUNT(*) AS num_events
FROM subscriptions AS s
JOIN plans as p
ON s.plan_id = p.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY s.plan_id, plan_name
ORDER BY s.plan_id

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(*) AS total, COUNT(DISTINCT customer_id) AS unique_c FROM subscriptions WHERE plan_id=4


SELECT 
    COUNT(DISTINCT customer_id) AS customer_count,
    CAST(
        ROUND(COUNT(DISTINCT customer_id)*100.0/
            (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1) 
        AS DECIMAL(10,1)) AS churn_pct
FROM subscriptions
WHERE plan_id = 4

--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH customer_plans_cte AS(
    SELECT
        ROW_NUMBER() OVER(
            PARTITION BY customer_id
            ORDER BY start_date ASC
        ) AS step_num,
        *
        FROM subscriptions
)
SELECT
    COUNT(*) AS churned_after_trial,
    CAST(COUNT(*) *100.0 / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) 
        AS INT) AS churned_pct
FROM customer_plans_cte 
WHERE plan_id = 4 AND step_num = 2

--What is the number and percentage of customer plans after their initial free trial?
WITH customer_plans_cte AS(
    SELECT
        ROW_NUMBER() OVER(
            PARTITION BY customer_id
            ORDER BY start_date ASC
        ) AS step_num,
        *
        FROM subscriptions
)
SELECT
    p.plan_name,
    COUNT(*) AS count_after_trial,
    CAST(COUNT(*) *100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS INT) AS pct
FROM customer_plans_cte AS c
JOIN plans AS p
ON p.plan_id = c.plan_id
WHERE step_num =2
GROUP BY c.plan_id, plan_name
ORDER BY c.plan_id

--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH ranked_plans AS (
SELECT
    customer_id,
    plan_id,
   ROW_NUMBER() OVER(
            PARTITION BY customer_id
            ORDER BY start_date DESC
        ) AS plan_latest_n
FROM subscriptions
WHERE start_date <= '2020-12-31'

)
SELECT
    p.plan_name,
    COUNT(rp.customer_id) AS latest_count,
    CAST(COUNT(*) *100.0 / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) 
        AS DECIMAL(10,2)) AS pct
FROM ranked_plans AS rp
JOIN plans AS p
ON rp.plan_id = p.plan_id
WHERE plan_latest_n = 1
GROUP BY rp.plan_id, p.plan_name
ORDER BY rp.plan_id

--How many customers have upgraded to an annual plan in 2020?

WITH next_plan_cte AS (
SELECT
    customer_id,
    plan_id,
    start_date,
    LEAD(plan_id) OVER (
        PARTITION BY customer_id
        ORDER BY start_date ASC
    ) AS next_plan_id,
        LEAD(start_date) OVER (
            PARTITION BY customer_id
            ORDER BY start_date ASC
        ) AS upgrade_date
FROM subscriptions
) SELECT
    COUNT(DISTINCT customer_id) AS upgraded_customers
FROM next_plan_cte
WHERE next_plan_id = 3 AND YEAR(upgrade_date) = 2020

--How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

SELECT
    ROUND(AVG(
        DATEDIFF(day, t.start_date, a.start_date)*1.0),
        2) AS avg_day_to_annual
FROM subscriptions AS t
JOIN subscriptions AS a
ON t.customer_id = a.customer_id
WHERE t.plan_id = 0 AND a.plan_id =3

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

SELECT
    CONCAT(
		FLOOR(DATEDIFF(day, t.start_date, a.start_date) / 30) * 30, 
			'-', FLOOR(DATEDIFF(day, t.start_date, a.start_date) / 30) 
            * 30 + 30) AS period_of_days,
	COUNT(DISTINCT t.customer_id) customer_count,
    ROUND(AVG(DATEDIFF(day, t.start_date, a.start_date)*1.0),2) AS avg_days_to_annual
FROM subscriptions AS t
JOIN subscriptions AS a
ON t.customer_id = a.customer_id
WHERE t.plan_id = 0 AND a.plan_id =3 
GROUP BY FLOOR(DATEDIFF(day, t.start_date, a.start_date) / 30)

--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH customer_plans_cte AS (
    SELECT
        customer_id,
        plan_id,
        start_date,
        LAG(plan_id) OVER (
            PARTITION BY customer_id
            ORDER BY start_date ASC
        ) AS previous_plan_id
    FROM subscriptions
)
SELECT
    COUNT(DISTINCT customer_id) AS downgraded_plans
FROM customer_plans_cte
WHERE plan_id < previous_plan_id
AND YEAR(start_date) = 2020

-- C
SELECT 
	s.customer_id,
	s.plan_id,
	p.plan_name,
	s.start_date AS payment_date,
	p.price AS amount,
	ROW_NUMBER() OVER(
            PARTITION BY customer_id
            ORDER BY start_date ASC
        ) AS payment_order
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id
WHERE s.plan_id <> 0
ORDER BY s.customer_id


-- D
