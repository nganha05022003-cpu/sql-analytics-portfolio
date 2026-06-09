 SELECT sellers.seller_state, COUNT(DISTINCT orders.order_id) AS stuck_orders
          FROM orders
          INNER JOIN order_items ON orders.order_id = order_items.order_id
          INNER JOIN sellers ON order_items.seller_id = sellers.seller_id
          WHERE order_status = 'shipped'
          GROUP BY sellers.seller_state
          ORDER BY stuck_orders DESC
        ) TO 'funnel_by_seller_state.csv' (HEADER, DELIMITER ',');
