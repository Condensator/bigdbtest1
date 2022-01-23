SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptApplicationDetailsForLockBoxReconciliationReport]
(
@ReceiptNumber NVARCHAR(MAX),
@ShowReceiptApplicationDetails BIT
)
AS
--DECLARE @ReceiptNumber NVARCHAR(MAX)
--SET @ReceiptNumber='5299'
BEGIN
SELECT
ReceivableType=ReceivableTypes.Name
,ContractType=CASE WHEN Receipts.EntityType in ('Lease','Loan','LeveragedLease') THEN Receipts.EntityType
ELSE '' END
,SequenceNumber=CASE WHEN Receipts.EntityType in ('Lease','Loan','LeveragedLease') THEN Contracts.SequenceNumber
ELSE '' END
,InvoiceNumber=ReceivableInvoices.Number
,InvoicedAmount=ReceivableInvoices.InvoiceAmount_Amount
,InvoicedAmountCurrency=ReceivableInvoices.InvoiceAmount_Currency
,InvoiceDueDate=ReceivableInvoices.DueDate
,Charges=ReceiptApplicationReceivableDetails.AmountApplied_Amount
,ChargesCurrency=ReceiptApplicationReceivableDetails.AmountApplied_Currency
,Taxes=ReceiptApplicationReceivableDetails.TaxApplied_Amount
,TaxesCurrency=ReceiptApplicationReceivableDetails.TaxApplied_Currency
,Total=ReceiptApplicationReceivableDetails.AmountApplied_Amount+ReceiptApplicationReceivableDetails.TaxApplied_Amount
FROM
Receipts
INNER JOIN ReceiptApplications ON ReceiptApplications.ReceiptId=Receipts.Id
AND Receipts.Number=@ReceiptNumber
INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
AND ReceiptApplicationReceivableDetails.IsActive=1
INNER JOIN ReceivableDetails ON ReceivableDetails.Id=ReceiptApplicationReceivableDetails.ReceivableDetailId
AND ReceivableDetails.IsActive=1
INNER JOIN Receivables ON Receivables.Id=ReceivableDetails.ReceivableId
INNER JOIN ReceivableInvoices ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId=ReceivableInvoices.Id
LEFT JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
AND ReceivableCodes.IsActive=1
LEFT JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
AND ReceivableTypes.IsActive=1
LEFT JOIN Contracts ON Contracts.Id=Receipts.ContractId
WHERE  @ShowReceiptApplicationDetails = 1
END

GO
