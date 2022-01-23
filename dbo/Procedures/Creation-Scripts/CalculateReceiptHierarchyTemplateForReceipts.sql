SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CalculateReceiptHierarchyTemplateForReceipts]
(
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SET NOCOUNT ON
--Computing DefaultHierarchyTemplateId
DECLARE @DefaultHierarchyTemplateId BIGINT
SET @DefaultHierarchyTemplateId = (SELECT TOP 1 Id FROM ReceiptHierarchyTemplates WHERE IsActive=1 AND IsDefault=1)

SELECT * INTO #NonFullCashPostedReceipts FROM (
SELECT Receipts_Extract.Id, ReceiptPostByFileExcel_Extract.ComputedContractLegalEntityId as ContractLegalEntityId
FROM Receipts_Extract
INNER JOIN ReceiptPostByFileExcel_Extract ON Receipts_Extract.ReceiptId = ReceiptPostByFileExcel_Extract.GroupNumber
AND ReceiptPostByFileExcel_Extract.JobStepInstanceId = @JobStepInstanceId
WHERE ReceiptPostByFileExcel_Extract.ComputedIsFullPosting = 0
OR ReceiptPostByFileExcel_Extract.IsInvoiceInMultipleReceipts = 1
OR ReceiptPostByFileExcel_Extract.NonAccrualCategory = 'SingleWithOnlyNonRentals'
OR ReceiptPostByFileExcel_Extract.NonAccrualCategory = 'GroupedNonRentals'
GROUP BY Receipts_Extract.Id, ReceiptPostByFileExcel_Extract.ComputedContractLegalEntityId

UNION

SELECT Receipts_Extract.Id, ReceiptPostByFileExcel_Extract.ComputedContractLegalEntityId as ContractLegalEntityId
FROM Receipts_Extract
INNER JOIN ReceiptPostByFileExcel_Extract ON Receipts_Extract.DumpId = ReceiptPostByFileExcel_Extract.GroupNumber AND Receipts_Extract.ReceiptClassification = 'Cash'
AND ReceiptPostByFileExcel_Extract.JobStepInstanceId = @JobStepInstanceId
WHERE ReceiptPostByFileExcel_Extract.ComputedIsFullPosting = 0
OR ReceiptPostByFileExcel_Extract.IsInvoiceInMultipleReceipts = 1
OR ReceiptPostByFileExcel_Extract.NonAccrualCategory = 'SingleWithOnlyNonRentals'
OR ReceiptPostByFileExcel_Extract.NonAccrualCategory = 'GroupedNonRentals'
GROUP BY Receipts_Extract.Id, ReceiptPostByFileExcel_Extract.ComputedContractLegalEntityId
) AS T

--Computing ReceiptHierarchyTemplates of Lease/Loan/Discounting Entity's Legal Entity
UPDATE Receipts_Extract SET
Receipts_Extract.ContractLegalEntityHierarchyTemplateId=LE.ReceiptHierarchyTemplateId
FROM Receipts_Extract ReceiptDetails INNER JOIN
#NonFullCashPostedReceipts ON ReceiptDetails.Id = #NonFullCashPostedReceipts.Id INNER JOIN
LegalEntities LE ON #NonFullCashPostedReceipts.ContractLegalEntityId=LE.Id
WHERE ReceiptDetails.LegalEntityId IS NOT NULL AND ReceiptDetails.EntityType!='Customer'
AND ReceiptDetails.EntityType!='_'
AND ReceiptDetails.JobStepInstanceId=@JobStepInstanceId

--Computing LegalEntityHierarchyTemplate Id
UPDATE Receipts_Extract SET
Receipts_Extract.LegalEntityHierarchyTemplateId=LE.ReceiptHierarchyTemplateId
FROM Receipts_Extract ReceiptDetails INNER JOIN
#NonFullCashPostedReceipts ON ReceiptDetails.Id = #NonFullCashPostedReceipts.Id INNER JOIN
LegalEntities LE ON ReceiptDetails.LegalEntityId=LE.Id
WHERE ReceiptDetails.LegalEntityId IS NOT NULL
AND ReceiptDetails.JobStepInstanceId=@JobStepInstanceId

--Computing ReceiptHierarchyTemplates of Lease/Loan Entity's Customer
UPDATE Receipts_Extract SET
Receipts_Extract.CustomerHierarchyTemplateId=C.ReceiptHierarchyTemplateId
FROM Receipts_Extract ReceiptDetails INNER JOIN
#NonFullCashPostedReceipts ON ReceiptDetails.Id = #NonFullCashPostedReceipts.Id INNER JOIN
Customers C ON ReceiptDetails.CustomerId=C.Id
WHERE ReceiptDetails.JobStepInstanceId=@JobStepInstanceId

UPDATE Receipts_Extract SET
Receipts_Extract.ContractHierarchyTemplateId =CTR.ReceiptHierarchyTemplateId
FROM Receipts_Extract ReceiptDetails INNER JOIN
#NonFullCashPostedReceipts ON ReceiptDetails.Id = #NonFullCashPostedReceipts.Id INNER JOIN
Contracts AS CTR ON ReceiptDetails.ContractId =CTR.Id
INNER JOIN LeaseFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent=1
WHERE ReceiptDetails.EntityType='Lease'

UPDATE Receipts_Extract SET
Receipts_Extract.ContractHierarchyTemplateId =CTR.ReceiptHierarchyTemplateId
FROM Receipts_Extract ReceiptDetails INNER JOIN
#NonFullCashPostedReceipts ON ReceiptDetails.Id = #NonFullCashPostedReceipts.Id INNER JOIN
Contracts AS CTR ON ReceiptDetails.ContractId =CTR.Id
INNER JOIN LoanFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent=1
WHERE ReceiptDetails.EntityType='Loan'

--Computing Main ReceiptHierarchyTemplateId
UPDATE Receipts_Extract SET
Receipts_Extract.ReceiptHierarchyTemplateId=
CASE
WHEN (Receipts_Extract.EntityType='Discounting') THEN
CASE
WHEN (Receipts_Extract.ContractLegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.ContractLegalEntityHierarchyTemplateId
WHEN (Receipts_Extract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (Receipts_Extract.EntityType='Lease' OR Receipts_Extract.EntityType='Loan') THEN
CASE
WHEN (Receipts_Extract.ContractHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.ContractHierarchyTemplateId
WHEN (Receipts_Extract.CustomerHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.CustomerHierarchyTemplateId
WHEN (Receipts_Extract.ContractLegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.ContractLegalEntityHierarchyTemplateId
WHEN (Receipts_Extract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (Receipts_Extract.EntityType='Customer') THEN
CASE
WHEN (Receipts_Extract.CustomerHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.CustomerHierarchyTemplateId
WHEN (Receipts_Extract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (Receipts_Extract.EntityType='_') THEN
CASE
WHEN (Receipts_Extract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN Receipts_Extract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
END
FROM Receipts_Extract INNER JOIN
#NonFullCashPostedReceipts ON Receipts_Extract.Id = #NonFullCashPostedReceipts.Id
WHERE JobStepInstanceId=@JobStepInstanceId
AND (Receipts_Extract.ReceiptClassification!='NonAccrualNonDSL' AND Receipts_Extract.ReceiptClassification!='NonAccrualNonDSLNonCash')

EXEC GetReceiptHierarchyTemplates @JobStepInstanceId

IF OBJECT_ID('tempdb..#NonFullCashPostedReceipts') IS NOT NULL DROP TABLE #NonFullCashPostedReceipts;

SET NOCOUNT OFF
END

GO
