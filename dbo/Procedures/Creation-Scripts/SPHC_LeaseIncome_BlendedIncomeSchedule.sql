SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LeaseIncome_BlendedIncomeSchedule]
(
@LegalEntityIds LeaseIncome_BlendedIncomeSchedule_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
-- Fetches and Stores Total Scheduled Income per Blended Item
SELECT
C.SequenceNumber,
BI.Id,
SUM(B.Income_Amount) [TotalScheduledIncome]
INTO #BSI
FROM BlendedIncomeSchedules B
JOIN BlendedItems BI ON BI.Id = B.BlendedItemId
JOIN LeaseFinances F ON F.Id = B.LeaseFinanceId
JOIN LeaseFinanceDetails D ON D.Id = F.Id
JOIN Contracts C ON C.Id = F.ContractId
WHERE B.IsSchedule = 1 AND F.IsCurrent = 1
AND (NOT EXISTS (SELECT * FROM @LegalEntityIds) OR F.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY C.SequenceNumber, BI.Id
-- Fetches and Stores Total Accounting Income per Blended Item
SELECT
C.SequenceNumber,
BI.Id,
SUM(B.Income_Amount) [TotalAccountingIncome]
INTO #BAI
FROM BlendedIncomeSchedules B
JOIN BlendedItems BI ON BI.Id = B.BlendedItemId
JOIN LeaseFinances F ON F.Id = B.LeaseFinanceId
JOIN LeaseFinanceDetails D ON D.Id = F.Id
JOIN Contracts C ON C.Id = F.ContractId
WHERE B.IsAccounting = 1 AND F.IsCurrent = 1
AND (NOT EXISTS (SELECT * FROM @LegalEntityIds) OR F.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY C.SequenceNumber, BI.Id
-- Preparing Failed List
SELECT
#BSI.SequenceNumber,
#BSI.Id,
BI.Name,
BI.Type,
BI.BookRecognitionMode,
BI.Amount_Amount,
#BSI.[TotalScheduledIncome],
#BAI.[TotalAccountingIncome],
#BSI.[TotalScheduledIncome] - #BAI.[TotalAccountingIncome] AS Delta
INTO #OutputList
FROM #BSI
JOIN #BAI ON #BSI.Id = #BAI.Id
JOIN BlendedItems BI ON BI.Id = #BSI.Id
WHERE #BSI.[TotalScheduledIncome] != #BAI.[TotalAccountingIncome]
ORDER BY #BSI.SequenceNumber ASC
SELECT @ErrorCount = count(*) FROM #OutputList ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LeaseError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('SuccessMessage', null);
END
SELECT * FROM #OutputList
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
