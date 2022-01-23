SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryStateSettingsReport]
@ExportDate DATE,
@Culture NVARCHAR(10)
AS
BEGIN
SET NOCOUNT ON
SELECT
ISNULL(EntityResourceForState.Value,States.ShortName) AS State
,CASE WHEN AssessmentDay > 0 THEN
CONVERT(nvarchar, DATEPART(MM, AssessmentMonth + ' 01 2017') ) + '/' + CONVERT(nvarchar ,AssessmentDay) +'/' + CONVERT(nvarchar, DATEPART(yyyy,@ExportDate))
ELSE 'NA' END AS AssessmentDate
,@ExportDate AS ExtractDate
,CASE WHEN FilingDueDay>0 THEN
CONVERT(nvarchar, DATEPART(MM, FilingDueMonth + ' 01 2017') ) + '/' + CONVERT(nvarchar ,FilingDueDay) +'/' + CONVERT(nvarchar, DATEPART(yyyy,@ExportDate))
ELSE 'NA' END AS FilingDueDate
,PropertyTaxStateSettings.IsSalesTaxOnPropertyTax
,PropertyTaxStateSettings.IsReportCSAs
,PropertyTaxStateSettings.IsReportInventory
,PropertyTaxStateSettings.Comment
FROM PropertyTaxStateSettings
JOIN States ON PropertyTaxStateSettings.StateId = States.Id
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE PropertyTaxStateSettings.IsActive=1
ORDER BY ISNULL(EntityResourceForState.Value,States.ShortName)
SET NOCOUNT OFF
END

GO
