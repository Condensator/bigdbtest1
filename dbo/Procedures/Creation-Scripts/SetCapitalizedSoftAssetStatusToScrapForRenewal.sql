SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetCapitalizedSoftAssetStatusToScrapForRenewal]
(
@LeaseFinanceId BIGINT,
@AssetHistoryReasonStatusChange NVARCHAR(15),
@AssetStatus NVARCHAR(5),
@SourceModule NVARCHAR(25),
@AsOfDate DATETIME,
@ContractId BIGINT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #UpdatedAssets
(
	AssetId BIGINT
)

UPDATE Assets SET Status = @AssetStatus
OUTPUT inserted.Id INTO #UpdatedAssets
FROM Assets
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseAssets.CapitalizedForId IS NOT NULL
AND LeaseFinances.Id = @LeaseFinanceId
AND LeaseAssets.IsActive = 1;


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
,@AsOfDate
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
INNER JOIN #UpdatedAssets AIds ON Assets.Id = Aids.AssetId

END

GO
