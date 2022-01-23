SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CalculateRHTForReceiptsForExternalReceiptPosting]
(
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SET NOCOUNT ON

--Computing DefaultHierarchyTemplateId
DECLARE @DefaultHierarchyTemplateId BIGINT
SET @DefaultHierarchyTemplateId = (SELECT TOP 1 Id FROM ReceiptHierarchyTemplates WHERE IsActive=1 AND IsDefault=1)


SELECT Receipts_Extract.Id
INTO #ReceiptsForCalculation
FROM Receipts_Extract
INNER JOIN CommonExternalReceipt_Extract CEX 
	ON Receipts_Extract.ReceiptId = CEX.Id
	AND CEX.JobStepInstanceId = @JobStepInstanceId
	AND CEX.IsValid = 1	
GROUP BY Receipts_Extract.Id, CEX.ContractLegalEntityId

--#1:Computing ReceiptHierarchyTemplates of Lease/Loan Entity's Customer
UPDATE Receipts_Extract 
SET
Receipts_Extract.CustomerHierarchyTemplateId = C.ReceiptHierarchyTemplateId
FROM Receipts_Extract RE
INNER JOIN #ReceiptsForCalculation
	ON RE.Id = #ReceiptsForCalculation.Id 
INNER JOIN Customers C 
	ON RE.CustomerId=C.Id
WHERE RE.JobStepInstanceId=@JobStepInstanceId


--#2:Computing LegalEntityHierarchyTemplate Id
UPDATE Receipts_Extract
SET
Receipts_Extract.LegalEntityHierarchyTemplateId = LE.ReceiptHierarchyTemplateId
FROM Receipts_Extract RE 
INNER JOIN #ReceiptsForCalculation 
	ON RE.Id = #ReceiptsForCalculation.Id 
INNER JOIN LegalEntities LE	
	ON RE.LegalEntityId=LE.Id
WHERE RE.LegalEntityId IS NOT NULL
AND RE.JobStepInstanceId=@JobStepInstanceId



--Computing Main ReceiptHierarchyTemplateId
UPDATE Receipts_Extract SET
Receipts_Extract.ReceiptHierarchyTemplateId=
CASE
WHEN (RE.EntityType='Customer') 
	THEN
	CASE
		WHEN (RE.CustomerHierarchyTemplateId IS NOT NULL) THEN RE.CustomerHierarchyTemplateId
		WHEN (RE.LegalEntityHierarchyTemplateId IS NOT NULL) THEN RE.LegalEntityHierarchyTemplateId
		ELSE @DefaultHierarchyTemplateId
	END
WHEN (RE.EntityType='_') 
	THEN
	CASE
		WHEN (RE.LegalEntityHierarchyTemplateId IS NOT NULL) THEN RE.LegalEntityHierarchyTemplateId
		ELSE @DefaultHierarchyTemplateId
	END
END
FROM Receipts_Extract RE INNER JOIN
#ReceiptsForCalculation ON RE.Id = #ReceiptsForCalculation.Id
WHERE JobStepInstanceId=@JobStepInstanceId


EXEC GetReceiptHierarchyTemplates @JobStepInstanceId

IF OBJECT_ID('tempdb..#NonFullCashPostedReceipts') IS NOT NULL DROP TABLE #NonFullCashPostedReceipts;

SET NOCOUNT OFF
END

GO
