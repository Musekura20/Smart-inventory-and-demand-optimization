# ✅ Data Dictionary

This document lists all tables in the system with their columns, data types, constraints, and descriptions.

---

## 1. MEDICINES TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Medicine_ID | NUMBER(10) | PK, NOT NULL | Unique ID for each medicine |
| Name | VARCHAR2(100) | NOT NULL | Medicine name |
| Type | VARCHAR2(50) | NOT NULL | Type or category of the medicine |
| Reorder_Point | NUMBER | DEFAULT 0 | Minimum stock before low‑stock alert |

---

## 2. SUPPLIERS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Supplier_ID | NUMBER(10) | PK, NOT NULL | Unique supplier ID |
| Name | VARCHAR2(100) | NOT NULL | Supplier name |
| Contact | VARCHAR2(150) | NULL | Phone, email, or address |

---

## 3. BRANCHES TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Branch_ID | NUMBER(10) | PK, NOT NULL | Unique branch ID |
| Name | VARCHAR2(100) | NOT NULL | Branch name |
| Location | VARCHAR2(150) | NULL | Physical location |

---

## 4. BATCHES TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Batch_ID | NUMBER(10) | PK, NOT NULL | Unique batch ID |
| Supplier_ID | NUMBER(10) | FK → Suppliers(Supplier_ID), NOT NULL | Supplier of the batch |
| Medicine_ID | NUMBER(10) | FK → Medicines(Medicine_ID), NOT NULL | Medicine in this batch |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NOT NULL | Branch storing the batch |
| Batch_No | VARCHAR2(50) | NOT NULL | Supplier batch number |
| Expiry_Date | DATE | NOT NULL | Expiry date |
| Quantity_Remaining | NUMBER | NOT NULL | Units left in the batch |

---

## 5. INVENTORY TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Inventory_ID | NUMBER(10) | PK, NOT NULL | Unique inventory record |
| Medicine_ID | NUMBER(10) | FK → Medicines(Medicine_ID), NOT NULL | Medicine tracked |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NOT NULL | Branch owning the stock |
| Quantity_On_Hand | NUMBER | NOT NULL | Current stock available |
| Threshold | NUMBER | NULL | Branch‑specific reorder level |

---

## 6. USERS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| User_ID | NUMBER(10) | PK, NOT NULL | Unique user ID |
| Username | VARCHAR2(50) | UNIQUE, NOT NULL | Login username |
| Role | VARCHAR2(20) | NOT NULL | ADMIN, MANAGER, or PHARMACIST |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NULL | Branch assigned (optional) |

---

## 7. TRANSACTIONS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Transaction_ID | NUMBER(10) | PK, NOT NULL | Transaction header ID |
| Transaction_Type | VARCHAR2(10) | NOT NULL | SALE, RESTOCK, or ADJUST |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NOT NULL | Branch where it happened |
| User_ID | NUMBER(10) | FK → Users(User_ID), NULL | User who performed it |
| Transaction_Date | TIMESTAMP | DEFAULT SYSTIMESTAMP | When it happened |

---

## 8. TRANSACTION_ITEMS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Transaction_Item_ID | NUMBER(10) | PK, NOT NULL | Unique line item ID |
| Transaction_ID | NUMBER(10) | FK → Transactions(Transaction_ID), NOT NULL | Parent transaction |
| Medicine_ID | NUMBER(10) | FK → Medicines(Medicine_ID), NOT NULL | Medicine involved |
| Batch_ID | NUMBER(10) | FK → Batches(Batch_ID), NULL | Batch used |
| Quantity | NUMBER | NOT NULL | Quantity sold or restocked |

---

## 9. PREDICTIONS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Prediction_ID | NUMBER(10) | PK, NOT NULL | Prediction ID |
| Medicine_ID | NUMBER(10) | FK → Medicines(Medicine_ID), NOT NULL | Medicine predicted |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NULL | Branch (NULL = global) |
| Year | NUMBER | NOT NULL | Prediction year |
| Month | NUMBER | NOT NULL | Prediction month (1–12) |
| Predicted_Demand | NUMBER | NOT NULL | Forecasted quantity |

---

## 10. ALERTS TABLE

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| Alert_ID | NUMBER(10) | PK, NOT NULL | Alert ID |
| Branch_ID | NUMBER(10) | FK → Branches(Branch_ID), NULL | Branch related to alert |
| Medicine_ID | NUMBER(10) | FK → Medicines(Medicine_ID), NULL | Medicine related |
| Batch_ID | NUMBER(10) | FK → Batches(Batch_ID), NULL | Batch related |
| Alert_Type | VARCHAR2(30) | NOT NULL | LOW_STOCK, EXPIRY_SOON, EXPIRED, TRANSFER_SUGGESTION |
| Message | VARCHAR2(255) | NOT NULL | Alert message |
| Created_At | TIMESTAMP | DEFAULT SYSTIMESTAMP | When alert was created |
