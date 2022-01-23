SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_GLRecon_LongTermLeaseReceivableReconciliation]
(
@LegalEntityIds GLRecon_LongTermLeaseReceivableReconciliation_LegalEntityIds READONLY
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
WHERE gi.Name LIKE '%LongTermLeaseReceivable'
AND gtt.Name ='CapitalLeaseBooking'
AND gi.IsActive = 1
AND gtt.IsActive = 1
UNION ALL
SELECT gmei.GLEntryItemId AS Id
FROM GLEntryItems gi
INNER JOIN GLMatchingEntryItems gmei ON gi.Id = gmei.MatchingEntryItemId
INNER JOIN GLTransactionTypes gtt ON gtt.Id = gi.GLTransactionTypeId
WHERE gi.Name LIKE '%LongTermLeaseReceivable'
AND gtt.Name ='CapitalLeaseBooking'
AND gi.IsActive = 1
AND gtt.IsActive = 1
) Temp;
SELECT DISTINCT rc.Id
INTO #ValidReceivableCodes
FROM ReceivableCodes rc
INNER JOIN ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN GLTransactionTypes gtt ON rt.GLTransactionTypeId = gtt.Id
WHERE gtt.Name ='CapitalLeaseAR'
SELECT DISTINCT SequenceNumber
INTO #QualifyingContracts
FROM Contracts c
JOIN LeaseFinances lF ON lf.ContractId = c.Id AND lf.IsCurrent = 1
JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
WHERE lf.BookingStatus NOT IN('Pending', 'InstallingAssets')
AND lfd.LeaseContractType NOT IN('Operating', 'Financing')
AND C.SyndicationType = 'None' AND (
NOT EXISTS(
SELECT LegalEntityId
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
WHEN gld.IsDebit = 1
THEN gld.Amount_Amount
ELSE 0.00
END) - SUM(CASE
WHEN gld.IsDebit = 0
THEN gld.Amount_Amount
ELSE 0.00
END) [AccountBalance]
, MAX(gl.PostDate) AS [MaxPostDate]
INTO #AccountBalance
FROM Contracts c
INNER JOIN GLJournalDetails gld ON gld.EntityId = c.Id
AND gld.EntityType = 'Contract'
INNER JOIN GLJournals gl ON gld.GLJournalId = gl.Id
INNER JOIN GLTemplateDetails gtd ON gtd.Id = gld.GLTemplateDetailId
INNER JOIN #UnEarnedGLIncome gli ON gli.Id = gtd.EntryItemId
INNER JOIN #QualifyingContracts qc ON qc.SequenceNumber = c.SequenceNumber
GROUP BY C.SequenceNumber;
SELECT C.SequenceNumber
, SUM(CASE
WHEN r.IsGLPosted = 1
THEN r.TotalAmount_Amount
ELSE 0.00
END) [Total ST Receivable]
, SUM(CASE
WHEN r.IsGLPosted = 0
THEN r.TotalAmount_Amount
ELSE 0.00
END) [Total LT Receivable]
, MAX(CASE WHEN r.IsGLPosted = 1 THEN r.DueDate ELSE NULL END) AS [Max Due Date Recognized]
INTO #Income
FROM Contracts c
INNER JOIN Receivables r ON r.EntityId = c.Id AND r.EntityType = 'CT'
INNER JOIN #ValidReceivableCodes rc ON R.ReceivableCodeId = rc.Id
AND r.IsActive = 1
AND r.IsDummy = 0
GROUP BY C.SequenceNumber;
SELECT C.SequenceNumber
, SUM(r.TotalAmount_Amount) AS [Total Payment]
INTO #TotalIncome
FROM Contracts c
INNER JOIN Receivables r ON r.EntityId = c.Id AND r.EntityType = 'CT'
INNER JOIN #ValidReceivableCodes rc ON R.ReceivableCodeId = rc.Id
INNER JOIN #QualifyingContracts qc ON qc.SequenceNumber = c.SequenceNumber
WHERE r.IsDummy = 0
GROUP BY C.SequenceNumber;
SELECT ab.*
, i.[Total ST Receivable] AS [ShortTermReceivable]
, i.[Total LT Receivable] AS [LongTermReceivable]
, ti.[Total Payment] AS [Total FixedTermReceivable]
, i.[Max Due Date Recognized]
, ab.[AccountBalance] - i.[Total LT Receivable] AS [Difference]
INTO #OutputList
FROM #AccountBalance ab
INNER JOIN #Income i ON ab.SequenceNumber = i.SequenceNumber
INNER JOIN #TotalIncome ti ON ti.SequenceNumber = i.SequenceNumber
WHERE ab.[AccountBalance] - i.[Total LT Receivable] != 0.00
ORDER BY ab.SequenceNumber;
select @ErrorCount = count(*) from #OutputList ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('GLError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END
SELECT *
FROM #OutputList;
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
