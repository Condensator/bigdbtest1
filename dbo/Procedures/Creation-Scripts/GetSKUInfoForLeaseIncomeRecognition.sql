SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetSKUInfoForLeaseIncomeRecognition]
(
	 @IncomeRecognitionLeaseAssetsIds IncomeRecognitionLeaseAssetsIds READONLY
)
AS
BEGIN
SET NOCOUNT ON;

;WITH CTE_LeaseAssetSKU
AS
(
SELECT 
	AssetSkuID = LeaseAssetSKUs.AssetSKUId,
    LeaseAssetId = LeaseAssetSKUs.LeaseAssetId,
    NBV = LeaseAssetSKUs.NBV_Amount,
    AssetResidual = LeaseAssetSKUs.BookedResidual_Amount,
    BookedResidual = LeaseAssetSKUs.BookedResidual_Amount,
    ETCAdjustmentAmount = LeaseAssetSKUs.ETCAdjustmentAmount_Amount,
    Depreciation = LeaseAssetSKUs.RVRecapAmount_Amount,
    OTPRent = LeaseAssetSKUs.OTPRent_Amount,
    Rent = LeaseAssetSKUs.Rent_Amount,
    RunningBookValue = LeaseAssetSKUs.BookedResidual_Amount,
    SupplementalRent = LeaseAssetSKUs.SupplementalRent_Amount,
    CustomerExpectedResidual = LeaseAssetSKUs.CustomerExpectedResidual_Amount,
    CustomerGuaranteedResidual = LeaseAssetSKUs.CustomerGuaranteedResidual_Amount,
    ThirdPartyGuaranteedResidual = LeaseAssetSKUs.ThirdPartyGuaranteedResidual_Amount,
    LeaseAssetSkusIsLeaseComponent = LeaseAssetSKUs.IsLeaseComponent
FROM LeaseAssetSKUs
JOIN @IncomeRecognitionLeaseAssetsIds LeaseAssetIds ON LeaseAssetSKUs.LeaseAssetId = LeaseAssetIds.LeaseAssetId
)
SELECT
	AssetSKUs.AssetId, 
	AssetSkuID,
    LeaseAssetId,
    NBV,
    AssetResidual,
    BookedResidual,
    ETCAdjustmentAmount,
    Depreciation,
    OTPRent,
    Rent,
    RunningBookValue,
    SupplementalRent,
    CustomerExpectedResidual,
    CustomerGuaranteedResidual,
    ThirdPartyGuaranteedResidual,
	AssetSkusIsLeaseComponent = AssetSKUs.IsLeaseComponent,
    LeaseAssetSkusIsLeaseComponent
FROM AssetSKUs
JOIN CTE_LeaseAssetSKU ON AssetSKUs.Id = CTE_LeaseAssetSKU.AssetSkuID

END

GO
