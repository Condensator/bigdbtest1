SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PreQuotePaymentHistoryReport]
(
@EntityId BIGINT
,@SequenceNumber NVARCHAR(100)
,@IsSummaryReport BIT
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @ReceiptHistorySummary TABLE
(
Currency NVARCHAR(3),
CustomerNumber NVARCHAR(80),
Customer NVARCHAR(500),
ReceivedDate DATE,
ReceiptNumber NVARCHAR(40),
ReceiptType NVARCHAR(40),
ReceiptBatch NVARCHAR(40),
Status NVARCHAR(20),
CheckNumber NVARCHAR(40),
CheckAmount DECIMAL(16,2),
Charges DECIMAL(16,2),
Taxes DECIMAL(16,2),
UnallocatedCashBalance DECIMAL(16,2),
PostDate DATE,
ReversalPostDate DATE,
InvoiceNumber NVARCHAR(40),
BillTo NVARCHAR(40),
InvoiceDueDate DATE,
Due DECIMAL(16,2),
Outstanding DECIMAL(16,2),
ChargesTowardsInvoice DECIMAL(16,2),
TaxesTowardsInvoice DECIMAL(16,2),
Total DECIMAL(16,2),
ReceivableType NVARCHAR(40),
ReceivableTypeOrder INT,
GroupedOrder INT,
CustomerId BIGINT
)
SELECT
Receipts.Id AS ReceiptId,
CurrencyCodes.ISO AS Currency,
Receipts.ReceivedDate,
Receipts.Number AS ReceiptNumber,
ReceiptTypes.ReceiptTypeName AS ReceiptType,
ReceiptBatches.Name AS ReceiptBatch,
Receipts.CheckNumber,
Receipts.ReceiptAmount_Amount AS CheckAmount,
Receipts.PostDate,
Receipts.ReversalPostDate,
SUM(ISNULL(ReceiptAllocations.AllocationAmount_Amount - ReceiptAllocations.AmountApplied_Amount,0)) AS UnallocatedCashBalance,
Receipts.Status,
Receipts.ReceiptClassification
INTO #ValidReceipts
FROM
Receipts
JOIN Currencies ON Receipts.CurrencyId = Currencies.Id
JOIN CurrencyCodes ON Currencies.CurrencyCodeId = CurrencyCodes.Id
JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
LEFT JOIN ReceiptBatches ON Receipts.ReceiptBatchId = ReceiptBatches.Id
LEFT JOIN ReceiptAllocations ON Receipts.Id = ReceiptAllocations.ReceiptId AND ReceiptAllocations.IsActive=1
WHERE Receipts.Status IN ('Posted','Completed','Reversed')
AND (ReceiptTypes.ReceiptTypeName NOT IN('WaivedFromReceivableAdjustment','PayDown') OR Receipts.Balance_Amount <> 0)
--AND (CAST(@FromDate AS DATE) <= Receipts.PostDate AND Receipts.PostDate <= CAST(@ToDate AS DATE))
--AND (@ReceiptType IS NULL OR @ReceiptType = ReceiptTypes.ReceiptTypeName)
--AND (@Currency IS NULL OR CurrencyCodes.ISO = @Currency)
AND Receipts.ContractId = @EntityId
GROUP BY
Receipts.Id,
CurrencyCodes.ISO,
Receipts.ReceivedDate,
Receipts.Number,
ReceiptTypes.ReceiptTypeName,
ReceiptBatches.Name,
Receipts.Status,
Receipts.CheckNumber,
Receipts.ReceiptAmount_Amount,
Receipts.ReceiptClassification,
Receipts.PostDate,
Receipts.ReversalPostDate
SELECT
#ValidReceipts.ReceiptId,
Receivables.CustomerId,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS Charges,
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS Taxes,
Parties.PartyNumber AS CustomerNumber,
Parties.PartyName AS Customer
INTO #CustomerLevelCharges
FROM #ValidReceipts
JOIN ReceiptApplications ON #ValidReceipts.ReceiptId = ReceiptApplications.ReceiptId
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND (#ValidReceipts.ReceiptClassification = 'DSL' OR ReceiptApplicationReceivableDetails.IsActive=1)
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN Customers ON Receivables.CustomerId = Customers.Id
JOIN Parties ON Customers.Id = Parties.Id
--WHERE (@CustomerNumber IS NULL OR Parties.PartyNumber = @CustomerNumber)
GROUP BY
#ValidReceipts.ReceiptId,
Receivables.CustomerId,
Parties.PartyNumber,
Parties.PartyName
SELECT
Receipts.ReceiptId,
#CustomerLevelCharges.CustomerId,
SUM(ISNULL(#CustomerLevelCharges.Charges,0)) AS Charges,
SUM(ISNULL(#CustomerLevelCharges.Taxes,0)) AS Taxes,
Receipts.Currency,
#CustomerLevelCharges.CustomerNumber,
#CustomerLevelCharges.Customer,
Receipts.ReceivedDate,
Receipts.ReceiptNumber,
Receipts.ReceiptType,
Receipts.ReceiptBatch,
Receipts.CheckNumber,
Receipts.CheckAmount,
Receipts.PostDate,
Receipts.ReversalPostDate,
Receipts.UnallocatedCashBalance,
Receipts.Status,
Receipts.ReceiptClassification
INTO #ReceiptLevelSummary
FROM #ValidReceipts Receipts
LEFT JOIN #CustomerLevelCharges ON Receipts.ReceiptId = #CustomerLevelCharges.ReceiptId
--WHERE (@CustomerNumber IS NULL OR #CustomerLevelCharges.CustomerNumber = @CustomerNumber)
GROUP BY
Receipts.ReceiptId,
#CustomerLevelCharges.CustomerId,
Receipts.Currency,
#CustomerLevelCharges.CustomerNumber,
#CustomerLevelCharges.Customer,
Receipts.ReceivedDate,
Receipts.ReceiptNumber,
Receipts.ReceiptType,
Receipts.ReceiptBatch,
Receipts.Status,
Receipts.CheckNumber,
Receipts.CheckAmount,
Receipts.ReceiptClassification,
Receipts.PostDate,
Receipts.ReversalPostDate,
Receipts.UnallocatedCashBalance
UPDATE #ReceiptLevelSummary
SET CustomerNumber = 'Dummy', Customer = 'Dummy'
WHERE CustomerId = NULL
SELECT
#ReceiptLevelSummary.ReceiptId,
#ReceiptLevelSummary.CustomerId,
ReceivableDetails.Id ReceivableDetailId,
ReceivableTypes.Name ReceivableType,
ReceivableDetails.Amount_Amount Amount,
ReceivableDetails.Balance_Amount Balance,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountPosted,
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxPosted
INTO #ReceivableAmountApplied
FROM
#ReceiptLevelSummary
JOIN ReceiptApplications ON #ReceiptLevelSummary.ReceiptId = ReceiptApplications.ReceiptId
JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId AND (#ReceiptLevelSummary.ReceiptClassification = 'DSL' OR ReceiptApplicationReceivableDetails.IsActive=1)
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND #ReceiptLevelSummary.CustomerId = Receivables.CustomerId
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
GROUP BY
#ReceiptLevelSummary.ReceiptId,
#ReceiptLevelSummary.CustomerId,
ReceivableDetails.Id,
ReceivableDetails.Amount_Amount,
ReceivableDetails.Balance_Amount,
ReceivableTypes.Name
SELECT
DISTINCT
#ReceivableAmountApplied.ReceivableDetailId,
SUM(ReceivableTaxImpositions.Amount_Amount) Amount,
SUM(ReceivableTaxImpositions.Balance_Amount) Balance
INTO #ReceivableTaxApplied
FROM
#ReceivableAmountApplied
INNER JOIN ReceivableTaxDetails ON #ReceivableAmountApplied.ReceivableDetailId = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive=1
INNER JOIN ReceivableTaxImpositions ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId AND ReceivableTaxImpositions.IsActive=1
GROUP BY
#ReceivableAmountApplied.ReceivableDetailId,
#ReceivableAmountApplied.ReceiptId
SELECT
#ReceivableAmountApplied.ReceivableDetailId,
ReceivableInvoices.Number InvoiceNumber,
ReceivableInvoices.DueDate InvoiceDueDate,
BillToes.Name BillTo
INTO #ReceivableInvoiceSummary
FROM
#ReceivableAmountApplied
JOIN ReceivableInvoiceDetails ON #ReceivableAmountApplied.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive=1
JOIN BillToes ON ReceivableInvoices.BillToId = BillToes.Id
GROUP BY
#ReceivableAmountApplied.ReceivableDetailId,
ReceivableInvoices.Number,
ReceivableInvoices.DueDate,
BillToes.Name
IF(@IsSummaryReport=1)
BEGIN
INSERT INTO @ReceiptHistorySummary
(
Currency,
CustomerNumber,
Customer,
ReceivedDate,
ReceiptNumber,
ReceiptType,
ReceiptBatch,
Status,
CheckNumber,
CheckAmount,
Charges,
Taxes,
UnallocatedCashBalance,
PostDate,
ReversalPostDate,
InvoiceNumber,
BillTo,
InvoiceDueDate,
Due,
Outstanding,
ChargesTowardsInvoice,
TaxesTowardsInvoice,
Total,
GroupedOrder,
CustomerId
)
SELECT
#ReceiptLevelSummary.Currency,
CASE WHEN #ReceiptLevelSummary.CustomerNumber='Dummy' THEN NULL ELSE #ReceiptLevelSummary.CustomerNumber END AS CustomerNumber,
CASE WHEN #ReceiptLevelSummary.Customer='Dummy' THEN NULL ELSE #ReceiptLevelSummary.Customer END AS Customer,
#ReceiptLevelSummary.ReceivedDate,
#ReceiptLevelSummary.ReceiptNumber,
#ReceiptLevelSummary.ReceiptType,
#ReceiptLevelSummary.ReceiptBatch,
#ReceiptLevelSummary.Status,
#ReceiptLevelSummary.CheckNumber,
#ReceiptLevelSummary.CheckAmount,
#ReceiptLevelSummary.Charges,
#ReceiptLevelSummary.Taxes,
#ReceiptLevelSummary.UnallocatedCashBalance,
#ReceiptLevelSummary.PostDate,
#ReceiptLevelSummary.ReversalPostDate,
#ReceivableInvoiceSummary.InvoiceNumber,
#ReceivableInvoiceSummary.BillTo,
#ReceivableInvoiceSummary.InvoiceDueDate,
SUM(ISNULL(#ReceivableAmountApplied.Amount,0)) + SUM(ISNULL(#ReceivableTaxApplied.Amount,0)) AS Due,
SUM(ISNULL(#ReceivableAmountApplied.Balance,0)) + SUM(ISNULL(#ReceivableTaxApplied.Balance,0)) AS Outstanding,
SUM(ISNULL(#ReceivableAmountApplied.AmountPosted,0)) AS ChargesTowardsInvoice,
SUM(ISNULL(#ReceivableAmountApplied.TaxPosted,0)) AS TaxesTowardsInvoice,
SUM(ISNULL(#ReceivableAmountApplied.AmountPosted,0)) + SUM(ISNULL(#ReceivableAmountApplied.TaxPosted,0)) AS Total,
ROW_NUMBER() OVER (PARTITION BY #ReceiptLevelSummary.ReceiptNumber,#ReceiptLevelSummary.CustomerNumber ORDER BY #ReceivableInvoiceSummary.InvoiceNumber) AS GroupedOrder,
#ReceiptLevelSummary.CustomerId
FROM
#ReceiptLevelSummary
LEFT JOIN #ReceivableAmountApplied ON #ReceiptLevelSummary.ReceiptId = #ReceivableAmountApplied.ReceiptId AND #ReceiptLevelSummary.CustomerId = #ReceivableAmountApplied.CustomerId
LEFT JOIN #ReceivableTaxApplied ON #ReceivableAmountApplied.ReceivableDetailId = #ReceivableTaxApplied.ReceivableDetailId
LEFT JOIN #ReceivableInvoiceSummary ON #ReceivableAmountApplied.ReceivableDetailId = #ReceivableInvoiceSummary.ReceivableDetailId
GROUP BY
#ReceiptLevelSummary.ReceiptId,
#ReceiptLevelSummary.Currency,
#ReceiptLevelSummary.CustomerId,
#ReceiptLevelSummary.CustomerNumber,
#ReceiptLevelSummary.Customer,
#ReceiptLevelSummary.ReceivedDate,
#ReceiptLevelSummary.ReceiptNumber,
#ReceiptLevelSummary.ReceiptType,
#ReceiptLevelSummary.ReceiptBatch,
#ReceiptLevelSummary.Status,
#ReceiptLevelSummary.CheckNumber,
#ReceiptLevelSummary.CheckAmount,
#ReceiptLevelSummary.Charges,
#ReceiptLevelSummary.Taxes,
#ReceiptLevelSummary.UnallocatedCashBalance,
#ReceiptLevelSummary.PostDate,
#ReceiptLevelSummary.ReversalPostDate,
#ReceivableInvoiceSummary.InvoiceNumber,
#ReceivableInvoiceSummary.BillTo,
#ReceivableInvoiceSummary.InvoiceDueDate
END
ELSE
BEGIN
INSERT INTO @ReceiptHistorySummary
(
Currency,
CustomerNumber,
Customer,
ReceivedDate,
ReceiptNumber,
ReceiptType,
ReceiptBatch,
Status,
CheckNumber,
CheckAmount,
Charges,
Taxes,
UnallocatedCashBalance,
PostDate,
ReversalPostDate,
InvoiceNumber,
BillTo,
InvoiceDueDate,
Due,
Outstanding,
ChargesTowardsInvoice,
TaxesTowardsInvoice,
Total,
ReceivableType,
ReceivableTypeOrder,
GroupedOrder,
CustomerId
)
SELECT
#ReceiptLevelSummary.Currency,
CASE WHEN #ReceiptLevelSummary.CustomerNumber='Dummy' THEN NULL ELSE #ReceiptLevelSummary.CustomerNumber END AS CustomerNumber,
CASE WHEN #ReceiptLevelSummary.Customer='Dummy' THEN NULL ELSE #ReceiptLevelSummary.Customer END AS Customer,
#ReceiptLevelSummary.ReceivedDate,
#ReceiptLevelSummary.ReceiptNumber,
#ReceiptLevelSummary.ReceiptType,
#ReceiptLevelSummary.ReceiptBatch,
#ReceiptLevelSummary.Status,
#ReceiptLevelSummary.CheckNumber,
#ReceiptLevelSummary.CheckAmount,
#ReceiptLevelSummary.Charges,
#ReceiptLevelSummary.Taxes,
#ReceiptLevelSummary.UnallocatedCashBalance,
#ReceiptLevelSummary.PostDate,
#ReceiptLevelSummary.ReversalPostDate,
#ReceivableInvoiceSummary.InvoiceNumber,
#ReceivableInvoiceSummary.BillTo,
#ReceivableInvoiceSummary.InvoiceDueDate,
SUM(ISNULL(#ReceivableAmountApplied.Amount,0)) + SUM(ISNULL(#ReceivableTaxApplied.Amount,0)) AS Due,
SUM(ISNULL(#ReceivableAmountApplied.Balance,0)) + SUM(ISNULL(#ReceivableTaxApplied.Balance,0)) AS Outstanding,
SUM(ISNULL(#ReceivableAmountApplied.AmountPosted,0)) AS ChargesTowardsInvoice,
SUM(ISNULL(#ReceivableAmountApplied.TaxPosted,0)) AS TaxesTowardsInvoice,
SUM(ISNULL(#ReceivableAmountApplied.AmountPosted,0)) + SUM(ISNULL(#ReceivableAmountApplied.TaxPosted,0)) AS Total,
#ReceivableAmountApplied.ReceivableType,
ROW_NUMBER() OVER (PARTITION BY #ReceiptLevelSummary.ReceiptNumber,#ReceiptLevelSummary.CustomerNumber,#ReceivableAmountApplied.ReceivableType,#ReceivableInvoiceSummary.InvoiceNumber ORDER BY #ReceivableInvoiceSummary.InvoiceNumber) AS ReceivableTypeOrder,
ROW_NUMBER() OVER (PARTITION BY #ReceiptLevelSummary.ReceiptNumber,#ReceiptLevelSummary.CustomerNumber ORDER BY #ReceivableInvoiceSummary.InvoiceNumber) AS GroupedOrder,
#ReceiptLevelSummary.CustomerId
FROM
#ReceiptLevelSummary
LEFT JOIN #ReceivableAmountApplied ON #ReceiptLevelSummary.ReceiptId = #ReceivableAmountApplied.ReceiptId AND #ReceiptLevelSummary.CustomerId = #ReceivableAmountApplied.CustomerId
LEFT JOIN #ReceivableTaxApplied ON #ReceivableAmountApplied.ReceivableDetailId = #ReceivableTaxApplied.ReceivableDetailId
LEFT JOIN #ReceivableInvoiceSummary ON #ReceivableAmountApplied.ReceivableDetailId = #ReceivableInvoiceSummary.ReceivableDetailId
GROUP BY
#ReceiptLevelSummary.ReceiptId,
#ReceiptLevelSummary.Currency,
#ReceiptLevelSummary.CustomerId,
#ReceiptLevelSummary.CustomerNumber,
#ReceiptLevelSummary.Customer,
#ReceiptLevelSummary.ReceivedDate,
#ReceiptLevelSummary.ReceiptNumber,
#ReceiptLevelSummary.ReceiptType,
#ReceiptLevelSummary.ReceiptBatch,
#ReceiptLevelSummary.Status,
#ReceiptLevelSummary.CheckNumber,
#ReceiptLevelSummary.CheckAmount,
#ReceiptLevelSummary.Charges,
#ReceiptLevelSummary.Taxes,
#ReceiptLevelSummary.UnallocatedCashBalance,
#ReceiptLevelSummary.PostDate,
#ReceiptLevelSummary.ReversalPostDate,
#ReceivableAmountApplied.ReceivableType,
#ReceivableInvoiceSummary.InvoiceNumber,
#ReceivableInvoiceSummary.BillTo,
#ReceivableInvoiceSummary.InvoiceDueDate
UPDATE @ReceiptHistorySummary
SET ReceivableType = NULL
WHERE ReceivableTypeOrder<>1
END
UPDATE @ReceiptHistorySummary
SET ReceivedDate = NULL,
ReceiptNumber = NULL,
ReceiptType = NULL,
ReceiptBatch = NULL,
CheckNumber = NULL,
CheckAmount =NULL,
Charges = NULL,
Taxes = NULL,
Status = NULL,
UnallocatedCashBalance = NULL,
PostDate = NULL,
ReversalPostDate = NULL
WHERE GroupedOrder <> 1
UPDATE @ReceiptHistorySummary
SET Charges = NULL, Taxes = NULL, Due = NULL, Outstanding = NULL, ChargesTowardsInvoice = NULL, TaxesTowardsInvoice = NULL, Total = NULL
WHERE CustomerId IS NULL
SELECT
Currency,
CustomerNumber,
Customer,
ReceivedDate,
ReceiptNumber,
ReceiptType,
ReceiptBatch,
Status,
CheckNumber,
CheckAmount,
Charges,
Taxes,
UnallocatedCashBalance,
PostDate,
ReversalPostDate,
InvoiceNumber,
BillTo,
InvoiceDueDate,
Due,
Outstanding,
ChargesTowardsInvoice,
TaxesTowardsInvoice,
Total,
ReceivableType,
GroupedOrder
FROM
@ReceiptHistorySummary
DROP TABLE #ReceiptLevelSummary
DROP TABLE #ReceivableAmountApplied
DROP TABLE #ReceivableInvoiceSummary
DROP TABLE #ReceivableTaxApplied
DROP TABLE #ValidReceipts
DROP TABLE #CustomerLevelCharges
END

GO
