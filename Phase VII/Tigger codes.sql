CREATE OR REPLACE TRIGGER trg_medicines_simple
BEFORE INSERT OR UPDATE OR DELETE ON Medicines
FOR EACH ROW
DECLARE
    v_allowed BOOLEAN;
    v_result  NUMBER;  
BEGIN
    v_allowed := Check_Restriction;

    IF NOT v_allowed THEN
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Medicines', 'DENIED', 'Operation blocked: weekday or holiday');
        RAISE_APPLICATION_ERROR(-20001, 'Operation not allowed on weekdays or public holidays!');
    ELSE
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Medicines', 'ALLOWED');
    END IF;
END;
/

  --trigger suppliers

CREATE OR REPLACE TRIGGER trg_suppliers_simple
BEFORE INSERT OR UPDATE OR DELETE ON Suppliers
FOR EACH ROW
DECLARE
    v_allowed BOOLEAN;
    v_result  NUMBER; 
BEGIN
    v_allowed := Check_Restriction;

    IF NOT v_allowed THEN
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Suppliers', 'DENIED', 'Operation blocked: weekday or holiday');
        RAISE_APPLICATION_ERROR(-20002, 'Operation not allowed on weekdays or public holidays!');
    ELSE
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Suppliers', 'ALLOWED');
    END IF;
END;
/

  --trigger users

CREATE OR REPLACE TRIGGER trg_users_simple
BEFORE INSERT OR UPDATE OR DELETE ON Users
FOR EACH ROW
DECLARE
    v_allowed BOOLEAN;
    v_result  NUMBER;  
BEGIN
    v_allowed := Check_Restriction;

    IF NOT v_allowed THEN
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Users', 'DENIED', 'Operation blocked: weekday or holiday');
        RAISE_APPLICATION_ERROR(-20003, 'Operation not allowed on weekdays or public holidays!');
    ELSE
        v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Users', 'ALLOWED');
    END IF;
END;
/

  -- TRG medecines compond

CREATE OR REPLACE TRIGGER trg_medicines_compound
FOR INSERT OR UPDATE OR DELETE ON Medicines
COMPOUND TRIGGER

    g_allowed BOOLEAN;
    v_result  NUMBER; 

    BEFORE STATEMENT IS
    BEGIN
        g_allowed := Check_Restriction;
        IF NOT g_allowed THEN
            v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Medicines', 'DENIED', 'Operation blocked at statement level');
            RAISE_APPLICATION_ERROR(-20010, 'Operation not allowed on weekdays or public holidays!');
        END IF;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF g_allowed THEN
            v_result := Log_Audit_Func(USER, ORA_SYSEVENT, 'Medicines', 'ALLOWED');
        END IF;
    END AFTER EACH ROW;

END;
/
