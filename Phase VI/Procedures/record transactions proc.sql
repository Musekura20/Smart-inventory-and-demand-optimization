SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE record_transaction(
    p_medicine_id  IN NUMBER,
    p_branch_id    IN NUMBER,
    p_quantity     IN NUMBER,
    p_tx_type      IN VARCHAR2,
    p_user_id      IN NUMBER DEFAULT NULL,
    p_batch_id     IN NUMBER DEFAULT NULL,
    p_new_trans_id OUT NUMBER
) IS
    v_trans_id NUMBER;
    v_prev_qty NUMBER;
BEGIN
    IF p_tx_type NOT IN ('SALE','RESTOCK','ADJUST') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Invalid transaction type: ' || NVL(p_tx_type,'NULL'));
    END IF;

    -- Insert transaction
    INSERT INTO Transactions(Transaction_ID, Transaction_Type, Branch_ID, User_ID, Transaction_Date)
    VALUES (seq_transactions.NEXTVAL, p_tx_type, p_branch_id, p_user_id, SYSTIMESTAMP)
    RETURNING Transaction_ID INTO v_trans_id;

    -- Insert transaction item
    INSERT INTO Transaction_Items(Transaction_Item_ID, Transaction_ID, Medicine_ID, Batch_ID, Quantity)
    VALUES (seq_transaction_items.NEXTVAL, v_trans_id, p_medicine_id, p_batch_id, p_quantity);

    -- Update Inventory
    BEGIN
        SELECT Quantity_On_Hand INTO v_prev_qty 
        FROM Inventory
        WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id
        FOR UPDATE;

        IF p_tx_type = 'SALE' THEN
            UPDATE Inventory
            SET Quantity_On_Hand  = Quantity_On_Hand - p_quantity
            WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
        ELSIF p_tx_type = 'RESTOCK' THEN
            UPDATE Inventory
            SET Quantity_On_Hand = Quantity_On_Hand + p_quantity
            WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
        ELSIF p_tx_type = 'ADJUST' THEN
            UPDATE Inventory
            SET Quantity_On_Hand = p_quantity
            WHERE Medicine_ID = p_medicine_id AND Branch_ID = p_branch_id;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF p_tx_type = 'SALE' THEN
                RAISE_APPLICATION_ERROR(-20012, 'No inventory record for SALE - medicine/branch');
            ELSE
                INSERT INTO Inventory(Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold)
                VALUES (seq_inventory.NEXTVAL, p_medicine_id, p_branch_id,
                        CASE WHEN p_tx_type = 'RESTOCK' THEN p_quantity ELSE NVL(p_quantity,0) END,
                        NULL);
            END IF;
    END;

    p_new_trans_id := v_trans_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('record_transaction_standalone: trans='||v_trans_id||' type='||p_tx_type);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('record_transaction_standalone error: ' || SQLERRM);
        ROLLBACK;
        p_new_trans_id := NULL;
END record_transaction;
/
