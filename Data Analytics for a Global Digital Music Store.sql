/* Data Analytics for a Global Digital Music Store */

--1) Leadership Structure
SELECT employee_id, first_name, last_name, title, levels  
FROM "Music".employee
ORDER BY levels DESC
LIMIT 1;

--2) Country-Based Invoice Volume
SELECT billing_country, COUNT(*) AS total_invoice_count 
FROM "Music".invoice
GROUP BY billing_country
ORDER BY total_invoice_count DESC
LIMIT 1;

--3) Track High-Value Transactions
SELECT * FROM "Music".invoice
ORDER BY total DESC
LIMIT 3;

--4) Choose the Best City for a Promotional Event
SELECT billing_city, SUM(total) AS total_invoice_amount 
FROM "Music".invoice
GROUP BY billing_city
ORDER BY total_invoice_amount DESC
LIMIT 1;

--5) Identify Top-Spending Customer
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_amount 
FROM "Music".customer c
JOIN "Music".invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_amount DESC
LIMIT 1;

--6) Target Rock Music Fans
SELECT DISTINCT  c.email, c.first_name, c.last_name, g.name
FROM "Music".customer c
INNER JOIN "Music".invoice i ON c.customer_id = i.customer_id
INNER JOIN "Music".invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN "Music".track t ON il.track_id = t.track_id
INNER JOIN "Music".genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock';

--7) Identify Top Rock Artists
SELECT art.name AS Artist_name, COUNT(t.track_id) AS track_count, g.name AS genre_name FROM "Music".artist art
INNER JOIN "Music".album a ON art.artist_id = a.artist_id
INNER JOIN "Music".track t ON a.album_id = t.album_id
INNER JOIN "Music".genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY art.name, g.name 
ORDER BY track_count DESC
LIMIT 10;

--8) Spot Long-Form Track Opportunities
SELECT name AS track_name, milliseconds 
FROM "Music".track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM "Music".track);

--9) Calculate Customer Spend by Artist
WITH customer_spending AS (
SELECT c.customer_id, c.first_name, c.last_name, art.name AS artist_name, 
SUM(il.unit_price * il.quantity) AS total_spent 
FROM "Music".customer c
INNER JOIN "Music".invoice i ON c.customer_id = i.customer_id
INNER JOIN "Music".invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN "Music".track t ON il.track_id = t.track_id
INNER JOIN "Music".album a ON t.album_id = a.album_id
INNER JOIN "Music".artist art ON a.artist_id = art.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, art.name
)
SELECT 
    customer_id, 
    first_name, 
    last_name, 
    artist_name,
	total_spent
FROM customer_spending;

--10) Determine Top Genre per Country
WITH purchase_per_country AS (
SELECT i.billing_country AS country, g.name AS genre, SUM(il.quantity) AS purchases  
FROM "Music".invoice i
INNER JOIN "Music".invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN "Music".track t ON il.track_id = t.track_id
INNER JOIN "Music".genre g ON t.genre_id = g.genre_id
GROUP BY country, genre), ranked_genres AS (
SELECT country, genre, purchases,
ROW_NUMBER() OVER (PARTITION BY country ORDER BY purchases DESC) AS rank
FROM purchase_per_country)
SELECT country, genre AS popular_genre, purchases
FROM ranked_genres
WHERE rank = 1
ORDER BY country DESC;

--11) Find Top-Spending Customer per Country
WITH customer_spending AS (
SELECT c.customer_id, c.first_name, c.last_name, c.country,
SUM(il.quantity * il.unit_price) AS total_spending
FROM "Music".customer c
INNER JOIN "Music".invoice i ON c.customer_id = i.customer_id
INNER JOIN "Music".invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country ), ranked_customers AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_spending DESC) AS rank
FROM customer_spending )
SELECT customer_id, first_name, last_name, country, total_spending
FROM ranked_customers
WHERE rank = 1
ORDER BY country;