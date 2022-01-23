SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PreQuotePaymentSummary]
(
@CustomerId BIGINT
,@Contracts PreQuoteContratEffectiveDate READONLY
)
AS
BEGIN
SET NOCOUNT ON
--SELECT * FROM COntracts WHERE SEquenceNumber = '123711585-13'
--SELECT CustomerId, * FROM Leasefinances WHERE COntractId = 72429
--CREATE TABLE #ContractEffectiveDateCSV (ContractId BIGINT , EffectiveDate DATETIME)
--INSERT INTO #ContractEffectiveDateCSV VALUES (294701,CAST(GETDATE() AS DATE))
--INSERT INTO #ContractEffectiveDateCSV VALUES (163978,'2016-02-15')
--INSERT INTO #ContractEffectiveDateCSV VALUES (194416,'2015-04-01')
--INSERT INTO #ContractEffectiveDateCSV VALUES (163952,'2016-05-01')
--DECLARE @CustomerId BIGINT = 1
CREATE TABLE #InvoicedReceivables
(
ContractId BIGINT
,InvoiceId BIGINT
,ReceivableId BIGINT
,ReceivableDetailId BIGINT
,Amount DECIMAL(18,2)
,Balance DECIMAL(18,2)
,IsRental TINYINT
,InvoiceDueDate DATETIME
,ReceivableCodeId BIGINT
,ReceivableTypeId BIGINT
)
CREATE TABLE #UnInvoicedReceivables
(
ContractId BIGINT
,ReceivableId BIGINT
,ReceivableDetailId BIGINT
,Amount DECIMAL(18,2)
,Balance DECIMAL(18,2)
,IsRental TINYINT
,DueDate DATETIME
,ReceivableCodeId BIGINT
,ReceivableTypeId BIGINT
)
CREATE TABLE #ContractReceivableType
(
ContractId BIGINT
,ReceivableTypeId BIGINT
,SequenceNumber NVARCHAR(150)
,ContractType NVARCHAR(100)
,ReceivableTypeName NVARCHAR(100)
,EffectiveDate DATETIME
,IsRental INT
)
CREATE TABLE #ContractReceivableCode
(
ContractId BIGINT
,ReceivableCodeId BIGINT
,SequenceNumber NVARCHAR(150)
,ContractType NVARCHAR(100)
,ReceivableCodeName NVARCHAR(100)
,EffectiveDate DATETIME
)
CREATE TABLE #ResultSet
(
ContractId BIGINT
,SequenceNumber NVARCHAR(150)
,ContractType NVARCHAR(100)
,ReceivableCode NVARCHAR(150)
,LastBilledDate DATETIME
,CurrentAmount DECIMAL(18,2)
,PaidAmount DECIMAL(18,2)
,DeliquentAmount DECIMAL(18,2)
,FutureAmount DECIMAL(18,2)
,LeasePaymentRemainingAmount DECIMAL(18,2)
,TotalAmount DECIMAL(18,2)
,EffectiveDate DATETIME
)
CREATE TABLE #ReceivablesCode
(
ReceivableCodeId BIGINT
,IsRental BIGINT
,ContractId BIGINT
)
SELECT ContractId,CAST(GETDATE() AS DATE) EffectiveDate INTO #ContractEffectiveDateCSV FROM @Contracts
INSERT INTO #ContractReceivableType
SELECT DISTINCT C.ContractId , RT.Id,CR.SequenceNumber,CR.ContractType,RT.Name,EffectiveDate
,CASE WHEN (RT.Name = 'LoanInterest' OR RT.Name='LoanPrincipal') THEN 1 ELSE RT.IsRental END IsRental
FROM #ContractEffectiveDateCSV C
JOIN Contracts CR ON CR.Id = C.ContractId
JOIN Receivables R ON R.EntityId = CR.Id
JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT ON RT.Id = RC.ReceivableTypeId
WHERE R.IsActive = 1
INSERT INTO #ContractReceivableCode
SELECT DISTINCT C.ContractId , RC.Id,CR.SequenceNumber,CR.ContractType,RC.Name,EffectiveDate
FROM #ContractEffectiveDateCSV C
JOIN Contracts CR ON CR.Id = C.ContractId
JOIN Receivables R ON R.EntityId = CR.Id
JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
WHERE R.IsActive = 1
INSERT INTO #ReceivablesCode
SELECT DISTINCT RC.Id,CASE WHEN (RT.Name = 'LoanInterest' OR RT.Name='LoanPrincipal') THEN 1 ELSE RT.IsRental END IsRental,C.ContractId
FROM #ContractEffectiveDateCSV C
JOIN Contracts CR ON CR.Id = C.ContractId
JOIN Receivables R ON R.EntityId = CR.Id
JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT ON RT.Id = RC.ReceivableTypeId
WHERE R.IsActive = 1
INSERT INTO #InvoicedReceivables
SELECT R.EntityId, RI.Id InvoiceId,RD.ReceivableId, RID.ReceivableDetailId,RD.Amount_Amount,RD.Balance_Amount
,CASE WHEN (RT.Name = 'LoanInterest' OR RT.Name='LoanPrincipal') THEN 1 ELSE RT.IsRental END IsRental, RI.DueDate,RC.Id,RT.Id FROM ReceivableInvoices RI
JOIN ReceivableInvoiceDetails RID ON RI.Id = RID.ReceivableInvoiceId
JOIN ReceivableDetails RD ON RD.Id = RID.ReceivableDetailId
JOIN Receivables R ON R.Id = RD.ReceivableId
JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT ON RT.Id = RC.ReceivableTypeId
JOIN #ContractEffectiveDateCSV C ON C.ContractId = R.EntityId
JOIN #ReceivablesCode RCT ON RCT.ReceivableCodeId = RC.Id AND RCT.ContractId = C.ContractId
WHERE RD.IsActive = 1 AND RI.IsActive = 1 AND RID.IsActive = 1 AND RT.IsActive = 1 AND RC.IsActive = 1 AND RD.BilledStatus = 'Invoiced'
--AND RC.Id IN (SELECT ReceivablecodeId FROM #ReceivablesCode)
--GROUP BY R.EntityId,R.EntityType,RT.Name
INSERT INTO #UnInvoicedReceivables
SELECT R.EntityId,RD.ReceivableId, RD.Id,RD.Amount_Amount,RD.Balance_Amount
,CASE WHEN (RT.Name = 'LoanInterest' OR RT.Name='LoanPrincipal') THEN 1 ELSE RT.IsRental END, R.DueDate,RC.Id,RT.Id
FROM ReceivableDetails RD
JOIN Receivables R ON R.Id = RD.ReceivableId
JOIN ReceivableCodes RC ON RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT ON RT.Id = RC.ReceivableTypeId
JOIN #ContractEffectiveDateCSV C ON C.ContractId = R.EntityId
JOIN #ReceivablesCode RCT ON RCT.ReceivableCodeId = RC.Id AND RCT.ContractId = C.ContractId
WHERE RD.IsActive = 1 AND RT.IsActive = 1 AND RC.IsActive = 1 AND RD.BilledStatus = 'NotInvoiced'
--AND RC.Id IN (SELECT ReceivablecodeId FROM #ReceivablesCode)
--SELECT * FROM ReceivableTypes WHERE IsActive = 1
--SELECT * FROM #InvoicedReceivables WHERE IsRental = 0
--SELECT * FROM #UnInvoicedReceivables WHERE IsRental = 0
--SELECT * FROM #ContractEffectiveDateCSV
/* For Rental Receivables */
;WITH CTE_CurrentAmount AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) CurrentAmount,ReceivableTypeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate = C.EffectiveDate
AND IsRental = 1
GROUP BY IR.ContractId,ReceivableTypeId
)
--SELECT * FROM CTE_CurrentAmount
,CTE_LastBilledDate AS
(
SELECT IR.ContractId,Max(InvoiceDueDate) LastBilledDate,ReceivableTypeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
--WHERE InvoiceDueDate >= GETDATE() AND InvoiceDueDate <= C.EffectiveDate
AND IsRental = 1
GROUP BY IR.ContractId,ReceivableTypeId
)
,CTE_Paid AS
(
SELECT ContractId,SUM(ISNULL(Paid,0)) Paid,ReceivableTypeId FROM
(SELECT IR.ContractId,Sum(IR.Amount) - Sum(IR.Balance) Paid,IR.ReceivableTypeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE IR.IsRental = 1
GROUP BY IR.ContractId,IR.ReceivableTypeId
UNION ALL
SELECT UIR.ContractId,SUM(ISNULL(UIR.Amount,0)) - Sum(ISNULL(UIR.Balance,0)) Paid,UIR.ReceivableTypeId FROM #UnInvoicedReceivables UIR
JOIN #ContractEffectiveDateCSV C ON UIR.ContractId = C.ContractId
WHERE UIR.IsRental = 1
GROUP BY UIR.ContractId,UIR.ReceivableTypeId) Paid GROUP BY ContractId,ReceivableTypeId
)
,CTE_Deliquent AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) Deliquent,ReceivableTypeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate < EffectiveDate AND IsRental = 1
GROUP BY IR.ContractId,ReceivableTypeId
)
,CTE_Future AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) Future ,ReceivableTypeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate > EffectiveDate AND IsRental = 1
GROUP BY IR.ContractId,ReceivableTypeId
)
,CTE_LeasePaymentRemaining AS
(
SELECT UIR.ContractId,SUM(ISNULL(UIR.Balance,0)) LeasePaymentRemaining,ReceivableTypeId FROM #UnInvoicedReceivables UIR
JOIN #ContractEffectiveDateCSV C ON UIR.ContractId = C.ContractId
WHERE IsRental = 1
GROUP BY UIR.ContractId,ReceivableTypeId
)
INSERT INTO #ResultSet
SELECT
CRT.ContractId
,CRT.SequenceNumber
,CRT.ContractType
,MIN(RC.Name) Name
,LBD.LastBilledDate
,ISNULL(CA.CurrentAmount,0) CurrentAmount
,ISNULL(P.Paid,0) Paid
,ISNULL(D.Deliquent,0) Deliquent
,ISNULL(F.Future,0) Future
,ISNULL(LPR.LeasePaymentRemaining,0) LeasePaymentRemaining
,ISNULL(CA.CurrentAmount,0) + ISNULL(P.Paid,0) + ISNULL(D.Deliquent,0) + ISNULL(F.Future,0) + ISNULL(LPR.LeasePaymentRemaining,0)
,CRT.EffectiveDate
FROM #ContractReceivableType CRT
JOIN Receivablecodes RC ON CRT.ReceivableTypeId = RC.ReceivableTypeId  AND CRT.IsRental = 1
JOIN #ReceivablesCode ON #ReceivablesCode.ReceivableCodeId = RC.Id AND #ReceivablesCode.IsRental = 1 AND #ReceivablesCode.ContractId = CRT.ContractId
LEFT JOIN CTE_CurrentAmount CA ON CRT.ContractId = CA.COntractId AND CA.ReceivableTypeId = CRT.ReceivableTypeId
LEFT JOIN CTE_LastBilledDate LBD ON CRT.ContractId = LBD.ContractId AND LBD.ReceivableTypeId = CRT.ReceivableTypeId
LEFT JOIN CTE_Paid P ON P.ContractId = CRT.ContractId AND P.ReceivableTypeId = CRT.ReceivableTypeId
LEFT JOIN CTE_Deliquent D ON D.ContractId = CRT.ContractId AND D.ReceivableTypeId = CRT.ReceivableTypeId
LEFT JOIN CTE_Future F ON F.ContractId = CRT.ContractId AND F.ReceivableTypeId = CRT.ReceivableTypeId
LEFT JOIN CTE_LeasePaymentRemaining LPR ON CRT.ContractId = LPR.ContractId AND LPR.ReceivableTypeId = CRT.ReceivableTypeId
GROUP BY CRT.ContractId
,CRT.SequenceNumber
,CRT.ContractType
,LBD.LastBilledDate
,CA.CurrentAmount
,P.Paid
,D.Deliquent
,F.Future
,LPR.LeasePaymentRemaining
,CRT.EffectiveDate
--SELECT * FROM #InvoicedReceivables WHERE IsRental = 0
--SELECT * FROM #UnInvoicedReceivables WHERE IsRental = 0
/* For Non Rental Receivables */
;WITH CTE_CurrentAmount AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) CurrentAmount,ReceivableCodeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate = C.EffectiveDate
AND IsRental = 0
GROUP BY IR.ContractId,ReceivableCodeId
)
,CTE_Paid AS
(
SELECT ContractId,SUM(ISNULL(Paid,0)) Paid,ReceivableCodeId FROM
(SELECT IR.ContractId,Sum(IR.Amount) - Sum(IR.Balance) Paid,IR.ReceivableCodeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE IR.IsRental = 0
GROUP BY IR.ContractId,IR.ReceivableCodeId
UNION ALL
SELECT UIR.ContractId,SUM(ISNULL(UIR.Amount,0)) - Sum(ISNULL(UIR.Balance,0)) Paid,UIR.ReceivableCodeId FROM #UnInvoicedReceivables UIR
JOIN #ContractEffectiveDateCSV C ON UIR.ContractId = C.ContractId
WHERE UIR.IsRental = 0
GROUP BY UIR.ContractId,UIR.ReceivableCodeId) Paid GROUP BY ContractId,ReceivableCodeId
)
,CTE_Deliquent AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) Deliquent,ReceivableCodeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate < EffectiveDate AND IsRental = 0
GROUP BY IR.ContractId,ReceivableCodeId
)
,CTE_Future AS
(
SELECT IR.ContractId,SUM(ISNULL(IR.Balance,0)) Future ,ReceivableCodeId FROM #InvoicedReceivables IR
JOIN #ContractEffectiveDateCSV C ON IR.ContractId = C.ContractId
WHERE InvoiceDueDate > EffectiveDate AND IsRental = 0
GROUP BY IR.ContractId,ReceivableCodeId
)
,CTE_LeasePaymentRemaining AS
(
SELECT UIR.ContractId,SUM(ISNULL(UIR.Balance,0)) LeasePaymentRemaining,ReceivableCodeId FROM #UnInvoicedReceivables UIR
JOIN #ContractEffectiveDateCSV C ON UIR.ContractId = C.ContractId
WHERE IsRental = 0
GROUP BY UIR.ContractId,ReceivableCodeId
)
INSERT INTO #ResultSet
SELECT
CRC.ContractId
,CRC.SequenceNumber
,CRC.ContractType
,RC.Name
,NULL LastBilledDate
,ISNULL(CA.CurrentAmount,0) CurrentAmount
,ISNULL(P.Paid,0) Paid
,ISNULL(D.Deliquent,0) Deliquent
,ISNULL(F.Future,0) Future
,ISNULL(LPR.LeasePaymentRemaining,0) LeasePaymentRemaining
,ISNULL(CA.CurrentAmount,0) + ISNULL(P.Paid,0) + ISNULL(D.Deliquent,0) + ISNULL(F.Future,0) + ISNULL(LPR.LeasePaymentRemaining,0)
,CRC.EffectiveDate
FROM #ReceivablesCode TRC
JOIN Receivablecodes RC ON TRC.ReceivableCodeId = RC.Id AND TRC.IsRental = 0
JOIN #ContractReceivableCode CRC ON CRC.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.Name NOT IN ('LoanInterest','LoanPrincipal')
LEFT JOIN CTE_CurrentAmount CA ON CRC.ContractId = CA.COntractId AND CA.ReceivableCodeId = CRC.ReceivableCodeId
LEFT JOIN CTE_Paid P ON P.ContractId = CRC.ContractId AND P.ReceivableCodeId = CRC.ReceivableCodeId
LEFT JOIN CTE_Deliquent D ON D.ContractId = CRC.ContractId AND D.ReceivableCodeId = CRC.ReceivableCodeId
LEFT JOIN CTE_Future F ON F.ContractId = CRC.ContractId AND F.ReceivableCodeId = CRC.ReceivableCodeId
LEFT JOIN CTE_LeasePaymentRemaining LPR ON CRC.ContractId = LPR.ContractId AND LPR.ReceivableCodeId = CRC.ReceivableCodeId
SELECT DISTINCT
ContractId
,SequenceNumber
,EffectiveDate
,ContractType
,ReceivableCode
,LastBilledDate
,ISNULL(CurrentAmount,0) CurrentAmount
,ISNULL(PaidAmount,0) PaidAmount
,ISNULL(DeliquentAmount,0) DelinquentAmount
,ISNULL(FutureAmount,0) FutureAmount
,ISNULL(LeasePaymentRemainingAmount,0) LeasePaymentRemainingAmount
,ISNULL(TotalAmount,0) TotalAmount
FROM #ResultSet
DROP TABLE #InvoicedReceivables
DROP TABLE #UnInvoicedReceivables
DROP TABLE #ContractReceivableType
DROP TABLE #ContractReceivableCode
DROP TABLE #ContractEffectiveDateCSV
DROP TABLE #ResultSet
DROP TABLE #ReceivablesCode
END

GO
