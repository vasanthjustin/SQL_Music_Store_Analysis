-- 1. Who is the senior most employee based on job title?
-- 2. Which countries have the most Invoices?
-- 3. What are top 3 values of total invoice?
-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money

-- q1 Who is the senior most employee based on job title?

SELECT * FROM employee ORDER BY levels DESC LIMIT 1;

-- -- q2 which countries have the most invoices?

select count(*) AS c, billing_country
from invoice
GROUP BY
    billing_country
ORDER BY c desc;

-- Q3 What are top 3 values of total invoice

SELECT total FROM invoice ORDER BY total DESC limit 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

SELECT sum(total) AS invoice_total, billing_city
FROM invoice
GROUP BY
    billing_city
ORDER BY invoice_total desc;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money

SELECT cus.customer_id, cus.first_name, cus.last_name, SUM(inv.total) as total
FROM customer as cus
    JOIN invoice as inv ON cus.customer_id = inv.customer_id
GROUP BY
    cus.customer_id,
    cus.first_name,
    cus.last_name
ORDER BY total DESC
LIMIT 1;

-- Question set2 Moderate
-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
-- 2. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
-- 3. Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A

SELECT cus.email, cus.first_name, cus.last_name
FROM
    customer AS cus
    JOIN invoice AS inv ON cus.customer_id = inv.customer_id
    JOIN invoice_line AS invl ON invl.invoice_id = inv.invoice_id
    JOIN track ON invl.track_id = track.track_id
    JOIN genre AS gen ON track.genre_id = gen.genre_id
WHERE
    gen.name = 'Rock'
ORDER BY cus.email ASC;

-- 2. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands

SELECT artist.artist_id, artist.name, MIN(genre.name), COUNT(artist.artist_id) as num_of_songs
FROM
    track
    JOIN album ON track.track_id = album.artist_id
    JOIN artist ON artist.artist_id = album.artist_id
    JOIN genre ON genre.genre_id = track.genre_id
WHERE
    genre.name LIKE 'Rock'
GROUP BY
    artist.artist_id,
    artist.name
ORDER BY num_of_songs DESC
LIMIT 10;

SELECT * from track;

-- 3. Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

SELECT name, milliseconds
FROM track
WHERE
    milliseconds > (
        SELECT AVG(milliseconds) as avg_track_length
        from track
        ORDER BY milliseconds DESC
    )
    -- or another way to solve the above

SELECT DISTINCT
    email,
    first_name,
    last_name,
    genre.name
FROM
    customer
    JOIN invoice on invoice.customer_id = customer.customer_id
    JOIN invoice_line on invoice_line.invoice_id = invoice.invoice_id
    JOIN track on track.track_id = invoice_line.track_id
    JOIN genre on genre.genre_id = track.track_id
where
    genre.name LIKE "Rock"
ORDER BY email;

-- Question Set 3 - Advance
-- 1. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent
-- 2. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres
-- 3. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount

-- 1. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent

WITH
    best_selling_artist AS (
        SELECT artist.artist_id, artist.name AS artist_name, SUM(
                invoice_line.unit_price * invoice_line.quantity
            ) total_invoice
        FROM
            invoice_line
            JOIN track ON track.track_id = invoice_line.track_id
            JOIN album ON album.album_id = track.album_id
            JOIN artist ON artist.artist_id = album.artist_id
        GROUP BY
            artist.artist_id,
            artist.name
        ORDER BY total_invoice DESC
        LIMIT 1
    )
SELECT cus.customer_id, cus.first_name, cus.last_name, bsa.artist_name, SUM(il.unit_price * il.quantity) amount_spent
FROM
    invoice i
    JOIN customer cus ON cus.customer_id = i.customer_id
    JOIN invoice_line il ON il.invoice_id = i.invoice_id
    JOIN track tr ON tr.track_id = il.track_id
    JOIN album alb ON alb.album_id = tr.album_id
    JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY
    cus.customer_id,
    cus.first_name,
    cus.last_name,
    bsa.artist_name
ORDER BY amount_spent DESC;

-- 2. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres

WITH
    popular_genre AS (
        SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, ROW_NUMBER() OVER (
                PARTITION BY
                    customer.country
                ORDER BY COUNT(invoice_line.quantity) DESC
            ) AS RowNo
        FROM
            invoice_line
            JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
            JOIN customer ON customer.customer_id = invoice.customer_id
            JOIN track ON track.track_id = invoice_line.track_id
            JOIN genre ON genre.genre_id = track.genre_id
        GROUP BY
            2,
            3,
            4
        ORDER BY 2 ASC, 1 DESC
    )
SELECT *
FROM popular_genre
WHERE
    RowNo <= 1

/* Method 2: : Using Recursive */

WITH RECURSIVE
    sales_per_country AS (
        SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
        FROM
            invoice_line
            JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
            JOIN customer ON customer.customer_id = invoice.customer_id
            JOIN track ON track.track_id = invoice_line.track_id
            JOIN genre ON genre.genre_id = track.genre_id
        GROUP BY
            2,
            3,
            4
        ORDER BY 2
    ),
    max_genre_per_country AS (
        SELECT MAX(purchases_per_genre) AS max_genre_number, country
        FROM sales_per_country
        GROUP BY
            2
        ORDER BY 2
    )
SELECT sales_per_country.*
FROM
    sales_per_country
    JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE
    sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

    /* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1



/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),
	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;