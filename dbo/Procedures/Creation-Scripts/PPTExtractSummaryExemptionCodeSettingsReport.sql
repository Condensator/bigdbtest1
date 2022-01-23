SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryExemptionCodeSettingsReport]
(
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #Temp
(
State NVARCHAR(30) NULL,
DefaultOrder INT,
ExemptionCode NVARCHAR(MAX),
Description NVARCHAR(MAX)
)
INSERT INTO #Temp
SELECT
ISNULL(EntityResourceForState.Value,States.ShortName) AS State
,ROW_NUMBER() OVER (PARTITION BY ISNULL(EntityResourceForState.Value,States.ShortName) ORDER BY PropertyTaxReportCodeConfigs.Code) AS DefaultOrder
,ISNULL(EntityResourceForPropertyTaxReportCodeConfigCode.Value,PropertyTaxReportCodeConfigs.Code) AS ExemptionCode
,ISNULL(EntityResourceForPropertyTaxReportCodeConfigdescription.Value,PropertyTaxReportCodeConfigs.Description) AS ExemptionCodeDescription
FROM PropertyTaxExemptCodes
JOIN States ON PropertyTaxExemptCodes.StateId = States.Id
JOIN PropertyTaxReportCodeConfigs ON PropertyTaxExemptCodes.PropertyTaxReportCodeId = PropertyTaxReportCodeConfigs.Id
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
LEFT JOIN EntityResources EntityResourceForPropertyTaxReportCodeConfigdescription ON PropertyTaxReportCodeConfigs.Id = EntityResourceForPropertyTaxReportCodeConfigdescription.EntityId
AND EntityResourceForPropertyTaxReportCodeConfigdescription.EntityType = 'PropertyTaxReportCodeConfig'
AND EntityResourceForPropertyTaxReportCodeConfigdescription.Name = 'Description'
AND EntityResourceForPropertyTaxReportCodeConfigdescription.Culture = @Culture
LEFT JOIN EntityResources EntityResourceForPropertyTaxReportCodeConfigCode ON PropertyTaxReportCodeConfigs.Id = EntityResourceForPropertyTaxReportCodeConfigCode.EntityId
AND EntityResourceForPropertyTaxReportCodeConfigCode.EntityType = 'PropertyTaxReportCodeConfig'
AND EntityResourceForPropertyTaxReportCodeConfigCode.Name = 'Code'
AND EntityResourceForPropertyTaxReportCodeConfigCode.Culture = @Culture
WHERE PropertyTaxExemptCodes.IsActive=1
ORDER BY ISNULL(EntityResourceForState.Value,States.ShortName)
UPDATE #Temp
SET State = NULL
WHERE DefaultOrder <> 1
SELECT * FROM #Temp
DROP TABLE #Temp
SET NOCOUNT OFF
END

GO
