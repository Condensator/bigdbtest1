SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLeaseAssetInfoForMigration]
(
@AssetIds NVARCHAR(MAX),
@AssetValueHistoryInventoryBookDepreciationType NVARCHAR(40),
@AssetValueHistoryFixedTermDepreciationType NVARCHAR(40),
@AssetValueAdjustmentType NVARCHAR(40),
@AssetImpairmentType NVARCHAR(40),
@OTPDepreciationType NVARCHAR(40),
@ResidualRecaptureType NVARCHAR(40)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #ThresholdDateInfo
(
MaxAssetValueHistoryId BIGINT NOT NULL Primary Key
);
INSERT INTO #ThresholdDateInfo
SELECT
MaxAssetValueHistoryId = MAX(AVH.Id)
FROM AssetValueHistories AVH
JOIN dbo.ConvertCSVToBigIntTable(@AssetIds,',') LA ON LA.Id = AVH.AssetId
AND AVH.SourceModule <> @AssetValueHistoryInventoryBookDepreciationType
AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
GROUP BY AVH.AssetId,AVH.IsLeaseComponent;

SELECT
AssetId = AVH.AssetId,
ValueAsOfDate = (CASE WHEN AVH.SourceModule IN (@AssetImpairmentType, @AssetValueAdjustmentType,@ResidualRecaptureType,@OTPDepreciationType,@AssetValueHistoryFixedTermDepreciationType,@AssetValueHistoryInventoryBookDepreciationType)
THEN DATEADD(DAY, 1, AVH.IncomeDate)
ELSE AVH.IncomeDate END),
AssetNBV = AVH.EndBookValue_Amount
FROM AssetValueHistories AVH
JOIN #ThresholdDateInfo MAV ON AVH.Id = MAV.MaxAssetValueHistoryId

END

GO
