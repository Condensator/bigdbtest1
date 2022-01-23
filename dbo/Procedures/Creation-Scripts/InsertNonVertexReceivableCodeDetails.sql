SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexReceivableCodeDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
WITH CTE_DistinctReceivableCodes AS
(
SELECT  DISTINCT
RD.ReceivableCodeId
,L.StateId
,L.CountryId
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexLocationDetailExtract L ON RD.LocationId = L.LocationId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL  AND RD.JobStepInstanceId = @JobStepInstanceId AND L.JobStepInstanceId = RD.JobStepInstanceId
)
INSERT INTO NonVertexReceivableCodeDetailExtract
(ReceivableCodeId,IsExemptAtReceivableCode,IsRental,TaxReceivableName,TaxTypeId,StateId,IsCountryTaxExempt,IsStateTaxExempt,IsCountyTaxExempt,IsCityTaxExempt,JobStepInstanceId)
SELECT
RC.Id AS ReceivableCodeId
,RC.IsTaxExempt as IsExemptAtReceivableCode
,RT.IsRental
,RT.Name  AS TaxReceivableName
,DTTFRT.TaxTypeId
,RD.StateId
,ISNULL(TE.IsCountryTaxExempt,0)
,ISNULL(TE.IsStateTaxExempt,0)
,ISNULL(TE.IsCountyTaxExempt,0)
,ISNULL(TE.IsCityTaxExempt,0)
,@JobStepInstanceId
FROM CTE_DistinctReceivableCodes RD
INNER JOIN ReceivableCodes RC ON RD.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
INNER JOIN DefaultTaxTypeForReceivableTypes DTTFRT ON RC.ReceivableTypeId = DTTFRT.ReceivableTypeId
AND DTTFRT.CountryId = RD.CountryId
LEFT JOIN ReceivableCodeTaxExemptRules RCE ON  RC.Id = RCE.ReceivableCodeId AND RD.StateId = RCE.StateId AND RCE.IsActive =1
LEFT JOIN TaxExemptRules TE ON RCE.TaxExemptRuleId = TE.Id AND RCE.IsActive =1;
END

GO
