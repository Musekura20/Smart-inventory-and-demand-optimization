CREATE OR REPLACE FUNCTION predict_demand(
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
    -- make sure you have a log_error(procedure_name, err_code, err_msg, backtrace) implementation
    log_error_proc('predict_demand', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 0;
END predict_demand;
/

-- test function

SET SERVEROUTPUT ON;
DECLARE
  v_pred NUMBER;
BEGIN
  v_pred := predict_demand(1, 1, 3);
  DBMS_OUTPUT.PUT_LINE('Predicted demand: ' || v_pred);
END;
/

