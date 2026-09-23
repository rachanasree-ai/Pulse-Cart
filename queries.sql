/* ==========================================================
   Station A: SQL Extraction Queries
   Database: pulsecart_dump
 ==========================================================
  DATABASE SETUP
 -------------- 
Before running the queries in this file:

1.Open MySQL Workbench.
2.Open: data/mysql/pulsecart_dump.sql
3.Execute the dump file using: File → Run SQL Script
4.The script creates and populates the `pulsecart` database automatically.
5.After the database has been loaded successfully, open this file (`queries.sql`).
6.Run the queries below against the `pulsecart` database.

IMPORTANT
---------
- The original SQL dump contained four duplicate `INSERT INTO ... VALUES` header lines that caused SQL syntax errors during import.
These duplicate header lines were removed from the cleaned dump:
- products: original lines 50–51
- customers: original lines 67–68
- orders: original lines 936–937
- support_tickets: original lines 4348–4349
Only the duplicate SQL statement headers were removed.
The underlying data was NOT removed.

IMPORTANT DATA NOTE
-------------------
Some data-quality issues intentionally remain in the dataset because they are required for Station A analysis.
For example:
- Duplicate customer emails are retained because one required query identifies customers with more than one row for the same email.
- Orders with customer IDs that do not exist in the customers table are retained because one required query identifies orphan orders.
Therefore, do not remove these records before running the Station A queries.

IF THE DATABASE DOES NOT LOAD
-----------------------------
1. Check the MySQL Workbench Action Output / Output panel for the exact error message.
2. Make sure the cleaned `pulsecart_dump.sql` file is being used.
3. Make sure the dump is executed completely before running `queries.sql`.
4. Make sure the `pulsecart` database exists and is selected.
5. If the dump was partially executed, run the dump again from the beginning because it recreates the database.
6. Do not modify or delete business-data records to resolve query results. Only SQL syntax/setup errors should be fixed.*/


USE pulsecart;

-- ----------------------------------------------------------
-- 1. Row counts per table
-- ----------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM support_tickets;
-- ----------------------------------------------------------
-- 2. Customers who churned and placed at least one returned order
-- ----------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(o.order_id) AS total_returned_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.churned = 1 
  AND o.returned = 1
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_returned_orders DESC, c.customer_id ASC;
-- ----------------------------------------------------------
-- 3. Return rate by category (JOIN orders to products)
-- ----------------------------------------------------------
SELECT
    p.category,
    COUNT(*) AS total_orders,
    SUM(o.returned) AS returned_orders,
    ROUND(
        SUM(o.returned) * 100.0 / COUNT(*),
        2
    ) AS return_rate
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY p.category;
-- ----------------------------------------------------------
-- 4. Customers with more than one row for the same email
-- ----------------------------------------------------------
SELECT 
    LOWER(TRIM(REPLACE(email, ' at ', '@'))) AS normalized_email,
    COUNT(*) AS row_count,
    GROUP_CONCAT(customer_id ORDER BY customer_id ASC SEPARATOR ', ') AS customer_ids
FROM customers
GROUP BY LOWER(TRIM(REPLACE(email, ' at ', '@')))
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
-- ----------------------------------------------------------
-- 5. Orders whose customer_id does not exist in customers
-- ----------------------------------------------------------
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.quantity,
    o.unit_price,
    o.status
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
ORDER BY o.order_id ASC;
-- ----------------------------------------------------------
-- 6. Top 20 customers by net revenue
-- ----------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    ROUND(SUM(
        CASE 
            WHEN o.returned = 1 
                THEN -1 * (o.quantity * o.unit_price * (1 - COALESCE(o.discount_pct, 0)))
            ELSE 
                (o.quantity * o.unit_price * (1 - COALESCE(o.discount_pct, 0)))
        END
    ), 2) AS net_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status != 'cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY net_revenue DESC
LIMIT 20;
