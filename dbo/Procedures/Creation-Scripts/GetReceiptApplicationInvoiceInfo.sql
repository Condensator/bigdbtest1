SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReceiptApplicationInvoiceInfo]
@ReceiptId BIGINT,
@ApplicationId BIGINT,
@InvoiceIds InvoiceIdCollection READONLY,
@ContractId BIGINT
AS
BEGIN
SET NOCOUNT ON
SELECT InvoiceId AS InvoiceId
INTO #InvoiceIds
FROM @InvoiceIds
SELECT  ReceivableInvoices.Id AS ReceivableInvoiceId,
ReceivableInvoices.Number AS InvoiceNumber,
ReceivableInvoices.DueDate AS DueDate,
InvoiceTypes.Name AS InvoiceType,
ReceivableInvoices.InvoicePreference AS InvoicePreference,
RemitToes.Name AS RemitTo,
BillToes.Name AS BillToe,
ISNULL(SUM(ReceivableInvoiceDetails.InvoiceAmount_Amount), 0.0) AS OriginalAmount,
ISNULL(SUM(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount), 0.0) AS OriginalTaxAmount,
ISNULL(SUM(ReceivableInvoiceDetails.TaxBalance_Amount), 0.0) AS TaxBalance,
ISNULL(SUM(ReceivableInvoiceDetails.Balance_Amount), 0.0) AS Balance,
ISNULL(PreviousAmountApplied_Amount, 0.0) AS PreviousApplication,
ISNULL(PreviousTaxApplied_Amount, 0.0) AS PreviousTaxApplication,
ISNULL(InProgressAmountApplied_Amount, 0.0) AS InProgressAmount,
ISNULL(InProgressTaxApplied_Amount, 0.0) AS InProgressTaxAmount,
ReceivableInvoices.Balance_Currency AS Currency,
CASE WHEN (0 > ISNULL(MAX(ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount), 0.0)) THEN 1 ELSE 0 END AS IsNegativeInvoice,
ISNULL(OutstandingAmount.OutstandingReceivableAmount, 0.0) - ISNULL(InProgressAmountApplied_Amount, 0.0) AS OutstandingReceivableAmount,
ISNULL(OutstandingAmount.OutstandingTaxAmount, 0.0) - ISNULL(InProgressTaxApplied_Amount, 0.0) AS OutstandingTaxAmount,
ISNULL(TotalCreditAmount.CreditAmount, 0.0) AS TotalCreditAmount,
ISNULL(SUM(ISNULL(ReceivableInvoiceDetails.InvoiceAmount_Amount, 0.0) + ISNULL(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount, 0.0)), 0.0) AS TotalAmount,
LegalEntities.LegalEntityNumber AS LegalEntityNumber
FROM ReceivableInvoices
JOIN #InvoiceIds ON ReceivableInvoices.Id = #InvoiceIds.InvoiceId
JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
AND ReceivableInvoices.IsActive = 1 AND ReceivableInvoiceDetails.IsActive = 1 AND ReceivableInvoices.IsDummy = 0
JOIN BillToes ON ReceivableInvoices.BillToId = BillToes.Id
JOIN RemitToes ON ReceivableInvoices.RemitToId = RemitToes.Id
JOIN ReceivableCategories ON ReceivableInvoiceDetails.ReceivableCategoryId = ReceivableCategories.Id
JOIN Parties ON ReceivableInvoices.CustomerId = Parties.Id
JOIN Customers ON ReceivableInvoices.CustomerId = Customers.Id
JOIN LegalEntities ON ReceivableInvoices.LegalEntityId = LegalEntities.Id
JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(SUM(ReceivableInvoiceDetails.Balance_Amount), 0.0) AS OutstandingReceivableAmount,
ISNULL(SUM(ReceivableInvoiceDetails.TaxBalance_Amount), 0.0) AS OutstandingTaxAmount
FROM  #InvoiceIds
LEFT JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableInvoiceId = #InvoiceIds.InvoiceId
AND ReceivableInvoiceDetails.IsActive = 1
AND ((ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) > 0
OR (ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) > 0)
GROUP BY #InvoiceIds.InvoiceId, ReceivableInvoiceDetails.ReceivableInvoiceId) AS OutstandingAmount ON ReceivableInvoices.Id = OutstandingAmount.ReceivableInvoiceId
JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(SUM(ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount), 0.0) AS CreditAmount
FROM #InvoiceIds
LEFT JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableInvoiceId = #InvoiceIds.InvoiceId
AND ReceivableInvoiceDetails.IsActive = 1
AND ((ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) < 0
OR (ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) < 0)
GROUP BY #InvoiceIds.InvoiceId, ReceivableInvoiceDetails.ReceivableInvoiceId) AS TotalCreditAmount ON ReceivableInvoices.Id = TotalCreditAmount.ReceivableInvoiceId
JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(PreviousAmountApplied_Amount, 0.0) AS PreviousAmountApplied_Amount,
ISNULL(PreviousTaxApplied_Amount, 0.0) AS PreviousTaxApplied_Amount
FROM #InvoiceIds
LEFT JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(SUM(ReceiptApplicationInvoices.AmountApplied_Amount), 0.0) AS PreviousAmountApplied_Amount,
ISNULL(SUM(ReceiptApplicationInvoices.TaxApplied_Amount), 0.0) AS PreviousTaxApplied_Amount
FROM #InvoiceIds
JOIN ReceiptApplicationInvoices ON ReceiptApplicationInvoices.ReceivableInvoiceId = #InvoiceIds.InvoiceId
JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationInvoices.ReceiptApplicationId
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE ReceiptApplicationInvoices.IsActive = 1
AND (@ApplicationId IS NULL OR @ApplicationId = 0)
AND (@ReceiptId IS NOT NULL AND ReceiptApplications.ReceiptId = @ReceiptId)
AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting')
GROUP BY #InvoiceIds.InvoiceId, ReceiptApplicationInvoices.ReceivableInvoiceId) AS PreviousAmount ON PreviousAmount.ReceivableInvoiceId = #InvoiceIds.InvoiceId
) AS PreviousApplications ON ReceivableInvoices.Id = PreviousApplications.ReceivableInvoiceId
JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(InProgressAmountApplied_Amount, 0.0) AS InProgressAmountApplied_Amount,
ISNULL(InProgressTaxApplied_Amount, 0.0) AS InProgressTaxApplied_Amount
FROM #InvoiceIds
LEFT JOIN
(SELECT #InvoiceIds.InvoiceId AS ReceivableInvoiceId,
ISNULL(SUM(ReceiptApplicationInvoices.AmountApplied_Amount), 0.0) AS InProgressAmountApplied_Amount,
ISNULL(SUM(ReceiptApplicationInvoices.TaxApplied_Amount), 0.0) AS InProgressTaxApplied_Amount
FROM #InvoiceIds
JOIN ReceiptApplicationInvoices ON ReceiptApplicationInvoices.ReceivableInvoiceId = #InvoiceIds.InvoiceId
AND ReceiptApplicationInvoices.IsActive = 1
JOIN ReceiptApplications ON ReceiptApplicationInvoices.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE (Receipts.Status = 'Pending' OR Receipts.Status = 'Submitted' OR Receipts.Status = 'ReadyForPosting')
AND (@ApplicationId IS NOT NULL AND ReceiptApplicationInvoices.ReceiptApplicationId != @ApplicationId)
GROUP BY #InvoiceIds.InvoiceId, ReceiptApplicationInvoices.ReceivableInvoiceId)
AS InProgressInvoice ON #InvoiceIds.InvoiceId = InProgressInvoice.ReceivableInvoiceId)
AS InProgressInvoiceAmount ON  ReceivableInvoices.Id  = InProgressInvoiceAmount.ReceivableInvoiceId
LEFT JOIN InvoiceTypes ON ReceivableCategories.InvoiceTypeId = InvoiceTypes.Id
LEFT JOIN Contracts ON ReceivableInvoiceDetails.EntityId = Contracts.Id AND ReceivableInvoiceDetails.EntityType = 'CT'
WHERE (@ContractId IS NULL OR @ContractId = Contracts.Id)
GROUP BY
ReceivableInvoices.Id,
LegalEntities.LegalEntityNumber,
ReceivableInvoices.Number,
ReceivableInvoices.DueDate,
InvoiceTypes.Name,
ReceivableInvoices.InvoicePreference,
RemitToes.Name,
BillToes.Name,
ReceivableInvoices.Balance_Currency,
PreviousAmountApplied_Amount,
PreviousTaxApplied_Amount,
InProgressAmountApplied_Amount,
InProgressTaxApplied_Amount,
OutstandingAmount.OutstandingReceivableAmount,
OutstandingAmount.OutstandingTaxAmount,
TotalCreditAmount.CreditAmount
DROP TABLE #InvoiceIds;
END

GO
