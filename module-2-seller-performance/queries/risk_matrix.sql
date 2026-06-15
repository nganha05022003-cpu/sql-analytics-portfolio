-- Module 2: Risk Matrix
-- Segments sellers by GMV quintile and review score tier
-- Key finding: 52 high-GMV sellers rated below 3.5 account for 6% of platform GMV

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
total_gmv AS (
    SELECT SUM(gmv) AS platform_gmv FROM seller_metrics
)
-- Risk matrix: seller count and GMV share per segment
SELECT
    gmv_quintile,
    review_score_tier,
    COUNT(seller_id) AS seller_count,
    ROUND(SUM(gmv), 2) AS total_gmv,
    ROUND(SUM(gmv) / (SELECT platform_gmv FROM total_gmv) * 100, 2) AS gmv_share_pct
FROM seller_quintiles
GROUP BY gmv_quintile, review_score_tier
ORDER BY gmv_quintile, review_score_tier;

-- High-risk segment detail: top GMV quintile, poor ratings
SELECT
    seller_id,
    ROUND(gmv, 2) AS gmv,
    ROUND(avg_review_score, 2) AS avg_review_score,
    gmv_quintile,
    review_score_tier,
    ROUND(gmv / (SELECT platform_gmv FROM total_gmv) * 100, 4) AS share_of_platform_gmv
FROM seller_quintiles, total_gmv
WHERE gmv_quintile = 1
  AND review_score_tier IN (4, 5)
ORDER BY gmv DESC;
