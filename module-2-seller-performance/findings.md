# Module 2: Seller Performance Segmentation — Findings

**Dataset:** Olist Brazil E-commerce (sellers, order_items, orders, order_reviews)
**Period:** Full dataset (~2016–2018)
**Total sellers analyzed:** 3,095

---

## Summary

Revenue on the Olist platform is sharply concentrated. The top 17.5% of sellers
(543 out of 3,095) generate 80% of total GMV — a more extreme concentration than
the classic 80/20 Pareto benchmark. This asymmetry means seller quality risk is
not evenly distributed: problems in the top quintile have outsized platform impact.

Within the top GMV quintile, 52 sellers have average review scores below 3.5.
Together they account for 6% of total platform GMV (~822K). These sellers represent
the core risk segment: high enough revenue to make removal costly, poor enough
ratings to be actively damaging customer trust and repeat purchase rate.

**Key numbers:**
- Total platform GMV: ~13.65M
- Pareto sellers (top 17.5%): 543 sellers, 80% of GMV
- High-risk segment: 52 sellers, 822K GMV, 6% of platform GMV
- Worst-rated high-GMV seller: avg score 1.0, GMV 4,700

---

## Recommended Actions

A tiered intervention is recommended rather than a blanket policy, segmenting
the 52 high-risk sellers by both GMV size and rating severity.

**Tier 1 — High GMV + rating 3.0–3.5 (review_score_tier 4): Warn + Support**
These sellers are borderline and commercially valuable. Recommended action:
issue private scorecards showing rating trajectory and peer benchmarks. Frame
improvement as protecting their own sales velocity, since low ratings suppress
organic visibility. No restrictions yet.

**Tier 2 — High GMV + rating below 3.0 (review_score_tier 5): Restrict + Monitor**
Incentives alone are insufficient at this severity. Recommended action: restrict
new product listings until rating recovers above 3.5. Cap promotional placement.
Set a 90-day review window with explicit rating targets. These sellers have leverage
but the platform cannot absorb continued trust erosion.

**Tier 3 — Lower GMV + rating below 3.0: Probation + Deadline**
Least leverage, worst quality. Issue a 60-day improvement deadline with a minimum
rating floor. Remove if unmet. The GMV impact is manageable.

**Long-term policy suggestion:** Introduce a seller health score combining GMV
contribution, review score trend (not just current score), and fulfillment
consistency. Use this as the basis for tiered seller benefits and restrictions
rather than reacting to point-in-time ratings.

---

## Data Limitations

**1. Review score coverage is incomplete.**
Not all orders have reviews. Sellers with fewer orders have noisier average scores
— a seller with 3 orders and 1 bad review looks identical in avg_review_score to
a seller with 100 orders and consistent bad reviews. Order count should be weighted
into any risk flag.

**2. NTILE for review scores is misleading without correction.**
Initial NTILE bucketing placed sellers with scores from 1.0 to 3.5 in the same
quintile due to rating skew (most Olist sellers rate 4.0–5.0). This was corrected
using fixed CASE WHEN thresholds. Any future analysis using NTILE on review scores
should validate bucket ranges first.

**3. GMV does not equal profit.**
High GMV sellers may operate on thin margins or high return rates. A seller with
190K GMV and a 3.35 rating may be less profitable than a seller with 50K GMV and
a 4.8 rating. Refund and return data would sharpen the risk assessment significantly.

**4. Temporal dimension is absent.**
This analysis is a point-in-time snapshot. A seller's rating may be improving or
declining — the trend matters more than the current value for intervention decisions.
A seller at 3.2 trending up is a different risk than a seller at 3.2 trending down.

---

## Analytical Note: Why CASE WHEN beats NTILE for review scores

NTILE divides sellers into equal-sized buckets by row count, not by value range.
Because Olist seller ratings cluster heavily between 4.0 and 5.0, NTILE quintile 5
spanned a range of 1.0 to 3.5 — a 2.5-point spread versus 0.25 for quintile 1.
This made a seller with a 1.0 rating appear equivalent to one with a 3.49 rating.

Fixed thresholds via CASE WHEN produce business-meaningful tiers that can be
defended in stakeholder conversations: "sellers rated below 3.0" is a clear,
actionable definition. "Sellers in the bottom quintile" is not.
