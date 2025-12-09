INSERT INTO Medicines (Name, Type, Reorder_Point)
VALUES ('Paracetamol', 'Tablet', 10);

INSERT INTO Suppliers (Name, Contact)
VALUES ('Global Pharma', '0781234567');

-- Add a holiday (today)
INSERT INTO Holidays (Holiday_Date, Description)
VALUES (TRUNC(SYSDATE), 'Test Holiday');

-- Try inserting a medicine on this holiday
INSERT INTO Medicines (Name, Type, Reorder_Point)
VALUES ('Amoxicillin', 'Capsule', 15);

SELECT Log_ID, User_Name, Operation, Table_Name, Status, Attempt_Time, Error_Message
FROM Audit_Log
ORDER BY Attempt_Time DESC;
