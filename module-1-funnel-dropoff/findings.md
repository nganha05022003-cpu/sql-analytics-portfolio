# Module 1 — E-commerce Funnel Dropoff Analysis
## Dataset: Olist Brazil E-commerce (2016–2018)

---

## Summary

Analysis of 99,441 orders across the Olist e-commerce platform reveals that 97% of orders are successfully delivered. However, 1,107 orders (1.1%) are permanently stuck at the shipped stage — meaning they left the seller but never confirmed as delivered to the customer. An additional 1,234 orders (1.2%) were canceled or marked unavailable before reaching fulfillment.

---

## Funnel Overview

| Stage | Orders | Share of Total |
|---|---|---|
| Created | 5 | 0.005% |
| Approved | 2 | 0.002% |
| Processing | 301 | 0.30% |
| Invoiced | 314 | 0.32% |
| Shipped (stuck) | 1,107 | 1.11% |
| Delivered | 96,478 | 97.02% |
| Canceled / Unavailable | 1,234 | 1.24% |

---

## Key Finding: Drop-off is Concentrated, Not Systemic

The biggest drop-off occurs at the **shipped stage** — orders that left the seller but never reached the customer. Initial analysis might suggest a platform-wide logistics failure. However, segment analysis reveals the problem is heavily concentrated:

**By seller state:** São Paulo (SP) accounts for 809 of 1,107 stuck orders — **73% of all stuck shipments** — despite being Brazil's largest commercial hub with the highest seller density.

**By product category:** Health & beauty (107), bed/bath/table (106), and sports/leisure (95) are the top three categories with stuck shipments, suggesting possible packaging, weight, or handling complexity in these product types.

---

## PM Hypothesis

The data suggests this is a **São Paulo seller fulfillment problem**, not a carrier or route problem. If it were a carrier issue, stuck orders would be distributed more evenly across states. The concentration in SP points to specific seller-side failures — likely in packaging, handoff to carriers, or order confirmation processes.

---

## Recommended Actions

1. **Audit SP sellers with >5 stuck orders** — identify whether specific sellers are responsible for a disproportionate share of the 809 SP stuck orders.
2. **Investigate health/beauty and bed/bath fulfillment** — these categories may have weight or fragility handling requirements that sellers are not meeting, causing carriers to reject shipments.
3. **Add delivery confirmation SLA** — implement an automated flag when an order remains in "shipped" status beyond the estimated delivery date, triggering a seller follow-up workflow.

---

## Data Limitations

This analysis is descriptive, not diagnostic. Confirming root cause would require: (1) carrier-level data showing where in transit orders stall, (2) seller-level attributes such as fulfillment center size and average handling time, and (3) customer complaint data for stuck orders. The current dataset narrows the hypothesis space but cannot confirm causality.

---

*Analysis conducted using DuckDB on the Olist Brazilian E-commerce public dataset (Kaggle). SQL queries available in `/queries`.*
