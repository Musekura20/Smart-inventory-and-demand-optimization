CREATE OR REPLACE FUNCTION is_stock_sufficient(
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
/
