USE data_bank

-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT
	COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes

--What is the number of nodes per region?
SELECT
	region_id,
	COUNT(node_id) AS node_count
FROM customer_nodes
GROUP BY region_id
ORDER By region_id

--How many customers are allocated to each region?
SELECT
	region_id,
	COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes
GROUP BY region_id
ORDER BY region_id

--How many days on average are customers reallocated to a different node?
--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?