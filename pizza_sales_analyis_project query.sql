CREATE DATABASE dominos_pizza;
USE dominos_pizza;

SELECT * FROM pizzas;
SELECT * FROM pizza_types;
SELECT * FROM orders;
SELECT * FROM order_details;


# Create Table pizza_types
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    ingredients TEXT NOT NULL
);

DESC pizza_types;

# Create Table
CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50) NOT NULL,
    size VARCHAR(5) NOT NULL,
    price DOUBLE NOT NULL,
    FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id)
);

DESC pizzas;

# Create Table orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    date DATE NOT NULL,
    time TIME NOT NULL
);

DESC orders;

# Create order_details table
CREATE TABLE order_details(
order_details_id INT PRIMARY KEY,
order_id INT NOT NULL,
pizza_id VARCHAR(50) NOT NULL,
quantity BIGINT,
FOREIGN KEY(order_id) REFERENCES orders(order_id),
FOREIGN KEY(pizza_id) REFERENCES pizzas(pizza_id)
);

DESC order_details;


# ----------------------------------------------------------------------------------------------------------------------------------
-- Queries

-- 1.Retrieve the total number of orders placed

SELECT count(*) AS total_orders FROM orders;


-- 2.Calculate the total revenue generated from pizza sales

SELECT 
    ROUND(SUM(pz.price * od.quantity), 2) AS total_revenue
FROM order_details od
	JOIN pizzas pz 
	ON od.pizza_id = pz.pizza_id;
    
-- 3.Identify the highest-priced pizza

SELECT pt.name, pz.price
FROM pizza_types pt
	JOIN pizzas pz 
    ON pt.pizza_type_id = pz.pizza_type_id
ORDER BY pz.price DESC 
LIMIT 1;

-- 4.Identify the most common pizza size ordered

SELECT pz.size, SUM(od.quantity) order_count
FROM pizzas pz 
	JOIN order_details od
    ON pz.pizza_id = od.pizza_id
GROUP BY pz.size
ORDER BY order_count DESC
LIMIT 1;

-- 5.List the top 5 most ordered pizza types along with their quantities

SELECT pt.name, SUM(od.quantity) AS qty_ordered
FROM pizzas pz 
	JOIN pizza_types pt
	ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od 
    ON od.pizza_id = pz.pizza_id
GROUP BY pt.name
ORDER BY qty_ordered DESC
LIMIT 5;

-- 6. Join the necessary tables to find the total quantity of each pizza category ordered

SELECT pt.category, SUM(od.quantity) AS ttl_order_qty
FROM pizzas pz 
	JOIN pizza_types pt
	ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od 
    ON od.pizza_id = pz.pizza_id
GROUP BY pt.category
ORDER BY ttl_order_qty DESC;


-- 7.Determine the distribution of orders by hour of the day

SELECT HOUR(time) AS order_hr, 
	COUNT(*) AS orders FROM orders
GROUP BY order_hr
ORDER BY order_hr;

-- 8.Join relevant tables to find the category-wise distribution of pizzas

SELECT category,COUNT(*) AS pizza_count
FROM pizza_types
GROUP BY category;

-- 9.Group the orders by date and calculate the average number of pizzas ordered per day

SELECT ROUND(AVG(quantity),0) AS avg_piz_ord_prday
FROM (SELECT o.date, SUM(od.quantity) AS quantity
		FROM orders o
			JOIN order_details od
			ON o.order_id = od.order_id
		GROUP BY o.date
		ORDER BY o.date) AS order_quantity;

-- 10.Determine the top 3 most ordered pizza types based on revenue

SELECT pt.name AS pizza_type, 
	ROUND(SUM(pz.price * od.quantity), 2) AS total_revenue
FROM pizzas pz 
	JOIN pizza_types pt
	ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od 
    ON od.pizza_id = pz.pizza_id
GROUP BY pizza_type
ORDER BY total_revenue DESC
LIMIT 3;


-- 11.Calculate the percentage contribution of each pizza category type to total revenue

# By using CTE(Common Table Expression) function

WITH TotalRevenue AS (
    SELECT SUM(pz.price * od.quantity) AS total_revenue
    FROM pizzas pz
    JOIN order_details od ON od.pizza_id = pz.pizza_id
)

SELECT pt.category AS pizza_type, 
       ROUND(SUM(pz.price * od.quantity) / tr.total_revenue * 100, 2) AS perc_contribution
FROM pizzas pz
JOIN pizza_types pt ON pz.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = pz.pizza_id
JOIN TotalRevenue tr
GROUP BY pt.category, tr.total_revenue
ORDER BY perc_contribution DESC;

# By using Subquery
SELECT pt.category AS pizza_type, 
       ROUND((SUM(pz.price * od.quantity) / (
       SELECT SUM(pz.price * od.quantity) 
	   FROM pizzas pz
           JOIN order_details od 
           ON od.pizza_id = pz.pizza_id))*100,2) as perc_contribution
FROM pizzas pz
JOIN pizza_types pt ON pz.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = pz.pizza_id
GROUP BY pt.category
ORDER BY perc_contribution DESC;

-- 12.Analyze the cumulative revenue generated over time

# With CTE function and window function
WITH MonthlyRevenue AS (
    SELECT 
        MONTH(o.date) AS month_num, 
        SUM(pz.price * od.quantity) AS total_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas pz ON od.pizza_id = pz.pizza_id
    GROUP BY MONTH(o.date)
)

SELECT 
    month_num,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(SUM(total_revenue) OVER (ORDER BY month_num), 2) AS cumulative_revenue
FROM MonthlyRevenue
ORDER BY month_num;


# Same approach but with subquery

SELECT 
    month_num,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(SUM(total_revenue) OVER (ORDER BY month_num), 2) AS cumulative_revenue
FROM (
    SELECT 
        MONTH(o.date) AS month_num,
        SUM(pz.price * od.quantity) AS total_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas pz ON od.pizza_id = pz.pizza_id
    GROUP BY MONTH(o.date)
) AS MonthlyRevenue
ORDER BY month_num;


# Alternative appproach-- using only window function

SELECT 
    MONTH(o.date) AS month_num,
    ROUND(SUM(pz.price * od.quantity), 2) AS total_revenue,
    ROUND(SUM(SUM(pz.price * od.quantity)) OVER (ORDER BY MONTH(o.date)), 2) AS cumulative_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas pz ON od.pizza_id = pz.pizza_id
GROUP BY MONTH(o.date)
ORDER BY month_num;


# Cumulative Revenue by date-- using subquery

SELECT 
    date,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(SUM(total_revenue) OVER (ORDER BY date), 2) AS cumulative_revenue
FROM (
    SELECT 
        o.date,
        SUM(pz.price * od.quantity) AS total_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas pz ON od.pizza_id = pz.pizza_id
    GROUP BY o.date
) AS RevenueByDate
ORDER BY date;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category

# By using CTE function-- and ROW_NUMBER() window function inside it
WITH RankedPizzaTypes AS (
    SELECT 
        pt.category, 
        pt.name,
        ROUND(SUM(pz.price * od.quantity), 2) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY pt.category ORDER BY SUM(pz.price * od.quantity) DESC) AS pizza_rank
    FROM pizzas pz
    JOIN pizza_types pt ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON od.pizza_id = pz.pizza_id
    GROUP BY pt.category, pt.name
)

SELECT 
    category, 
    name, 
    revenue,
    pizza_rank
FROM RankedPizzaTypes
WHERE pizza_rank <= 3
ORDER BY category, revenue DESC;


# By using CTE function-- and RANK() window function inside it
WITH RankedPizzaTypes AS (
    SELECT 
        pt.category, 
        pt.name,
        ROUND(SUM(pz.price * od.quantity), 2) AS revenue,
        RANK() OVER (PARTITION BY pt.category ORDER BY SUM(pz.price * od.quantity) DESC) AS pizza_rank
    FROM pizzas pz
    JOIN pizza_types pt ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON od.pizza_id = pz.pizza_id
    GROUP BY pt.category, pt.name
)

SELECT 
    category, 
    name, 
    revenue,
    pizza_rank
FROM RankedPizzaTypes
WHERE pizza_rank <= 3
ORDER BY category, revenue DESC;

# By using Subqueries

SELECT 
    category, 
    name, 
    revenue, 
    pizza_rank
FROM (
    SELECT 
        pt.category, 
        pt.name,
        ROUND(SUM(pz.price * od.quantity), 2) AS revenue,
        RANK() OVER (PARTITION BY pt.category ORDER BY SUM(pz.price * od.quantity) DESC) AS pizza_rank
    FROM pizzas pz
    JOIN pizza_types pt ON pz.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON od.pizza_id = pz.pizza_id
    GROUP BY pt.category, pt.name
) AS RankedPizzaTypes
WHERE pizza_rank <= 3
ORDER BY category, revenue DESC;













