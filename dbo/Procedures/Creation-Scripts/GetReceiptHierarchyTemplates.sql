SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceiptHierarchyTemplates]
(
@JobStepInstanceId	BIGINT
)
AS
BEGIN
SELECT rht.Id, PreferenceOrder, ApplicationWithinReceivableGroups AS ApplicationWithinReceivableGroup,
TaxHandling INTO #ReceiptHierarchyTemplates FROM ReceiptHierarchyTemplates rht INNER JOIN
(SELECT DISTINCT ReceiptHierarchyTemplateId  FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND ReceiptHierarchyTemplateId IS NOT NULL ) distinctRHT
on rht.Id = distinctRHT.ReceiptHierarchyTemplateId

SELECT * FROM #ReceiptHierarchyTemplates

SELECT DISTINCT rht.id AS ReceiptHierarchyTemplateId, rpo.ReceivableTypeId, rpo.[Order], ReceivableTypes.[Name] AS ReceivableType
from ReceiptPostingOrders rpo INNER JOIN #ReceiptHierarchyTemplates rht
ON rpo.ReceiptHierarchyTemplateId = rht.Id
INNER JOIN ReceivableTypes ON rpo.ReceivableTypeId = ReceivableTypes.Id
END

GO
