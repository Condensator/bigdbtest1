SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AssetFinancialStatusChangeFromLease]
(
@LeaseFinanceId BIGINT,
@AssetHistoryReasonStatusChange NVARCHAR(15),
@SourceModule NVARCHAR(25),
@CommencementDate DATETIME = NULL,
@ContractId BIGINT,
@AssetFinancialTypeReal NVARCHAR(20),
@AssetFinancialTypeDummy NVARCHAR(20),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON


CREATE TABLE #AssetFinancialDetails
(
AssetId BIGINT,
AssetFinancialType NVARCHAR(20),
AsOfDate DATE,
LeaseAssetIsActive BIT
)

INSERT INTO #AssetFinancialDetails
SELECT
Asset.Id
,@AssetFinancialTypeReal
,@CommencementDate
,LeaseAsset.IsActive
FROM Assets Asset
INNER JOIN LeaseAssets LeaseAsset ON Asset.Id = LeaseAsset.AssetId
WHERE LeaseAsset.LeaseFinanceId = @LeaseFinanceId AND Asset.FinancialType = @AssetFinancialTypeDummy AND LeaseAsset.IsNewlyAdded = 1
UPDATE Assets SET FinancialType = #AssetFinancialDetails.AssetFinancialType, UpdatedTime = @CreatedTime, UpdatedById = @CreatedById
FROM Assets
INNER JOIN #AssetFinancialDetails ON Assets.Id = #AssetFinancialDetails.AssetId



INSERT INTO AssetHistories
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[ContractId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
@AssetHistoryReasonStatusChange
,#AssetFinancialDetails.AsOfDate
,Assets.AcquisitionDate
,Assets.Status
,Assets.FinancialType
,@SourceModule
,@ContractId
,@CreatedById
,@CreatedTime
,NULL
,NULL
,Assets.CustomerId
,Assets.ParentAssetId
,Assets.LegalEntityId
,@ContractId
,Assets.Id
,0
,Assets.PropertyTaxReportCodeId
FROM Assets
INNER JOIN #AssetFinancialDetails ON Assets.Id = #AssetFinancialDetails.AssetId
UPDATE AssetHistory SET AsOfDate = AssetDetail.AsOfDate, UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM AssetHistories AssetHistory
JOIN #AssetFinancialDetails AssetDetail ON AssetHistory.AssetId = AssetDetail.AssetId
WHERE AssetHistory.Id = (SELECT TOP 1 Id FROM AssetHistories WHERE AssetId = AssetDetail.AssetId AND AssetHistory.AsOfDate != AssetDetail.AsOfDate ORDER BY Id DESC)
DROP TABLE #AssetFinancialDetails
SET NOCOUNT OFF
END

GO
