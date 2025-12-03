# FLOWCHART OVERVIEW

👉 **Flowchart Diagram:**  
![Flowchart](My%20project%20BM.drawio.png)


The **Smart Medicine Inventory and Demand Optimization System** manages the full flow of medicines from sale or purchase to stock monitoring, expiry control, and replenishment across branches. It has **five main components**:

- Pharmacist  
- Inventory System  
- Manager  
- Supplier  
- Branch  

---

## 1. Pharmacist Role
The pharmacist is responsible for recording daily activities. They:

- Capture and record all sales transactions  
- Capture and record all purchase transactions  

---

## 2. Inventory System Role
After the pharmacist submits a transaction, the system automatically:

- Updates inventory levels  
- Runs demand prediction  
- Checks for low stock  
- Checks for near-expiry items  
- Generates alerts for the manager  

### After manager approves a transfer:
The **Inventory System**:

- Creates the transfer record   
- Notifies the branch receiving near-expiry medicines  

---

## 3. Manager Role
The manager reviews system alerts and decides whether to:

- **Approve a stock transfer**, or  
- **Send a purchase order (PO) to the supplier**

---

## 4. Supplier Process
After receiving the PO, the supplier:

- Confirms the order  
- Prepares the shipment  
- Delivers medicines to the pharmacy  

---

## 5. Branch Process
The branch:

- Receives transfer notifications  
- Receives the shipment  
- Confirms it  
- Updates its inventory with the new stock  

All actors together create an **integrated workflow** represented in the swimlane diagram.

---

## 6. Benefits as a Management Information System (MIS)

The system collects data such as:

- Transactions  
- Stock levels  
- Expiry dates  

And converts it into timely information for decision making.

### Main improvements:

- Less manual calculation  
- Standardized inventory updates  
- Fewer stock-outs  
- Less waste from expired items  
- Better stock sharing between branches  
- Improved medicine availability  

---

## 7. Analytics & Optimization

### **Demand Prediction**
Based on past sales, the system predicts future demand.  
This helps improve:

- Reorder quantities  
- Stock limits  

### **Performance & Alert Analysis**
The system studies:

- Transfer records  
- Alerts  
- Supplier performance  
- Stock wastage patterns  
- Out-of-stock frequency  

This helps identify:

- Slow-moving items  
- Medicines that expire often  
- Poor supplier performance  

Overall, the system helps continuously improve stock management and reduce losses.
