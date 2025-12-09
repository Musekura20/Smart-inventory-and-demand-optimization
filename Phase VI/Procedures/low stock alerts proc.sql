SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE generate_low_stock_alerts(
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
        -- Use log_error_proc if log_error is only inside your package
        log_error_proc('generate_low_stock_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
        p_alerts_created := -1;
END generate_low_stock_alerts;
/
