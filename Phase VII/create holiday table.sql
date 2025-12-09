CREATE TABLE Holidays (
    Holiday_Date DATE PRIMARY KEY,
    Description  VARCHAR2(100)
);
-- Sample holidays for next month
INSERT INTO Holidays VALUES (TO_DATE('10-01-2026','DD-MM-YYYY'), 'New year Celebration');
INSERT INTO Holidays VALUES (TO_DATE('15-01-2026','DD-MM-YYYY'), 'Our company anniversary' );
COMMIT;
