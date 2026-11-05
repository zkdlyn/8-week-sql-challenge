
USE dannys_diner
-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  s.customer_id,
  CONCAT('$', SUM(price)) AS total_spent
FROM sales AS s JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER By s.customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT 
	customer_id,
    COUNT(DISTINCT(order_date)) AS total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM sales
    GROUP BY customer_id
)
SELECT
    sales.customer_id,
    STRING_AGG(product_name, ', ') AS first_order 
FROM sales 
JOIN first_orders
    ON sales.customer_id = first_orders.customer_id
    AND sales.order_date = first_orders.first_order_date
JOIN menu
    ON menu.product_id = sales.product_id
GROUP BY sales.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1
    product_name,
    COUNT(*) AS total_orders
FROM sales
JOIN menu on sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY total_orders DESC;

-- 5. Which item was the most popular for each customer?

WITH order_counts AS (
    SELECT 
        customer_id,
        product_name,
        COUNT(*) AS order_count
    FROM sales
    JOIN menu
        ON sales.product_id = menu.product_id
    GROUP BY customer_id, product_name
),
ranked AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY customer_id
            ORDER BY order_count DESC
        ) AS rnk
    FROM order_counts
)
SELECT
    customer_id,
    STRING_AGG(product_name, ', ') AS product_name,
    MAX(order_count) AS top_order
FROM ranked
WHERE rnk = 1
GROUP BY customer_id
ORDER BY customer_id;



-- 6. Which item was purchased first by the customer after they became a member?

WITH customer_orders AS (
    SELECT 
        sales.*,
        members.join_date,
        menu.product_name,
        menu.price
    FROM sales
    JOIN members 
        ON sales.customer_id = members.customer_id
    JOIN menu 
        ON menu.product_id = sales.product_id
),
member_status AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(day, join_date, order_date) >= 0 THEN 'Y'
            ELSE 'N'
        END AS member
    FROM customer_orders
),
first_orders_mem AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM member_status
    WHERE member = 'Y'
    GROUP BY customer_id
)
SELECT
    ms.customer_id,
    STRING_AGG(ms.product_name, ', ') AS first_order 
FROM member_status as ms 
JOIN first_orders_mem as fo
    ON ms.customer_id = fo.customer_id 
    AND ms.order_date = fo.first_order_date
WHERE member = 'Y'
GROUP BY ms.customer_id


-- 7. Which item was purchased just before the customer became a member?

-- 8. What is the total items and amount spent for each member before they became a member?


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points_item AS (
    SELECT *,
    CASE 
    WHEN product_name = 'sushi' THEN 20
    ELSE 10
    END AS multiplier
    FROM menu
) 
SELECT
    s.customer_id,
    SUM(p.price*p.multiplier) AS total_points
FROM sales as s
JOIN points_item as p
ON s.product_id = p.product_id
GROUP BY s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Bonus: Join All

WITH customer_orders AS (
    SELECT 
        sales.*,
        members.join_date,
        menu.product_name,
        menu.price
    FROM sales
    LEFT JOIN members 
        ON sales.customer_id = members.customer_id
    JOIN menu 
        ON menu.product_id = sales.product_id
),
member_status AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(day, join_date, order_date) >= 0 THEN 'Y'
            ELSE 'N'
        END AS member
    FROM customer_orders
)
SELECT 
    customer_id,
    order_date,
    product_name,
    price,
    member
FROM member_status

-- Bonus: Rank

WITH customer_orders AS (
    SELECT 
        sales.*,
        members.join_date,
        menu.product_name,
        menu.price
    FROM sales
    LEFT JOIN members 
        ON sales.customer_id = members.customer_id
    JOIN menu 
        ON menu.product_id = sales.product_id
),
member_status AS (
    SELECT
        *,
        CASE 
            WHEN DATEDIFF(day, join_date, order_date) >= 0 THEN 'Y'
            ELSE 'N'
        END AS member
    FROM customer_orders
),
ranked_members AS (
    SELECT
        *,
        CASE
            WHEN member = 'Y' THEN
                RANK() OVER (
                    PARTITION BY customer_id, member
                    ORDER BY order_date
                )
        END AS ranking
    FROM member_status
)
SELECT 
    customer_id,
    order_date,
    product_name,
    price,
    member,
    ranking
FROM ranked_members

