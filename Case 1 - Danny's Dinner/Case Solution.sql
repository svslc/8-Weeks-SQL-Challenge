/* --------------------
   Case Study Questions
   --------------------*/


-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_sales
FROM sales JOIN menu
ON menu.product_id = sales.product_id
GROUP BY customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS total_days_visited
FROM sales 
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer? 


WITH purchase_transactions AS(

	SELECT customer_id, product_name, order_date, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) item_rank
	FROM sales JOIN menu
	ON menu.product_id = sales.product_id

)

SELECT customer_id, product_name, order_date
FROM   purchase_transactions
WHERE item_rank = 1
GROUP BY customer_id, product_name, order_date;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 product_name, COUNT(sales.product_id) AS times_purchased
FROM sales JOIN menu
ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY times_purchased DESC;


-- 5. Which item was the most popular for each customer? 

WITH popular_product AS(

	SELECT customer_id, product_name, COUNT(sales.product_id) as total_order,
			DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(sales.product_id) DESC) product_rank
	FROM sales JOIN menu
	ON menu.product_id = sales.product_id
	GROUP BY customer_id, product_name
)

SELECT customer_id, product_name, total_order
FROM  popular_product
WHERE product_rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?

SELECT DISTINCT sales.customer_id, FIRST_VALUE(product_name) OVER(PARTITION BY sales.customer_id ORDER BY order_date) first_purchased_item, order_date
FROM sales JOIN menu
ON menu.product_id = sales.product_id
JOIN members 
ON members.customer_id = sales.customer_id
WHERE order_date >= join_date;

WITH member_transactions AS(

	SELECT sales.customer_id, product_name, order_date,
			DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) order_rank, join_date
	FROM sales JOIN menu
	ON menu.product_id = sales.product_id
	JOIN members 
	ON members.customer_id = sales.customer_id
	WHERE order_date >= join_date
)

SELECT customer_id, product_name, order_date
FROM  member_transactions
WHERE order_rank = 1;


-- 7. Which item was purchased just before the customer became a member? 

WITH non_member_transactions AS(

	SELECT sales.customer_id, product_name, order_date,
			DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) order_rank, join_date
	FROM sales JOIN menu
	ON menu.product_id = sales.product_id
	JOIN members 
	ON members.customer_id = sales.customer_id
	WHERE order_date < join_date
)

SELECT customer_id, product_name, order_date
FROM  non_member_transactions
WHERE order_rank = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id, count(sales.product_id) as total_items, sum(price) as total_sales
FROM sales JOIN menu
ON menu.product_id = sales.product_id
JOIN members 
ON members.customer_id = sales.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH price_points AS (
	SELECT product_id, product_name, price,  
			CASE
				WHEN product_name = 'sushi' THEN 2*10*price
				ELSE 1*10*price
			END AS points
	FROM menu
)

SELECT customer_id, SUM(points) as total_points
FROM sales JOIN price_points
ON price_points.product_id = sales.product_id
GROUP BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--buat cte yg isi casee


WITH price_points_new_members AS (
	
	SELECT sales.customer_id, sales.product_id, product_name, price, order_date, join_date,
		CASE
			WHEN product_name = 'sushi' THEN 2*10*price
			WHEN order_date BETWEEN join_date AND DATEADD(DAY, 7, join_date) THEN 2*10*price
			ELSE 1*10*price
		END AS points 
	FROM sales JOIN menu
	ON menu.product_id = sales.product_id
	JOIN members 
	ON members.customer_id = sales.customer_id
)


SELECT customer_id, SUM(points) as total_points
FROM price_points_new_members
WHERE order_date < EOMONTH('2021-01-31')
GROUP BY customer_id;
