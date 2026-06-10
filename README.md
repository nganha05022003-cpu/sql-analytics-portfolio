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
