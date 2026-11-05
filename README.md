<div align = center>

# 8 Week SQL Challenge

</div>

This repository contains my solutions to Data With Danny’s [8-Week SQL Challenge](https://8weeksqlchallenge.com/), covering eight real-world business case studies. Each case study includes SQL solutions, analysis, and key insights derived from the data.


## Tools
- MS SQL Server
- SQL Server Management Studio
- Git/GitHub

## Case Studies

| No. | Case Study | Domain | Key Focus |
| :---: | ---- | ----| ---- |
| 1 | [Danny's Diner](#case-study-1-dannys-diner) | Food | Customer loyalty and purchasing behavior |
| 2 | [Pizza Runner](#case-study-2-pizza-runner) | Food Delivery | Delivery operations |
| 3 | [Foodie-Fi](#case-study-3-foodie-fi) | Subscription Service | Customer subscription and churn |
| 4 | [Data Bank](#case-study-4-data-bank) | Digital Banking | |
 


## Highlights

### Danny's Diner

#### Overview:
Danny's Diner wants to better understand its customers, purchasing behavior, and visiting patterns to make informed business decisions. Using insights gained on these data, he would evaluate the effectiveness of the existing customer loyalty program.

#### Business Questions:
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    
#### Key Insights:
- Ramen is the most popular item on the menu, accounting for 8 out of 15 purchases. It is a favorite by both members (A and B) and non-members (C). 
  - *Danny should keep ramen on the menu and may consider expanding the offering by introducing different ramen variations.*

- Curry, the most expensive product, was only purchased 4 times, which may indicate low demand for its higher price point. 
  - *Danny may want to review its pricing, portion, or overall positioning before deciding whether to keep it on the menu*.

- Membership behavior showed that customers tend to make a few purchases before joining the loyalty program. After joining, customers continue to make purchases, indicating sustained engagement with the business. 
  - *Danny may seek to encourage first-time customers to join the loyalty program through introductory promotions or discounts*.


#### Project Files:


- [Read Full Case](https://8weeksqlchallenge.com/case-study-1/) 
- [View My Solution](./Case%20Study%201%20-%20Danny's%20Diner/README.md)

### Pizza Runner

#### Overview:
Danny launched Pizza Runner, a pizza delivery business inspired by the idea of combining retro-style pizza with an app-based delivery service. He recruited runners to deliver orders and developed a mobile app to manage customer orders, creating an opportunity to analyze sales, delivery operations, and business performance.

#### Business Questions:
This case study is divided into several key areas of focus:
1. Pizza metrics
2. Runner and customer experience 
3. Ingredient optimisation
4. Pricing and ratings
5. Data manipulation challenges

#### Key Insights:
- Meat Lovers was the most frequently ordered pizza, sold 9 times. 
  - *It can be prioritized in promotions and ensure sufficient inventory to meet demand.*
- Average pickup times ranged from 10-20 minutes, delivery distances ranged from 10-25 km, and successful deliveries took 10-40 minutes. Preparation time significantly increases with order size. 
  - *Optimize pizza preparation and pickup workflows, especially for larger orders, to improve delivery efficiency*
- Bacon was the most popular extra while cheese was the most common exclusion in pizza orders. Bacon, mushrooms, and cheese were the most used ingredients across all orders.
  - *Sufficient stock of popular ingredients must be ensured.*
- Pizza Runner generated $138 in revenue, which increased to $142 with additional charges for extras, while retaining $94.44 after runner delivery expenses.
  - *They can explore additional revenue opportunities through upselling extras while monitoring delivery costs to improve profitability.*

#### Project Files:
- [Read Full Case](https://8weeksqlchallenge.com/case-study-2/) 
- [View My Solution](./Case%20Study%202%20-%20Pizza%20Runner/README.md)

### Foodie-Fi

#### Overview:

Danny launched his new startup Foodie-Fi, a streaming platform for food-related content, selling monthly and annual subscriptions. Using subscription data, he wants to gain insights into customer behaviour and subscription trends to support data-driven investment decisions and feature improvements. 

#### Business Questions:
This case study is split into an initial data understanding question before diving straight into data analysis questions.

Data analysis questions cover 


[Read Full Case](https://8weeksqlchallenge.com/case-study-3/) \
[View My Solution](./Case%20Study%203%20-%20Foodie%20Fi/README.md)

## Case Study 4: Data Bank

**Domain: Digital Banking**

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

[Read Full Case](https://8weeksqlchallenge.com/case-study-4/) \
[View My Solution](./Case%20Study%204%20-%20Data%20Bank/README.md)
