SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CalculateAndFetchLockBoxHierarchyTemplateDetails]
(
@JobStepInstanceId						BIGINT,
@ReceiptEntityTypeValues_Customer		NVARCHAR(10),
@ReceiptEntityTypeValues_Lease			NVARCHAR(10),
@ReceiptEntityTypeValues_Loan			NVARCHAR(10),
@ReceiptEntityTypeValues_Discounting	NVARCHAR(15),
@ReceiptEntityTypeValues_Unknown		NVARCHAR(10)
)
AS
BEGIN
--Computing DefaultHierarchyTemplateId
DECLARE @DefaultHierarchyTemplateId BIGINT
SET @DefaultHierarchyTemplateId = (SELECT TOP 1 Id FROM ReceiptHierarchyTemplates WHERE IsActive=1 AND IsDefault=1)
CREATE TABLE #ReceiptsExtract(
[ExtractId] [bigint] NULL,
[ReceiptId] [bigint] NULL,
[ReceiptClassification] [nvarchar](23) NULL,
[LegalEntityId] [bigint] NULL,
[ContractId] [bigint] NULL,
[DiscountingId] [bigint] NULL,
[DumpId] [bigint] NULL,
[ContractLegalEntityId] [bigint] NULL,
[EntityType] [nvarchar](14) NULL,
[CustomerId] [bigint] NULL,
[LegalEntityHierarchyTemplateId] [bigint] NULL,
[ContractHierarchyTemplateId] [bigint] NULL,
[CustomerHierarchyTemplateId] [bigint] NULL,
[ContractLegalEntityHierarchyTemplateId] [bigint] NULL,
[ReceiptHierarchyTemplateId] [bigint] NULL
)
SELECT
Receipts_Extract.Id, RPBL.LegalEntityId AS ContractLegalEntityId
INTO #NonFullCashPostedReceipts
FROM Receipts_Extract
INNER JOIN ReceiptPostByLockBox_Extract RPBL
ON Receipts_Extract.DumpId = RPBL.Id
AND RPBL.JobStepInstanceId = @JobStepInstanceId
WHERE
RPBL.IsNonAccrualLoan=0 AND (RPBL.IsFullPosting = 0	OR RPBL.HasMoreInvoice = 1)
--Insert Cash Receipt Data from RE
INSERT INTO #ReceiptsExtract
SELECT
RE.Id,
Re.ReceiptId,
RE.ReceiptClassification,
Re.LegalEntityId,
RE.ContractId,
RE.DiscountingId,
RE.DumpId,
NFC.ContractLegalEntityId,
RE.EntityType,
RE.CustomerId,
NULL,
NULL,
NULL,
NULL,
NULL
FROM Receipts_Extract RE INNER JOIN #NonFullCashPostedReceipts NFC
ON RE.Id = NFC.Id
--Insert Non-Accrual Data from RPBL
INSERT INTO #ReceiptsExtract
SELECT
NULL,
RPBL.LockBoxReceiptId,
RPBL.ReceiptClassification,
RPBL.LegalEntityId,
RPBL.ContractId,
NULL,
RPBL.Id,
RPBL.LegalEntityId,
RPBL.EntityType,
RPBL.CustomerId,
NULL,
NULL,
NULL,
NULL,
NULL
FROM ReceiptPostByLockBox_Extract AS RPBL
WHERE RPBL.JobStepInstanceId = @JobStepInstanceId
AND RPBL.IsValid = 1
AND RPBL.IsNonAccrualLoan=1
--Computing ReceiptHierarchyTemplates of Lease/Loan/Discounting Entity's Legal Entity
UPDATE RD
SET ContractLegalEntityHierarchyTemplateId=LE.ReceiptHierarchyTemplateId
FROM #ReceiptsExtract RD
INNER JOIN LegalEntities LE ON RD.ContractLegalEntityId = LE.Id
WHERE RD.LegalEntityId IS NOT NULL
AND RD.EntityType != @ReceiptEntityTypeValues_Customer
AND RD.EntityType != @ReceiptEntityTypeValues_Unknown
--Computing LegalEntityHierarchyTemplate Id
UPDATE RD
SET RD.LegalEntityHierarchyTemplateId=LE.ReceiptHierarchyTemplateId
FROM #ReceiptsExtract RD
INNER JOIN LegalEntities LE ON RD.LegalEntityId=LE.Id
WHERE RD.LegalEntityId IS NOT NULL
AND (RD.EntityType = @ReceiptEntityTypeValues_Customer
OR RD.EntityType = @ReceiptEntityTypeValues_Unknown )
--Computing ReceiptHierarchyTemplates of Lease/Loan Entity's Customer
UPDATE RD
SET RD.CustomerHierarchyTemplateId=C.ReceiptHierarchyTemplateId
FROM #ReceiptsExtract RD
INNER JOIN Customers C ON RD.CustomerId = C.Id
UPDATE RD
SET RD.ContractHierarchyTemplateId =CTR.ReceiptHierarchyTemplateId
FROM #ReceiptsExtract RD
INNER JOIN Contracts AS CTR ON RD.ContractId = CTR.Id
INNER JOIN LeaseFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent = 1
WHERE RD.EntityType = @ReceiptEntityTypeValues_Lease
UPDATE RD
SET RD.ContractHierarchyTemplateId =CTR.ReceiptHierarchyTemplateId
FROM #ReceiptsExtract RD
INNER JOIN Contracts AS CTR ON RD.ContractId =CTR.Id
INNER JOIN LoanFinances AS LF ON LF.ContractId = CTR.Id AND LF.IsCurrent=1
WHERE RD.EntityType = @ReceiptEntityTypeValues_Loan
--Computing Main ReceiptHierarchyTemplateId
UPDATE #ReceiptsExtract SET
#ReceiptsExtract.ReceiptHierarchyTemplateId=
CASE
WHEN (#ReceiptsExtract.EntityType=@ReceiptEntityTypeValues_Discounting) THEN
CASE
WHEN (#ReceiptsExtract.ContractLegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.ContractLegalEntityHierarchyTemplateId
WHEN (#ReceiptsExtract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (#ReceiptsExtract.EntityType=@ReceiptEntityTypeValues_Lease OR #ReceiptsExtract.EntityType=@ReceiptEntityTypeValues_Loan) THEN
CASE
WHEN (#ReceiptsExtract.ContractHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.ContractHierarchyTemplateId
WHEN (#ReceiptsExtract.CustomerHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.CustomerHierarchyTemplateId
WHEN (#ReceiptsExtract.ContractLegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.ContractLegalEntityHierarchyTemplateId
WHEN (#ReceiptsExtract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (#ReceiptsExtract.EntityType=@ReceiptEntityTypeValues_Customer) THEN
CASE
WHEN (#ReceiptsExtract.CustomerHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.CustomerHierarchyTemplateId
WHEN (#ReceiptsExtract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
WHEN (#ReceiptsExtract.EntityType=@ReceiptEntityTypeValues_Unknown) THEN
CASE
WHEN (#ReceiptsExtract.LegalEntityHierarchyTemplateId IS NOT NULL) THEN #ReceiptsExtract.LegalEntityHierarchyTemplateId
ELSE @DefaultHierarchyTemplateId
END
END
FROM #ReceiptsExtract
--Update the HierarchyTemplateIds found for all Cash Receipts to Receipts_Extract
UPDATE RE SET
RE.ContractHierarchyTemplateId=RD.ContractHierarchyTemplateId,
RE.ContractLegalEntityHierarchyTemplateId=RD.ContractLegalEntityHierarchyTemplateId,
RE.LegalEntityHierarchyTemplateId=RD.LegalEntityHierarchyTemplateId,
RE.CustomerHierarchyTemplateId=RD.CustomerHierarchyTemplateId,
RE.ReceiptHierarchyTemplateId=RD.ReceiptHierarchyTemplateId
FROM Receipts_Extract RE
INNER JOIN #ReceiptsExtract RD ON RE.Id=RD.ExtractId AND RD.ExtractId IS NOT NULL
--Finding out RHT For All receipts
select rht.Id, PreferenceOrder, ApplicationWithinReceivableGroups as ApplicationWithinReceivableGroup,
TaxHandling into #ReceiptHierarchyTemplates from ReceiptHierarchyTemplates rht INNER JOIN
(Select distinct ReceiptHierarchyTemplateId From #ReceiptsExtract where ReceiptHierarchyTemplateId IS NOT NULL) distinctRHT
on rht.Id = distinctRHT.ReceiptHierarchyTemplateId
--Fetch RHT for all receipts
SELECT * FROM #ReceiptHierarchyTemplates
--Fetch Posting Orders
select distinct rht.id as ReceiptHierarchyTemplateId, rpo.ReceivableTypeId, rpo.[Order], ReceivableTypes.[Name] as ReceivableType
from ReceiptPostingOrders rpo INNER JOIN #ReceiptHierarchyTemplates rht
ON rpo.ReceiptHierarchyTemplateId = rht.Id
INNER JOIN ReceivableTypes ON rpo.ReceivableTypeId = ReceivableTypes.Id
--Fetch Non-Accrual Receipts' Hierarchy Template Ids
SELECT
DumpId,
ReceiptHierarchyTemplateId
FROM #ReceiptsExtract
WHERE ReceiptClassification='NonAccrualNonDSL' AND ExtractId IS NULL
DROP TABLE #NonFullCashPostedReceipts
DROP TABLE #ReceiptsExtract
DROP TABLE #ReceiptHierarchyTemplates
END

GO
