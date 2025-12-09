SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE compute_and_store_top_sellers(
    p_branch_id IN NUMBER, 
    p_top_n IN NUMBER := 5, 
    p_rows_inserted OUT NUMBER
) IS
    -- compute sum(quantity) and use RANK() window function then insert top N rows
    CURSOR c_top IS
      SELECT Medicine_ID, total_sold, sales_rank FROM (
        SELECT ti.Medicine_ID,
               SUM(ti.Quantity) OVER (PARTITION BY ti.Medicine_ID, t.Branch_ID) AS total_sold,
               RANK() OVER (PARTITION BY t.Branch_ID ORDER BY SUM(ti.Quantity) DESC) AS sales_rank,
               t.Branch_ID
        FROM Transactions t 
        JOIN Transaction_Items ti ON t.Transaction_ID = ti.Transaction_ID
        WHERE t.Branch_ID = p_branch_id
        GROUP BY ti.Medicine_ID, t.Branch_ID
      ) WHERE sales_rank <= p_top_n
      ORDER BY sales_rank;
BEGIN
    p_rows_inserted := 0;

    FOR r IN c_top LOOP
        INSERT INTO TOP_SELLING_MEDICINES (
            BRANCH_ID, MEDICINE_ID, TOTAL_SOLD, SALES_RANK
        ) VALUES (
            p_branch_id, r.Medicine_ID, r.total_sold, r.sales_rank
        );

        p_rows_inserted := p_rows_inserted + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('compute_and_store_top_sellers: inserted='||p_rows_inserted);

EXCEPTION
    WHEN OTHERS THEN
        log_error_proc('compute_and_store_top_sellers','OTHERS', SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
        p_rows_inserted := -1;
END compute_and_store_top_sellers;
/
