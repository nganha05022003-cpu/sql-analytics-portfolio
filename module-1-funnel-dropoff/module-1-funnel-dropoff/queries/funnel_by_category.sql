SELECT product_category_name_english, 
       COUNT(DISTINCT orders.order_id) AS stuck_orders
FROM orders
INNER JOIN order_items ON orders.order_id = order_items.order_id
INNER JOIN products ON order_items.product_id = products.product_id
INNER JOIN categories ON products.product_category_name = categories.product_category_name
WHERE order_status = 'shipped'
GROUP BY product_category_name_english
ORDER BY stuck_orders DESC;
