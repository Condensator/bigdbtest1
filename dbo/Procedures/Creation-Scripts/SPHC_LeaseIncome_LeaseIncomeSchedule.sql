SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_LeaseIncome_LeaseIncomeSchedule]
(
@LegalEntityIds LeaseIncome_LeaseIncomeSchedule_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
SELECT
C.SequenceNumber,
D.LeaseContractType,
SUM(L.Income_Amount) [TotalScheduledIncome]
INTO #CSI
FROM LeaseIncomeSchedules L
JOIN LeaseFinances F ON F.Id = L.LeaseFinanceId
JOIN LeaseFinanceDetails D ON D.Id = F.Id
JOIN Contracts C ON C.Id = F.ContractId
WHERE L.IsSchedule = 1
AND L.IsLessorOwned = 1
AND F.IsCurrent = 1
AND D.LeaseContractType NOT IN ('Operating')
AND F.BookingStatus NOT IN ('Pending', 'InstallingAssets')
AND (NOT EXISTS (SELECT * FROM @LegalEntityIds)  OR F.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY C.SequenceNumber, D.LeaseContractType
SELECT
C.SequenceNumber,
D.LeaseContractType,
SUM(L.Income_Amount) [TotalAccountingIncome]
INTO #CAI
FROM LeaseIncomeSchedules L
JOIN LeaseFinances F ON F.Id = L.LeaseFinanceId
JOIN LeaseFinanceDetails D ON D.Id = F.Id
JOIN Contracts C ON C.Id = F.ContractId
WHERE L.IsAccounting = 1
AND L.IsLessorOwned = 1
AND F.IsCurrent = 1
AND D.LeaseContractType NOT IN ('Operating')
AND F.BookingStatus NOT IN ('Pending', 'InstallingAssets')
AND (NOT EXISTS(SELECT * FROM @LegalEntityIds) OR F.LegalEntityId IN (SELECT LegalEntityId FROM @LegalEntityIds))
GROUP BY C.SequenceNumber, D.LeaseContractType
SELECT
#CSI.SequenceNumber,
#CSI.LeaseContractType,
#CSI.[TotalScheduledIncome],
#CAI.[TotalAccountingIncome],
#CSI.[TotalScheduledIncome] -#CAI.[TotalAccountingIncome] AS Delta
INTO #ErrorList
FROM #CSI
JOIN #CAI ON #CSI.SequenceNumber = #CAI.SequenceNumber
WHERE #CSI.[TotalScheduledIncome] != #CAI.[TotalAccountingIncome]
SELECT @ErrorCount = count(*) FROM #ErrorList ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('LeaseError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('SuccessMessage', null);
END
SELECT *
FROM #ErrorList;
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
