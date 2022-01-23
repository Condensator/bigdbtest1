SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetPayoffAssetInfo]
(
@AssetIds LeaseAssetDetailInfo READONLY,
@LeaseFinanceId BIGINT,
@DepositType NVARCHAR(MAX),
@PayableInvoiceStatusCompleted NVARCHAR(MAX),
@PayoffEffectiveDate DATE = NULL
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #LocationInfo
(
LeaseAssetId BIGINT,
LocationEffectiveDate DATE
)
CREATE TABLE #AssetLocationInfo
(
LeaseAssetId BIGINT,
LocationCode Nvarchar(max)
)
CREATE TABLE #AssetInfo
(
AssetId BIGINT,
Alias NVARCHAR(max),
PartNumber NVARCHAR(max),
LocationCode NVARCHAR(max),
FinancialType NVARCHAR(max),
AssetStatus NVARCHAR(max),
Usefullife INT,
AcquisitionDate Datetime,
HoldingStatus NVARCHAR(3),
AssetBookValueAdjustmentGLTemplateId BIGINT,
BookDepreciationGLTemplateId BIGINT,
BookDepSetupTemplateId BIGINT,
ParentAssetId BIGINT
)
CREATE TABLE #TakeDownAssetInfo
(
LeaseAssetId BIGINT,
AssociatedAssetId NVARCHAR(max)
)
CREATE TABLE #TakeDownAssetListInfo
(
LeaseDepositAssetId BIGINT,
AssociatedAssetList NVARCHAR(MAX)
)
CREATE TABLE #SelectedLeaseAssets
(
LeaseAssetId BIGINT
);
CREATE CLUSTERED INDEX IDX_SelectedLeaseAssets ON #SelectedLeaseAssets(LeaseAssetId)

INSERT INTO #SelectedLeaseAssets
SELECT LeaseAssetId = AI.Id
FROM @AssetIds AI 

INSERT INTO #LocationInfo
SELECT
SA.LeaseAssetId,
MAX(AL.EffectiveFromDate)
FROM
#SelectedLeaseAssets SA
JOIN
LeaseAssets LA ON SA.LeaseAssetId = LA.Id
JOIN
AssetLocations AL on LA.AssetId = AL.AssetId
WHERE
LA.LeaseFinanceId=@LeaseFinanceId
AND
AL.EffectiveFromDate <= @PayoffEffectiveDate
AND AL.IsActive =1
AND LA.IsActive=1
GROUP BY
SA.LeaseAssetId

INSERT INTO #AssetLocationInfo
SELECT
SA.LeaseAssetId,
LO.Code
FROM
#SelectedLeaseAssets SA 
JOIN
LeaseAssets LA ON LA.Id = SA.LeaseAssetId AND LA.LeaseFinanceId=@LeaseFinanceId
JOIN
AssetLocations AL ON LA.AssetId = AL.AssetId AND AL.IsActive =1
JOIN
Locations LO ON AL.LocationId = LO.Id
JOIN
#LocationInfo LI ON LA.Id = LI.LeaseAssetId
WHERE (LI.LocationEffectiveDate=null OR LI.LocationEffectiveDate = AL.EffectiveFromDate)

INSERT INTO #AssetInfo
SELECT
A.Id ,
A.Alias,
A.PartNumber,
AI.LocationCode,
A.FinancialType,
A.Status,
CASE
WHEN AC.Usefullife IS NOT NULL THEN AC.Usefullife
ELSE AT.EconomicLifeInMonths
END AS Usefullife,
A.AcquisitionDate,
AGL.HoldingStatus,
AGL.AssetBookValueAdjustmentGLTemplateId,
AGL.BookDepreciationGLTemplateId,
LA.BookDepreciationTemplateId,
A.ParentAssetId
FROM
#SelectedLeaseAssets SA 
JOIN LeaseAssets LA ON LA.Id = SA.LeaseAssetId AND LA.LeaseFinanceId=@LeaseFinanceId
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetGLDetails AGL ON A.Id = AGL.Id
JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN #AssetLocationInfo AI ON AI.LeaseAssetId = SA.LeaseAssetId

INSERT INTO #TakeDownAssetInfo
SELECT
SA.LeaseAssetId,
CONVERT(NVARCHAR(MAX),LA1.Id)
FROM
#SelectedLeaseAssets SA
JOIN
LeaseAssets LA ON LA.Id = SA.LeaseAssetId AND LA.LeaseFinanceId = @LeaseFinanceId AND LA.IsActive=1
JOIN
Assets A ON LA.AssetId  = A.Id AND A.FinancialType = @DepositType
JOIN
PayableInvoiceAssets PA ON A.Id = PA.AssetId AND PA.IsActive=1
JOIN
PayableInvoiceDepositAssets PAD ON PA.Id = PAD.DepositAssetId AND PAD.IsActive=1
JOIN
PayableInvoiceDepositTakeDownAssets PADA ON PAD.Id = PADA.PayableInvoiceDepositAssetId AND PADA.IsActive=1
JOIN
PayableInvoiceAssets PA1 ON PADA.TakeDownAssetId = PA1.Id AND PA1.IsActive=1
JOIN
LeaseAssets LA1 ON PA1.AssetId = LA1.AssetId AND LA1.LeaseFinanceId = @LeaseFinanceId AND LA1.IsActive=1
JOIN
PayableInvoices PIV ON PA1.PayableInvoiceId = PIV.Id AND PIV.Status = @PayableInvoiceStatusCompleted

--Get AssetYieldForLeaseComponents
SELECT LAID.Id, LAID.AssetYieldForLeaseComponents 
INTO #AssetYieldForLeaseComponents 
FROM #SelectedLeaseAssets SA
JOIN LeaseAssetIncomeDetails LAID ON SA.LeaseAssetId = LAID.Id

INSERT INTO #TakeDownAssetListInfo
SELECT  LeaseAssetId,
SUBSTRING(d.AssociatedAssetList,1, LEN(d.AssociatedAssetList) - 1) AssociatedAssetList
FROM
        (
            SELECT DISTINCT LeaseAssetId
            FROM #TakeDownAssetInfo
        ) A
        CROSS APPLY
        (
            SELECT AssociatedAssetId + ', ' 
            FROM #TakeDownAssetInfo AS B 
            WHERE A.LeaseAssetId = B.LeaseAssetId
            FOR XML PATH('')
        ) D (AssociatedAssetList) 

SELECT 
	LA.Id AS LeaseAssetId,
	A.AssetId AS AssetId,
	A.ParentAssetId AS ParentAssetId,
	A.Alias AS Alias,
	A.PartNumber AS PartNumber,
	LA.NBV_Amount AS NBV,
	LA.FMV_Amount AS FMV,
	LA.CustomerCost_Amount AS CustomerCost,
	LA.BookedResidual_Amount AS BookedResidual,
	LA.ThirdPartyGuaranteedResidual_Amount AS ThirdPartyGuaranteedResidual,
	LA.CustomerGuaranteedResidual_Amount AS CustomerGuaranteedResidual,
	LA.CustomerExpectedResidual_Amount AS CustomerExpectedResidual,
	LA.Rent_Amount AS FixedTermRent,
	A.LocationCode AS LocationCode,
	A.FinancialType AS FinancialType,
	LA.InterimInterestStartDate AS InterimInterestStartDate,
    LA.InterimRentStartDate AS InterimRentStartDate,
	AYFLC.AssetYieldForLeaseComponents AS AssetYieldForLeaseComponents,
	LA.IsLeaseAsset as IsLeaseAsset,
	LA.CapitalizedForId AS CapitalizedForId,
	CapitalizedAmount = LA.CapitalizedInterimInterest_Amount + LA.CapitalizedInterimRent_Amount + LA.CapitalizedProgressPayment_Amount,
	D.AssociatedAssetList AS AssociatedAssetList,
	A.AssetStatus As AssetStatus,
	LA.IsApproved As Approved,
	A.AcquisitionDate,
	A.Usefullife,
	A.HoldingStatus,
	A.AssetBookValueAdjustmentGLTemplateId,
	A.BookDepreciationGLTemplateId,
	A.BookDepSetupTemplateId,
	LA.OTPRent_Amount AS OTPRent,
	LA.SupplementalRent_Amount AS SupplementalRent
FROM
#SelectedLeaseAssets SA
JOIN
LeaseAssets LA ON LA.Id = SA.LeaseAssetId AND LA.LeaseFinanceId=@LeaseFinanceId
LEFT JOIN
#AssetYieldForLeaseComponents AYFLC ON LA.Id = AYFLC.Id
LEFT JOIN
#AssetInfo A ON LA.AssetId = A.AssetId
LEFT JOIN
#TakeDownAssetListInfo D ON D.LeaseDepositAssetId = SA.LeaseAssetId

DROP TABLE
#SelectedLeaseAssets,
#LocationInfo,
#AssetInfo,
#AssetLocationInfo,
#TakeDownAssetInfo,
#TakeDownAssetListInfo,
#AssetYieldForLeaseComponents
END

GO
