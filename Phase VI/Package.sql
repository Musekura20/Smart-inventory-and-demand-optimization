 -- Generate alerts (uses explicit cursor)
  PROCEDURE generate_low_stock_alerts(p_branch_id IN NUMBER DEFAULT NULL, p_alerts_created OUT NUMBER);

  PROCEDURE generate_expiry_alerts(p_days_before_expiry IN NUMBER DEFAULT 60, p_alerts_created OUT NUMBER);

  -- Save top sellers
  PROCEDURE compute_and_store_top_sellers(p_branch_id IN NUMBER, p_top_n IN NUMBER DEFAULT 5, p_rows_inserted OUT NUMBER);

  -- FUNCTIONS 
  FUNCTION predict_demand(p_medicine_id IN NUMBER, p_branch_id IN NUMBER, p_months IN NUMBER DEFAULT 3) RETURN NUMBER;

  FUNCTION total_inventory(p_medicine_id IN NUMBER) RETURN NUMBER;

  FUNCTION is_stock_sufficient(p_medicine_id IN NUMBER, p_branch_id IN NUMBER, p_required_qty IN NUMBER) RETURN VARCHAR2;

  FUNCTION get_supplier_name(p_supplier_id IN NUMBER) RETURN VARCHAR2;

END smart_inventory_pkg;
/

CREATE OR REPLACE PACKAGE BODY smart_inventory_pkg AS
  PROCEDURE log_error_proc(
    p_proc_name VARCHAR2,
    p_err_code  VARCHAR2,
    p_err_msg   VARCHAR2,
    p_backtrace CLOB
  ) IS
  BEGIN
    INSERT INTO ERROR_LOG (SCHEMA_USER, PROC_NAME, ERR_CODE, ERR_MSG, ERR_BACKTRACE)
    VALUES (USER, p_proc_name, p_err_code, SUBSTR(p_err_msg,1,4000), p_backtrace);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('log_error_proc failed: ' || SQLERRM);
      ROLLBACK;
  END log_error_proc;

  -- PROCEDURES

  PROCEDURE register_medicine(
    p_name          IN VARCHAR2,
    p_type          IN VARCHAR2,
    p_reorder_point IN NUMBER DEFAULT 10,
    p_new_med_id    OUT NUMBER
  ) IS
  BEGIN
    -- Basic validation
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
      RAISE_APPLICATION_ERROR(-20010, 'Medicine name is required');
    END IF;

    INSERT INTO Medicines (Medicine_ID, Name, Type, Reorder_Point)
    VALUES (seq_medicines.NEXTVAL, p_name, p_type, NVL(p_reorder_point,10))
    RETURNING Medicine_ID INTO p_new_med_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('register_medicine: inserted id='||p_new_med_id);

  EXCEPTION
    WHEN VALUE_ERROR THEN
      log_error_proc('register_medicine','VALUE_ERROR', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
    WHEN OTHERS THEN
      log_error_proc('register_medicine', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      ROLLBACK;
      p_new_med_id := NULL;
  END register_medicine;


  PROCEDURE record_transaction(
      p_medicine_id  IN NUMBER,
      p_branch_id    IN NUMBER,
      p_quantity     IN NUMBER,
      p_tx_type      IN VARCHAR2,
      p_user_id      IN NUMBER DEFAULT NULL,
      p_batch_id     IN NUMBER DEFAULT NULL,
      p_new_trans_id OUT NUMBER
  ) IS
      v_trans_id NUMBER;
      v_prev_qty NUMBER;
  BEGIN
      IF p_tx_type NOT IN ('SALE','RESTOCK','ADJUST') THEN
          RAISE_APPLICATION_ERROR(-20011, 'Invalid transaction type: ' || NVL(p_tx_type,'NULL'));
      END IF;

      -- Insert transaction
      INSERT INTO Transactions(Transaction_ID, Transaction_Type, Branch_ID, User_ID, Transaction_Date)
      VALUES (seq_transactions.NEXTVAL, p_tx_type, p_branch_id, p_user_id, SYSTIMESTAMP)
      RETURNING Transaction_ID INTO v_trans_id;

      -- Insert transaction item
      INSERT INTO Transaction_Items(Transaction_Item_ID, Transaction_ID, Medicine_ID, Batch_ID, Quantity)
      VALUES (seq_transaction_items.NEXTVAL, v_trans_id, p_medicine_id, p_batch_id, p_quantity);

      -- Update Inventory
      BEGIN
          SELECT Quantity_On_Hand INTO v_prev_qty 
          FROM Inventory
          WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id
          FOR UPDATE;

          IF p_tx_type = 'SALE' THEN
              UPDATE Inventory
              SET Quantity_On_Hand  = Quantity_On_Hand - p_quantity
              WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
          ELSIF p_tx_type = 'RESTOCK' THEN
              UPDATE Inventory
              SET Quantity_On_Hand = Quantity_On_Hand + p_quantity
              WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
          ELSIF p_tx_type = 'ADJUST' THEN
              UPDATE Inventory
              SET Quantity_On_Hand = p_quantity
              WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
          END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              IF p_tx_type = 'SALE' THEN
                  RAISE_APPLICATION_ERROR(-20012, 'No inventory record for SALE - medicine/branch');
              ELSE
                  INSERT INTO Inventory(Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold)
                  VALUES (seq_inventory.NEXTVAL, p_medicine_id, p_branch_id,
                          CASE WHEN p_tx_type = 'RESTOCK' THEN p_quantity ELSE NVL(p_quantity,0) END,
                          NULL);
              END IF;
      END;

      p_new_trans_id := v_trans_id;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('record_transaction: trans='||v_trans_id||' type='||p_tx_type);

  EXCEPTION
      WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('record_transaction error: ' || SQLERRM);
          ROLLBACK;
          p_new_trans_id := NULL;
  END record_transaction;


  PROCEDURE update_inventory(
      p_medicine_id   IN NUMBER,
      p_branch_id     IN NUMBER,
      p_new_quantity  IN OUT NUMBER
  ) IS
      v_old_qty NUMBER;
  BEGIN
      -- Try to update; return previous quantity via IN OUT param
      BEGIN
          SELECT Quantity_On_Hand INTO v_old_qty 
          FROM Inventory
          WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id
          FOR UPDATE;

          -- set OUT value to previous
          p_new_quantity := v_old_qty;

          UPDATE Inventory
          SET Quantity_On_Hand = p_new_quantity
          WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              -- create record if not exists, and previous quantity considered 0
              v_old_qty := 0;
              INSERT INTO Inventory(Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold)
              VALUES (seq_inventory.NEXTVAL, p_medicine_id, p_branch_id, p_new_quantity, NULL);
      END;

      COMMIT;
      DBMS_OUTPUT.PUT_LINE('update_inventory: medicine='||p_medicine_id||' branch='||p_branch_id||
                           ' prev_qty='||v_old_qty||' new_qty='||p_new_quantity);

  EXCEPTION
      WHEN VALUE_ERROR THEN
          log_error_proc('update_inventory','VALUE_ERROR', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
      WHEN OTHERS THEN
          log_error_proc('update_inventory','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
  END update_inventory;


  PROCEDURE delete_old_alerts(
      p_days_old      IN NUMBER DEFAULT 30,
      p_deleted_count OUT NUMBER
  ) IS
  BEGIN
      DELETE FROM Alerts
      WHERE Created_At < TRUNC(SYSDATE) - p_days_old;

      p_deleted_count := SQL%ROWCOUNT;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('delete_old_alerts: deleted='||p_deleted_count);

  EXCEPTION
      WHEN OTHERS THEN
          log_error_proc('delete_old_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
          p_deleted_count := -1;
  END delete_old_alerts;


  PROCEDURE generate_low_stock_alerts(
      p_branch_id IN NUMBER DEFAULT NULL, 
      p_alerts_created OUT NUMBER
  ) IS
      CURSOR c_low IS
        SELECT inv.Medicine_ID, inv.Branch_ID, inv.Quantity_on_hand, NVL(inv.Threshold, m.Reorder_Point) eff_th
        FROM Inventory inv 
        JOIN Medicines m ON inv.Medicine_ID = m.Medicine_ID
        WHERE (p_branch_id IS NULL OR inv.Branch_ID = p_branch_id)
          AND inv.Quantity_on_hand <= NVL(inv.Threshold, m.Reorder_Point);

      TYPE t_rec IS TABLE OF c_low%ROWTYPE;
      l_rows t_rec;
      l_count PLS_INTEGER := 0;
  BEGIN
      OPEN c_low;
      LOOP
          FETCH c_low BULK COLLECT INTO l_rows LIMIT 100;
          EXIT WHEN l_rows.COUNT = 0;

          FOR i IN 1..l_rows.COUNT LOOP
              INSERT INTO Alerts(
                  Alert_ID, Branch_ID, Medicine_ID, Alert_Type, Message, Created_at
              ) VALUES (
                  seq_alerts.NEXTVAL,
                  l_rows(i).Branch_ID,
                  l_rows(i).Medicine_ID,
                  'LOW_STOCK',
                  'Low stock detected. Qty='||l_rows(i).Quantity_on_hand||' Thr='||l_rows(i).eff_th,
                  SYSTIMESTAMP
              );
              l_count := l_count + 1;
          END LOOP;
      END LOOP;
      CLOSE c_low;

      p_alerts_created := l_count;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('generate_low_stock_alerts: created='||p_alerts_created);

  EXCEPTION
      WHEN OTHERS THEN
          log_error_proc('generate_low_stock_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
          p_alerts_created := -1;
  END generate_low_stock_alerts;


  PROCEDURE generate_expiry_alerts(
      p_days_before_expiry IN NUMBER := 60, 
      p_alerts_created OUT NUMBER
  ) IS
      CURSOR c_exp IS
        SELECT Batch_ID, Medicine_ID, Branch_ID, Expiry_Date, Quantity_Remaining
        FROM Batches
        WHERE Expiry_Date <= TRUNC(SYSDATE) + p_days_before_expiry
          AND Quantity_Remaining > 0;

      TYPE t_batch IS TABLE OF c_exp%ROWTYPE;
      l_batches t_batch;
      l_count PLS_INTEGER := 0;
  BEGIN
      OPEN c_exp;
      LOOP
          FETCH c_exp BULK COLLECT INTO l_batches LIMIT 200;
          EXIT WHEN l_batches.COUNT = 0;

          FOR i IN 1..l_batches.COUNT LOOP
              IF l_batches(i).Expiry_Date < TRUNC(SYSDATE) THEN
                  INSERT INTO Alerts(
                      Alert_ID, Branch_ID, Medicine_ID, Batch_ID, Alert_Type, Message, Created_at
                  ) VALUES (
                      seq_alerts.NEXTVAL,
                      l_batches(i).Branch_ID,
                      l_batches(i).Medicine_ID,
                      l_batches(i).Batch_ID,
                      'EXPIRED',
                      'Batch expired: '||l_batches(i).Batch_ID||' Exp='||TO_CHAR(l_batches(i).Expiry_Date,'YYYY-MM-DD'),
                      SYSTIMESTAMP
                  );
              ELSE
                  INSERT INTO Alerts(
                      Alert_ID, Branch_ID, Medicine_ID, Batch_ID, Alert_Type, Message, Created_at
                  ) VALUES (
                      seq_alerts.NEXTVAL,
                      l_batches(i).Branch_ID,
                      l_batches(i).Medicine_ID,
                      l_batches(i).Batch_ID,
                      'EXPIRY_SOON',
                      'Batch expiring soon: '||l_batches(i).Batch_ID||' Exp='||TO_CHAR(l_batches(i).Expiry_Date,'YYYY-MM-DD'),
                      SYSTIMESTAMP
                  );
              END IF;

              l_count := l_count + 1;
          END LOOP;
      END LOOP;
      CLOSE c_exp;

      p_alerts_created := l_count;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('generate_expiry_alerts: created='||p_alerts_created);

  EXCEPTION
      WHEN OTHERS THEN
          log_error_proc('generate_expiry_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
          p_alerts_created := -1;
  END generate_expiry_alerts;


  PROCEDURE compute_and_store_top_sellers(
      p_branch_id IN NUMBER, 
      p_top_n IN NUMBER := 5, 
      p_rows_inserted OUT NUMBER
  ) IS
      CURSOR c_top IS
        SELECT Medicine_ID, total_sold, sales_rank FROM (
          SELECT ti.Medicine_ID,
                 SUM(ti.Quantity) OVER (PARTITION BY ti.Medicine_ID, t.Branch_ID) AS total_sold,
                 RANK() OVER (PARTITION BY t.Branch_ID ORDER BY SUM(ti.Quantity) DESC) AS sales_rank,
                 t.Branch_ID
          FROM Transactions t 
          JOIN Transaction_Items ti ON t.Transaction_ID = ti.Transaction_ID
          WHERE t.Branch_ID = p_branch_id
          GROUP BY ti.Medicine_ID, t.Branch_ID
        ) WHERE sales_rank <= p_top_n
        ORDER BY sales_rank;
      l_count PLS_INTEGER := 0;
  BEGIN
      p_rows_inserted := 0;

      FOR r IN c_top LOOP
          INSERT INTO TOP_SELLING_MEDICINES (
              BRANCH_ID, MEDICINE_ID, TOTAL_SOLD, SALES_RANK
          ) VALUES (
              p_branch_id, r.Medicine_ID, r.total_sold, r.sales_rank
          );

          p_rows_inserted := p_rows_inserted + 1;
      END LOOP;

      COMMIT;
      DBMS_OUTPUT.PUT_LINE('compute_and_store_top_sellers: inserted='||p_rows_inserted);

  EXCEPTION
      WHEN OTHERS THEN
          log_error_proc('compute_and_store_top_sellers','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          ROLLBACK;
          p_rows_inserted := -1;
  END compute_and_store_top_sellers;

  -- FUNCTIONS

  FUNCTION predict_demand(
    p_medicine_id IN NUMBER,
    p_branch_id   IN NUMBER,
    p_months      IN NUMBER := 3
  ) RETURN NUMBER IS
    v_avg NUMBER := 0;
  BEGIN
    /*
      Compute the simple monthly moving average of quantity sold for
      the given medicine
    */
    SELECT NVL(ROUND(AVG(month_qty)), 0)
      INTO v_avg
      FROM (
        SELECT TRUNC(t.Transaction_Date, 'MM') AS month_start,
               SUM(ti.Quantity) AS month_qty
        FROM Transactions t
        JOIN Transaction_Items ti ON t.Transaction_ID = ti.Transaction_ID
        WHERE ti.Medicine_ID = p_medicine_id
          AND (p_branch_id IS NULL OR t.Branch_ID = p_branch_id)
          AND t.Transaction_Date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -p_months)
        GROUP BY TRUNC(t.Transaction_Date, 'MM')
      );

    RETURN v_avg;

  EXCEPTION
    WHEN OTHERS THEN
      log_error_proc('predict_demand', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RETURN 0;
  END predict_demand;


  FUNCTION total_inventory(
    p_medicine_id IN NUMBER
  ) RETURN NUMBER IS
    v_total NUMBER := 0;
  BEGIN
    -- Sum the quantity of this medicine across all inventory records
    SELECT NVL(SUM(Quantity_on_hand), 0)
      INTO v_total
      FROM Inventory
      WHERE Medicine_ID = p_medicine_id;

    RETURN v_total;

  EXCEPTION
    WHEN OTHERS THEN
      log_error_proc('total_inventory', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RETURN 0;
  END total_inventory;


  FUNCTION is_stock_sufficient(
    p_medicine_id  IN NUMBER,
    p_branch_id    IN NUMBER,
    p_required_qty IN NUMBER
  ) RETURN VARCHAR2 IS
    v_qty NUMBER;
  BEGIN
    SELECT Quantity_on_hand
      INTO v_qty
      FROM Inventory
      WHERE Medicine_ID = p_medicine_id;

    IF v_qty >= p_required_qty THEN
      RETURN 'YES';
    ELSE
      RETURN 'NO';
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- no inventory row for that medicine
      RETURN 'NO_RECORD';
    WHEN TOO_MANY_ROWS THEN
      log_error_proc(
        'is_stock_sufficient',
        'TOO_MANY_ROWS',
        'More than one Inventory row for Medicine_ID=' || NVL(TO_CHAR(p_medicine_id),'NULL'),
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RETURN 'ERROR';
    WHEN OTHERS THEN
      log_error_proc(
        'is_stock_sufficient',
        'OTHERS',
        SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RETURN 'ERROR';
  END is_stock_sufficient;


  FUNCTION get_supplier_name(p_supplier_id IN NUMBER) RETURN VARCHAR2 IS
    v_name VARCHAR2(200);
  BEGIN
    SELECT Name INTO v_name FROM Suppliers WHERE Supplier_ID = p_supplier_id;
    RETURN v_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'UNKNOWN';
    WHEN OTHERS THEN
      log_error_proc('get_supplier_name','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RETURN 'ERROR';
  END get_supplier_name;


END smart_inventory_pkg;
/
