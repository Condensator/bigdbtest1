SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceiptApplicationReceivableInfoForReceipt]
@ReceiptId BIGINT
AS
BEGIN

SELECT
ReceiptApplicationReceivableDetails.ReceivableDetailId
,Max(ReceiptApplicationReceivableDetails.ReceivableInvoiceId) ReceivableInvoiceId,
Max(ReceivableInvoices.Number) Number,
Sum(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied_Amount,
Sum(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied_Amount,
Sum(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount) AS AdjustedWithholdingTax_Amount
INTO #ReceivableDetailSummary
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
left join ReceivableInvoices ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId = ReceivableInvoices.Id
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive=1
GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId
HAVING (Sum(ReceiptApplicationReceivableDetails.AmountApplied_Amount) <> 0 OR Sum(ReceiptApplicationReceivableDetails.TaxApplied_Amount) <> 0 OR Sum(ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount) <> 0)

SELECT DISTINCT
ReceivableDetails.Id AS ReceivableDetailId,
Receivables.Id AS ReceivableId,
ReceivableDetails.AssetId AS AssetId,
Receivables.DueDate AS DueDate,
Funders.PartyName AS FunderName,
Contracts.SequenceNumber AS SequenceNumber,
ReceivableTypes.Name AS ReceivableType,
ReceivableDetails.Amount_Amount AS ReceivableAmount,
ReceivableDetails.Balance_Amount AS Balance,
ReceivableDetails.EffectiveBalance_Amount AS EffectiveReceivableBalance,
TaxDetails.Amount_Amount AS TaxAmount,
TaxDetails.Balance_Amount AS TaxBalance,
TaxDetails.EffectiveBalance_Amount AS EffectiveTaxBalance,
ReceivableDetails.Amount_Currency AS Currency,
#ReceivableDetailSummary.Number AS InvoiceNumber,
#ReceivableDetailSummary.AmountApplied_Amount AS AmountApplied,
#ReceivableDetailSummary.TaxApplied_Amount AS TaxApplied,
#ReceivableDetailSummary.AdjustedWithholdingTax_Amount AS AdjustedWithHoldingTax,
WHT.EffectiveBalance_Amount AS WithHoldingTaxBalance,
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
#ReceivableDetailSummary.ReceivableInvoiceId as ReceivableInvoiceId,
Receivables.ReceivableTaxType AS ReceivableTaxType
FROM ReceivableDetails
JOIN #ReceivableDetailSummary ON ReceivableDetails.Id = #ReceivableDetailSummary.ReceivableDetailId
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
LEFT JOIN
(SELECT ReceivableTaxDetails.ReceivableDetailId,
--SUM(ReceivableTaxImpositions.Amount_Amount) AS Amount_Amount,
SUM(ReceivableTaxDetails.Amount_Amount) AS Amount_Amount,
--SUM(ReceivableTaxImpositions.Balance_Amount) AS Balance_Amount,
SUM(ReceivableTaxDetails.Balance_Amount) AS Balance_Amount,
--SUM(ReceivableTaxImpositions.EffectiveBalance_Amount) AS EffectiveBalance_Amount
SUM(ReceivableTaxDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount
FROM ReceivableTaxDetails
JOIN #ReceivableDetailSummary ON ReceivableTaxDetails.ReceivableDetailId = #ReceivableDetailSummary.ReceivableDetailId
JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id
--JOIN ReceivableTaxImpositions ON ReceivableTaxDetails.Id = ReceivableTaxImpositions.ReceivableTaxDetailId
WHERE ReceivableTaxDetails.IsActive = 1
AND ReceivableTaxes.IsActive=1
GROUP BY ReceivableTaxDetails.ReceivableDetailId
) AS TaxDetails ON ReceivableDetails.Id = TaxDetails.ReceivableDetailId
LEFT JOIN Contracts ON Receivables.EntityId = Contracts.Id AND Receivables.EntityType = 'CT'
LEFT JOIN Parties AS Funders ON Receivables.FunderId = Funders.Id
LEFT JOIN ReceivableDetailsWithholdingTaxDetails WHT ON ReceivableDetails.Id=WHT.ReceivableDetailId AND WHT.IsActive=1

DROP TABLE #ReceivableDetailSummary;
END

GO
