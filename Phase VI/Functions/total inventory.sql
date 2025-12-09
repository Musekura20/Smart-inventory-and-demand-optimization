CREATE OR REPLACE FUNCTION total_inventory(
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
    -- Make sure the log_error procedure exists in your schema
    log_error_proc('total_inventory', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 0;
END total_inventory;
/

-- test function
SET SERVEROUTPUT ON;
DECLARE
  v_total NUMBER;
BEGIN
  v_total := total_inventory(1);
  DBMS_OUTPUT.PUT_LINE('Total inventory: ' || v_total);
END;
/

