SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SPHC_ContractFinance_ActiveFinanceObject]
(
@LegalEntityIds ContractFinance_ActiveFinanceObject_LegalEntityIds readonly
)
AS
SET NOCOUNT ON;
DECLARE @Messages StoredProcMessage
DECLARE @ErrorCount int
DECLARE @RecordsProcessed int
SELECT
C.SequenceNumber,
COUNT(F1.Id) LeaseFinanceCount,
COUNT(F2.Id) LoanFinanceCount
INTO #Output
FROM Contracts C
LEFT JOIN LeaseFinances F1 ON C.Id = F1.ContractId AND F1.IsCurrent = 1
LEFT JOIN LoanFinances F2 ON C.Id = F2.ContractId AND F2.IsCurrent = 1
WHERE C.ContractType IN ('Lease', 'Loan', 'ProgressLoan')
AND (
NOT EXISTS (
SELECT *
FROM @LegalEntityIds
)
OR F1.LegalEntityId IN
(
SELECT LegalEntityId
FROM @LegalEntityIds
)
OR F2.LegalEntityId IN
(
SELECT LegalEntityId
FROM @LegalEntityIds
)
)
GROUP BY C.SequenceNumber
HAVING COUNT(F1.Id) != 1 AND COUNT(F2.Id) != 1
SELECT * FROM #Output;
select @ErrorCount = count(*) from #Output ;
IF(@ErrorCount > 0)
BEGIN
INSERT INTO @Messages VALUES ('ContractError', 'Count=' + str(@ErrorCount));
END
ELSE
BEGIN
INSERT INTO @Messages VALUES ('Success', null);
END
SELECT Name, ParameterValuesCsv FROM @Messages;

GO
