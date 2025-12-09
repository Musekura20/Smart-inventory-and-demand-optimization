CREATE OR REPLACE FUNCTION get_supplier_name(p_supplier_id IN NUMBER) RETURN VARCHAR2 IS
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
/

--test function

SET SERVEROUTPUT ON;
DECLARE
  v_name VARCHAR2(200);
BEGIN
  v_name := get_supplier_name(1); -- assuming supplier_id=1 exists
  DBMS_OUTPUT.PUT_LINE('Supplier name: ' || v_name);
END;
/
