-- “Who are our top 10 customers based on total money spent in last 30 dates? (based on latest dataset date)”
EXPLAIN ANALYSE
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    SUM(p.amount) AS total_spent
FROM payment p
JOIN customer c 
    ON p.customer_id = c.customer_id
WHERE p.payment_date >= (
    SELECT MAX(payment_date) FROM payment
) - INTERVAL '30 days'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC
LIMIT 10;

-- “Find customers who have NOT made any payment in the last 30 days (based on latest dataset date)”
SELECT C.customer_id, concat(C.first_name, ' ', C.last_name) AS full_name, email
FROM customer C
WHERE NOT EXISTS (
    SELECT 1
    FROM payment P
    WHERE P.customer_id = C.customer_id
      AND P.payment_date >= (
          SELECT MAX(payment_date) FROM payment
      ) - INTERVAL '30 days'
);

-- Show each customer’s 2nd highest payment
SELECT *
FROM (
  SELECT *,
  DENSE_RANK() OVER (
    PARTITION BY p.customer_id
    ORDER BY amount DESC
  ) AS rn
  FROM payment p
) t
WHERE rn = 2

-- Show customers with above-average payment per transaction
SELECT *
FROM (
  SELECT *,
  AVG(p.amount) OVER (
    PARTITION BY p.customer_id
  ) AS average
  FROM payment p
) t
WHERE t.amount > t.average

-- Show payment difference between current and previous transaction
SELECT *,
  t.amount - t.prev_transaction AS difference
FROM (
  SELECT *,
  LAG(p.amount) OVER (
    PARTITION BY p.customer_id
    ORDER BY p.payment_date
  ) as prev_transaction
  FROM payment p
) t

-- Find top 3 customers by total spending
WITH customer_spending AS (
  SELECT p.customer_id,
    SUM(p.amount) AS total_spending
  FROM payment p
  GROUP BY p.customer_id
)

SELECT *
FROM customer_spending
ORDER BY total_spending DESC
LIMIT 3

-- Show top 3 customers per store
WITH customer_total_spent_per_store AS (
  SELECT c.customer_id, 
    c.first_name || ' ' || c.last_name AS full_name, 
    s.store_id,
    SUM(amount) AS total_spent
  FROM payment p
  INNER JOIN customer c
    ON c.customer_id = p.customer_id
  INNER JOIN staff st
    ON st.staff_id = p.staff_id
  INNER JOIN store s
    ON s.store_id = st.store_id
  GROUP BY s.store_id, c.customer_id, c.first_name
), 
rank_customers_per_store AS (
  SELECT t.*,
    ROW_NUMBER() OVER (
      PARTITION BY t.store_id
      ORDER BY t.total_spent DESC
    ) AS rank
  FROM customer_total_spent_per_store t
)

SELECT * 
FROM rank_customers_per_store t
WHERE t.rank <= 3


-- Find customers whose total spending is above the average total spending of all customers
WITH customer_spending AS (
  SELECT 
    p.customer_id,
    SUM(p.amount) AS total_spending
  FROM payment p
  GROUP BY p.customer_id
),
spending_with_avg AS (
  SELECT 
    cs.*,
    AVG(cs.total_spending) OVER () AS avg_spending
  FROM customer_spending cs
)
SELECT 
  s.customer_id,
  c.first_name || ' ' || c.last_name AS full_name,
  s.total_spending
FROM spending_with_avg s
JOIN customer c 
  ON c.customer_id = s.customer_id
WHERE s.total_spending > s.avg_spending;

