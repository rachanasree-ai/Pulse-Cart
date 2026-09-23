# PulseCart Customer Intelligence case

## 1. How to Rerun

1. Place the following files under `data/csv/` relative to the notebook:
   - `customers.csv`
   - `orders.csv`
   - `products.csv`
   - `support_tickets.csv`
   - `daily_ops.csv`
2. Place labeled images under `data/images/{damaged, normal, wrong_item}/` for the ANN/CNN section (Station H).
3. Run all cells top to bottom. Later stations depend on cleaned frames built earlier (`customers_clean`, `orders_clean`, `model_data`), so partial reruns can break references.
4. Random seeds are fixed (`random_state=42`) for the train/test splits, K-Means, DBSCAN sensitivity scan, and the ANN, so results are reproducible.

## 2. Environment

- Python 3 with: `pandas`, `numpy`, `matplotlib`, `seaborn`, `re`, `statsmodels`, `scikit-learn`, `Pillow (PIL)`.
- Installed in-notebook via `%pip install pandas numpy matplotlib seaborn`, `%pip install statsmodels`, `%pip install scikit-learn`.
- No GPU required — the ANN uses `sklearn.neural_network.MLPClassifier` on 32×32 flattened RGB images.

---

## 3. Answers to the Business Questions

### 1. Who is leaving, and is any city or plan actually different?

Houston had an observed churn rate of 30.16% (57 of 189 customers), compared with 12.78% for customers in the other cities. This represents a difference of 17.38 percentage points. A two-proportion z-test produced a p-value of 1.38 × 10⁻⁸, indicating a statistically significant difference in the observed churn rates. Customer order count also showed a negative association with churn, with a correlation of approximately -0.272. This is an association and does not establish that order frequency causes lower churn. The analysis therefore identifies Houston as an area that warrants further investigation.

### 2. Which category is driving returns, and is that gap large enough to act on?

The Kitchen category had the highest observed return rate at 23.75% (171 returns out of 720 orders). The other categories combined had a return rate of approximately 5.32% (142 returns out of 2,668 orders). This represents a difference of approximately 18.43 percentage points. A two-proportion z-test showed a statistically significant difference between Kitchen and the other categories, with a p-value of approximately 7.21 × 10⁻⁵². Kitchen therefore stands out as the category requiring further investigation. Possible areas to investigate include product quality, packaging, fulfillment, product descriptions, and customer complaints.

### 3. Can you predict churn for an outreach list without leaking the future?

A Random Forest model was developed using customer information available up to the 1 June 2026 cutoff date. The features included order count, total spend, return rate, recency, ticket count, plan, and city. The `last_active_date` field was excluded because it could introduce target leakage. The Random Forest achieved 40.48% precision, 58.62% recall, and 0.753 ROC-AUC on the test set. The model produced 12 false negatives and 25 false positives. These results indicate that the model can be used to prioritize customers for outreach, but predictions should not be treated as definitive churn decisions.

### 4. Did daily orders change after 1 June 2026, or is that noise?

Average daily orders were 171.71 before 1 June 2026 and 133.70 from 1 June 2026 onward. This represents a 22.14% decrease in average daily orders. The time-series analysis shows a noticeable downward level shift after the 1 June cutoff. A time-based train-test split was used without randomly shuffling the observations, and a naive previous-day forecast was used as the baseline. However, the observed decrease is descriptive and does not by itself prove that the June change caused the decline. Further investigation into site activity, conversion, promotions, and operational changes is required.

### 5. What should PulseCart do in the next 30 days?

**Action 1 — Investigate Kitchen Returns.** Kitchen had a return rate of 23.75%, compared with approximately 5.32% for the other categories. PulseCart should review the highest-returned Kitchen products, customer complaints, product descriptions, packaging, and fulfillment processes to identify the source of the high return rate.

**Action 2 — Investigate Houston Churn.** Houston had a churn rate of 30.16%, compared with 12.78% for the other cities. PulseCart should analyze Houston customers' order frequency, recency, support tickets, returns, and customer feedback to identify potential reasons for the difference.

**Action 3 — Use the Churn Model for Targeted Outreach.** The Random Forest achieved 58.62% recall and 0.753 ROC-AUC. PulseCart can use the model to prioritize a smaller group of customers for outreach and measure their response over the next 30 days. Because the model produced 25 false positives and 12 false negatives, it should be used for prioritization rather than automatic customer decisions.


---

## 4. Limitations

- **Causality**: the city churn gap, category return gap, and the June order drop are all *associations/descriptive comparisons*. None of the hypothesis tests or before/after comparisons establish causation.
- **Data cleaning caveats**: 24 rows involved in duplicate emails (12 duplicated values), 20 invalid emails, 17 invalid phone numbers, and 25 orphan orders (0.74% of all orders, dropped from customer-linked analysis) were found and handled — some information loss is inherent in this cleaning.
- **Price correction**: 16 order records had a unit price that didn't match the product's list price; these were corrected to the list price. Zero products had invalid (≤0) list prices, and no IQR-based price outliers were found among products.
- **Model precision**: the churn Random Forest has only 40.5% precision — a majority of "predicted churn" customers in any outreach list will not actually churn. Use as a prioritization/ranking tool, not a hard label.
- **Clustering is exploratory**: K-Means (k=6 by silhouette score) and DBSCAN (6 clusters + a noise group at eps=0.8, 10.32% noise) give complementary but not identical customer segments — they should inform, not dictate, business definitions of customer types.
- **ANN/CNN (Station H) is on a very small, likely synthetic image set**: 240 images total (80 per class), 100% test accuracy on only 48 test images. This is far too small and too clean a result to trust for production damage/defect classification — it almost certainly indicates an easy/synthetic dataset rather than a production-ready model, and should be re-validated on a larger, real-world labeled set before any operational use.
- **Regex extraction** from support tickets (520 total) achieved a 100% hit rate for order IDs, 98.08% for emails, and 88.85% for phone numbers — high but not perfect; the ~11% of tickets with no extracted phone number may need manual review if phone-based follow-up is required.
