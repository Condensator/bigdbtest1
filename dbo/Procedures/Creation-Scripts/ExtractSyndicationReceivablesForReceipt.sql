SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ExtractSyndicationReceivablesForReceipt]
(
@CreatedById										BIGINT,
@CreatedTime										DATETIMEOFFSET,
@JobStepInstanceId									BIGINT,
@ReceivableForTransferApprovalStatusValues_Approved	NVARCHAR(40),
@SalesTaxResposibilityValues_RemitOnly				NVARCHAR(10),
@ReceivableSourceTableValues_SyndicatedAR			NVARCHAR(40),
@ReceivableEntityTypeValues_CT						NVARCHAR(10)
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
;WITH CTE_SyndicatedContracts (ContractId) AS
(
SELECT
DISTINCT ContractId
FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
AND IsSyndicatedContract = 1
)
SELECT Contract.ContractId,
RFT.Id ReceivableForTransferId,
RFT.EffectiveDate [SyndicationEffectiveDate],
RemitOnlyRFTFS.FunderId [TaxRemitFunderId],
RemitOnlyRFTFS.FunderRemitToId [TaxRemitToId],
RFT.ScrapeReceivableCodeId,
RFT.RentalProceedsPayableCodeId,
RFT.RemitToId ReceivableRemitToId,
PC.Name [RentalProceedsPayableCodeName],
RFT.RentalProceedsWithholdingTaxRate WithholdingTaxRate,
RC.DefaultInvoiceReceivableGroupingOption InvoiceReceivableGroupingOption
INTO #ReceivableForTransfers
FROM CTE_SyndicatedContracts Contract
INNER JOIN ReceivableForTransfers RFT ON Contract.ContractId = RFT.ContractId AND RFT.ApprovalStatus = @ReceivableForTransferApprovalStatusValues_Approved
INNER JOIN ReceivableForTransferServicings RFTS ON RFT.Id = RFTS.ReceivableForTransferId AND RFTS.IsActive=1 AND RFTS.IsPerfectPay = 0
INNER JOIN PayableCodes PC ON RFT.RentalProceedsPayableCodeId = PC.Id
LEFT JOIN ReceivableForTransferFundingSources RemitOnlyRFTFS ON RFT.Id = RemitOnlyRFTFS.ReceivableForTransferId
AND RemitOnlyRFTFS.SalesTaxResponsibility = @SalesTaxResposibilityValues_RemitOnly  AND RemitOnlyRFTFS.IsActive = 1
LEFT JOIN ReceivableCodes RC ON RFT.ScrapeReceivableCodeId = RC.Id
WHERE RFT.LeasePaymentId IS NOT NULL OR RFT.LoanPaymentId IS NOT NULL;
--Funder Owned Receivables For All Receivable Types
INSERT INTO [dbo].[ReceiptSyndicatedReceivables_Extract]
([ReceivableId]
,[UtilizedScrapeAmount]
,[CreatedById]
,[CreatedTime]
,[ReceivableRemitToId]
,[ScrapeFactor]
,[ScrapeReceivableCodeId]
,[RentalProceedsPayableCodeId]
,[RentalProceedsPayableCodeName]
,[FunderBillToId]
,[FunderLocationId]
,[FunderRemitToId]
,[TaxRemitFunderId]
,[TaxRemitToId]
,[InvoiceReceivableGroupingOption]
,[JobStepInstanceId]
,[WithholdingTaxRate])
SELECT
R.[ReceivableId]
,0
,@CreatedById
,@CreatedTime
,RFT.[ReceivableRemitToId]
,RFTFS.[ScrapeFactor]
,RFT.[ScrapeReceivableCodeId]
,RFT.[RentalProceedsPayableCodeId]
,RFT.[RentalProceedsPayableCodeName]
,RFTFS.[FunderBillToId]
,RFTFS.[FunderLocationId]
,RFTFS.[FunderRemitToId]
,RFT.[TaxRemitFunderId]
,RFT.[TaxRemitToId]
,RFT.[InvoiceReceivableGroupingOption]
,@JobStepInstanceId [JobStepInstanceId]
,WithholdingTaxRate
FROM
(
SELECT ReceivableId,ContractId,ReceivableTypeId,PaymentScheduleId,FunderId
FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND IsSyndicatedContract = 1
AND FunderId IS NOT NULL
GROUP BY ReceivableId,ContractId,ReceivableTypeId,PaymentScheduleId,FunderId
) AS R
INNER JOIN #ReceivableForTransfers RFT ON R.ContractId = RFT.ContractId
INNER JOIN ReceivableForTransferFundingSources RFTFS ON RFT.ReceivableForTransferId = RFTFS.ReceivableForTransferId
AND R.FunderId = RFTFS.FunderId AND RFTFS.IsActive = 1;
--Lessor Owned Receivables - Syndicated
SELECT ContractId INTO #SyndicatedContractsWithTaxRemitToFunder FROM #ReceivableForTransfers WHERE TaxRemitFunderId IS NOT NULL
;WITH CTE_Receivables (ReceivableId,ContractId,PaymentScheduleId,SourceTable,SourceId) AS
(
SELECT ReceivableId,C.ContractId,PaymentScheduleId,SourceTable,SourceId
FROM ReceiptReceivableDetails_Extract RARD
INNER JOIN #SyndicatedContractsWithTaxRemitToFunder C ON RARD.ContractId = C.ContractId
WHERE JobStepInstanceId = @JobStepInstanceId AND RARD.FunderId IS NULL
GROUP BY ReceivableId,C.ContractId,PaymentScheduleId,SourceTable,SourceId
)
SELECT ReceivableId,ContractId
INTO #LessorOwnedSyndicatedReceivables
FROM CTE_Receivables LR
INNER JOIN Receivables FR ON LR.ContractId = FR.EntityId AND FR.EntityType = @ReceivableEntityTypeValues_CT AND FR.FunderId IS NOT NULL
WHERE ((LR.PaymentScheduleId IS NULL AND FR.PaymentScheduleId IS NULL) OR (LR.PaymentScheduleId = FR.PaymentScheduleId))
AND ((FR.SourceTable IS NULL AND LR.SourceTable IS NULL) OR (LR.SourceTable = FR.SourceTable))
AND ((LR.SourceId IS NULL AND FR.SourceId IS NULL) OR (LR.SourceId = FR.SourceId))
GROUP BY ReceivableId,ContractId
INSERT INTO [dbo].[ReceiptSyndicatedReceivables_Extract]
([ReceivableId]
,[UtilizedScrapeAmount]
,[CreatedById]
,[CreatedTime]
,[ReceivableRemitToId]
,[ScrapeFactor]
,[ScrapeReceivableCodeId]
,[RentalProceedsPayableCodeId]
,[RentalProceedsPayableCodeName]
,[FunderBillToId]
,[FunderLocationId]
,[FunderRemitToId]
,[TaxRemitFunderId]
,[TaxRemitToId]
,[InvoiceReceivableGroupingOption]
,[JobStepInstanceId]
,[WithholdingTaxRate])
SELECT
R.[ReceivableId]
,0
,@CreatedById
,@CreatedTime
,RFT.[ReceivableRemitToId]
,0.00
,RFT.[ScrapeReceivableCodeId]
,RFT.[RentalProceedsPayableCodeId]
,RFT.[RentalProceedsPayableCodeName]
,NULL
,NULL
,NULL
,RFT.[TaxRemitFunderId]
,RFT.[TaxRemitToId]
,RFT.[InvoiceReceivableGroupingOption]
,@JobStepInstanceId [JobStepInstanceId]
,WithholdingTaxRate
FROM #LessorOwnedSyndicatedReceivables AS R
INNER JOIN #ReceivableForTransfers RFT ON R.ContractId = RFT.ContractId ;
;WITH CTE_SyndicatedReceivableForScrape AS
(
SELECT Id,ReceivableId FROM [ReceiptSyndicatedReceivables_Extract] SR
WHERE JobStepInstanceId = @JobStepInstanceId AND ScrapeFactor != 0
)
SELECT R.Id,SUM(SR.TotalAmount_Amount) ScrapeAmount
INTO #UtilizedScrapeInfo
FROM CTE_SyndicatedReceivableForScrape R
JOIN Receivables SR ON R.ReceivableId = SR.SourceId
AND SR.SourceTable = @ReceivableSourceTableValues_SyndicatedAR AND SR.IsActive = 1
GROUP BY R.Id
UPDATE [ReceiptSyndicatedReceivables_Extract]
SET [UtilizedScrapeAmount] = ScrapeAmount
FROM [ReceiptSyndicatedReceivables_Extract]
JOIN #UtilizedScrapeInfo ON [ReceiptSyndicatedReceivables_Extract].Id = #UtilizedScrapeInfo.Id
END

GO
