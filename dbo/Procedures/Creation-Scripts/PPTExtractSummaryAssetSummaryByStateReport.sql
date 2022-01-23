SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PPTExtractSummaryAssetSummaryByStateReport]
(
@ExportFile NVARCHAR(MAX) = NULL,
@ExportDate DATE,
@Currency NVARCHAR(3),
@Culture NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
SELECT
ISNULL(EntityResourceForState.Value,States.ShortName) AS State
,SUM(PPTExtractIncludedAssetDetails.NumberOfAssets) AS NumberOfAssets
,SUM(PPTExtractIncludedAssetDetails.TotalPPTBasis_Amount) AS TotalPPTBasisAmount
,SUM(PPTExtractIncludedAssetDetails.NumberOfAssetsToTransfer) AS NumberOfAssetsToTransfer
,SUM(PPTExtractIncludedAssetDetails.TotalPPTBasisToTransfer_Amount) AS TotalPPTBasisToTransferAmount
,PPTExtractIncludedAssetDetails.TotalPPTBasis_Currency AS Currency
FROM PPTExtractDetails
JOIN PPTExtractIncludedAssetDetails ON PPTExtractDetails.Id = PPTExtractIncludedAssetDetails.PPTExtractDetailId
JOIN States ON PPTExtractIncludedAssetDetails.StateId = States.Id
LEFT JOIN EntityResources EntityResourceForState ON States.Id = EntityResourceForState.EntityId
AND EntityResourceForState.EntityType = 'State'
AND EntityResourceForState.Name = 'ShortName'
AND EntityResourceForState.Culture = @Culture
WHERE PPTExtractDetails.ExportDate = @ExportDate
AND (@ExportFile IS NULL OR PPTExtractIncludedAssetDetails.ExportFile = @ExportFile)
AND PPTExtractIncludedAssetDetails.TotalPPTBasis_Currency = @Currency
GROUP BY PPTExtractIncludedAssetDetails.TotalPPTBasis_Currency, ISNULL(EntityResourceForState.Value,States.ShortName)
ORDER BY ISNULL(EntityResourceForState.Value,States.ShortName)
SET NOCOUNT OFF
END

GO
