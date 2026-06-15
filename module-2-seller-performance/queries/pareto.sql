-- Module 2: Pareto Analysis
-- Identifies which sellers drive 80% of platform GMV
-- Result: 543 sellers (17.5%) account for 80% of total GMV

WITH seller_metrics AS (
    SELECT
        sellers.seller_id,
        SUM(order_items.price) AS gmv,
        COUNT(DISTINCT orders.order_id) AS order_count,
        AVG(order_reviews.review_score) AS avg_review_score,
        AVG(DATE_DIFF('day', orders.order_purchase_timestamp, orders.order_delivered_customer_date)) AS avg_fulfillment_days
    FROM sellers
    LEFT JOIN order_items ON sellers.seller_id = order_items.seller_id
    LEFT JOIN orders ON order_items.order_id = orders.order_id
    LEFT JOIN order_reviews ON orders.order_id = order_reviews.order_id
    GROUP BY sellers.seller_id
),
seller_quintiles AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY gmv DESC) AS gmv_quintile,
        CASE
            WHEN avg_review_score >= 4.5 THEN 1
            WHEN avg_review_score >= 4.0 THEN 2
            WHEN avg_review_score >= 3.5 THEN 3
            WHEN avg_review_score >= 3.0 THEN 4
            ELSE 5
        END AS review_score_tier
    FROM seller_metrics
),
pareto_calc AS (
    SELECT
        seller_id,
        gmv,
        SUM(gmv) OVER (ORDER BY gmv DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gmv,
        SUM(gmv) OVER (ORDER BY gmv DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / SUM(gmv) OVER () AS cumulative_share
    FROM seller_quintiles
),
pareto_flagged AS (
    SELECT
        seller_id,
        gmv,
        cumulative_gmv,
        cumulative_share,
        CASE WHEN cumulative_share <= 0.80 THEN 'pareto' ELSE 'tail' END AS pareto_flag
    FROM pareto_calc
)
SELECT
    pareto_flag,
    COUNT(seller_id) AS seller_count,
    ROUND(MAX(cumulative_share) * 100, 2) AS max_cumulative_share_pct
FROM pareto_flagged
GROUP BY pareto_flag;
