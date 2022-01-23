SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryStateClassCodeSettingsReport]
@Culture NVARCHAR(10)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #Temp
(
State NVARCHAR(30),
GroupedOrder INT,
AssetClassCode NVARCHAR(80),
AssetClassCodeDescription NVARCHAR(400)
)
INSERT INTO #Temp
SELECT
ISNULL(EntityResourceForState.Value,States.ShortName) AS State
,ROW_NUMBER() OVER (PARTITION BY ISNULL(EntityResourceForState.Value,States.ShortName) ORDER BY AssetClassCodes.ClassCode) AS GroupedOrder
,AssetClassCodes.ClassCode AS AssetClassCode
,AssetClassCodes.Description AS AssetClassCodeDescription
FROM PropertyTaxStateClassCodes
JOIN States ON PropertyTaxStateClassCodes.StateId = States.Id
JOIN AssetClassCodes ON PropertyTaxStateClassCodes.AssetClassCodeId = AssetClassCodes.Id
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE PropertyTaxStateClassCodes.IsActive=1
ORDER BY ISNULL(EntityResourceForState.Value,States.ShortName)
UPDATE #Temp
SET State = NULL
WHERE GroupedOrder <> 1
SELECT * FROM #Temp
DROP TABLE #Temp
SET NOCOUNT OFF
END

GO
