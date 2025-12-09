SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE delete_old_alerts(
    p_days_old      IN NUMBER DEFAULT 30,
    p_deleted_count OUT NUMBER
) IS
BEGIN
    DELETE FROM Alerts
    WHERE Created_At < TRUNC(SYSDATE) - p_days_old;

    p_deleted_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('delete_old_alerts: deleted='||p_deleted_count);

EXCEPTION
    WHEN OTHERS THEN
        log_error_proc('delete_old_alerts','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
        p_deleted_count := -1;
END delete_old_alerts;
/
