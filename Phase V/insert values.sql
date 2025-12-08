SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_supplier_id  NUMBER;
  v_user_id      NUMBER;
  v_branch_id    NUMBER;
  v_med_id       NUMBER;
  v_batch_id     NUMBER;
  v_inv_id       NUMBER;
  v_tx_id        NUMBER;
  v_ti_id        NUMBER;
  v_qty          NUMBER;
  v_batch_no     VARCHAR2(60);
  v_expiry       DATE;
  v_now          DATE := TRUNC(SYSDATE);
  -- counters to produce unique IDs
  c_supplier_ctr NUMBER := 0;
  c_user_ctr     NUMBER := 0;
  c_branch_ctr   NUMBER := 0;
  c_med_ctr      NUMBER := 0;
  c_batch_ctr    NUMBER := 0;
  c_inv_ctr      NUMBER := 0;
  c_tx_ctr       NUMBER := 0;
  c_ti_ctr       NUMBER := 0;
  c_pred_ctr     NUMBER := 0;
  c_alert_ctr    NUMBER := 0;
  c_transfer_ctr NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== Start test data insertion ===');
-- suppliers
FOR i IN 1..10 LOOP
    c_supplier_ctr := c_supplier_ctr + 1;
    INSERT INTO Suppliers(Supplier_ID, Name, Contact, Rating)
    VALUES (
        c_supplier_ctr,
        'Supplier ' || LPAD(c_supplier_ctr, 3, '0'),
        'supplier' || c_supplier_ctr || '@example.com | +250' || TO_CHAR(700000000 + c_supplier_ctr),
        ROUND(DBMS_RANDOM.VALUE(1, 5), 2)
    );
END LOOP;
COMMIT;

DBMS_OUTPUT.PUT_LINE('Inserted suppliers: 10');
END;
/

-- Users
DECLARE
  -- Counter to generate unique User_IDs
  c_user_ctr NUMBER := 0;

  -- List of roles for each user
  roles SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
      'ADMIN', 'MANAGER', 'PHARMACIST', 'PHARMACIST',
      'PHARMACIST', 'PHARMACIST', 'PHARMACIST', 'PHARMACIST',
      'PHARMACIST', 'PHARMACIST'
  );
BEGIN
  -- Loop through roles and insert users
  FOR i IN 1..roles.COUNT LOOP
    c_user_ctr := c_user_ctr + 1;

    INSERT INTO Users(User_ID, Username, Role, Branch_ID)
    VALUES (
        c_user_ctr,                    
        'user' || c_user_ctr,          
        roles(i),                      
        1                               
    );
  END LOOP;

  -- Commit the changes
  COMMIT;

  -- Output message
  DBMS_OUTPUT.PUT_LINE('Inserted users: ' || c_user_ctr);
END;
/

--Branches
DECLARE
  c_branch_ctr NUMBER := 0;
BEGIN
  FOR i IN 1..5 LOOP
    c_branch_ctr := c_branch_ctr + 1;

    IF c_branch_ctr = 1 THEN
      -- Internal branch
      INSERT INTO Branches(Branch_ID, Name, Location, Branch_Ownership)
      VALUES (c_branch_ctr, 'Central Pharmacy - Main', 'Kigali Central', 'INTERNAL');
    ELSE
      -- External branches
      INSERT INTO Branches(Branch_ID, Name, Location, Branch_Ownership)
      VALUES (c_branch_ctr, 'External Pharmacy ' || (c_branch_ctr - 1), 'Area ' || (c_branch_ctr - 1), 'EXTERNAL');
    END IF;
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Inserted branches: 5 (1 internal, 4 external)');
END;
/

--Medecines
DECLARE
  c_med_ctr NUMBER := 0;
BEGIN
  FOR i IN 1..200 LOOP
    c_med_ctr := c_med_ctr + 1;

    INSERT INTO Medicines(Medicine_ID, Name, Type, Reorder_Point, Unit)
    VALUES (
      c_med_ctr,
      'Medicine_' || LPAD(c_med_ctr, 4, '0'),
      CASE MOD(c_med_ctr,6)
        WHEN 0 THEN 'ANTIBIOTIC'
        WHEN 1 THEN 'ANALGESIC'
        WHEN 2 THEN 'ANTIVIRAL'
        WHEN 3 THEN 'ANTIMALARIAL'
        WHEN 4 THEN 'SUPPLEMENT'
        ELSE 'OTHER'
      END,
      CASE WHEN MOD(c_med_ctr,10)=0 THEN 5 ELSE TRUNC(DBMS_RANDOM.VALUE(5,30)) END,
      CASE MOD(c_med_ctr,4)
        WHEN 0 THEN 'TAB'
        WHEN 1 THEN 'ML'
        WHEN 2 THEN 'CAP'
        ELSE 'SACH'
      END
    );
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted medicines: 200');
END;
/

--Batches
DECLARE
  c_batch_ctr NUMBER := 0;
  v_supplier_id NUMBER;
  v_branch_id NUMBER;
  v_qty NUMBER;
  v_batch_no VARCHAR2(60);
  v_expiry DATE;
  v_now DATE := TRUNC(SYSDATE);
BEGIN
  FOR m IN 1..200 LOOP  -- each medicine
    FOR j IN 1..2 LOOP  -- 2 batches per medicine
      c_batch_ctr := c_batch_ctr + 1;
      v_batch_no := 'B' || LPAD(m,4,'0') || '-' || j;

      -- Random expiry
      IF DBMS_RANDOM.VALUE < 0.08 THEN
        v_expiry := v_now - TRUNC(DBMS_RANDOM.VALUE(1,365)); -- expired
      ELSIF DBMS_RANDOM.VALUE < 0.45 THEN
        v_expiry := v_now + TRUNC(DBMS_RANDOM.VALUE(1,120)); -- near expiry
      ELSE
        v_expiry := v_now + TRUNC(DBMS_RANDOM.VALUE(121,1200)); -- future
      END IF;

      -- Random quantity
      IF DBMS_RANDOM.VALUE < 0.03 THEN
        v_qty := 0;
      ELSE
        v_qty := TRUNC(DBMS_RANDOM.VALUE(1,500));
      END IF;

      -- Random supplier (NULL sometimes)
      IF DBMS_RANDOM.VALUE < 0.1 THEN
        v_supplier_id := NULL;
      ELSE
        v_supplier_id := TRUNC(DBMS_RANDOM.VALUE(1,11)); -- adjust if ≤10 suppliers
      END IF;

      -- Random branch assignment
      IF DBMS_RANDOM.VALUE < 0.75 THEN
        v_branch_id := 1; -- central/internal
      ELSE
        v_branch_id := TRUNC(DBMS_RANDOM.VALUE(2,6)); -- external branches 2..5
      END IF;

      -- Insert batch
      INSERT INTO Batches(Batch_ID, Supplier_ID, Medicine_ID, Branch_ID, Batch_No, Expiry_Date, Quantity_Remaining)
      VALUES (c_batch_ctr, v_supplier_id, m, v_branch_id, v_batch_no, v_expiry, v_qty);

    END LOOP;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted batches: ' || c_batch_ctr);
END;
/

--Inventory
DECLARE
  c_inv_ctr NUMBER := 0;
  v_qty     NUMBER;
BEGIN
  -- Inventory rows for central/internal branch (Branch_ID = 1)
  FOR m IN 1..200 LOOP
    c_inv_ctr := c_inv_ctr + 1;

    -- pick random quantity for testing
    v_qty := TRUNC(DBMS_RANDOM.VALUE(0,200));

    INSERT INTO Inventory(Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold)
    VALUES (
      c_inv_ctr, 
      m, 
      1,  -- central/internal branch only
      v_qty, 
      CASE 
        WHEN v_qty < 10 THEN 5 
        ELSE TRUNC(DBMS_RANDOM.VALUE(5,40)) 
      END
    );
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted inventory rows for internal branch: ' || c_inv_ctr);
END;
/

--Transactions
DECLARE
  c_tx_ctr NUMBER := 0;
  c_ti_ctr NUMBER := 0;
  v_batch_id NUMBER;
  v_med_id NUMBER;
  v_qty NUMBER;
BEGIN
  -- 1000 transactions (SALE, RESTOCK, ADJUST)
  FOR i IN 1..1000 LOOP
    c_tx_ctr := c_tx_ctr + 1;

    -- Decide transaction type randomly
    DECLARE
      v_type VARCHAR2(10);
    BEGIN
      IF DBMS_RANDOM.VALUE < 0.6 THEN
        v_type := 'SALE';
      ELSIF DBMS_RANDOM.VALUE < 0.9 THEN
        v_type := 'RESTOCK';
      ELSE
        v_type := 'ADJUST';
      END IF;

      INSERT INTO Transactions(Transaction_ID, Transaction_Type, Branch_ID, User_ID, Transaction_Date)
      VALUES (
        c_tx_ctr,
        v_type,
        1,  -- internal branch
        TRUNC(DBMS_RANDOM.VALUE(1,9)), -- random user 1-8
        SYSDATE - TRUNC(DBMS_RANDOM.VALUE(0,400))  -- random date in last ~400 days
      );
    END;

    -- 1-3 transaction items per transaction
    FOR k IN 1..TRUNC(DBMS_RANDOM.VALUE(1,4)) LOOP
      c_ti_ctr := c_ti_ctr + 1;

      -- pick a random batch and medicine
      SELECT Batch_ID, Medicine_ID
      INTO v_batch_id, v_med_id
      FROM (
        SELECT Batch_ID, Medicine_ID FROM Batches ORDER BY DBMS_RANDOM.VALUE
      ) WHERE ROWNUM = 1;

      -- random quantity
      v_qty := TRUNC(DBMS_RANDOM.VALUE(1,25));

      INSERT INTO Transaction_Items(Transaction_Item_ID, Transaction_ID, Medicine_ID, Batch_ID, Quantity)
      VALUES (c_ti_ctr, c_tx_ctr, v_med_id, v_batch_id, v_qty);
    END LOOP;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted transactions: ' || c_tx_ctr || ' and transaction_items: ' || c_ti_ctr);
END;
/

--Predictions
DECLARE
  c_pred_ctr NUMBER := 0;
BEGIN
  FOR m IN 1..120 LOOP  -- 120 medicines
    FOR mo IN 1..12 LOOP  -- 12 months
      c_pred_ctr := c_pred_ctr + 1;

      INSERT INTO Predictions(Prediction_ID, Medicine_ID, Branch_ID, Year_, Month_, Predicted_Demand)
      VALUES (
        c_pred_ctr,
        m,
        1,  -- internal branch only
        EXTRACT(YEAR FROM SYSDATE),
        mo,
        TRUNC(DBMS_RANDOM.VALUE(0,300))
      );
    END LOOP;
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Inserted predictions: ' || c_pred_ctr);
END;
/

--Alerts
DECLARE
  c_alert_ctr NUMBER := 0;
  v_med_id    NUMBER;
  v_batch_id  NUMBER;
BEGIN
  FOR m IN 1..120 LOOP  -- 120 medicines
    IF DBMS_RANDOM.VALUE < 0.2 THEN  -- 20% chance to create an alert
      BEGIN
        -- Pick a random batch for this medicine in internal branch
        SELECT Batch_ID INTO v_batch_id
        FROM (
          SELECT Batch_ID FROM Batches
          WHERE Medicine_ID = m
            AND Branch_ID = 1
          ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;

        c_alert_ctr := c_alert_ctr + 1;

        INSERT INTO Alerts(Alert_ID, Branch_ID, Medicine_ID, Batch_ID, Alert_Type, Message)
        VALUES (
          c_alert_ctr,
          1,  -- internal branch only
          m,
          v_batch_id,
          CASE WHEN DBMS_RANDOM.VALUE < 0.5 THEN 'LOW_STOCK' ELSE 'NEAR_EXPIRY' END,
          'This is a test alert for medicine ' || m
        );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;  -- skip if no batch exists for this medicine
      END;
    END IF;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted alerts: ' || c_alert_ctr);
END;
/

--transfers
DECLARE
  c_transfer_ctr NUMBER := 0;
BEGIN
  FOR r IN (
    SELECT Batch_ID, Medicine_ID, Quantity_Remaining
    FROM Batches
    WHERE Expiry_Date <= SYSDATE + 120
      AND Quantity_Remaining > 0
      AND ROWNUM <= 120
  ) LOOP
    c_transfer_ctr := c_transfer_ctr + 1;

    INSERT INTO Transfers(
      Transfer_ID,
      From_Branch_ID,
      To_Branch_ID,
      Medicine_ID,
      Batch_ID,
      Quantity,
      Requested_By,
      Requested_At,
      Status,
      Notes
    )
    VALUES (
      c_transfer_ctr,
      1,  -- From internal branch
      MOD(r.Batch_ID,4)+2,  -- To external branch 2..5
      r.Medicine_ID,
      r.Batch_ID,
      LEAST(r.Quantity_Remaining, TRUNC(DBMS_RANDOM.VALUE(1, r.Quantity_Remaining+1))),
      TRUNC(DBMS_RANDOM.VALUE(1,9)),  -- Requested_By user_id 1..8
      SYSTIMESTAMP - INTERVAL '1' DAY * TRUNC(DBMS_RANDOM.VALUE(0,30)),
      'SENT',
      'Auto transfer - near expiry'
    );
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserted transfers: ' || c_transfer_ctr);
  DBMS_OUTPUT.PUT_LINE('=== Test data insertion completed successfully ===');
END;
/
