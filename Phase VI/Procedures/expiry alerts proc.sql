CREATE OR REPLACE PROCEDURE generate_expiry_alerts(
    p_days_before_expiry IN NUMBER := 60, 
    p_alerts_created OUT VARCHAR2
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
        -- Use log_error_proc if log_error is only inside your package
        log_error_proc('generate_expiry_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
        p_alerts_created := 'Some medecines are about to be expired';
END generate_expiry_alerts;
/

-- test procedure

SET SERVEROUTPUT ON;
DECLARE
  v_created NUMBER;
BEGIN
  generate_expiry_alerts(60, v_created);
  DBMS_OUTPUT.PUT_LINE('Expiry alerts created: ' || v_created);
END;
/

