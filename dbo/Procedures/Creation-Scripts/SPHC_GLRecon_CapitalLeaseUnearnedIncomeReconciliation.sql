SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_GLRecon_CapitalLeaseUnearnedIncomeReconciliation]
(
@LegalEntityIds GLRecon_CapitalLeaseUnearnedIncomeReconciliation_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
SELECT DISTINCT
Temp.Id
INTO #UnEarnedGLIncome
FROM
(
SELECT gi.Id AS Id
FROM GLEntryItems gi
JOIN GLTransactionTypes gtt ON gtt.Id = gi.GLTransactionTypeId
WHERE gi.Name = 'UnEarnedIncome'
AND gtt.Name ='CapitalLeaseBooking'
AND gi.IsActive = 1
AND gtt.IsActive = 1
UNION ALL
SELECT gmei.GLEntryItemId AS Id
FROM GLEntryItems gi
INNER JOIN GLMatchingEntryItems gmei ON gi.Id = gmei.MatchingEntryItemId
INNER JOIN GLTransactionTypes gtt ON gtt.Id = gi.GLTransactionTypeId
WHERE gi.Name = 'UnEarnedIncome'
AND gi.IsActive = 1
AND gtt.IsActive = 1
AND gtt.Name ='CapitalLeaseBooking'
) Temp;
SELECT DISTINCT SequenceNumber
INTO #QualifyingContracts
FROM Contracts c
JOIN LeaseFinances lF ON lf.ContractId = c.Id AND lf.IsCurrent = 1
JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
WHERE  lf.BookingStatus NOT IN('Pending', 'InstallingAssets')
AND lfd.LeaseContractType NOT IN('Operating', 'Financing')
AND C.SyndicationType = 'None' AND (
NOT EXISTS(
SELECT *
FROM @LegalEntityIds
)
OR lf.LegalEntityId IN
(
SELECT LegalEntityId
FROM @LegalEntityIds
))
SELECT C.SequenceNumber
, SUM(CASE
WHEN gld.IsDebit = 1
THEN gld.Amount_Amount
ELSE 0.00
END) AS         [TotalDebits]
, SUM(CASE
WHEN gld.IsDebit = 0
THEN gld.Amount_Amount
ELSE 0.00
END) AS         [TotalCredits]
, SUM(CASE
WHEN gld.IsDebit = 0
THEN gld.Amount_Amount
ELSE 0.00
END) - SUM(CASE
WHEN gld.IsDebit = 1
THEN gld.Amount_Amount
ELSE 0.00
END) [AccountBalance]
, MAX(gl.PostDate) AS [MaxPostDate]
INTO #AccountBalance
FROM Contracts c
INNER JOIN #QualifyingContracts qc ON c.SequenceNumber = qc.SequenceNumber
INNER JOIN GLJournalDetails gld ON gld.EntityId = c.Id
AND gld.EntityType = 'Contract'
INNER JOIN GLJournals gl ON gld.GLJournalId = gl.Id
INNER JOIN GLTemplateDetails gtd ON gtd.Id = gld.GLTemplateDetailId
INNER JOIN #UnEarnedGLIncome gli ON gli.Id = gtd.EntryItemId
GROUP BY C.SequenceNumber;
SELECT C.SequenceNumber
, SUM(CASE
WHEN lis.IsGLPosted = 1
THEN lis.Income_Amount
ELSE 0.00
END) [Income Earned Till As of Date]
, SUM(CASE
WHEN lis.IsGLPosted = 0
THEN lis.Income_Amount
ELSE 0.00
END) [Income left to be earned]
, SUM(CASE
WHEN lis.IsGLPosted = 1
THEN lis.ResidualIncome_Amount
ELSE 0.00
END) [Residual Earned Till As of Date]
, SUM(CASE
WHEN lis.IsGLPosted = 0
THEN lis.ResidualIncome_Amount
ELSE 0.00
END) [Residual left to be earned]
, MAX (CASE WHEN lis.IsGLPosted = 1 THEN lis.IncomeDate ELSE NULL END) AS [MaxIncomeDateRecognized]
INTO #Income
FROM Contracts c
INNER JOIN LeaseFinances lf ON c.Id = lf.ContractId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
INNER JOIN #QualifyingContracts qc ON c.SequenceNumber = qc.SequenceNumber
WHERE lis.IncomeType = 'FixedTerm'
AND lis.IsAccounting = 1
AND lis.IsLessorOwned = 1
GROUP BY C.SequenceNumber;
SELECT C.SequenceNumber
, SUM(lis.Income_Amount) - SUM(lis.ResidualIncome_Amount) AS [TotalIncome]
INTO #TotalIncome
FROM Contracts c
INNER JOIN LeaseFinances lf ON lf.ContractId = c.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN LeaseIncomeSchedules lis ON lis.LeaseFinanceId = lf.Id
INNER JOIN #QualifyingContracts qc ON c.SequenceNumber = qc.SequenceNumber
WHERE lis.IncomeType = 'FixedTerm'
AND lis.IsAccounting = 1
AND lis.IsLessorOwned = 1
GROUP BY C.SequenceNumber;
SELECT ab.*
, (i.[Income Earned Till As of Date] - i.[Residual Earned Till As of Date]) AS [IncomeEarnedTillAsofDate]
, (i.[Income left to be earned] - i.[Residual left to be earned]) AS [IncomeLeftToBeEarned]
, ti.[TotalIncome]
, i.[MaxIncomeDateRecognized]
, ab.[AccountBalance] - (i.[Income left to be earned] - i.[Residual left to be earned]) AS [Difference]
INTO #OutputList
FROM #AccountBalance ab
INNER JOIN #Income i ON ab.SequenceNumber = i.SequenceNumber
INNER JOIN #TotalIncome ti ON ti.SequenceNumber = i.SequenceNumber
WHERE ab.[AccountBalance] - (i.[Income left to be earned]  - i.[Residual left to be earned]) != 0.00
ORDER BY ab.SequenceNumber;
SELECT * FROM #OutputList
select @ErrorCount = count(*) from #OutputList ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('GLError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
