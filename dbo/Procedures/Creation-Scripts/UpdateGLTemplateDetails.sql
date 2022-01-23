SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateGLTemplateDetails]
(
@JobStepInstanceId BIGINT
)
AS
SET NOCOUNT ON;
BEGIN
SELECT
DISTINCT RD.LegalEntityId
INTO #LegalEntityIds
FROM SalesTaxReceivableDetailExtract RD
WHERE RD.JobStepInstanceId = @JobStepInstanceId
SELECT
RD.LegalEntityId,
LE.Name AS LegalEntityName,
MAX(GLT.Id) AS GLTemplateId
INTO #LegalEntityGLInfo
FROM #LegalEntityIds RD
INNER JOIN LegalEntities LE ON LE.Id = RD.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
GROUP BY
RD.LegalEntityId,
LE.Name
UPDATE RD SET GLTemplateId = GL.GLTemplateId, LegalEntityName = GL.LegalEntityName
FROM #LegalEntityGLInfo GL
INNER JOIN SalesTaxReceivableDetailExtract RD ON GL.LegalEntityId = RD.LegalEntityId AND RD.JobStepInstanceId = @JobStepInstanceId;
UPDATE RD SET LegalEntityName = L.Name
FROM LegalEntities L INNER JOIN SalesTaxReceivableDetailExtract RD ON L.Id = RD.LegalEntityId AND RD.JobStepInstanceId = @JobStepInstanceId AND RD.LegalEntityName IS NULL;
END
DROP Table #LegalEntityIds;
DROP Table #LegalEntityGLInfo;

GO
