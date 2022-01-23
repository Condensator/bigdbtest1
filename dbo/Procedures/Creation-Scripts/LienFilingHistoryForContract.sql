SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LienFilingHistoryForContract]
(
@CustomerNumber nvarchar(40) = NULL
,@ContractSequenceNumber nvarchar(40) = NULL
,@LegalEntity nvarchar(MAX) = NULL
,@AsOfDate datetime = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
WITH LFHContract_CTE
AS
(
SELECT lrsh.Id,lrsh.LienFilingId,lrsh.CreatedById,lrsh.HistoryDate,lrsh.FileNumber,lrsh.FilingStatus
FROM LienRecordStatusHistories lrsh
INNER JOIN dbo.LienFilings lf
ON lrsh.LienFilingId = lf.Id
LEFT JOIN dbo.Contracts c
ON lf.ContractId = c.Id
LEFT JOIN dbo.DisbursementRequests dr
ON dr.ContractSequenceNumber = c.SequenceNumber
WHERE lrsh.Id IN
(SELECT MAX(LienRecordStatusHistories.Id) FROM LienRecordStatusHistories GROUP BY LienRecordStatusHistories.LienFilingId)
)
SELECT
Party.PartyNumber AS Customer#,
Party.PartyName AS CustomerName,
Contract.SequenceNumber AS ContractSequence#,
LegalEntity.LegalEntityNumber AS LegalEnity#,
LienFiling.Id AS LienID,
LFHContract_CTE.FileNumber AS File#,
LFHContract_CTE.FilingStatus AS FilingStatus,
LienFiling.TransactionType AS TransactionType,
LoanFinances.Id AS LoanFinanceId,
LeaseFinances.Id AS LeaseFinanceId,
ISNULL(EntityResourcesForState.Value,State.ShortName) AS State,
LFHContract_CTE.HistoryDate AS StatusDate,
U.FullName AS UserName
INTO #LienFiling
FROM LienFilings LienFiling
JOIN States State
ON State.Id = LienFiling.StateId
JOIN Parties Party
ON Party.Id = LienFiling.CustomerId
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
ANd EntityResourcesForState.Culture= @Culture
JOIN Contracts Contract
ON Contract.Id = LienFiling.ContractId
LEFT JOIN LFHContract_CTE
ON LienFiling.Id = LFHContract_CTE.LienFilingId
LEFT JOIN Users U
ON U.Id = LFHContract_CTE.CreatedById
LEFT JOIN LoanFinances
ON Contract.Id = LoanFinances.ContractId
AND LoanFinances.IsCurrent = 1
LEFT JOIN LeaseFinances
ON Contract.Id = LeaseFinances.ContractId
AND LeaseFinances.IsCurrent = 1
LEFT JOIN LegalEntities LegalEntity
ON LegalEntity.Id = (CASE WHEN (Contract.ContractType = 'Loan' OR Contract.ContractType = 'ProgressLoan')
THEN LoanFinances.LegalEntityId ELSE LeaseFinances.LegalEntityId END)
WHERE (@CustomerNumber IS NULL  OR Party.PartyNumber = @CustomerNumber)
AND (@ContractSequenceNumber IS NULL OR Contract.SequenceNumber = @ContractSequenceNumber)
AND (@LegalEntity IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')))
AND (@AsOfDate IS NULL OR CAST(LFHContract_CTE.HistoryDate AS date) <= CAST(@AsOfDate AS date))
ORDER BY Party.PartyNumber, LegalEntity.LegalEntityNumber, LienFiling.Id
SELECT lf.LoanFinanceId,Max(dr.PaymentDate) AS PaymentDate INTO #Lienloantem
FROM dbo.LoanFundings lf
INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 1
GROUP BY lf.LoanFinanceId
INSERT INTO #Lienloantem (LoanFinanceId,PaymentDate)
SELECT lf.LoanFinanceId, Max(pv.PaymentDate) AS PaymentDate
FROM dbo.LoanFundings lf
INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LoanFinanceId
SELECT lot1.LoanFinanceId,Max(lot1.PaymentDate)AS PaymentDate into #Lienloan
FROM #Lienloantem lot1 GROUP BY lot1.LoanFinanceId
SELECT lf.LeaseFinanceId,Max(dr.PaymentDate) AS PaymentDate INTO #Lienleasetem
FROM dbo.LeaseFundings lf
INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 1
GROUP BY lf.LeaseFinanceId
INSERT INTO #Lienleasetem (LeaseFinanceId,PaymentDate)
SELECT lf.LeaseFinanceId, Max(pv.PaymentDate) AS PaymentDate FROM dbo.LeaseFundings lf
INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LeaseFinanceId
SELECT let1.LeaseFinanceId,Max(let1.PaymentDate)AS PaymentDate into #Lienlease
FROM #Lienleasetem let1 GROUP BY let1.LeaseFinanceId
SELECT DISTINCT lf.Customer#,
lf.CustomerName,
lf.ContractSequence#,
ISNULL(le.PaymentDate,lo.PaymentDate) AS FundingDate,
lf.LegalEnity#,
lf.LienID,
lf.File#,
lf.TransactionType,
ISNULL(lf.FilingStatus,'_') FilingStatus,
lf.State,
lf.StatusDate,
lf.UserName
FROM dbo.#LienFiling lf
LEFT JOIN dbo.#Lienlease le ON lf.LeaseFinanceId = le.LeaseFinanceId
LEFT JOIN dbo.#Lienloan lo ON lf.LoanFinanceId = lo.LoanFinanceId
DROP TABLE #LienFiling
DROP TABLE #Lienloantem
DROP TABLE #Lienloan
DROP TABLE #Lienleasetem
DROP TABLE #Lienlease
END

GO
