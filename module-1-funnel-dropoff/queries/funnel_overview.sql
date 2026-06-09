 COPY (
          SELECT CASE WHEN order_status = 'delivered' THEN 'stage 6 - delivered'
                      WHEN order_status = 'shipped' THEN 'stage 5 - shipped'
                      WHEN order_status = 'created' THEN 'stage 1 - created'
                      WHEN order_status = 'approved' THEN 'stage 2 - approved'
                      WHEN order_status = 'processing' THEN 'stage 3 - processing'
                      WHEN order_status = 'invoiced' THEN 'stage 4 - invoiced'
                      ELSE 'canceled/unavailable' END AS funnel_stage,
                 COUNT(*) AS num_orders
          FROM orders
          GROUP BY 1 ORDER BY 1
        ) TO 'funnel_overview.csv' (HEADER, DELIMITER ',');
