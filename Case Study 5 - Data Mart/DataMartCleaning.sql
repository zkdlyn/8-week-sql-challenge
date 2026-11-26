
SELECT
    TRY_CONVERT(DATE, week_date, 3) AS week_date,
    DATEPART(week, CONVERT(DATE, week_date, 3)) AS week_number,
    DATEPART(month, CONVERT(DATE, week_date, 3)) AS month_number,
    YEAR(CONVERT(DATE, week_date, 3)) AS calendar_year,
    region,
    platform,
    COALESCE(NULLIF(segment, 'NULL'), 'unknown') AS segment,
    CASE 
        WHEN segment LIKE '%1' THEN 'Young Adults' 
        WHEN segment LIKE '%2' THEN 'Middle Aged'
        WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
        ELSE 'unknown'
    END AS age_band,
    CASE
        WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families'
        ELSE 'unknown'
    END AS demographic,
    customer_type,
    transactions,
    sales,
    CAST(sales*1.0/transactions AS DECIMAL(10,2)) AS avg_transaction
INTO clean_weekly_sales
FROM weekly_sales

