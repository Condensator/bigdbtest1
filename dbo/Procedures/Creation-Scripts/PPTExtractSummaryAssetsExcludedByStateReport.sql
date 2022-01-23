SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryAssetsExcludedByStateReport]
(
@ExportFile NVARCHAR(MAX) = NULL,
@ExportDate DATE,
@Currency NVARCHAR(3),
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #Temp
(
State NVARCHAR(30),
DefaultOrder INT,
Reason NVARCHAR(MAX),
NumberOfAssets BIGINT,
TotalPPTBasisAmount DECIMAL(16,2),
)
INSERT INTO #Temp
SELECT
ISNULL(EntityResourceForState.Value,States.ShortName) AS State
,ROW_NUMBER() OVER (PARTITION BY ISNULL(EntityResourceForState.Value,States.ShortName) ORDER BY PPTExtractExcludedAssetDetails.Reason) AS DefaultOrder
,PPTExtractExcludedAssetDetails.Reason
,SUM(PPTExtractExcludedAssetDetails.NumberOfAssets) AS NumberOfAssets
,SUM(PPTExtractExcludedAssetDetails.TotalPPTBasis_Amount) AS TotalPPTBasisAmount
FROM PPTExtractDetails
JOIN PPTExtractExcludedAssetDetails ON PPTExtractDetails.Id = PPTExtractExcludedAssetDetails.PPTExtractDetailId
JOIN States ON PPTExtractExcludedAssetDetails.StateId = States.Id
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE PPTExtractDetails.ExportDate = @ExportDate
AND (@ExportFile IS NULL OR PPTExtractExcludedAssetDetails.ExportFile = @ExportFile)
AND PPTExtractExcludedAssetDetails.TotalPPTBasis_Currency = @Currency
GROUP BY PPTExtractExcludedAssetDetails.TotalPPTBasis_Currency, ISNULL(EntityResourceForState.Value,States.ShortName), PPTExtractExcludedAssetDetails.Reason
ORDER BY ISNULL(EntityResourceForState.Value,States.ShortName)
SELECT * FROM #Temp
DROP TABLE #Temp
SET NOCOUNT OFF
END

GO
