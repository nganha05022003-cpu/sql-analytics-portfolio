# sql-analytics-portfolio
A collection of SQL analytics projects built on real e-commerce data

### Module 1 — E-commerce Funnel Dropoff Analysis
- Dataset: Olist Brazil E-commerce (Kaggle)
- Tools: DuckDB, Looker Studio
- Key finding: 73% of stuck shipments originate from São Paulo sellers,
  concentrated in health/beauty and bed/bath categories
- [View Dashboard](https://datastudio.google.com/s/sbAslzCVr3s)
- [View Findings](module-1-funnel-dropoff/findings.md)
- Here's your complete Module 1 summary — everything you learned, the key queries, and how to interpret them analytically.

---
Key Learning Points Summary
---
### 1. SELECT, FROM, LIMIT
**What it does:** Retrieves specific columns from a table. LIMIT controls how many rows come back.

```sql
SELECT order_id, order_status
FROM orders
LIMIT 5;
```

**Analytical use:** Schema exploration — understanding what's in a table before writing any analytical query. Always do this first on an unfamiliar dataset.

---

### 2. WHERE + AND / OR
**What it does:** Filters rows based on conditions. AND requires both conditions true, OR requires either.

```sql
SELECT order_id, order_status
FROM orders
WHERE order_status = 'shipped'
OR order_status = 'invoiced';
```

**Analytical use:** Isolating specific subsets of data — for example, finding only stuck or failed orders. Foundation for every filter operation in analytics.

---

### 3. COUNT + GROUP BY + ORDER BY
**What it does:** Counts rows per group and sorts the result.

```sql
SELECT order_status, COUNT(*) AS num_orders
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;
```

**Analytical interpretation:** This single query told you the entire distribution of orders across statuses — 96,478 delivered vs 1,107 stuck at shipped. The rule: every non-COUNT column in SELECT must appear in GROUP BY.

---

### 4. CASE WHEN
**What it does:** Labels or categorizes rows based on conditions — SQL's if/then logic.

```sql
SELECT CASE WHEN order_status = 'delivered' THEN 'stage 6 - delivered'
            WHEN order_status = 'shipped'   THEN 'stage 5 - shipped'
            WHEN order_status = 'invoiced'  THEN 'stage 4 - invoiced'
            WHEN order_status = 'processing'THEN 'stage 3 - processing'
            WHEN order_status = 'approved'  THEN 'stage 2 - approved'
            WHEN order_status = 'created'   THEN 'stage 1 - created'
            ELSE 'canceled/unavailable'
       END AS funnel_stage,
       COUNT(*) AS num_orders
FROM orders
GROUP BY 1
ORDER BY 1;
```

**Analytical interpretation:** Transforms raw status values into a readable funnel. Combined with COUNT and GROUP BY, this produces the full funnel overview in one query. The ELSE clause catches all unmatched rows — never leave it out or you get NULLs.

---

### 5. INNER JOIN across multiple tables
**What it does:** Combines rows from two or more tables where a shared column matches.

```sql
SELECT product_category_name_english,
       COUNT(DISTINCT orders.order_id) AS stuck_orders
FROM orders
INNER JOIN order_items ON orders.order_id = order_items.order_id
INNER JOIN products    ON order_items.product_id = products.product_id
INNER JOIN categories  ON products.product_category_name = categories.product_category_name
WHERE order_status = 'shipped'
GROUP BY product_category_name_english
ORDER BY stuck_orders DESC;
```

**Analytical interpretation:** This query crosses 4 tables to answer "which product categories have the most stuck orders?" Result: health_beauty (107) and bed_bath_table (106) lead. Key rule: when two tables share a column name, prefix with `table_name.column_name` to avoid ambiguity errors.

---

### 6. COUNT DISTINCT
**What it does:** Counts unique values only — ignores duplicates.

```sql
COUNT(DISTINCT orders.order_id)
```

**Analytical interpretation:** Essential when joining to `order_items` because one order can have multiple product rows. Without DISTINCT, an order with 3 items gets counted 3 times. Use COUNT DISTINCT whenever you're counting entities (orders, customers, sellers) across a JOIN.

---

### 7. CTE (Common Table Expression)
**What it does:** Names a query result so you can reference it in subsequent steps of the same statement.

```sql
WITH funnel_counts AS (
    SELECT CASE WHEN order_status = 'delivered' THEN 'stage 6 - delivered'
                WHEN order_status = 'shipped'   THEN 'stage 5 - shipped'
                ELSE 'other' END AS funnel_stage,
           COUNT(*) AS num_orders
    FROM orders
    GROUP BY 1
)
SELECT funnel_stage,
       num_orders,
       num_orders * 100.0 / (SELECT SUM(num_orders) FROM funnel_counts) AS pct_of_total
FROM funnel_counts
ORDER BY funnel_stage;
```

**Analytical interpretation:** The CTE calculates stage counts once. The main SELECT reuses those counts to compute percentage share without rewriting the CASE WHEN block. CTEs make complex queries readable — one named step at a time.

---

### 8. COPY to CSV
**What it does:** Exports query results to a CSV file on disk.

```sql
COPY (SELECT ... FROM ...) TO 'filename.csv' (HEADER, DELIMITER ',');
```

**Analytical use:** Bridge between DuckDB and visualization tools. Export results → upload to Google Sheets → connect Looker Studio. Essential workflow for local SQL environments.

---

### Key SQL execution order to memorize

```
FROM      → which table
WHERE     → filter rows
GROUP BY  → group them
SELECT    → compute columns and aliases
ORDER BY  → sort the result
LIMIT     → cut to N rows
```

This order explains why GROUP BY can't use SELECT aliases — aliases don't exist yet when GROUP BY runs.

---

### The analytical story of Module 1

| Query | Question answered |
|---|---|
| GROUP BY order_status | Where are orders distributed across statuses? |
| CASE WHEN + COUNT | How does the funnel look stage by stage? |
| JOIN + WHERE shipped + GROUP BY category | Which product categories have the most stuck orders? |
| JOIN + WHERE shipped + GROUP BY seller_state | Which regions have the most stuck orders? |

**The finding:** Drop-off is concentrated, not systemic. São Paulo sellers account for 73% of stuck shipments, with health/beauty and bed/bath as the top affected categories. That's a targeted ops problem, not a platform-wide logistics failure.

---
###  Module 2: Seller Performance Segmentation

**Goal:** Rank sellers by GMV, identify the top 20% driving 80% of revenue,
and flag high-GMV/low-rating sellers as an operational risk segment.

**Output:** Pareto analysis, 5x5 risk matrix, high-risk seller list with GMV share.
### Key SQL Patterns Learned
**Multi-table LEFT JOIN chain**
Always use LEFT JOIN from the primary entity outward to preserve sellers with
zero orders. INNER JOIN would silently drop them.
```sql
FROM sellers
LEFT JOIN order_items ON sellers.seller_id = order_items.seller_id
LEFT JOIN orders      ON order_items.order_id = orders.order_id
LEFT JOIN order_reviews ON orders.order_id = order_reviews.order_id
```

**NTILE vs CASE WHEN for bucketing**
NTILE divides by row count — correct for GMV (relative ranking matters).
CASE WHEN divides by value thresholds — correct for review scores (absolute
values are meaningful). Always check bucket ranges with MIN/MAX before using
NTILE on skewed distributions.
```sql
-- Wrong for review scores (skewed distribution):
NTILE(5) OVER (ORDER BY avg_review_score DESC)

-- Right for review scores (business-defined thresholds):
CASE
    WHEN avg_review_score >= 4.5 THEN 1
    WHEN avg_review_score >= 4.0 THEN 2
    WHEN avg_review_score >= 3.5 THEN 3
    WHEN avg_review_score >= 3.0 THEN 4
    ELSE 5
END AS review_score_tier
```

**Cumulative SUM window frame**
The ROWS BETWEEN clause controls which rows are included in the running total.
UNBOUNDED PRECEDING means "from the very first row down to here."
```sql
SUM(gmv) OVER (
    ORDER BY gmv DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS cumulative_gmv
```

**Global SUM with empty OVER()**
An empty OVER() applies the aggregate across all rows with no partitioning.
Used to get total platform GMV for percentage calculations.
```sql
SUM(gmv) OVER () AS total_platform_gmv
```

**Why aggregate calculations belong outside row-level CTEs**
CTEs like seller_quintiles are row-level — one row per seller. Placing COUNT
or SUM inside them without GROUP BY collapses all rows into one number.
Aggregations that summarize the data go in the final SELECT with GROUP BY.

**CTE chaining for layered logic**
Each CTE builds on the previous one, keeping logic separated and readable:
WITH seller_metrics AS (
    -- base metrics per seller
),
seller_quintiles AS (
    SELECT *, NTILE(5) OVER (ORDER BY gmv DESC) AS gmv_quintile
    FROM seller_metrics
),
pareto_calc AS (
    SELECT *, SUM(gmv) OVER (ORDER BY gmv DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gmv
    FROM seller_quintiles
)
SELECT * FROM pareto_calc;
**CASE WHEN waterfall pattern**
When conditions are ordered and mutually exclusive, each WHEN only needs
one comparison — prior conditions already eliminated higher values.
```sql
CASE
    WHEN score >= 4.5 THEN 1   -- only reaches here if score < 4.5
    WHEN score >= 4.0 THEN 2   -- only reaches here if score < 4.0
    WHEN score >= 3.5 THEN 3
    WHEN score >= 3.0 THEN 4
    ELSE 5
END
```
**Window functions — RANK, DENSE_RANK, ROW_NUMBER**
What they do: Assign rank numbers to rows based on a sort order without collapsing rows like GROUP BY does.
sqlRANK() OVER (ORDER BY gmv DESC)        -- ties share rank, next rank skips
DENSE_RANK() OVER (ORDER BY gmv DESC)  -- ties share rank, no skipping
ROW_NUMBER() OVER (ORDER BY gmv DESC)  -- every row gets unique number
When to use which:

RANK → when gaps matter (official leaderboards)
DENSE_RANK → when you want clean sequential tiers despite ties
ROW_NUMBER → when you need a unique ID for every row regardless of ties
### Key PM Insight from This Module

Revenue concentration is not just a statistical curiosity — it defines where
operational risk is asymmetric. When 17.5% of sellers control 80% of GMV,
the platform cannot treat all seller quality failures equally. The correct
response is a tiered intervention framework, not a blanket policy.
