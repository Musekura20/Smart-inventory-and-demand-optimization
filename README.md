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
 

### Triggers
Used to:  
- Auto-generate primary keys with sequences  
- Update stock automatically after transactions  
- Block dangerous operations (like editing on weekends)  
- Send expiry alerts  
- Record audit logs  

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

1. **Open Oracle SQL Developer** and connect to your database.  

2. **Create tables and sequences**:  
   - Run the scripts in the [Phase V](phase%20V) folder to create all 13 tables and their sequences.  
   - This will ensure your IDs are automatically generated when inserting data.  

3. **Compile functions and procedures**:  
   - Go to the `phase VI/functions` folder and compile all functions, including `Check_Restriction` and `Log_Audit_Func`.  
   - Make sure they compile successfully, because triggers depend on them.  

4. **Compile triggers**:  
   - Go to the `phase V/Triggers.sql` folder.  
   - Compile the simple triggers first (`trg_medicines_simple`, `trg_suppliers_simple`, `trg_users_simple`).  
   - Then compile the compound triggers (like `trg_medicines_compound`).  

5. **Insert sample data**:  
   - Use the test scripts from the `Phase V/Insert data` folder to insert sample medicines, suppliers, and users.  
   - This will also trigger your auditing and restriction checks.  

6. **Check results**:  
   - Verify which inserts were allowed or denied using the audit log:  
```sql
SELECT * FROM Audit_Log ORDER BY Attempt_Time DESC;


