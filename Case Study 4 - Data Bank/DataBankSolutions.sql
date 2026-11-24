USE data_bank

-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT
	COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes

--What is the number of nodes per region?
SELECT
	region_name,
	COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes AS cn
JOIN regions AS r
	ON cn.region_id = r.region_id
GROUP BY region_name


--How many customers are allocated to each region?
SELECT
	region_name,
	COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes AS cn
JOIN regions AS r
	ON cn.region_id = r.region_id
GROUP BY region_name


--How many days on average are customers reallocated to a different node?
SELECT DISTINCT start_date
FROM customer_nodes
ORDER BY start_date ASC

SELECT DISTINCT end_date
FROM customer_nodes
ORDER BY end_date DESC

-- problematic date found '9999-12-31'; exclude from calculation

SELECT 
	AVG(DATEDIFF(DAY, start_date, end_date)) AS avg_number_of_day
FROM customer_nodes
WHERE end_date != '9999-12-31'


--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH reallocation_days_cte AS (
SELECT 
	customer_id,
	cn.region_id,
	region_name,
	DATEDIFF(DAY, start_date, end_date) AS reallocation_days
FROM customer_nodes AS cn
JOIN regions r
	ON cn.region_id = r.region_id
WHERE end_date != '9999-12-31'
)
SELECT DISTINCT
	region_name,
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS median,
	PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS percentile_80,
	PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS percentile_95
FROM reallocation_days_cte


--B. Customer Transactions

--What is the unique count and total amount for each transaction type?
SELECT
	txn_type,
	COUNT(txn_type) AS unique_cnt,
	SUM(txn_amount) AS total_amt
FROM 
customer_transactions
GROUP BY txn_type;


--What is the average total historical deposit counts and amounts for all customers?
WITH deposits_cte AS (
	SELECT
		customer_id,
		COUNT(txn_type)*1.0 AS deposit_cnt,
		SUM(txn_amount)*1.0 AS deposit_sum
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)
SELECT
	AVG(deposit_cnt) AS avg_deposit_cnt,
	AVG(deposit_sum) AS avg_deposit_sum
FROM deposits_cte;

--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH transaction_cnt_cte AS(
	SELECT
		DATETRUNC(month, txn_date) AS month_trunc,
		DATENAME(month, txn_date) AS month,
		customer_id,
		SUM(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_cnt,
		SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_cnt,
		SUM(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_cnt
	FROM customer_transactions
	GROUP BY 
		DATETRUNC(month, txn_date), 
		DATENAME(month, txn_date),
		customer_id
)
SELECT 
	month,
	COUNT(customer_id) AS customer_count
FROM transaction_cnt_cte
WHERE deposit_cnt >1 AND (purchase_cnt = 1 OR withdrawal_cnt = 1)
GROUP BY month_trunc, month
ORDER BY month_trunc

--What is the closing balance for each customer at the end of the month?
WITH transactions_sum_cte AS(
	SELECT
		customer_id,
		DATETRUNC(month, txn_date) AS month_trunc,
		SUM(CASE WHEN txn_type = 'deposit' 
			THEN txn_amount ELSE 0 END) AS deposits,
		SUM(CASE WHEN txn_type = 'withdrawal' 
			THEN txn_amount ELSE 0 END) AS withdrawals,
		SUM(CASE WHEN txn_type = 'purchase' 
			THEN txn_amount ELSE 0 END) AS purchases
	FROM customer_transactions
	GROUP BY 
		customer_id,
		DATETRUNC(month, txn_date), 
		DATENAME(month, txn_date)
		
)
SELECT
	customer_id,
	DATENAME(month, month_trunc) AS month,
	SUM(deposits - withdrawals - purchases) OVER (
        PARTITION BY customer_id
        ORDER BY month_trunc
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_balance
FROM transactions_sum_cte
ORDER BY customer_id, month_trunc


--What is the percentage of customers who increase their closing balance by more than 5%?