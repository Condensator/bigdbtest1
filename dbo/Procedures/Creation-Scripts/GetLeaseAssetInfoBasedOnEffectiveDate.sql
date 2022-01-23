SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLeaseAssetInfoBasedOnEffectiveDate]
(
@LeaseAssetEffectiveDateDetail LeaseAssetInfo READONLY,
@AssetValueHistoryInventoryBookDepreciationType NVARCHAR(40),
@AssetValueHistoryFixedTermDepreciationType NVARCHAR(40),
@AssetValueHistoryETCType NVARCHAR(40),
@AssetValueAdjustmentType NVARCHAR(40),
@AssetImpairmentType NVARCHAR(40),
@OTPDepreciationType NVARCHAR(40),
@ResidualRecaptureType NVARCHAR(40),
@ContractId BIGINT = NULL,
@IsRebook BIT = 0
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @RecordsToExclude TABLE (SourceModuleId BIGINT, SourceModule NVARCHAR(40));
DECLARE @ETCSourceModuleIdsToExclude TABLE (SourceModuleId BIGINT);
IF(@ContractId IS NOT NULL)
BEGIN
INSERT INTO @RecordsToExclude
SELECT Id, @AssetValueHistoryFixedTermDepreciationType
FROM LeaseFinances WHERE ContractId = @ContractId;
INSERT INTO @RecordsToExclude
SELECT BlendedItems.Id, @AssetValueHistoryETCType
FROM LeaseFinances
JOIN LeaseBlendedItems ON LeaseFinances.Id = LeaseBlendedItems.LeaseFinanceId
JOIN BlendedItems ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
WHERE LeaseFinances.ContractId = @ContractId
AND BlendedItems.IsETC=1
AND BlendedItems.IsActive=1;
END
CREATE TABLE #MaxIncomeDateInfo
(
AssetId BIGINT,
MaxIncomeDate DATE
);
CREATE TABLE #ThresholdDateInfo
(
AssetId BIGINT,
ThresholdDate DATE
);
INSERT INTO #ThresholdDateInfo
SELECT
AssetId = AVH.AssetId,
ThresholdDate = MAX(AVH.IncomeDate)
FROM AssetValueHistories AVH
JOIN @LeaseAssetEffectiveDateDetail LA ON LA.AssetId = AVH.AssetId
AND AVH.SourceModule <> @AssetValueHistoryInventoryBookDepreciationType
AND AVH.IsSchedule = 1 AND AVH.IsLessorOwned = 1
LEFT JOIN @RecordsToExclude RTE ON AVH.SourceModuleId = RTE.SourceModuleId AND AVH.SourceModule = RTE.SourceModule
WHERE RTE.SourceModuleId IS NULL
GROUP BY AVH.AssetId;
CREATE TABLE #MaxInventoryBookDep
(
AssetId BIGINT,
BookDepId BIGINT
);
INSERT INTO #MaxInventoryBookDep
SELECT
AssetId = LA.AssetId,
BookDepId = BD.Id
FROM @LeaseAssetEffectiveDateDetail LA
JOIN BookDepreciations BD ON LA.AssetId = BD.AssetId
WHERE BD.IsActive = 1 AND BD.ContractId IS NULL;
INSERT INTO #MaxIncomeDateInfo
SELECT
AssetId = LA.AssetId,
MaxIncomeDate = ISNULL(MAX(AVH.IncomeDate), MAX(TDI.ThresholdDate))
FROM @LeaseAssetEffectiveDateDetail LA
JOIN #ThresholdDateInfo TDI ON LA.AssetId = TDI.AssetId
LEFT JOIN AssetValueHistories AVH ON LA.AssetId = AVH.AssetId
AND AVH.IncomeDate >= TDI.ThresholdDate
AND AVH.IncomeDate < LA.AssetEffectiveDate
AND AVH.SourceModule = @AssetValueHistoryInventoryBookDepreciationType
LEFT JOIN @RecordsToExclude RTE ON AVH.SourceModuleId = RTE.SourceModuleId AND AVH.SourceModule = RTE.SourceModule
LEFT JOIN #MaxInventoryBookDep MIBP ON AVH.AssetId = MIBP.AssetId
AND AVH.SourceModuleId = MIBP.BookDepId
AND AVH.SourceModule = @AssetValueHistoryInventoryBookDepreciationType
WHERE (AVH.Id IS NULL OR (AVH.IsSchedule = 1  AND AVH.IsLessorOwned = 1 OR (@IsRebook = 1 AND MIBP.BookDepId IS NOT NULL)))
AND RTE.SourceModuleId IS NULL
GROUP BY LA.AssetId;
SELECT MaxAssetValueHistoryId = MAX(AVH.Id)
INTO #MaxAssetValueHistoryInfo
FROM AssetValueHistories AVH
JOIN #MaxIncomeDateInfo MID ON AVH.AssetId = MID.AssetId AND AVH.IncomeDate = MID.MaxIncomeDate
LEFT JOIN @RecordsToExclude RTE ON AVH.SourceModuleId = RTE.SourceModuleId AND AVH.SourceModule = RTE.SourceModule
LEFT JOIN #MaxInventoryBookDep MIBP ON AVH.AssetId = MIBP.AssetId
AND AVH.SourceModuleId = MIBP.BookDepId
AND AVH.SourceModule = @AssetValueHistoryInventoryBookDepreciationType
WHERE (AVH.IsSchedule = 1  AND AVH.IsLessorOwned = 1  OR (@IsRebook = 1 AND MIBP.BookDepId IS NOT NULL))
AND RTE.SourceModuleId IS NULL
GROUP BY AVH.AssetId,AVH.IsLeaseComponent;
SELECT
AssetId = AVH.AssetId,
ValueAsOfDate = (CASE WHEN AVH.SourceModule IN (@AssetImpairmentType, @AssetValueAdjustmentType,@ResidualRecaptureType,@OTPDepreciationType,@AssetValueHistoryFixedTermDepreciationType,@AssetValueHistoryInventoryBookDepreciationType)
THEN DATEADD(DAY, 1, AVH.IncomeDate)
ELSE AVH.IncomeDate END),
AssetNBV = AVH.EndBookValue_Amount
FROM AssetValueHistories AVH
JOIN #MaxAssetValueHistoryInfo MAV ON AVH.Id = MAV.MaxAssetValueHistoryId
WHERE  AVH.IsLessorOwned = 1;
DROP TABLE #MaxIncomeDateInfo;
DROP TABLE #ThresholdDateInfo;
DROP TABLE #MaxInventoryBookDep;
DROP TABLE #MaxAssetValueHistoryInfo;
END

GO
