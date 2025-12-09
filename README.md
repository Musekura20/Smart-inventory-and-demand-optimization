# Smart Medicine Inventory and Demand Optimization System

**Student Name:** INEZA MUSEKURA Esperance
**Student ID:** 28777 
**Institution:** Adventist University of Central Africa (AUCA)

---

## 1. Overview
This project is a PL/SQL system that helps pharmacies and hospitals manage their medicine stock in a smarter and faster way.  
The system keeps track of medicine quantities, checks expiry dates, sends alerts, and predicts future demand using past data.  
It reduces waste, avoids shortages, and protects patients from expired drugs.

---

## 2. Problem Statement
Many pharmacies still use manual methods to manage medicine stock.  
This causes mistakes, shortages, expired drugs, and financial losses.  
The system solves these problems by automating updates, monitoring expiry, and predicting demand.

---

## 3. Key Objectives
- Keep enough stock for all important medicines  
- Reduce losses caused by expiry  
- Update stock automatically after sales and supplies  
- Predict future demand using past transactions  
- Send alerts when stock is low or near expiry  
- Improve safety and decision-making for pharmacy staff  

---

## 4. Main Features (PL/SQL Work Done)
### Stored Procedures
Used for:  
- Registering medicines  
- Recording supplies  
- Processing sales  
- Updating inventory  
- Generating reports  

### Functions
Used to:  
- Predict demand  
- Check expiry dates  
- Calculate stock needs  
- Compute top sellers
  [Functions](./Phase%20VI/functions.sql) 

### Triggers
Used to:  
- Auto-generate primary keys with sequences  
- Update stock automatically after transactions  
- Block dangerous operations (like editing on weekends)  
- Send expiry alerts  
- Record audit logs  
[triggers.sql](phase%20V/datascripts/triggers.sql)
### Cursors
Used to loop through lists of medicines for reports and expiry checks.

### Packages
Used to group related functions and procedures for easier management.

### Exception Handling
Improves error messages and protects the system from breakdowns.

---

## 5. Database Design
### ER Diagram (13 Tables)
[ER_Diagram.png](phase%203/ER_Diagram.png)  
  

### Business Processes
I also created:
- Swimlane diagram  
[swimlane.png](phase%202/swimlane.png)

---

## 6. Technical Tools Used
- **Oracle Database 21c**  
- **SQL Developer /**  
- **PL/SQL** (procedures, functions, triggers, packages)  
- **Diagrams** for ERD and swimlanes  

---

## 7. Quick Start Instructions
1. Clone or download the project folder  
2. Open SQL Developer  
3. Run the scripts in this order:

