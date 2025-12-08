--total counts for main tables
SELECT 'Suppliers', COUNT(*) FROM Suppliers UNION ALL
SELECT 'Users', COUNT(*) FROM Users UNION ALL
SELECT 'Branches', COUNT(*) FROM Branches UNION ALL
SELECT 'Medicines', COUNT(*) FROM Medicines UNION ALL
SELECT 'Batches', COUNT(*) FROM Batches UNION ALL
SELECT 'Inventory', COUNT(*) FROM Inventory UNION ALL
SELECT 'Transactions', COUNT(*) FROM Transactions UNION ALL
SELECT 'Transaction_Items', COUNT(*) FROM Transaction_Items UNION ALL
SELECT 'Predictions', COUNT(*) FROM Predictions UNION ALL
SELECT 'Alerts', COUNT(*) FROM Alerts UNION ALL
SELECT 'Transfers', COUNT(*) FROM Transfers;

-- expired batches
SELECT Batch_ID, Medicine_ID, Batch_No, Expiry_Date, Quantity_Remaining FROM Batches WHERE Expiry_Date < TRUNC(SYSDATE) ORDER BY Expiry_Date;

-- low stock inventory (quantity <= threshold)
SELECT Inventory_ID, Medicine_ID, Branch_ID, Quantity_On_Hand, Threshold FROM Inventory WHERE Quantity_On_Hand <= NVL(Threshold,0) ORDER BY Quantity_On_Hand;

-- sample top demanded medicines by transaction items (most quantity sold)
SELECT ti.Medicine_ID, COUNT(*) AS lines, SUM(ti.Quantity) AS total_qty
FROM Transaction_Items ti JOIN Transactions t ON ti.Transaction_ID = t.Transaction_ID
WHERE t.Transaction_Type = 'SALE'
GROUP BY ti.Medicine_ID
ORDER BY total_qty DESC FETCH FIRST 20 ROWS ONLY;

-- Find low-stock medicines and their total sales
SELECT m.Medicine_ID,
       m.Name,
       i.Quantity_On_Hand,
       i.Threshold,
       (SELECT SUM(ti.Quantity)
        FROM Transaction_Items ti
        JOIN Transactions t ON ti.Transaction_ID = t.Transaction_ID
        WHERE ti.Medicine_ID = m.Medicine_ID
          AND t.Transaction_Type = 'SALE') AS Total_Sold
FROM Medicines m
JOIN Inventory i ON m.Medicine_ID = i.Medicine_ID
WHERE i.Branch_ID = 1
  AND i.Quantity_On_Hand <= i.Threshold
ORDER BY Total_Sold DESC; 
