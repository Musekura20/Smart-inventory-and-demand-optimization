CREATE OR REPLACE FUNCTION Log_Audit_Func(
    p_user      IN VARCHAR2,
    p_operation IN VARCHAR2,
    p_table     IN VARCHAR2,
    p_status    IN VARCHAR2,
    p_error_msg IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER IS
BEGIN
    INSERT INTO Audit_Log(User_Name, Operation, Table_Name, Status, Error_Message)
    VALUES (p_user, p_operation, p_table, p_status, p_error_msg);
    COMMIT;
    RETURN 1; 
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0; -- fail
END;
/

CREATE OR REPLACE FUNCTION Check_Restriction RETURN BOOLEAN IS
    v_today DATE := TRUNC(SYSDATE);
    v_count NUMBER;
BEGIN
    -- Deny weekdays (Monday-Friday)
    IF TO_CHAR(v_today, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('MON','TUE','WED','THU','FRI') THEN
        RETURN FALSE;
    END IF;

    -- Deny holidays
    SELECT COUNT(*) INTO v_count
    FROM Holidays
    WHERE Holiday_Date = v_today;

    IF v_count > 0 THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE; 
END;
/

