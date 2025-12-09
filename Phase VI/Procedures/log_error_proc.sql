SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE log_error_proc(
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
/

