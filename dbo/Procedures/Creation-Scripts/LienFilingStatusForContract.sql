SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LienFilingStatusForContract]
(
@CustomerNumber NVARCHAR(40) = NULL
,@ContractSequenceNumber NVARCHAR(40) = NULL
,@LegalEntity NVARCHAR(MAX) = NULL
,@FilingStatus NVarChar(10) = NULL
,@AsOfDate DATETIME = NULL
,@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
SELECT DISTINCT
Party.PartyNumber AS Customer#
,Party.PartyName AS CustomerName
,LoanFinances.Id AS LoanFinanceId
,LeaseFinances.Id AS LeaseFinanceId
,Contract.SequenceNumber AS ContractSequence#
,Contract.ContractType AS ContractType
,LegalEntity.LegalEntityNumber AS LegalEnity#
,LienFiling.Id AS LienID
,LienFiling.LienRefNumber AS LienReference#
,LienResponse.AuthorityFileNumber AS File#
,LienResponse.AuthorityFilingStatus AS FilingStatus
,LienFiling.TransactionType AS TransactionType
,ISNULL(EntityResourcesForState.Value,State.ShortName) AS State
,CONVERT(DATE,ISNULL(LienResponse.UpdatedTime,LienResponse.CreatedTime)) AS StatusDate
,U.FullName AS ExportGeneratedBy
INTO #LienFiling
FROM LienFilings LienFiling
JOIN  LienResponses LienResponse on LienResponse.Id = LienFiling.Id
JOIN States State on State.Id = LienFiling.StateId
JOIN Users U on U.Id = ISNULL(LienResponse.UpdatedById,LienResponse.CreatedById)
JOIN Contracts Contract ON Contract.Id = LienFiling.ContractId
JOIN Parties Party ON Party.Id = LienFiling.CustomerId
LEFT JOIN LoanFinances ON Contract.Id = LoanFinances.ContractId
LEFT JOIN LeaseFinances ON Contract.Id = LeaseFinances.ContractId
LEFT JOIN LegalEntities LegalEntity ON LegalEntity.Id = (CASE WHEN (Contract.ContractType = 'Loan' OR Contract.ContractType = 'ProgressLoan') THEN LoanFinances.LegalEntityId ELSE LeaseFinances.LegalEntityId END)
LEFT JOIN EntityResources EntityResourcesForState ON State.Id = EntityResourcesForState.EntityId
AND EntityResourcesForState.EntityType = 'State'
AND EntityResourcesForState.Name = 'ShortName'
ANd EntityResourcesForState.Culture= @Culture
WHERE (@CustomerNumber IS NULL OR Party.PartyNumber = @CustomerNumber)
AND (@ContractSequenceNumber IS NULL OR Contract.SequenceNumber = @ContractSequenceNumber)
AND (@LegalEntity IS NULL OR LegalEntity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')))
AND (@FilingStatus IS NULL OR LienResponse.AuthorityFilingStatus = @FilingStatus)
AND (@AsOfDate IS NULL OR CAST(LienFiling.CreatedTime AS DATE) <= CAST(@AsOfDate AS DATE))
ORDER BY Party.PartyNumber,LegalEntity.LegalEntityNumber,LienFiling.Id
select lf.LoanFinanceId,Max(dr.PaymentDate)
AS PaymentDate INTO #Lienloantem
FROM dbo.LoanFundings lf INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 1
GROUP BY lf.LoanFinanceId
INSERT INTO #Lienloantem (LoanFinanceId,PaymentDate)
SELECT lf.LoanFinanceId, Max(pv.PaymentDate)
AS PaymentDate
FROM dbo.LoanFundings lf INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LoanFinanceId
SELECT lot1.LoanFinanceId,Max(lot1.PaymentDate)AS PaymentDate into #Lienloan FROM #Lienloantem lot1 GROUP BY lot1.LoanFinanceId
select lf.LeaseFinanceId,Max(dr.PaymentDate)
AS PaymentDate INTO #Lienleasetem
FROM dbo.LeaseFundings lf INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 1
GROUP BY lf.LeaseFinanceId
INSERT INTO #Lienleasetem (LeaseFinanceId,PaymentDate)
SELECT lf.LeaseFinanceId, Max(pv.PaymentDate)
AS PaymentDate FROM dbo.LeaseFundings lf INNER JOIN dbo.PayableInvoices pi ON lf.FundingId = pi.Id
INNER JOIN dbo.DisbursementRequestInvoices dri ON dri.InvoiceId = pi.Id
INNER JOIN dbo.DisbursementRequests dr ON dri.DisbursementRequestId = dr.Id
INNER JOIN dbo.DisbursementRequestPayables drp ON drp.DisbursementRequestId = dr.Id
INNER JOIN dbo.TreasuryPayableDetails tpd ON tpd.PayableId = drp.PayableId
INNER JOIN dbo.PaymentVoucherDetails pvd ON pvd.TreasuryPayableId = tpd.TreasuryPayableId
INNER JOIN dbo.PaymentVouchers pv ON pvd.PaymentVoucherId = pv.Id
WHERE pi.Balance_Amount = 0 AND pi.IsForeignCurrency = 0
GROUP BY lf.LeaseFinanceId
SELECT let1.LeaseFinanceId,Max(let1.PaymentDate)AS PaymentDate into #Lienlease FROM #Lienleasetem let1 GROUP BY let1.LeaseFinanceId
SELECT DISTINCT lf.Customer#,
lf.CustomerName,
lf.ContractSequence#,
Isnull(le.PaymentDate,lo.PaymentDate) AS FundingDate,
lf.LegalEnity#,
lf.LienID,
lf.LienReference#,
lf.File#,
lf.TransactionType,
lf.State,
lf.FilingStatus,
lf.StatusDate,
lf.ExportGeneratedBy
from dbo.#LienFiling lf LEFT JOIN dbo.#Lienlease le ON lf.LeaseFinanceId = le.LeaseFinanceId
LEFT JOIN dbo.#Lienloan lo ON lf.LoanFinanceId = lo.LoanFinanceId
END

GO
