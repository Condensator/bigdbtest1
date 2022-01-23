SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateLateFeeReceivablesForJob]
(
@LateFeeReceivableSummary LateFeeReceivableInfo READONLY,
@EntityType NVARCHAR(8),
@ReceivableAmendmentType NVARCHAR(20),
@ReceivableEntityType NVARCHAR(40),
@SourceTable NVARCHAR(19),
@IsDSL BIT,
@IsCollected BIT,
@IsServiced  BIT,
@IsPrivateLabel BIT,
@IsDummy BIT,
@BilledStatus NVARCHAR(11),
@IncomeType NVARCHAR(16),
@CreatedTime DATETIMEOFFSET,
@CreatedById BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- We should remove it RS:

SELECT * INTO #LateFeeReceivableSummary FROM @LateFeeReceivableSummary

CREATE TABLE #PersistedLateFeeReceivables
(
	Id BIGINT
	,EntityId BIGINT
	,DueDate DATE
	,EndDate DATE
	,Amount DECIMAL(16,2)
	,Currency NVARCHAR(3)
	,InvoiceId BIGINT
	,FullyAssessed BIT
)
CREATE TABLE #PersistedReceivables
(
	Id BIGINT
	,SourceId BIGINT
	,EntityId BIGINT
	,InvoiceId BIGINT
)
CREATE TABLE #LateFeeContractSyndicationInfo
(
	ReceiptId BIGINT,
	InvoiceId BIGINT
	,EntityId BIGINT
	,DueDate DATE
	,ReceivableForTransferId BIGINT
	,SyndicationEffectiveDate DATE
)

DECLARE @IsSalesTaxRequiredForLoan BIT = (SELECT CASE WHEN Value = 'true' THEN 1 ELSE 0 END  FROM GlobalParameters WHERE Category = 'SalesTax' AND Name = 'IsSalesTaxRequiredForLoan')

INSERT INTO #LateFeeContractSyndicationInfo
SELECT
LFR.ReceiptId,
LFR.InvoiceId
,LFR.EntityId
,LFR.DueDate
,ReceivableForTransfers.Id [ReceivableForTransferId]
,MAX(ReceivableForTransferServicings.EffectiveDate) [SyndicationEffectiveDate]
FROM #LateFeeReceivableSummary LFR
JOIN Contracts ON LFR.EntityId = Contracts.Id
LEFT JOIN ReceivableForTransfers ON Contracts.Id = ReceivableForTransfers.ContractId
AND ReceivableForTransfers.ApprovalStatus = 'Approved'
LEFT JOIN ReceivableForTransferServicings ON ReceivableForTransfers.Id = ReceivableForTransferServicings.ReceivableForTransferId
AND ReceivableForTransferServicings.IsActive = 1
AND ReceivableForTransferServicings.EffectiveDate <= LFR.DueDate
GROUP BY LFR.ReceiptId, LFR.InvoiceId, LFR.EntityId,LFR.DueDate, ReceivableForTransfers.Id

SELECT DISTINCT ReceiptId, InvoiceId,LateFeeTemplateId,EntityId,DueDate,AlternateBillingCurrencyId,ExchangeRate INTO #LateFees FROM #LateFeeReceivableSummary

SELECT #LateFeeContractSyndicationInfo.ReceivableForTransferId, ReceivableForTransferServicings.EffectiveDate
, ReceivableForTransferServicings.RemitToId [InvoicingRemitToId]
INTO #LateFeeContractSyndications
FROM #LateFeeContractSyndicationInfo
JOIN ReceivableForTransferServicings
ON #LateFeeContractSyndicationInfo.ReceivableForTransferId = ReceivableForTransferServicings.ReceivableForTransferId
AND ReceivableForTransferServicings.IsActive = 1
AND ReceivableForTransferServicings.EffectiveDate = #LateFeeContractSyndicationInfo.SyndicationEffectiveDate
GROUP BY #LateFeeContractSyndicationInfo.ReceivableForTransferId, ReceivableForTransferServicings.EffectiveDate
, ReceivableForTransferServicings.RemitToId

SELECT * 
INTO #ContractInvoiceInfo
FROM (
	SELECT DISTINCT
	LFR.EntityId ContractId
	,ReceivableCodes.DefaultInvoiceReceivableGroupingOption
	,LateFeeTemplates.Comment
	,ReceivableCodes.AccountingTreatment
	,LeaseFinances.LegalEntityId LegalEntityId
	,ReceivableInvoices.CurrencyId
	,ReceivableInvoices.BillToId
	,CASE WHEN SyndicatedContract.InvoicingRemitToId IS NOT NULL
	THEN SyndicatedContract.InvoicingRemitToId
	ELSE Contracts.RemitToId
	END RemitToId
	,ReceivableCodes.Id ReceivableCodeId
	,ReceivableInvoices.Id ReceivableInvoiceId
	,ReceivableInvoices.CustomerId
	,ReceivableInvoices.IsPrivateLabel
	,LeaseFinances.InstrumentTypeId AS InstrumentTypeId
	,0 IsTaxAssessed
	,Contracts.LineofBusinessId
	,Contracts.CostCenterId
	,LFR.AlternateBillingCurrencyId AS BillingCurrencyId
	,LFR.ExchangeRate AS BillingExchangeRate
	,LFR.DueDate [ContractDueDate]
	,null LocationId
FROM #LateFees AS LFR
JOIN ReceivableInvoices ON LFR.InvoiceId = ReceivableInvoices.Id
JOIN LateFeeTemplates ON LFR.LateFeeTemplateId = LateFeeTemplates.Id
JOIN ReceivableCodes ON LateFeeTemplates.ReceivableCodeId = ReceivableCodes.Id
JOIN Contracts ON LFR.EntityId = Contracts.Id
JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
	AND LeaseFinances.IsCurrent=1
JOIN #LateFeeContractSyndicationInfo ON LFR.EntityId = #LateFeeContractSyndicationInfo.EntityId
	AND LFR.InvoiceId = #LateFeeContractSyndicationInfo.InvoiceId
	AND LFR.DueDate = #LateFeeContractSyndicationInfo.DueDate
LEFT JOIN #LateFeeContractSyndications AS SyndicatedContract
	ON #LateFeeContractSyndicationInfo.ReceivableForTransferId = SyndicatedContract.ReceivableForTransferId
	AND #LateFeeContractSyndicationInfo.SyndicationEffectiveDate = SyndicatedContract.EffectiveDate

UNION ALL

SELECT DISTINCT
	LFR.EntityId ContractId
	,ReceivableCodes.DefaultInvoiceReceivableGroupingOption
	,LateFeeTemplates.Comment
	,ReceivableCodes.AccountingTreatment
	,LoanFinances.LegalEntityId  LegalEntityId
	,ReceivableInvoices.CurrencyId
	,ReceivableInvoices.BillToId
	,CASE WHEN SyndicatedContract.InvoicingRemitToId IS NOT NULL
	THEN SyndicatedContract.InvoicingRemitToId
	ELSE Contracts.RemitToId
	END RemitToId
	,ReceivableCodes.Id ReceivableCodeId
	,ReceivableInvoices.Id ReceivableInvoiceId
	,ReceivableInvoices.CustomerId
	,ReceivableInvoices.IsPrivateLabel
	,LoanFinances.InstrumentTypeId InstrumentTypeId
	--,1 IsTaxAssessed
	,CASE WHEN @IsSalesTaxRequiredForLoan = 1 THEN 0 ELSE 1 END AS IsTaxAssessed
	,Contracts.LineofBusinessId
	,Contracts.CostCenterId
	,LFR.AlternateBillingCurrencyId AS BillingCurrencyId
	,LFR.ExchangeRate AS BillingExchangeRate
	,LFR.DueDate [ContractDueDate]
	,CASE WHEN @IsSalesTaxRequiredForLoan = 1 THEN BillTo.LocationId ELSE null END AS LocationId
FROM #LateFees AS LFR
JOIN ReceivableInvoices ON LFR.InvoiceId = ReceivableInvoices.Id
JOIN BillToes BillTo ON BillTo.Id = ReceivableInvoices.BillToId
JOIN LateFeeTemplates ON LFR.LateFeeTemplateId = LateFeeTemplates.Id
JOIN ReceivableCodes ON LateFeeTemplates.ReceivableCodeId = ReceivableCodes.Id
JOIN Contracts ON LFR.EntityId = Contracts.Id
JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
	AND LoanFinances.IsCurrent=1
JOIN #LateFeeContractSyndicationInfo ON LFR.EntityId = #LateFeeContractSyndicationInfo.EntityId
	AND LFR.InvoiceId = #LateFeeContractSyndicationInfo.InvoiceId
	AND LFR.DueDate = #LateFeeContractSyndicationInfo.DueDate
LEFT JOIN #LateFeeContractSyndications AS SyndicatedContract
	ON #LateFeeContractSyndicationInfo.ReceivableForTransferId = SyndicatedContract.ReceivableForTransferId
	AND #LateFeeContractSyndicationInfo.SyndicationEffectiveDate = SyndicatedContract.EffectiveDate
) List

MERGE INTO LateFeeReceivables
USING(SELECT * FROM
#LateFeeReceivableSummary LFR
JOIN #ContractInvoiceInfo CI ON LFR.InvoiceId = CI.ReceivableInvoiceId
AND CI.ContractId = LFR.EntityId
AND CI.ContractDueDate = LFR.DueDate)
AS LFR ON 1=0
WHEN NOT MATCHED THEN
INSERT
(
EntityType
,EntityId
,DueDate
,DaysLate
,StartDate
,EndDate
,InvoiceReceivableGroupingOption
,Amount_Amount
,Amount_Currency
,ReceivableAmendmentType
,InvoiceComment
,AccountingTreatment
,IsActive
,LegalEntityId
,CurrencyId
,BillToId
,RemitToId
,ReceivableCodeId
,ReceivableInvoiceId
,InstrumentTypeId
,LineofBusinessId
,IsManuallyAssessed
,CreatedById
,CreatedTime
,ReceiptId
,CostCenterId
,IsServiced
,IsCollected
,IsPrivateLabel
,IsOwned
,TaxBasisAmount_Amount
,TaxBasisAmount_Currency
)
VALUES
(
@EntityType
,LFR.ContractId
,LFR.DueDate
,LFR.DaysDue
,LFR.StartDate
,LFR.EndDate
,LFR.DefaultInvoiceReceivableGroupingOption
,LFR.LateFeeAmount
,LFR.Currency
,@ReceivableAmendmentType
,LFR.Comment
,LFR.AccountingTreatment
,1
,LFR.LegalEntityId
,LFR.CurrencyId
,LFR.BillToId
,LFR.RemitToId
,LFR.ReceivableCodeId
,LFR.ReceivableInvoiceId
,LFR.InstrumentTypeId
,LFR.LineofBusinessId
,0
,@CreatedById
,@CreatedTime
,LFR.ReceiptId
,LFR.CostCenterId
,0
,0
,0
,0
,LFR.TaxBasisAmount
,LFR.Currency
)
OUTPUT INSERTED.Id,INSERTED.EntityId,INSERTED.DueDate,INSERTED.EndDate,INSERTED.Amount_Amount,INSERTED.Amount_Currency,INSERTED.ReceivableInvoiceId,LFR.FullyAssessed
INTO #PersistedLateFeeReceivables;

MERGE INTO Receivables
USING(SELECT * FROM #PersistedLateFeeReceivables
JOIN #ContractInvoiceInfo ON #PersistedLateFeeReceivables.EntityId = #ContractInvoiceInfo.ContractId
AND #PersistedLateFeeReceivables.InvoiceId = #ContractInvoiceInfo.ReceivableInvoiceId
AND #PersistedLateFeeReceivables.DueDate = #ContractInvoiceInfo.ContractDueDate)
AS LF ON 1=0
WHEN NOT MATCHED THEN
INSERT
([DueDate]
,[EntityType]
,[IsActive]
,[InvoiceComment]
,[InvoiceReceivableGroupingOption]
,[IsGLPosted]
,[IncomeType]
,[PaymentScheduleId]
,[IsCollected]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[ReceivableCodeId]
,[CustomerId]
,[RemitToId]
,[TaxRemitToId]
,[LocationId]
,[LegalEntityId]
,[EntityId]
,[IsDSL]
,[IsServiced]
,[IsDummy]
,[IsPrivateLabel]
,[FunderId]
,[SourceTable]
,[SourceId]
,[TotalAmount_Currency]
,[TotalAmount_Amount]
,[TotalEffectiveBalance_Currency]
,[TotalEffectiveBalance_Amount]
,[TotalBalance_Currency]
,[TotalBalance_Amount]
,[TotalBookBalance_Currency]
,[TotalBookBalance_Amount]
,[ExchangeRate]
,[AlternateBillingCurrencyId])
VALUES
(
LF.DueDate
,@ReceivableEntityType
,1
,LF.Comment
,LF.DefaultInvoiceReceivableGroupingOption
,0
,@IncomeType
,NULL
,@IsCollected
,@CreatedById
,@CreatedTime
,NULL
,NULL
,LF.ReceivableCodeId
,LF.CustomerId
,LF.RemitToId
,LF.RemitToId
,LF.LocationId
,LF.LegalEntityId
,LF.ContractId
,@IsDSL
,@IsServiced
,@IsDummy
,LF.IsPrivateLabel
,NULL
,@SourceTable
,LF.Id
,LF.Currency
,LF.Amount
,LF.Currency
,LF.Amount
,LF.Currency
,LF.Amount
,LF.Currency
,0.0
,BillingExchangeRate
,BillingCurrencyId)
OUTPUT INSERTED.Id,INSERTED.SourceId,INSERTED.EntityId,LF.ReceivableInvoiceId
INTO #PersistedReceivables;
INSERT INTO [dbo].[ReceivableDetails]
           ([Amount_Amount]
           ,[Amount_Currency]
           ,[Balance_Amount]
           ,[Balance_Currency]
           ,[EffectiveBalance_Amount]
           ,[EffectiveBalance_Currency]
           ,[IsActive]
           ,[BilledStatus]
           ,[IsTaxAssessed]
           ,[CreatedById]
           ,[CreatedTime]
           ,[UpdatedById]
           ,[UpdatedTime]
           ,[AssetId]
           ,[BillToId]
           ,[AdjustmentBasisReceivableDetailId]
           ,[ReceivableId]
		   ,[StopInvoicing]
		   ,[EffectiveBookBalance_Amount]
		   ,[EffectiveBookBalance_Currency]
		   ,[AssetComponentType]
	       ,[LeaseComponentAmount_Amount]
	       ,[LeaseComponentAmount_Currency]
	       ,[NonLeaseComponentAmount_Amount]
	       ,[NonLeaseComponentAmount_Currency]
	       ,[LeaseComponentBalance_Amount]
	       ,[LeaseComponentBalance_Currency]
	       ,[NonLeaseComponentBalance_Amount]
	       ,[NonLeaseComponentBalance_Currency]
		   ,[PreCapitalizationRent_Amount]
		   ,[PreCapitalizationRent_Currency]
		   )
SELECT 
	LFR.Amount
	,LFR.Currency
	,LFR.Amount
	,LFR.Currency
	,LFR.Amount
	,LFR.Currency
	,1
	,@BilledStatus
	,CI.IsTaxAssessed
	,@CreatedById
	,@CreatedTime
	,NULL
	,NULL
	,NULL
	,CI.BillToId
	,NULL
	,R.Id
	,0
	,0.00
	,LFR.Currency
	,'_'
	,LFR.Amount
	,LFR.Currency
	,0.00
	,LFR.Currency
	,LFR.Amount
	,LFR.Currency
	,0.00
	,LFR.Currency
	,0.00
	,LFR.Currency
FROM 
#PersistedReceivables R 
JOIN #PersistedLateFeeReceivables LFR ON R.SourceId = LFR.Id 
JOIN #ContractInvoiceInfo CI ON LFR.EntityId = CI.ContractId AND LFR.InvoiceId = CI.ReceivableInvoiceId AND LFR.DueDate = CI.ContractDueDate

MERGE INTO LateFeeAssessments
USING (SELECT InvoiceId,EntityId,FullyAssessed,MAX(EndDate) EndDate
FROM #PersistedLateFeeReceivables GROUP BY InvoiceId,EntityId,FullyAssessed) AS LFR
ON LateFeeAssessments.ReceivableInvoiceId = LFR.InvoiceId
AND LateFeeAssessments.ContractId = LFR.EntityId
WHEN MATCHED THEN
UPDATE SET
LateFeeAssessedUntilDate = LFR.EndDate
,FullyAssessed = LFR.FullyAssessed
,IsActive = 1
,UpdatedById = @CreatedById
,UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
(
LateFeeAssessedUntilDate
,FullyAssessed
,IsActive
,ContractId
,CustomerId
,ReceivableInvoiceId
,CreatedById
,CreatedTime
)
VALUES
(
LFR.EndDate
,LFR.FullyAssessed
,1
,LFR.EntityId
,NULL
,LFR.InvoiceId
,@CreatedById
,@CreatedTime
);

SELECT Id AS ReceivableId FROM #PersistedReceivables

DROP TABLE #ContractInvoiceInfo
DROP TABLE #PersistedLateFeeReceivables
DROP TABLE #PersistedReceivables
DROP TABLE #LateFeeContractSyndicationInfo
DROP TABLE #LateFeeReceivableSummary
DROP TABLE #LateFees
DROP TABLE #LateFeeContractSyndications

SET NOCOUNT OFF;
END

GO
