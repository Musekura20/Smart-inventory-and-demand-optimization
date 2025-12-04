#  Assumptions

These assumptions describe how the system works and what rules it follows.

- Medicines can appear in many batches because branches restock at different times.
- Inventory levels change only through transactions (SALE, RESTOCK, ADJUST).
- Low‑stock and expiry alerts are created automatically by PL/SQL triggers or procedures.
- Managers or pharmacists may review and update alert statuses when needed.
- Suppliers only provide medicines; they do not track expiry or stock levels.
- A medicine can be stored in multiple branches and in multiple batches inside each branch.
- Predictions use past sales data and assume all timestamps are correct.
- FEFO (First‑Expired‑First‑Out) is used when selecting which batch to sell first.
- If a branch does not set its own threshold, the system uses the global reorder point from the Medicines table.
- All dates and times (transactions, alerts, predictions) are assumed to be accurate.
- Alerts are not deleted; they stay in the system for audit and reporting.
