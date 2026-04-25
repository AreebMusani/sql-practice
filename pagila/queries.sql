-- Find the top 5 customers who spent the most money
SELECT 
    p.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(p.amount) AS total_amount_spent
FROM payment p
JOIN customer c 
    ON p.customer_id = c.customer_id
GROUP BY 
    p.customer_id, c.first_name, c.last_name
ORDER BY total_amount_spent DESC
LIMIT 5;

-- Find the most rented movie category
SELECT cat."name", 
	COUNT(r.rental_id) total_rentals 
FROM rental r 
INNER JOIN inventory i 
	ON r.inventory_id = i.inventory_id 
INNER JOIN film_category fc 
	ON i.film_id = fc.film_id 
INNER JOIN category cat 
	ON fc.category_id = cat.category_id 
GROUP BY cat."name" 
ORDER BY total_rentals DESC 
LIMIT 1

-- Customers Who Haven’t Rented in Last 6 Months
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name
FROM customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM rental r
    WHERE r.customer_id = c.customer_id
      AND r.rental_date >= NOW() - INTERVAL '6 months'
);

-- For each category, calculate total revenue, number of rentals, average rental duration
SELECT 
    c.category_id,
    c.name AS category_name,
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_revenue,
    AVG(r.return_date - r.rental_date) 
        FILTER (WHERE r.return_date IS NOT NULL) AS avg_rental_duration
FROM rental r
JOIN inventory i 
    ON r.inventory_id = i.inventory_id
JOIN film_category fc 
    ON i.film_id = fc.film_id
JOIN category c 
    ON fc.category_id = c.category_id
JOIN payment p 
    ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name;


-- Find the top 3 customers per category by total spending
WITH category_spendings AS (
    SELECT 
        c.name AS category,
        cus.customer_id,
        cus.first_name || ' ' || cus.last_name AS customer,
        SUM(p.amount) AS total_spent
    FROM payment p
    JOIN customer cus 
        ON p.customer_id = cus.customer_id
    JOIN rental r 
        ON p.rental_id = r.rental_id
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc 
        ON i.film_id = fc.film_id
    JOIN category c 
        ON fc.category_id = c.category_id
    GROUP BY 
        c.category_id, c.name,
        cus.customer_id, cus.first_name, cus.last_name
),
ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY total_spent DESC
        ) AS rank
    FROM category_spendings
)
SELECT *
FROM ranked_customers
WHERE rank <= 3;