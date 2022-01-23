SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: 29-09-2016
-- exec GetPaymentHistoriesForContractService '9-7'
-- =============================================
CREATE PROCEDURE [dbo].[GetPaymentHistoriesForContractService]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ContractId AS BIGINT;
Declare @ContractType AS NVARCHAR(100);
SET @ContractId = (SELECT Id FROM Contracts WHERE SequenceNumber = @ContractSequenceNumber ) --50429;
SET @ContractType = (SELECT ContractType FROM Contracts WHERE SequenceNumber = @ContractSequenceNumber);
;WITH
CTE_GetInvoicedReceivables
AS
(
SELECT
ReceivableInvoices.Id ReceivableInvoicesId
,Case
when @ContractType = 'Loan' then  COALESCE(SUM(ReceivableDetails.Amount_Amount),0)
else COALESCE(SUM(ReceivableTaxDetails.Revenue_Amount),0)
End
as ReceivableAmount
,COALESCE(SUM(ReceivableTaxDetails.Amount_Amount),0) as TaxAmount
,MIN(ReceivableInvoices.DueDate) DueDate
,ReceivableTypes.Id ReceivableTypeId
FROM
Receivables
INNER JOIN ReceivableDetails
ON Receivables.Id = ReceivableDetails.ReceivableId
AND Receivables.IsActive = 1
AND Receivables.EntityId = @ContractId
AND Receivables.EntityType = 'CT'
AND ReceivableDetails.BilledStatus = 'Invoiced'
AND ReceivableDetails.IsActive = 1
INNER JOIN ReceivableInvoiceDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
AND ReceivableInvoiceDetails.IsActive = 1
INNER JOIN ReceivableInvoices
ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsDummy = 0
AND ReceivableInvoices.IsActive = 1
AND (@FilterCustomerId IS NULL OR ReceivableInvoices.CustomerId = @FilterCustomerId )
INNER JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
AND ReceivableCodes.IsActive = 1
INNER JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
AND ReceivableTypes.IsActive = 1
LEFT JOIN ReceivableTaxDetails
ON ReceivableTaxDetails.ReceivableDetailId = ReceivableDetails.Id
AND COALESCE(ISNULL(ReceivableDetails.AssetId,ReceivableTaxDetails.AssetId),0 ) = COALESCE(ReceivableTaxDetails.AssetId,0)
AND ReceivableTaxDetails.IsActive = 1
GROUP BY
ReceivableInvoices.Id
,ReceivableTypes.Id
HAVING
SUM(COALESCE(ReceivableTaxDetails.Balance_Amount ,0) + ReceivableDetails.Balance_Amount) = 0
)
,CTE_ReceivableReceiptDetails
AS
(
SELECT
Receipts.Id ReceiptId
,MIN(CTE_GetInvoicedReceivables.DueDate) DueDate
,MIN(CTE_GetInvoicedReceivables.ReceivableAmount) ReceivableAmount
,MIN(CTE_GetInvoicedReceivables.TaxAmount) TaxAmount
,CTE_GetInvoicedReceivables.ReceivableInvoicesId
,CTE_GetInvoicedReceivables.ReceivableTypeId ReceivableTypeId
,CAST(ReceiptApplicationReceivableDetails.CreatedTime as date) AppliedDate
FROM
CTE_GetInvoicedReceivables
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableInvoiceId = CTE_GetInvoicedReceivables.ReceivableInvoicesId
AND ReceiptApplicationReceivableDetails.IsActive = 1
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
INNER JOIN Receipts
ON Receipts.Id = ReceiptApplications.ReceiptId
AND Receipts.Status in ('Posted','Completed')
GROUP BY
Receipts.Id
,CTE_GetInvoicedReceivables.ReceivableInvoicesId
,CTE_GetInvoicedReceivables.ReceivableTypeId
,CAST(ReceiptApplicationReceivableDetails.CreatedTime as date)
)
,CTE_ReceiptDetails
AS
(
Select
CTE_ReceivableReceiptDetails.ReceivableInvoicesId
,MIN(CTE_ReceivableReceiptDetails.DueDate) DueDate
,MIN(CTE_ReceivableReceiptDetails.ReceivableAmount) ReceivableAmount
,MIN(CTE_ReceivableReceiptDetails.TaxAmount) TaxAmount
,CTE_ReceivableReceiptDetails.ReceivableTypeId
,STUFF((SELECT
DISTINCT ', ' + Receipts.CheckNumber
FROM
CTE_ReceivableReceiptDetails CTE_ReceivableReceiptDetails_Inner
JOIN Receipts
ON Receipts.Id = CTE_ReceivableReceiptDetails_Inner.ReceiptId
WHERE
CTE_ReceivableReceiptDetails_Inner.ReceivableInvoicesId = CTE_ReceivableReceiptDetails.ReceivableInvoicesId
AND CTE_ReceivableReceiptDetails_Inner.AppliedDate = CTE_ReceivableReceiptDetails.AppliedDate
GROUP BY
Receipts.CheckNumber
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
, 1, 1, '') CheckNumber
,STUFF((SELECT
DISTINCT ', ' + Name
FROM
CTE_ReceivableReceiptDetails CTE_ReceivableReceiptDetails_Inner
JOIN Receipts
ON Receipts.Id =  CTE_ReceivableReceiptDetails_Inner.ReceiptId
JOIN ReceiptBatches
ON ReceiptBatches.Id = Receipts.ReceiptBatchId
WHERE
CTE_ReceivableReceiptDetails_Inner.ReceivableInvoicesId = CTE_ReceivableReceiptDetails.ReceivableInvoicesId
AND CTE_ReceivableReceiptDetails_Inner.AppliedDate = CTE_ReceivableReceiptDetails.AppliedDate
GROUP BY
ReceiptBatches.Name
,CTE_ReceivableReceiptDetails_Inner.ReceiptId
,CTE_ReceivableReceiptDetails_Inner.AppliedDate
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
, 1, 1, '')
BatchName
,STUFF((SELECT
DISTINCT ', ' + CAST(Receipts.Id AS VARCHAR(100))
FROM
CTE_ReceivableReceiptDetails CTE_ReceivableReceiptDetails_Inner
JOIN Receipts
ON Receipts.Id = CTE_ReceivableReceiptDetails_Inner.ReceiptId
WHERE
CTE_ReceivableReceiptDetails_Inner.ReceivableInvoicesId = CTE_ReceivableReceiptDetails.ReceivableInvoicesId
AND CTE_ReceivableReceiptDetails_Inner.AppliedDate = CTE_ReceivableReceiptDetails.AppliedDate
GROUP BY
Receipts.Id
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
, 1, 1, '')
ReceiptIds
,CTE_ReceivableReceiptDetails.AppliedDate
FROM
CTE_ReceivableReceiptDetails
GROUP BY
CTE_ReceivableReceiptDetails.ReceivableInvoicesId
,CTE_ReceivableReceiptDetails.AppliedDate
,CTE_ReceivableReceiptDetails.ReceivableTypeId
)
SELECT
ReceivableInvoices.Number as InvoiceNumber
,ReceivableTypes.Name as ReceivableType
,CTE_ReceiptDetails.DueDate
,CTE_ReceiptDetails.ReceivableAmount
,CTE_ReceiptDetails.TaxAmount
,CTE_ReceiptDetails.ReceivableAmount + CTE_ReceiptDetails.TaxAmount  TotalAmount
,CAST(CTE_ReceiptDetails.AppliedDate AS DATE) AS AppliedDate
,COALESCE(CTE_ReceiptDetails.BatchName,'') Batch
,COALESCE(CTE_ReceiptDetails.CheckNumber,'') CheckNumber
,COALESCE(CTE_ReceiptDetails.ReceiptIds,'') ReceiptIds
,ReceivableInvoices.Balance_Currency Currency
,ReceivableInvoices.InvoiceFile_Source
,ReceivableInvoices.InvoiceFile_Type
,ReceivableInvoices.InvoiceFile_Content
,Parties.PartyNumber [CustomerNumber]
FROM
CTE_ReceiptDetails
INNER JOIN ReceivableInvoices
ON ReceivableInvoices.Id = CTE_ReceiptDetails.ReceivableInvoicesId
INNER JOIN Parties ON
ReceivableInvoices.CustomerId = Parties.Id
INNER JOIN ReceivableTypes
ON ReceivableTypes.Id = CTE_ReceiptDetails.ReceivableTypeId
END

GO
