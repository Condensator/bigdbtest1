SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReceiptBatchManagementReport]
(
@ReceivedDate DATETIMEOFFSET = NULL,
@BatchName NVARCHAR(40) = NULL,
@AccessibleLegalEntities NVARCHAR(MAX) = NULL
)
AS
BEGIN
SELECT
LegalEntities.Name AS LegalEntity,
CurrencyCodes.ISO AS Currency,
ReceiptBatches.Name AS BatchName,
ReceiptBatches.DepositAmount_Amount AS DepositAmount,
ReceiptBatches.Status AS BatchStatus,
ReceiptBatches.ReceivedDate,
ReceiptBatches.Comment,
Receipts.Number AS ReceiptNumber,
Receipts.Id AS ReceiptId,
Receipts.PostDate,
ReceiptTypes.ReceiptTypeName AS ReceiptType,
Receipts.CheckNumber,
Receipts.ReceiptClassification,
Receipts.ReceiptAmount_Amount AS ReceiptAmount,
Receipts.Status,
SUM(ISNULL(ReceiptAllocations.AllocationAmount_Amount - ReceiptAllocations.AmountApplied_Amount,0)) AS UnallocatedCashAmount
INTO #ValidReceiptBatchDetails
FROM ReceiptBatches
JOIN LegalEntities ON ReceiptBatches.LegalEntityId = LegalEntities.Id
JOIN Currencies ON ReceiptBatches.CurrencyId = Currencies.Id
JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
JOIN ReceiptBatchDetails ON ReceiptBatchDetails.ReceiptBatchId = ReceiptBatches.Id AND ReceiptBatchDetails.IsActive=1
JOIN Receipts ON ReceiptBatchDetails.ReceiptBatchId = Receipts.ReceiptBatchId AND ReceiptBatchDetails.ReceiptId = Receipts.Id AND Receipts.Status NOT IN ('Inactive')
JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
LEFT JOIN ReceiptAllocations ON Receipts.Id = ReceiptAllocations.ReceiptId AND ReceiptAllocations.IsActive=1
WHERE ReceiptBatches.Status NOT IN ('Inactive')
AND ((@BatchName IS NULL AND ReceiptBatches.LegalEntityId in (select value from String_split(@AccessibleLegalEntities,',')))OR ReceiptBatches.Name = @BatchName)
AND (@ReceivedDate IS NULL OR ReceiptBatches.ReceivedDate = CAST(@ReceivedDate AS DATE))
GROUP BY
LegalEntities.Name,
CurrencyCodes.ISO,
ReceiptBatches.Name,
ReceiptBatches.DepositAmount_Amount,
ReceiptBatches.Status,
ReceiptBatches.ReceivedDate,
ReceiptBatches.Comment,
Receipts.Number,
Receipts.Id,
Receipts.PostDate,
ReceiptTypes.ReceiptTypeName,
Receipts.CheckNumber,
Receipts.ReceiptClassification,
Receipts.ReceiptAmount_Amount,
Receipts.Status
SELECT
#ValidReceiptBatchDetails.ReceiptId,
Parties.PartyNumber AS CustomerNumber,
Contracts.SequenceNumber,
Receivables.EntityType,
ReceivableTypes.Name AS ReceivableType,
ReceivableInvoices.Number AS InvoiceNumber,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountPosted,
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxPosted
INTO #CustomerLevelCharges
FROM #ValidReceiptBatchDetails
JOIN ReceiptApplications ON #ValidReceiptBatchDetails.ReceiptId = ReceiptApplications.ReceiptId
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND (#ValidReceiptBatchDetails.ReceiptClassification = 'DSL' OR ReceiptApplicationReceivableDetails.IsActive=1)
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Customers ON Receivables.CustomerId = Customers.Id
JOIN Parties ON Customers.Id = Parties.Id
LEFT JOIN Contracts ON Receivables.EntityType = 'CT' AND Receivables.EntityId = Contracts.Id
LEFT JOIN ReceivableInvoices ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId = ReceivableInvoices.Id
GROUP BY
#ValidReceiptBatchDetails.ReceiptId,
Parties.PartyNumber,
Contracts.SequenceNumber,
Receivables.EntityType,
ReceivableTypes.Name,
ReceivableInvoices.Number
SELECT
ReceiptBatchDetail.LegalEntity,
ReceiptBatchDetail.Currency,
ReceiptBatchDetail.BatchName,
ReceiptBatchDetail.DepositAmount,
ReceiptBatchDetail.BatchStatus,
ReceiptBatchDetail.ReceivedDate,
ReceiptBatchDetail.Comment,
#CustomerLevelCharges.CustomerNumber,
ReceiptBatchDetail.ReceiptNumber,
ReceiptBatchDetail.PostDate,
ReceiptBatchDetail.ReceiptType,
ReceiptBatchDetail.CheckNumber,
ReceiptBatchDetail.ReceiptAmount,
ReceiptBatchDetail.UnallocatedCashAmount,
ReceiptBatchDetail.Status,
#CustomerLevelCharges.SequenceNumber,
#CustomerLevelCharges.EntityType,
#CustomerLevelCharges.ReceivableType,
#CustomerLevelCharges.InvoiceNumber,
SUM(#CustomerLevelCharges.AmountPosted) AS AmountPosted,
SUM(#CustomerLevelCharges.TaxPosted) AS TaxPosted,
ROW_NUMBER() OVER (PARTITION BY ReceiptBatchDetail.BatchName,ReceiptBatchDetail.ReceiptNumber,#CustomerLevelCharges.CustomerNumber ORDER BY #CustomerLevelCharges.InvoiceNumber) AS GroupedOrder
FROM #ValidReceiptBatchDetails ReceiptBatchDetail
LEFT JOIN #CustomerLevelCharges ON ReceiptBatchDetail.ReceiptId = #CustomerLevelCharges.ReceiptId
GROUP BY
ReceiptBatchDetail.LegalEntity,
ReceiptBatchDetail.Currency,
ReceiptBatchDetail.BatchName,
ReceiptBatchDetail.DepositAmount,
ReceiptBatchDetail.BatchStatus,
ReceiptBatchDetail.ReceivedDate,
ReceiptBatchDetail.Comment,
#CustomerLevelCharges.CustomerNumber,
ReceiptBatchDetail.ReceiptNumber,
ReceiptBatchDetail.PostDate,
ReceiptBatchDetail.ReceiptType,
ReceiptBatchDetail.CheckNumber,
ReceiptBatchDetail.ReceiptAmount,
ReceiptBatchDetail.Status,
ReceiptBatchDetail.UnallocatedCashAmount,
#CustomerLevelCharges.SequenceNumber,
#CustomerLevelCharges.EntityType,
#CustomerLevelCharges.ReceivableType,
#CustomerLevelCharges.InvoiceNumber
DROP TABLE #CustomerLevelCharges
DROP TABLE #ValidReceiptBatchDetails
END

GO
