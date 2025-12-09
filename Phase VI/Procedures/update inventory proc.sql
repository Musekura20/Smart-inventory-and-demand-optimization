SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE update_inventory(
    p_medicine_id   IN NUMBER,
    p_branch_id     IN NUMBER,
    p_new_quantity  IN OUT NUMBER
) IS
    v_old_qty NUMBER;
BEGIN
    -- Try to update; return previous quantity via IN OUT param
    BEGIN
        SELECT Quantity_On_Hand INTO v_old_qty 
        FROM Inventory
        WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id
        FOR UPDATE;

        -- set OUT value to previous
        p_new_quantity := v_old_qty;

        UPDATE Inventory
        SET Quantity_On_Hand = p_new_quantity
        WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- create record if not exists, and previous quantity considered 0
            v_old_qty := 0;
            INSERT INTO Inventory(Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold)
            VALUES (seq_inventory.NEXTVAL, p_medicine_id, p_branch_id, p_new_quantity, NULL);
    END;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('update_inventory: medicine='||p_medicine_id||' branch='||p_branch_id||
                         ' prev_qty='||v_old_qty||' new_qty='||p_new_quantity);

EXCEPTION
    WHEN VALUE_ERROR THEN
        log_error_proc('update_inventory','VALUE_ERROR', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
    WHEN OTHERS THEN
        log_error_proc('update_inventory','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
END update_inventory;
/

-- test procedure

SET SERVEROUTPUT ON;
DECLARE
  v_prev_qty NUMBER := 100; -- the new quantity to set
BEGIN
  update_inventory(1, 1, v_prev_qty);
END;
/
