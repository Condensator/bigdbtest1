SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePropertyTaxReportCodesInAssetsFromLease]
(
@LeaseFinanceId BIGINT,
@CommencementDate DATETIME = NULL,
@LeaseContractType NVARCHAR(16),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@PropertyTaxResponsibility NVARCHAR(16),
@LeaseTransactionType NVARCHAR(32)
)
AS
BEGIN
SET NOCOUNT ON
SELECT
Assets.Id as AssetId,
MAX(AssetLocations.EffectiveFromDate) as EffectiveDateAsOfCommencement
INTO #AssetLocationSummary
FROM
AssetLocations
JOIN Assets ON AssetLocations.AssetId = Assets.Id
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
WHERE
AssetLocations.IsActive = 1
AND LeaseAssets.LeaseFinanceId = @LeaseFinanceId
AND LeaseAssets.IsActive = 1
AND LeaseAssets.CapitalizedForId IS NULL
AND AssetLocations.EffectiveFromDate <= @CommencementDate
GROUP BY Assets.Id
SELECT
#AssetLocationSummary.AssetId as AssetId,
Locations.StateId as StateId,
PropertyTaxReportCodeStateAssociations.PropertyTaxReportCodeConfigId
INTO #AssetDetails
FROM
AssetLocations
JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN  #AssetLocationSummary ON AssetLocations.AssetId = #AssetLocationSummary.AssetId
JOIN PropertyTaxReportCodeStateAssociations ON Locations.StateId = PropertyTaxReportCodeStateAssociations.StateId
WHERE
AssetLocations.EffectiveFromDate = #AssetLocationSummary.EffectiveDateAsOfCommencement
AND PropertyTaxReportCodeStateAssociations.LeaseContractType = @LeaseContractType
AND PropertyTaxReportCodeStateAssociations.LeaseTransactionType = @LeaseTransactionType
UPDATE Assets SET PropertyTaxReportCodeId = #AssetDetails.PropertyTaxReportCodeConfigId, UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
FROM
Assets
JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId

INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,[ContractId]
,[PropertyTaxReportCodeId]
,[IsReversed])
SELECT
'PPTReportCodeChange'
,@CommencementDate
,Assets.AcquisitionDate
,Assets.Status
,Assets.FinancialType
,'LeaseBooking'
,@LeaseFinanceId
,@CreatedById
,@CreatedTime
,LeaseFinances.CustomerId
,Assets.ParentAssetId
,LeaseFinances.LegalEntityId
,Assets.Id
,LeaseFinances.ContractId
,Assets.PropertyTaxReportCodeId
,0
FROM Assets
JOIN #AssetDetails ON Assets.Id = #AssetDetails.AssetId
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId AND LeaseAssets.IsActive = 1
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
WHERE LeaseFinances.Id = @LeaseFinanceId
UPDATE Assets SET PropertyTaxResponsibility = @PropertyTaxResponsibility
FROM Assets
JOIN LeaseAssets
ON LeaseAssets.LeaseFinanceId=@LeaseFinanceId
AND Assets.Id = LeaseAssets.AssetId
AND LeaseAssets.IsActive = 1
DROP TABLE #AssetDetails,#AssetLocationSummary
SET NOCOUNT OFF
END

GO
