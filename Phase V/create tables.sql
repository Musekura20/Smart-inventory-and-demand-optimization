SET SERVEROUTPUT ON SIZE 1000000;
DECLARE
  PROCEDURE safe_create(p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
BEGIN
  safe_create('CREATE SEQUENCE seq_medicines START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_suppliers START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_branches START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_batches START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_inventory START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_transactions START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_transaction_items START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_predictions START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_alerts START WITH 1 INCREMENT BY 1 NOCACHE');
  safe_create('CREATE SEQUENCE seq_transfers START WITH 1 INCREMENT BY 1 NOCACHE');
END;
/
COMMIT;

--Create DDL tables
--Medecines
CREATE TABLE Medicines (
  Medicine_ID     NUMBER PRIMARY KEY,
  Name            VARCHAR2(120) NOT NULL,
  Type            VARCHAR2(50) NOT NULL,
  Reorder_Point   NUMBER DEFAULT 0 NOT NULL,
  Unit            VARCHAR2(20) DEFAULT 'TAB' NOT NULL,
  CONSTRAINT chk_med_type CHECK (LENGTH(TYPE) > 0)
);

-- Suppliers
CREATE TABLE Suppliers (
  Supplier_ID NUMBER PRIMARY KEY,
  Name        VARCHAR2(150) NOT NULL,
  Contact     VARCHAR2(150),
  Rating      NUMBER(3,2) DEFAULT NULL CHECK (Rating BETWEEN 0 AND 5)
);

-- Branches
CREATE TABLE Branches (
  Branch_ID NUMBER PRIMARY KEY,
  Name      VARCHAR2(150) NOT NULL,
  Location  VARCHAR2(200),
  Branch_Ownership VARCHAR2(20) DEFAULT 'EXTERNAL' CHECK (Branch_Ownership IN ('EXTERNAL','INTERNAL'))
);

-- Batches
CREATE TABLE Batches (
  Batch_ID           NUMBER PRIMARY KEY,
  Supplier_ID        NUMBER,
  Medicine_ID        NUMBER NOT NULL,
  Branch_ID          NUMBER NOT NULL,
  Batch_No           VARCHAR2(80) NOT NULL,
  Expiry_Date        DATE NOT NULL,
  Quantity_Remaining NUMBER NOT NULL CHECK (Quantity_Remaining >= 0),
  CONSTRAINT fk_batch_med FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_batch_branch FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID),
  CONSTRAINT fk_batch_supplier FOREIGN KEY (Supplier_ID) REFERENCES Suppliers(Supplier_ID)
);

-- Inventory 
CREATE TABLE Inventory (
  Inventory_ID     NUMBER PRIMARY KEY,
  Medicine_ID      NUMBER NOT NULL,
  Branch_ID        NUMBER NOT NULL,
  Quantity_On_Hand NUMBER DEFAULT 0 NOT NULL,
  Threshold        NUMBER,
  CONSTRAINT uq_inv_branch_med UNIQUE (Medicine_ID, Branch_ID),
  CONSTRAINT fk_inv_med FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_inv_branch FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID),
  CONSTRAINT chk_quantity_nonneg CHECK (Quantity_On_Hand >= 0),
  CONSTRAINT chk_threshold_nonneg CHECK (Threshold IS NULL OR Threshold >= 0)
);

--Users
CREATE TABLE Users (
  User_ID   NUMBER PRIMARY KEY,
  Username  VARCHAR2(50) UNIQUE NOT NULL,
  Role      VARCHAR2(20) NOT NULL,
  -- Link only to internal site if needed; trigger will block EXTERNAL assignment
  Branch_ID NUMBER,
  CONSTRAINT chk_user_role CHECK (Role IN ('ADMIN','MANAGER','PHARMACIST'))
);

-- Transactions
CREATE TABLE Transactions (
  Transaction_ID   NUMBER PRIMARY KEY,
  Transaction_Type VARCHAR2(10) NOT NULL,
  Branch_ID        NUMBER NOT NULL,
  User_ID          NUMBER,
  Transaction_Date TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_trans_branch FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID),
  CONSTRAINT fk_trans_user FOREIGN KEY (User_ID) REFERENCES Users(User_ID) ENABLE NOVALIDATE,
  CONSTRAINT chk_trans_type CHECK (Transaction_Type IN ('SALE','RESTOCK','ADJUST'))
);

-- Transaction_items
CREATE TABLE Transaction_Items (
  Transaction_Item_ID NUMBER PRIMARY KEY,
  Transaction_ID      NUMBER NOT NULL,
  Medicine_ID         NUMBER NOT NULL,
  Batch_ID            NUMBER,
  Quantity            NUMBER NOT NULL CHECK (Quantity > 0),
  CONSTRAINT fk_ti_trans FOREIGN KEY (Transaction_ID) REFERENCES Transactions(Transaction_ID),
  CONSTRAINT fk_ti_med   FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_ti_batch FOREIGN KEY (Batch_ID) REFERENCES Batches(Batch_ID)
);

-- Predictions
CREATE TABLE Predictions (
  Prediction_ID    NUMBER PRIMARY KEY,
  Medicine_ID      NUMBER NOT NULL,
  Branch_ID        NUMBER,
  Year_            NUMBER NOT NULL,
  Month_           NUMBER NOT NULL CHECK (Month_ BETWEEN 1 AND 12),
  Predicted_Demand NUMBER NOT NULL CHECK (Predicted_Demand >= 0),
  CONSTRAINT fk_pred_med FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_pred_branch FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID)
);

-- Alerts
CREATE TABLE Alerts (
  Alert_ID    NUMBER PRIMARY KEY,
  Branch_ID   NUMBER,
  Medicine_ID NUMBER,
  Batch_ID    NUMBER,
  Alert_Type  VARCHAR2(30) NOT NULL,
  Message     VARCHAR2(1000) NOT NULL,
  Created_At  TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_alert_branch FOREIGN KEY (Branch_ID) REFERENCES Branches(Branch_ID),
  CONSTRAINT fk_alert_med FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_alert_batch FOREIGN KEY (Batch_ID) REFERENCES Batches(Batch_ID)
);

CREATE TABLE Transfers (
  Transfer_ID    NUMBER PRIMARY KEY,
  From_Branch_ID NUMBER NOT NULL,
  To_Branch_ID   NUMBER NOT NULL,
  Medicine_ID    NUMBER NOT NULL,
  Batch_ID       NUMBER,
  Quantity       NUMBER NOT NULL CHECK (Quantity > 0),
  Requested_By   NUMBER,
  Requested_At   TIMESTAMP DEFAULT SYSTIMESTAMP,
  Status         VARCHAR2(20) DEFAULT 'SENT' CHECK (Status IN ('SENT','CANCELLED')),
  Notes          VARCHAR2(2000),
  CONSTRAINT fk_tr_from_branch FOREIGN KEY (From_Branch_ID) REFERENCES Branches(Branch_ID),
  CONSTRAINT fk_tr_to_branch   FOREIGN KEY (To_Branch_ID)   REFERENCES Branches(Branch_ID),
  CONSTRAINT fk_tr_med FOREIGN KEY (Medicine_ID) REFERENCES Medicines(Medicine_ID),
  CONSTRAINT fk_tr_batch FOREIGN KEY (Batch_ID) REFERENCES Batches(Batch_ID),
  CONSTRAINT fk_tr_user FOREIGN KEY (Requested_By) REFERENCES Users(User_ID)
);

CREATE TABLE ERROR_LOG (
  ERROR_ID       NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
  LOG_TIMESTAMP  TIMESTAMP DEFAULT SYSTIMESTAMP,
  SCHEMA_USER    VARCHAR2(30),
  PROC_NAME      VARCHAR2(100),
  ERR_CODE       VARCHAR2(50),
  ERR_MSG        VARCHAR2(4000),
  ERR_BACKTRACE  CLOB
);
