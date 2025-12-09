SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE reg_medicine(
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
  DBMS_OUTPUT.PUT_LINE('reg_medicine_standalone: inserted id='||p_new_med_id);

EXCEPTION
  WHEN VALUE_ERROR THEN
    log_error_proc('reg_medicine_standalone','VALUE_ERROR', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RAISE;
  WHEN OTHERS THEN
    log_error_proc('reg_medicine_standalone', 'OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    p_new_med_id := NULL;
END reg_medicine;
/
