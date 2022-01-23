SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SPHC_AssetLifeCycle_HealthCheck]
(
	@ResultOption NVARCHAR(20),
	@IsFromLegalEntity BIT NULL,
	@LegalEntityIds ReconciliationId READONLY
)
AS
BEGIN

IF OBJECT_ID('tempdb..#ReceivableForTransfersInfo') IS NOT NULL
DROP TABLE #ReceivableForTransfersInfo;

IF OBJECT_ID('tempdb..#InvestorLeasedAssets') IS NOT NULL
DROP TABLE #InvestorLeasedAssets;

IF OBJECT_ID('tempdb..#CollateralLoanScrapedAssets') IS NOT NULL
DROP TABLE #CollateralLoanScrapedAssets;

IF OBJECT_ID('tempdb..#EligibleAssets') IS NOT NULL
DROP TABLE #EligibleAssets;

IF OBJECT_ID('tempdb..#PayoffInfo') IS NOT NULL
DROP TABLE #PayoffInfo;

IF OBJECT_ID('tempdb..#BuyoutInfo') IS NOT NULL
DROP TABLE #BuyoutInfo;

IF OBJECT_ID('tempdb..#HasChildAssets') IS NOT NULL
DROP TABLE #HasChildAssets;

IF OBJECT_ID('tempdb..#CapitalizedSoftAssetInfo') IS NOT NULL
DROP TABLE #CapitalizedSoftAssetInfo;

IF OBJECT_ID('tempdb..#LeaseAssetsInfo') IS NOT NULL
DROP TABLE #LeaseAssetsInfo;

IF OBJECT_ID('tempdb..#LeaseAssetsAmountInfo') IS NOT NULL
DROP TABLE #LeaseAssetsAmountInfo;

IF OBJECT_ID('tempdb..#LeaseCapitalizedAmountInfo') IS NOT NULL
DROP TABLE #LeaseCapitalizedAmountInfo;

IF OBJECT_ID('tempdb..#CurrentNBVInfo') IS NOT NULL
DROP TABLE #CurrentNBVInfo;

IF OBJECT_ID('tempdb..#SKUComponentCount') IS NOT NULL
DROP TABLE #SKUComponentCount;

IF OBJECT_ID('tempdb..#PayableInvoiceInfo') IS NOT NULL
DROP TABLE #PayableInvoiceInfo;

IF OBJECT_ID('tempdb..#ContractInfo') IS NOT NULL
DROP TABLE #ContractInfo;

IF OBJECT_ID('tempdb..#ChargeOffInfo') IS NOT NULL
DROP TABLE #ChargeOffInfo;

IF OBJECT_ID('tempdb..#AssetSplitInfo') IS NOT NULL
DROP TABLE #AssetSplitInfo;

IF OBJECT_ID('tempdb..#CreatedFromAssetSplit') IS NOT NULL
DROP TABLE #CreatedFromAssetSplit;

IF OBJECT_ID('tempdb..#AssetSaleInfo') IS NOT NULL
DROP TABLE #AssetSaleInfo;

IF OBJECT_ID('tempdb..#AcquisitionCostInfo') IS NOT NULL
DROP TABLE #AcquisitionCostInfo;

IF OBJECT_ID('tempdb..#PayableInvoiceOtherCostInfo') IS NOT NULL
DROP TABLE #PayableInvoiceOtherCostInfo;

IF OBJECT_ID('tempdb..#SpecificCostInfo') IS NOT NULL
DROP TABLE #SpecificCostInfo;

IF OBJECT_ID('tempdb..#OverTerm') IS NOT NULL
DROP TABLE #OverTerm;

IF OBJECT_ID('tempdb..#LeaseAmendmentInfo') IS NOT NULL
DROP TABLE #LeaseAmendmentInfo;

IF OBJECT_ID('tempdb..#OTPReclass') IS NOT NULL
DROP TABLE #OTPReclass;

IF OBJECT_ID('tempdb..#BookDepId') IS NOT NULL
DROP TABLE #BookDepId;

IF OBJECT_ID('tempdb..#BookDepreciationInfo') IS NOT NULL
DROP TABLE #BookDepreciationInfo;

IF OBJECT_ID('tempdb..#BookedResidualInfo') IS NOT NULL
DROP TABLE #BookedResidualInfo;

IF OBJECT_ID('tempdb..#RELBookDepInfo') IS NOT NULL
DROP TABLE #RELBookDepInfo;

IF OBJECT_ID('tempdb..#RemainingEconomicLifeInfo') IS NOT NULL
DROP TABLE #RemainingEconomicLifeInfo;

IF OBJECT_ID('tempdb..#ContractCount') IS NOT NULL
DROP TABLE #ContractCount;

IF OBJECT_ID('tempdb..#PreviousSeq') IS NOT NULL
DROP TABLE #PreviousSeq;

IF OBJECT_ID('tempdb..#GroupedSeq') IS NOT NULL
DROP TABLE #GroupedSeq;

IF OBJECT_ID('tempdb..#BlendedItemInfo') IS NOT NULL
DROP TABLE #BlendedItemInfo;

IF OBJECT_ID('tempdb..#RenewalBlendedItemInfo') IS NOT NULL
DROP TABLE #RenewalBlendedItemInfo;

IF OBJECT_ID('tempdb..#BlendedItemCapitalizeInfo') IS NOT NULL
DROP TABLE #BlendedItemCapitalizeInfo;

IF OBJECT_ID('tempdb..#AVHClearedTillDate') IS NOT NULL
DROP TABLE #AVHClearedTillDate;

IF OBJECT_ID('tempdb..#AVHClearedTillDateFixedTerm') IS NOT NULL
DROP TABLE #AVHClearedTillDateFixedTerm;

IF OBJECT_ID('tempdb..#AVHClearedTillDateOTP') IS NOT NULL
DROP TABLE #AVHClearedTillDateOTP;

IF OBJECT_ID('tempdb..#AssetImpairmentAVHInfo') IS NOT NULL
DROP TABLE #AssetImpairmentAVHInfo;

IF OBJECT_ID('tempdb..#ValueChangeInfo') IS NOT NULL
DROP TABLE #ValueChangeInfo;

IF OBJECT_ID('tempdb..#AssetImpairmentInfo') IS NOT NULL
DROP TABLE #AssetImpairmentInfo;

IF OBJECT_ID('tempdb..#PaydownAVHInfo') IS NOT NULL
DROP TABLE #PaydownAVHInfo;

IF OBJECT_ID('tempdb..#AssetInventoryAVHInfo') IS NOT NULL
DROP TABLE #AssetInventoryAVHInfo;

IF OBJECT_ID('tempdb..#AVHAssetsInfo') IS NOT NULL
DROP TABLE #AVHAssetsInfo;

IF OBJECT_ID('tempdb..#ChargeOffAssetsInfo') IS NOT NULL
DROP TABLE #ChargeOffAssetsInfo;

IF OBJECT_ID('tempdb..#SKUAVHClearedTillDate') IS NOT NULL
DROP TABLE #SKUAVHClearedTillDate;

IF OBJECT_ID('tempdb..#PayoffAssetInfo') IS NOT NULL
DROP TABLE #PayoffAssetInfo;

IF OBJECT_ID('tempdb..#SyndicatedAssets') IS NOT NULL
DROP TABLE #SyndicatedAssets;

IF OBJECT_ID('tempdb..#ChargeOffMaxCleared') IS NOT NULL
DROP TABLE #ChargeOffMaxCleared;

IF OBJECT_ID('tempdb..#AVHMaxSourceModuleIdInfo') IS NOT NULL
DROP TABLE #AVHMaxSourceModuleIdInfo;

IF OBJECT_ID('tempdb..#SKUAVHMaxSourceModuleIdInfo') IS NOT NULL
DROP TABLE #SKUAVHMaxSourceModuleIdInfo;

IF OBJECT_ID('tempdb..#AVHMaxClearedSourceModule') IS NOT NULL
DROP TABLE #AVHMaxClearedSourceModule;

IF OBJECT_ID('tempdb..#SKUAVHMaxClearedSourceModule') IS NOT NULL
DROP TABLE #SKUAVHMaxClearedSourceModule;

IF OBJECT_ID('tempdb..#RenewedAssets') IS NOT NULL
DROP TABLE #RenewedAssets;

IF OBJECT_ID('tempdb..#AccumulatedAVHInfo') IS NOT NULL
DROP TABLE #AccumulatedAVHInfo;

IF OBJECT_ID('tempdb..#MaxBeforeSynd') IS NOT NULL
DROP TABLE #MaxBeforeSynd;

IF OBJECT_ID('tempdb..#ResidualAVHInfo') IS NOT NULL
DROP TABLE #ResidualAVHInfo;

IF OBJECT_ID('tempdb..#SyndicationAmountInfo') IS NOT NULL
DROP TABLE #SyndicationAmountInfo;

IF OBJECT_ID('tempdb..#OtherAVHInfo') IS NOT NULL
DROP TABLE #OtherAVHInfo;

IF OBJECT_ID('tempdb..#LeaseAmendmentImpairmentInfo') IS NOT NULL
DROP TABLE #LeaseAmendmentImpairmentInfo;

IF OBJECT_ID('tempdb..#RenewalAmortizeInfo') IS NOT NULL
DROP TABLE #RenewalAmortizeInfo;

IF OBJECT_ID('tempdb..#ComputedValueCalculation') IS NOT NULL
DROP TABLE #ComputedValueCalculation;

IF OBJECT_ID('tempdb..#ActualValueCalculation') IS NOT NULL
DROP TABLE #ActualValueCalculation;

IF OBJECT_ID('tempdb..#PayoffAtInceptionSoftAssets') IS NOT NULL
DROP TABLE #PayoffAtInceptionSoftAssets;

IF OBJECT_ID('tempdb..#NotGLPostedPIInfo') IS NOT NULL
DROP TABLE #NotGLPostedPIInfo;

IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL
DROP TABLE #ResultList;

IF OBJECT_ID('tempdb..#ResidualBeforePayoff') IS NOT NULL
DROP TABLE #ResidualBeforePayoff;

IF OBJECT_ID('tempdb..#ActiveRenewedAssets') IS NOT NULL
DROP TABLE #ActiveRenewedAssets;

IF OBJECT_ID('tempdb..#OperatingLeaseChargeOff') IS NOT NULL
DROP TABLE #OperatingLeaseChargeOff;

IF OBJECT_ID('tempdb..#RenewalPaidOffInventory') IS NOT NULL
DROP TABLE #RenewalPaidOffInventory;

IF OBJECT_ID('tempdb..#ChargedOffCapitalLeaseAssetsInfo') IS NOT NULL
DROP TABLE #ChargedOffCapitalLeaseAssetsInfo;

IF OBJECT_ID('tempdb..#FinanceChargeOffAmount_Info') IS NOT NULL
DROP TABLE #FinanceChargeOffAmount_Info;

IF OBJECT_ID('tempdb..#LeasedChargedOffTableInfo') IS NOT NULL
DROP TABLE #LeasedChargedOffTableInfo;

IF OBJECT_ID('tempdb..#SoldAssetsPostChargeOff') IS NOT NULL
DROP TABLE #SoldAssetsPostChargeOff;

IF OBJECT_ID('tempdb..#AssetSummary') IS NOT NULL
DROP TABLE #AssetSummary;

DECLARE @True BIT= 1;
DECLARE @False BIT= 0;

DECLARE @FilterCondition nvarchar(max) = '';
DECLARE @IsSku BIT = 0;
DECLARE @Sql nvarchar(max) ='';
DECLARE @AddCharge BIT = 0;
DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Assets' AND COLUMN_NAME = 'IsSku')
BEGIN
SET @FilterCondition = ' AND ea.IsSKU = 0'
SET @IsSku = 1
END;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LeaseAssets' AND COLUMN_NAME = 'CapitalizedAdditionalCharge_Amount')
BEGIN
SET @AddCharge = 1;
END;

CREATE TABLE #BuyoutInfo
(AssetId                               BIGINT NOT NULL,
BuyoutCostOfGoodsSold_LeaseComponent   DECIMAL (16, 2) NOT NULL,
BuyoutCostOfGoodsSold_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #CapitalizedSoftAssetInfo
(AssetId                BIGINT NOT NULL,
CapitalizationType      NVARCHAR(52) NOT NULL,
SoftAssetCapitalizedFor NVARCHAR(30) NULL
);

CREATE TABLE #LeaseAssetsInfo
(AssetId                    BIGINT NOT NULL,
LeaseContractId             BIGINT NOT NULL,
LeaseContractType           NVARCHAR (52) NOT NULL,
CommencementDate            DATE NULL,
LeaseFinanceId              BIGINT NOT NULL,
LeaseAssetId                BIGINT NOT NULL,
IsLeaseAsset                BIT NOT NULL,
IsFailedSaleLeaseback       BIT NOT NULL,
LeasedAssetCost             DECIMAL (16, 2) NOT NULL,
AssetStatus                 NVARCHAR (52) NOT NULL,
RemainingEconomicLife       BIGINT NOT NULL
);

CREATE TABLE #LeaseAssetsAmountInfo
(AssetId                        BIGINT NOT NULL,
FMVAmount_LeaseComponent        DECIMAL (16, 2) NOT NULL,
BookedResidual_LeaseComponent   DECIMAL (16, 2) NOT NULL,
BookedResidual_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #LeaseCapitalizedAmountInfo
(AssetId                                              BIGINT NOT NULL,
TaxCapitalizedAmount_LeaseComponent                   DECIMAL (16, 2) NOT NULL,
TaxCapitalizedAmount_FinanceComponent                 DECIMAL (16, 2) NOT NULL,
InterimRentCapitalizationAmount_LeaseComponent        DECIMAL (16, 2) NOT NULL,
InterimRentCapitalizationAmount_FinanceComponent      DECIMAL (16, 2) NOT NULL,
InterimInterestCapitalizationAmount_LeaseComponent    DECIMAL (16, 2) NOT NULL,
InterimInterestCapitalizationAmount_FinanceComponent  DECIMAL (16, 2) NOT NULL,
AdditionalChargesCapitalizationAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
AdditionalChargesCapitalizationAmount_FinanceComponent DECIMAL (16, 2) NOT NULL,
ProgressPaymentCapitalizationAmount_LeaseComponent    DECIMAL (16, 2) NOT NULL,
ProgressPaymentCapitalizationAmount_FinanceComponent  DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #CurrentNBVInfo
(AssetId                          BIGINT NOT NULL,
CurrentNBVAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
CurrentNBVAmount_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #SKUComponentCount
(AssetId                 BIGINT NOT NULL,
LeaseComponentSKUCount   BIGINT NOT NULL,
FinanceComponentSKUCount BIGINT NOT NULL
);

CREATE TABLE #PayableInvoiceInfo
(InvoiceNumber         NVARCHAR (80) NOT NULL,
VendorName             NVARCHAR (500) NOT NULL,
AssetId                BIGINT NOT NULL,
PayableInvoiceAssetId  BIGINT NOT NULL,
AcquisitionCost_Amount DECIMAL (16, 2) NOT NULL,
OtherCost_Amount       DECIMAL (16, 2) NOT NULL,
Id                     BIGINT NOT NULL,
IsForeignCurrency      BIT NOT NULL,
InitialExchangeRate    DECIMAL (20, 10) NOT NULL,
OriginalExchangeRate   DECIMAL (20, 10) NOT NULL,
IsSKU                  BIT NOT NULL,
AssetStatus            NVARCHAR (50) NOT NULL,
IsLeaseComponent       BIT NOT NULL
);

CREATE TABLE #AssetSaleInfo
(AssetId                                  BIGINT NOT NULL,
AssetSaleCostOfGoodsSold_LeaseComponent   DECIMAL (16, 2) NOT NULL,
AssetSaleCostOfGoodsSold_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #AcquisitionCostInfo
(AssetId                         BIGINT NOT NULL,
AcquisitionCost_LeaseComponent   DECIMAL (16, 2) NOT NULL,
AcquisitionCost_FinanceComponent DECIMAL (16, 2) NOT NULL,
OtherCost_LeaseComponent         DECIMAL (16, 2) NOT NULL,
OtherCost_FinanceComponent       DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #PayableInvoiceOtherCostInfo
(AssetId                  BIGINT NOT NULL,
IsSKU                     BIT NOT NULL,
IsLeaseComponent          BIT NOT NULL,
AssetStatus               NVARCHAR (50) NOT NULL,
PayableInvoiceId          BIGINT NOT NULL,
IsForeignCurrency         BIT NOT NULL,
InitialExchangeRate       DECIMAL (20, 10) NOT NULL,
PayableInvoiceOtherCostId BIGINT NOT NULL,
SpecificCost_Amount       DECIMAL (16, 2) NOT NULL,
AssignOtherCostAtSKULevel BIT NOT NULL,
IsGLPosted                BIT NOT NULL
);

CREATE TABLE #SpecificCostInfo
(AssetId                                BIGINT NOT NULL,
SpecificCostAdjustment_LeaseComponent   DECIMAL (16, 2) NOT NULL,
SpecificCostAdjustment_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #OTPReclass
(AssetId BIGINT NOT NULL
);

CREATE TABLE #BookDepId
(AssetId           BIGINT NOT NULL,
IsLeaseComponent   BIT NOT NULL,
BookDepreciationId BIGINT NOT NULL
);

CREATE TABLE #BookDepreciationInfo
(AssetId                        BIGINT NOT NULL,
BookedResidual_LeaseComponent   DECIMAL (16, 2) NOT NULL,
BookedResidual_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #BlendedItemInfo
(AssetId                   BIGINT NOT NULL,
ETCAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
ETCAmount_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #RenewalBlendedItemInfo
(AssetId                   BIGINT NOT NULL,
ETCAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
ETCAmount_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #BlendedItemCapitalizeInfo
(AssetId                            BIGINT NOT NULL,
CapitalizedIDCAmount_LeaseComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #ValueChangeInfo
(AssetId                               BIGINT NOT NULL,
ValueChangeAmount_LeaseComponent       DECIMAL (16, 2) NOT NULL,
ValueChangeAmount_FinanceComponent     DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #AssetImpairmentInfo
(AssetId                                               BIGINT NOT NULL,
ClearedAssetImpairmentAmount_LeaseComponent            DECIMAL (16, 2) NOT NULL,
ClearedAssetImpairmentAmount_FinanceComponent          DECIMAL (16, 2) NOT NULL,
AccumulatedAssetImpairmentAmount_LeaseComponent        DECIMAL (16, 2) NOT NULL,
AccumulatedAssetImpairmentAmount_FinanceComponent      DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #PaydownAVHInfo
(AssetId           BIGINT NOT NULL,
PaydownValueAmount DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #AssetInventoryAVHInfo
(AssetId                                                     BIGINT NOT NULL,
ClearedInventoryDepreciationAmount_LeaseComponent            DECIMAL (16, 2) NOT NULL,
ClearedInventoryDepreciationAmount_FinanceComponent          DECIMAL (16, 2) NOT NULL,
AccumulatedInventoryDepreciationAmount_LeaseComponent        DECIMAL (16, 2) NOT NULL,
AccumulatedInventoryDepreciationAmount_FinanceComponent      DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #AVHAssetsInfo
(AssetId              BIGINT NOT NULL,
IsLeaseAsset          BIT NOT NULL,
IsFailedSaleLeaseback BIT NOT NULL
);

CREATE TABLE #SKUAVHClearedTillDate
(AssetId           BIGINT NOT NULL,
IsLeaseComponent   BIT NOT NULL,
AVHClearedTillDate DATE NOT NULL,
AVHClearedId       BIGINT NOT NULL
);

CREATE TABLE #SKUAVHMaxSourceModuleIdInfo
(AssetId                    BIGINT NOT NULL,
IsLeaseComponent            BIT NOT NULL,
ClearedFTDMaxSourceModuleId BIGINT NOT NULL,
ClearedOTPMaxSourceModuleId BIGINT NOT NULL,
ClearedNBVMaxSourceModuleId BIGINT NOT NULL
);

CREATE TABLE #SKUAVHMaxClearedSourceModule
(AssetId         BIGINT NOT NULL,
IsLeaseComponent BIT NOT NULL,
SourceModule     NVARCHAR (50) NOT NULL
);

CREATE TABLE #AccumulatedAVHInfo
(AssetId                                                  BIGINT NOT NULL, 
 ClearedFixedTermDepreciationAmount_LeaseComponent        DECIMAL(16, 2) NOT NULL, 
 AccumulatedFixedTermDepreciationAmount_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent DECIMAL(16, 2) NOT NULL, 
 ClearedFixedTermDepreciationAmount_Adj_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 AccumulatedAssetDepreciationAmount_FTD_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 ClearedOTPDepreciationAmount_LeaseComponent              DECIMAL(16, 2) NOT NULL, 
 ClearedOTPDepreciationAmount_FinanceComponent            DECIMAL(16, 2) NOT NULL, 
 AccumulatedOTPDepreciationAmount_LeaseComponent          DECIMAL(16, 2) NOT NULL, 
 AccumulatedOTPDepreciationAmount_FinanceComponent        DECIMAL(16, 2) NOT NULL, 
 AccumulatedOTPDepreciationAmount_PO_LeaseComponent       DECIMAL(16, 2) NOT NULL, 
 AccumulatedOTPDepreciationAmount_PO_FinanceComponent     DECIMAL(16, 2) NOT NULL, 
 ClearedOTPDepreciationAmount_Adj_LeaseComponent          DECIMAL(16, 2) NOT NULL, 
 ClearedOTPDepreciationAmount_Adj_FinanceComponent        DECIMAL(16, 2) NOT NULL, 
 AccumulatedAssetDepreciationAmount_OTP_LeaseComponent    DECIMAL(16, 2) NOT NULL, 
 AccumulatedAssetDepreciationAmount_OTP_FinanceComponent  DECIMAL(16, 2) NOT NULL, 
 ClearedNBVImpairmentAmount_LeaseComponent                DECIMAL(16, 2) NOT NULL, 
 ClearedNBVImpairmentAmount_FinanceComponent              DECIMAL(16, 2) NOT NULL, 
 AccumulatedNBVImpairmentAmount_LeaseComponent            DECIMAL(16, 2) NOT NULL, 
 AccumulatedNBVImpairmentAmount_FinanceComponent          DECIMAL(16, 2) NOT NULL, 
 AccumulatedNBVImpairmentAmount_PO_LeaseComponent         DECIMAL(16, 2) NOT NULL, 
 AccumulatedNBVImpairmentAmount_PO_FinanceComponent       DECIMAL(16, 2) NOT NULL, 
 ClearedNBVImpairmentAmount_Adj_LeaseComponent            DECIMAL(16, 2) NOT NULL, 
 ClearedNBVImpairmentAmount_Adj_FinanceComponent          DECIMAL(16, 2) NOT NULL, 
 AccumulatedAssetImpairmentAmount_NBV_LeaseComponent      DECIMAL(16, 2) NOT NULL, 
 AccumulatedAssetImpairmentAmount_NBV_FinanceComponent    DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #OtherAVHInfo
(AssetId                                   BIGINT NOT NULL,
ResidualReclassAmount_LeaseComponent       DECIMAL (16, 2) NOT NULL,
ResidualReclassAmount_FinanceComponent     DECIMAL (16, 2) NOT NULL,
ResidualRecaptureAmount_LeaseComponent     DECIMAL (16, 2) NOT NULL,
ResidualRecaptureAmount_FinanceComponent   DECIMAL (16, 2) NOT NULL,
SyndicationValueAmount_LeaseComponent      DECIMAL (16, 2) NOT NULL,
SyndicationValueAmount_FinanceComponent    DECIMAL (16, 2) NOT NULL,
AssetAmortizedValueAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
AssetAmortizedValueAmount_FinanceComponent DECIMAL (16, 2) NOT NULL,
ChargeOffValueAmount_LeaseComponent        DECIMAL (16, 2) NOT NULL,
ChargeOffValueAmount_FinanceComponent      DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #RenewalAmortizeInfo
(AssetId                                BIGINT NOT NULL,
RenewalAmortizedAmount_LeaseComponent   DECIMAL (16, 2) NOT NULL,
RenewalAmortizedAmount_FinanceComponent DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #ActualValueCalculation
(AssetId    BIGINT NOT NULL,
ActualValue DECIMAL (16, 2) NOT NULL
);

CREATE TABLE #NotGLPostedPIInfo
(AssetId BIGINT NOT NULL,
EntityId BIGINT NOT NULL
);

CREATE TABLE #OperatingLeaseChargeOff
(AssetId                       BIGINT NOT NULL, 
 OperatingLeaseChargeOff_Table DECIMAL(16, 2) NOT NULL
);

CREATE TABLE #FinanceChargeOffAmount_Info
(AssetId               BIGINT NOT NULL,
FinanceChargeOffAmount DECIMAL (16,2) NOT NULL
);

SELECT 
	ContractId
	,EffectiveDate
	,IsFromContract
	,ReceivableForTransferType
	,ContractType
	,CAST((RetainedPercentage / 100) as decimal (16,2)) RetainedPortion
	,CAST((1 - (CAST((RetainedPercentage / 100) as decimal (16,2)))) as decimal (16,2)) ParticipatedPortion
	,LeaseFinanceId AS SyndicationLeaseFinanceId
INTO #ReceivableForTransfersInfo
FROM ReceivableForTransfers where ApprovalStatus = 'Approved';

CREATE NONCLUSTERED INDEX IX_Id ON #ReceivableForTransfersInfo(ContractId);

SELECT
	DISTINCT a.Id
INTO #InvestorLeasedAssets
FROM Assets a
INNER JOIN LeaseAssets la ON la.AssetId = a.Id
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN #ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
WHERE rft.IsFromContract = 1
ORDER BY a.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #InvestorLeasedAssets(Id);

SELECT
	DISTINCT a.Id
INTO #CollateralLoanScrapedAssets
FROM Assets a
INNER JOIN Contracts c ON a.PreviousSequenceNumber = c.SequenceNumber
WHERE c.ContractType = 'Loan' AND a.Status NOT IN ('Inventory')
ORDER BY a.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #CollateralLoanScrapedAssets(Id);

SELECT
	a.Alias
	,a.Id [AssetId]
	,a.Status [AssetStatus]
	,a.ParentAssetId
	,at.Name [AssetType]
	,at.Id [AssetTypesId]
	,ac.Name [AssetCategory]
	,a.SubStatus
	,a.FinancialType
	,a.PreviousSequenceNumber
	,a.PlaceHolderAssetId
	,CASE WHEN at.IsSoft = 1 THEN 'Yes' ELSE 'No' END [IsSoft]
	,le.Name [LegalEntityName]
	,p.PartyName [CustomerName]
	,a.IsLeaseComponent
	,CAST (0 AS bit) [IsSKU]
	,v.PartyName [RemarketingVendorName]
	,CASE 
		WHEN at.Id IS NOT NULL AND act.Id IS NOT NULL THEN CAST (act.Usefullife AS nvarchar(10))
		WHEN at.Id IS NOT NULL AND act.Id IS NULL THEN CAST (at.EconomicLifeInMonths AS nvarchar(10))
		ELSE 'NA'
	END [TotalEconomicLife]
	,agl.HoldingStatus
	,agl.LineofBusinessId
	,a.ManufacturerId
	,a.AcquisitionDate
	,a.IsSystemCreated
INTO #EligibleAssets
FROM Assets a
INNER JOIN AssetGLDetails agl ON agl.Id = a.Id
INNER JOIN LegalEntities le ON a.LegalEntityId = le.Id
LEFT JOIN AssetTypes at ON a.TypeId = at.Id
LEFT JOIN AssetCatalogs act ON a.AssetCatalogId = act.Id
LEFT JOIN AssetCategories ac ON a.AssetCategoryId = ac.Id
LEFT JOIN Parties p ON a.CustomerId = p.Id
LEFT JOIN Parties v ON a.RemarketingVendorId = v.Id
LEFT JOIN #InvestorLeasedAssets il ON il.Id = a.Id
LEFT JOIN #CollateralLoanScrapedAssets cl ON cl.Id = a.Id
WHERE a.Status NOT IN ('Investor','Collateral','CollateralOnLoan')
	  AND il.Id IS NULL AND cl.Id IS NULL
	  AND @True = (CASE 
					   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = a.LegalEntityId) THEN @True
					   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)

CREATE NONCLUSTERED INDEX IX_Id ON #EligibleAssets(AssetId);

UPDATE ea
SET ea.AssetStatus = 'Inventory'
FROM #EligibleAssets ea
LEFT JOIN (
SELECT DISTINCT ea.AssetId
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
WHERE lf.IsCurrent = 1 AND la.IsActive = 1
AND ea.AssetStatus = 'Leased' AND lf.BookingStatus IN ('Commenced','InsuranceFollowup')) t ON t.AssetId = ea.AssetId
WHERE ea.AssetStatus = 'Leased' AND t.AssetId IS NULL
AND ea.IsSystemCreated = 0;

IF @IsSku = 1
BEGIN
SET @Sql =
'UPDATE ea
SET ea.IsSKU = 1
FROM #EligibleAssets ea
INNER JOIN Assets a ON ea.AssetId = a.Id AND a.IsSKU = 1'
INSERT INTO #EligibleAssets
EXEC (@Sql)
END;

SELECT
	ea.AssetId
	,CASE
		WHEN pa.IsPartiallyOwned = 1
		THEN 'Yes'
		ELSE 'No'
	END [IsPartiallyOwned]
	,CASE
		WHEN p.PayoffEffectiveDate >= ea.AcquisitionDate
		THEN DATEDIFF(MONTH,ea.AcquisitionDate,p.PayoffEffectiveDate)
		ELSE 0
	END [RemainingEconomicLife]
INTO #PayoffInfo
FROM #EligibleAssets ea
INNER JOIN (
	SELECT ea.AssetId,MAX(pa.Id) AS PayoffAssetId
	FROM #EligibleAssets ea
	INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
	INNER JOIN PayoffAssets pa ON pa.LeaseAssetId = la.Id
	INNER JOIN Payoffs p ON pa.PayoffId = p.Id
	AND p.Status = 'Activated' AND pa.IsActive = 1
	GROUP BY ea.AssetId) AS t ON t.AssetId = ea.AssetId
INNER JOIN PayoffAssets pa ON t.PayoffAssetId = pa.Id
INNER JOIN Payoffs p ON pa.PayoffId = p.Id
WHERE p.Status = 'Activated' AND pa.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #PayoffInfo(AssetId);

BEGIN
INSERT INTO #BuyoutInfo
SELECT
	ea.AssetId
	,SUM(CASE 
			WHEN (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
			AND ((p.LeaseFinanceId < rft.SyndicationLeaseFinanceId) OR rft.SyndicationLeaseFinanceId IS NULL)
			THEN pa.AssetValuation_Amount
			WHEN (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
			AND p.LeaseFinanceId >= rft.SyndicationLeaseFinanceId
			THEN CAST(pa.AssetValuation_Amount * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00 
		END) [BuyoutCostOfGoodsSold_LeaseComponent]
	,SUM(CASE 
			WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			AND ((p.LeaseFinanceId < rft.SyndicationLeaseFinanceId) OR rft.SyndicationLeaseFinanceId IS NULL)
			THEN pa.AssetValuation_Amount
			WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
			AND p.LeaseFinanceId >= rft.SyndicationLeaseFinanceId
			THEN CAST(pa.AssetValuation_Amount * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00 
		END) [BuyoutCostOfGoodsSold_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN PayoffAssets pa ON pa.LeaseAssetId = la.Id
INNER JOIN Payoffs p ON pa.PayoffId = p.Id
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
WHERE p.Status = 'Activated' AND pa.IsActive = 1
AND pa.Status IN ('Purchase','Repossessed','ReturnToUpgrade')
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
AND ea.IsSKU = 0
GROUP BY ea.AssetId
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	ea.AssetId
	,SUM(CASE 
			WHEN (las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0)
			AND ((p.LeaseFinanceId < rft.SyndicationLeaseFinanceId) OR rft.SyndicationLeaseFinanceId IS NULL)
			THEN pas.SKUValuation_Amount
			WHEN (las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0)
			AND p.LeaseFinanceId >= rft.SyndicationLeaseFinanceId
			THEN CAST(pas.SKUValuation_Amount * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00 
		END) [BuyoutCostOfGoodsSold_LeaseComponent]
	,SUM(CASE 
			WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
			AND ((p.LeaseFinanceId < rft.SyndicationLeaseFinanceId) OR rft.SyndicationLeaseFinanceId IS NULL)
			THEN pas.SKUValuation_Amount
			WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1)
			AND p.LeaseFinanceId >= rft.SyndicationLeaseFinanceId
			THEN CAST(pas.SKUValuation_Amount * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00 
		END) [BuyoutCostOfGoodsSold_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN Payoffs p ON lf.Id = p.LeaseFinanceId
INNER JOIN PayoffAssets pa ON pa.LeaseAssetId = la.Id AND pa.PayoffId = p.Id
INNER JOIN PayoffAssetSKUs pas ON las.Id = pas.LeaseAssetSKUId AND pas.PayoffAssetId = pa.Id
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
WHERE p.Status = ''Activated'' AND pa.IsActive = 1
AND pa.Status IN (''Purchase'',''Repossessed'',''ReturnToUpgrade'')
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
AND las.IsActive = 1
AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #BuyoutInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #BuyoutInfo(AssetId);

SELECT
	DISTINCT a.Id AS ParentAsset
INTO #HasChildAssets
FROM #EligibleAssets ea
INNER JOIN Assets a ON ea.ParentAssetId = a.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #HasChildAssets(ParentAsset);

BEGIN
INSERT INTO #CapitalizedSoftAssetInfo
SELECT DISTINCT
	ea.AssetId
	,la.CapitalizationType
	,lai.AssetId [SoftAssetCapitalizedFor]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseAssets lai ON lai.Id = la.CapitalizedForId
WHERE la.CapitalizedForId IS NOT NULL 
END;

IF @AddCharge = 1
BEGIN
SET @Sql =
'SELECT DISTINCT 
	ea.AssetId
	,CapitalizationType = ''AdditionalCharge'' 
	,la.CapitalizedForId [SoftAssetCapitalizedFor]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE IsAdditionalChargeSoftAsset = 1'
INSERT INTO #CapitalizedSoftAssetInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #CapitalizedSoftAssetInfo(AssetId);

BEGIN
SET @Sql =
'SELECT
	ea.AssetId
	,lf.ContractId [LeaseContractId]
	,lfd.LeaseContractType [LeaseContractType]
	,lfd.CommencementDate
	,lf.Id [LeaseFinanceId]
	,la.Id [LeaseAssetId]
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
	,(CASE WHEN ea.AssetStatus IN (''Leased'',''InvestorLeased'')
		THEN la.NBV_Amount
		ELSE 0.00 END)
	+(CASE WHEN ea.AssetStatus IN (''Leased'',''InvestorLeased'') AND la.CapitalizedForId IS NOT NULL
		THEN la.CapitalizedSalesTax_Amount
			+ la.CapitalizedInterimInterest_Amount
			+ la.CapitalizedInterimRent_Amount
			+ la.CapitalizedProgressPayment_Amount
		ELSE 0.00 END)
	+ (AdditionalCharge) AS LeasedAssetCost
	,ea.AssetStatus
	,CASE WHEN ea.AssetStatus IN (''Leased'',''InvestorLeased'') AND ea.HoldingStatus = ''HFI''
	THEN DATEDIFF(Month,ea.AcquisitionDate,lfd.MaturityDate)
	ELSE 0
	END [RemainingEconomicLife]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1 AND la.IsActive = 1'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge', 'CASE WHEN ea.AssetStatus IN (''Leased'',''InvestorLeased'') AND la.IsAdditionalChargeSoftAsset = 1 THEN la.CapitalizedAdditionalCharge_Amount ELSE 0.00 END');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO #LeaseAssetsInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAssetsInfo(AssetId);

UPDATE lai
SET lai.LeasedAssetCost -= bia.TaxCredit_Amount
FROM #LeaseAssetsInfo lai
INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = lai.LeaseAssetId
INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
WHERE (bia.IsActive = 1 and bi.IsActive = 1) AND bi.IsETC = 1

BEGIN
INSERT INTO #LeaseAssetsAmountInfo
SELECT 
	ea.AssetId
	,CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND lfd.LeaseContractType != 'Operating'
		THEN la.FMV_Amount
		ELSE 0.00
	END AS [FMVAmount_LeaseComponent]
	,CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		THEN la.BookedResidual_Amount
		ELSE 0.00
	END AS [BookedResidual_LeaseComponent]
	,CASE
		WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1
		THEN la.BookedResidual_Amount
		ELSE 0.00
	END AS [BookedResidual_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1 AND la.IsActive = 1
AND lf.ApprovalStatus IN ('Approved','InsuranceFollowup')
AND ea.IsSKU = 0
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT 
	ea.AssetId
	,SUM(CASE
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.FMV_Amount
		ELSE 0.00
	END) AS [FMVAmount_LeaseComponent]
	,SUM(CASE
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.BookedResidual_Amount
		ELSE 0.00
	END) AS [BookedResidual_LeaseComponent]
	,SUM(CASE
		WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
		THEN las.BookedResidual_Amount
		ELSE 0.00
	END) AS [BookedResidual_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1 AND la.IsActive = 1 AND las.IsActive = 1
AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #LeaseAssetsAmountInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAssetsAmountInfo(AssetId);

BEGIN
SET @Sql =
'SELECT 
	ea.AssetId
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
		THEN la.NBV_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedInterimRent_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 1
		THEN la.CapitalizedSalesTax_Amount
		ELSE 0.00
	END) AS [TaxCapitalizedAmount_LeaseComponent]
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForCappedSalesTax = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		THEN la.NBV_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedInterimRent_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 0
		THEN la.CapitalizedSalesTax_Amount
		ELSE 0.00
	END) AS [TaxCapitalizedAmount_FinanceComponent]
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 1
		THEN la.CapitalizedInterimRent_Amount
		ELSE 0.00
	END) AS [InterimRentCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForInterimRent = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 0
		THEN la.CapitalizedInterimRent_Amount
		ELSE 0.00
	END) AS [InterimRentCapitalizationAmount_FinanceComponent]
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimRent_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 1
		THEN la.CapitalizedInterimInterest_Amount
		ELSE 0.00
	END) AS [InterimInterestCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN lfd.CreateSoftAssetsForInterimInterest = 1 AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimRent_Amount
			   - la.CapitalizedProgressPayment_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 0
		THEN la.CapitalizedInterimInterest_Amount
		ELSE 0.00
	END) AS [InterimInterestCapitalizationAmount_FinanceComponent]
	,SUM(CAST (0 AS decimal(16,2))) [AdditionalChargesCapitalizationAmount_LeaseComponent]
	,SUM(CAST (0 AS decimal(16,2))) [AdditionalChargesCapitalizationAmount_FinanceComponent]
	,SUM(CASE 
		WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedInterimRent_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 1
		THEN la.CapitalizedProgressPayment_Amount
		ELSE 0.00
	END) AS [ProgressPaymentCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN la.CapitalizationType = ''CapitalizedProgressPayment'' AND la.CapitalizedForId IS NOT NULL
		AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		THEN la.NBV_Amount
			   - la.CapitalizedSalesTax_Amount
			   - la.CapitalizedInterimInterest_Amount
			   - la.CapitalizedInterimRent_Amount
			   AdditionalCharge
		WHEN la.IsLeaseAsset = 0
		THEN la.CapitalizedProgressPayment_Amount
		ELSE 0.00
	END) AS [ProgressPaymentCapitalizationAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1 AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
AND ea.IsSKU = 0
GROUP BY ea.AssetId'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','- la.CapitalizedAdditionalCharge_Amount');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO #LeaseCapitalizedAmountInfo
EXEC (@Sql)
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT 
	ea.AssetId
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.CapitalizedSalesTax_Amount
		ELSE 0.00
	END) AS [TaxCapitalizedAmount_LeaseComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
		THEN las.CapitalizedSalesTax_Amount
		ELSE 0.00
	END) AS [TaxCapitalizedAmount_FinanceComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.CapitalizedInterimRent_Amount
		ELSE 0.00
	END) AS [InterimRentCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
		THEN las.CapitalizedInterimRent_Amount
		ELSE 0.00
	END) AS [InterimRentCapitalizationAmount_FinanceComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.CapitalizedInterimInterest_Amount
		ELSE 0.00
	END) AS [InterimInterestCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
		THEN las.CapitalizedInterimInterest_Amount
		ELSE 0.00
	END) AS [InterimInterestCapitalizationAmount_FinanceComponent]
	,SUM(CAST (0 AS decimal(16,2))) [AdditionalChargesCapitalizationAmount_LeaseComponent]
	,SUM(CAST (0 AS decimal(16,2))) [AdditionalChargesCapitalizationAmount_FinanceComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
		THEN las.CapitalizedProgressPayment_Amount
		ELSE 0.00
	END) AS [ProgressPaymentCapitalizationAmount_LeaseComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
		THEN las.CapitalizedProgressPayment_Amount
		ELSE 0.00
	END) AS [ProgressPaymentCapitalizationAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #LeaseCapitalizedAmountInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseCapitalizedAmountInfo(AssetId);

IF @AddCharge = 1
BEGIN
SET @Sql =
'UPDATE lci
SET lci.AdditionalChargesCapitalizationAmount_LeaseComponent =
	CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND la.IsAdditionalChargeSoftAsset = 1
		THEN la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount - la.CapitalizedProgressPayment_Amount - la.CapitalizedInterimInterest_Amount
		WHEN la.IsLeaseAsset = 1 AND la.IsAdditionalChargeSoftAsset = 0
		THEN la.CapitalizedAdditionalCharge_Amount
		ELSE 0.00
	END
	,lci.AdditionalChargesCapitalizationAmount_FinanceComponent =
	CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		AND la.IsAdditionalChargeSoftAsset = 1
		THEN la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount - la.CapitalizedProgressPayment_Amount - la.CapitalizedInterimInterest_Amount
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
		AND la.IsAdditionalChargeSoftAsset = 0
		THEN la.CapitalizedAdditionalCharge_Amount
		ELSE 0.00
	END
FROM #LeaseCapitalizedAmountInfo lci
INNER JOIN #EligibleAssets ea ON lci.AssetId = ea.AssetId
INNER JOIN LeaseAssets la ON la.AssetId = lci.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE lf.IsCurrent = 1 AND ea.IsSKU = 0
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')'
INSERT INTO #LeaseCapitalizedAmountInfo
EXEC (@Sql)
END;

IF @AddCharge = 1 AND @IsSku = 1
BEGIN
SET @Sql =
'UPDATE lci
SET lci.AdditionalChargesCapitalizationAmount_LeaseComponent = t.AdditionalChargesCapitalizationAmount_LeaseComponent
	,lci.AdditionalChargesCapitalizationAmount_FinanceComponent = t.AdditionalChargesCapitalizationAmount_FinanceComponent
FROM #LeaseCapitalizedAmountInfo lci
INNER JOIN (
		SELECT 
			lci.AssetId
			,SUM(CASE WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
			THEN las.CapitalizedAdditionalCharge_Amount ELSE 0.00 END) as AdditionalChargesCapitalizationAmount_LeaseComponent
			,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
			THEN las.CapitalizedAdditionalCharge_Amount ELSE 0.00 END) as AdditionalChargesCapitalizationAmount_FinanceComponent
		FROM #LeaseCapitalizedAmountInfo lci
		INNER JOIN #EligibleAssets ea ON lci.AssetId = ea.AssetId
		INNER JOIN LeaseAssets la ON la.AssetId = lci.AssetId
		INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
		INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
		INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
		WHERE lf.IsCurrent = 1
		AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
		AND las.IsActive = 1 AND ea.IsSKU = 1
		AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
		GROUP BY lci.AssetId
	) AS t ON t.AssetId = lci.AssetId'
INSERT INTO #LeaseCapitalizedAmountInfo
EXEC (@Sql)
END;

BEGIN
INSERT INTO #CurrentNBVInfo
SELECT
	t.AssetId
	,SUM(CASE WHEN t.IsLeaseAsset = 1 AND t.IsFailedSaleLeaseback = 0 THEN EndNetBookValue_Amount ELSE 0.00 END) [CurrentNBVAmount_LeaseComponent]
	,SUM(CASE WHEN t.IsLeaseAsset = 0 OR t.IsFailedSaleLeaseback = 1 THEN EndNetBookValue_Amount ELSE 0.00 END) [CurrentNBVAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
	,ais.EndNetBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId,la.IsLeaseAsset,la.IsFailedSaleLeaseback
	ORDER BY lis.IncomeDate DESC) AS rn
FROM #EligibleAssets ea
INNER JOIN AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id AND lf.IsCurrent = 1
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
INNER JOIN Contracts c ON lf.ContractId = c.Id
WHERE lis.IsGLPosted = 1 AND lis.IsAccounting = 1 AND ea.IsSKU = 0 AND lis.AdjustmentEntry = 0
AND ((lfd.LeaseContractType != 'Operating' AND la.IsLeaseAsset = 1) OR la.IsLeaseAsset = 0)
AND ea.AssetStatus IN ('Leased','InvestorLeased') AND c.SyndicationType != 'FullSale'
) AS t
WHERE t.rn = 1
GROUP BY t.AssetId
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.LeaseEndNetBookValue_Amount) [CurrentNBVAmount_LeaseComponent]
	,SUM(t.FinanceEndNetBookValue_Amount) [CurrentNBVAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,CASE WHEN lfd.LeaseContractType != ''Operating'' THEN ais.LeaseEndNetBookValue_Amount ELSE 0.00 END LeaseEndNetBookValue_Amount
	,ais.FinanceEndNetBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId
	ORDER BY lis.IncomeDate DESC) AS rn
FROM #EligibleAssets ea
INNER JOIN AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lis.LeaseFinanceId
WHERE lis.IsGLPosted = 1 AND lis.IsAccounting = 1 AND ea.IsSKU = 1 AND lis.AdjustmentEntry = 0
AND ea.AssetStatus IN (''Leased'',''InvestorLeased'')
) AS t
WHERE t.rn = 1
GROUP BY t.AssetId'
INSERT INTO #CurrentNBVInfo
EXEC (@Sql)
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.LeaseComponentSKUCount)
	,SUM(t.FinanceComponentSKUCount)
FROM (
	SELECT
		ea.AssetId
		,SUM(CASE WHEN las.IsLeaseComponent = 1 THEN 1 ELSE 0 END) [LeaseComponentSKUCount]
		,SUM(CASE WHEN las.IsLeaseComponent = 0 THEN 1 ELSE 0 END) [FinanceComponentSKUCount]
	FROM #EligibleAssets ea
	INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
	INNER JOIN LeaseAssetSKUs las ON la.Id = las.LeaseAssetId
	INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
	WHERE ea.IsSKU = 1 AND ea.AssetStatus = ''Leased''
	AND la.IsActive = 1 AND las.IsActive = 1 AND lf.IsCurrent = 1
	GROUP BY ea.AssetId,las.IsLeaseComponent
	UNION
	SELECT
		ea.AssetId
		,SUM(CASE WHEN ask.IsLeaseComponent = 1 THEN 1 ELSE 0 END) [LeaseComponentSKUCount]
		,SUM(CASE WHEN ask.IsLeaseComponent = 0 THEN 1 ELSE 0 END) [FinanceComponentSKUCount]
	FROM #EligibleAssets ea
	INNER JOIN AssetSKUs ask ON ask.AssetId = ea.AssetId
	WHERE ea.IsSKU = 1 AND ea.AssetStatus != ''Leased''
	GROUP BY ea.AssetId,ask.IsLeaseComponent
	) AS t GROUP BY t.AssetId'
INSERT INTO #SKUComponentCount
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #SKUComponentCount(AssetId);

BEGIN
INSERT INTO #PayableInvoiceInfo
SELECT 
	pin.InvoiceNumber
	,p.PartyName [VendorName]
	,pia.AssetId
	,pia.Id [PayableInvoiceAssetId]
	,pia.AcquisitionCost_Amount
	,pia.OtherCost_Amount
	,pin.Id
	,pin.IsForeignCurrency
	,pin.InitialExchangeRate
	,pin.OriginalExchangeRate
	,ea.IsSKU
	,ea.AssetStatus
	,ea.IsLeaseComponent
FROM PayableInvoices pin
INNER JOIN PayableInvoiceAssets pia ON pia.PayableInvoiceId = pin.Id
INNER JOIN #EligibleAssets ea ON pia.AssetId = ea.AssetId
INNER JOIN Parties p ON pin.VendorId = p.Id
LEFT JOIN LeaseFundings lfu ON lfu.FundingId = pin.Id
LEFT JOIN LeaseFinances lf ON lfu.LeaseFinanceId = lf.Id
WHERE pin.Status = 'Completed' AND pia.IsActive = 1
AND (lfu.FundingId IS NULL OR (lfu.FundingId IS NOT NULL AND lf.IsCurrent = 1 AND lfu.IsActive = 1))
END;

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceInfo(AssetId);

SELECT 
	ea.AssetId
	,IIF((a.Status IN ('Leased','InvestorLeased')),c.SyndicationType,'NA') [SyndicationType]
	,c.Id AS [ContractId]
	,IIF(la.AssetId IS NOT NULL AND (a.Status IN ('Leased','InvestorLeased')),c.SequenceNumber,'NA') [SequenceNumber]
	,IIF(la.AssetId IS NOT NULL AND (a.Status IN ('Leased','InvestorLeased')),la.LeaseContractType,'NA') [ContractType]
INTO #ContractInfo
FROM #EligibleAssets ea
INNER JOIN Assets a ON ea.AssetId = a.Id
LEFT JOIN #LeaseAssetsInfo la ON ea.AssetId = la.AssetId
LEFT JOIN Contracts c ON la.LeaseContractId = c.Id;

CREATE NONCLUSTERED INDEX IX_Id ON #ContractInfo(AssetId);

SELECT
	c.AssetId
INTO #ChargeOffInfo
FROM #ContractInfo c
INNER JOIN ChargeOffs co ON co.ContractId = c.ContractId
WHERE co.IsActive = 1 AND co.Status = 'Approved'
AND co.IsRecovery = 0 AND co.ReceiptId IS NULL;

CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOffInfo(AssetId);

SELECT
	t.AssetId
INTO #AssetSplitInfo
FROM (
	SELECT
		ea.AssetId
	FROM #EligibleAssets ea
	INNER JOIN AssetSplitDetails asd ON ea.AssetId = asd.OriginalAssetId
	INNER JOIN AssetSplits asl ON asl.Id = asd.AssetSplitId
	WHERE asd.IsActive = 1 AND asl.ApprovalStatus = 'Approved'
	UNION
	SELECT
		ea.AssetId
	FROM #EligibleAssets ea
	INNER JOIN AssetSplits asl ON asl.FeatureAssetId = ea.AssetId
	WHERE asl.ApprovalStatus = 'Approved'
	) AS t GROUP BY t.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetSplitInfo(AssetId);

SELECT 
	ea.AssetId
	,asi.AssetId [OriginalAssetId]
INTO #CreatedFromAssetSplit
FROM #EligibleAssets ea
INNER JOIN AssetSplitAssetDetails asad ON ea.AssetId = asad.NewAssetId
INNER JOIN AssetSplitAssets asa ON asa.Id = asad.AssetSplitAssetId
INNER JOIN #AssetSplitInfo asi ON asa.OriginalAssetId = asi.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #CreatedFromAssetSplit(AssetId);

BEGIN
INSERT INTO #AssetSaleInfo
SELECT
	AssetId
	,SUM(CASE WHEN IsLeaseComponent = 1 THEN EndBookValue_Amount ELSE 0.00 END) [AssetSaleCostOfGoodsSold_LeaseComponent]
	,SUM(CASE WHEN IsLeaseComponent = 0 THEN EndBookValue_Amount ELSE 0.00 END) [AssetSaleCostOfGoodsSold_FinanceComponent]
FROM (
SELECT
	ea.AssetId
	,ea.IsLeaseComponent
	,avh.EndBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId,ea.IsLeaseComponent
	ORDER BY avh.Id DESC) AS rn
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN AssetSaleDetails asd ON ea.AssetId = asd.AssetId
INNER JOIN AssetSales asl ON asd.AssetSaleId = asl.Id
AND asd.IsActive = 1 AND asl.Status = 'Completed'
WHERE avh.IncomeDate <= asl.TransactionDate
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND ea.IsSKU = 0
) AS t
WHERE t.rn = 1
GROUP BY AssetId
END;

UPDATE asi
SET asi.AssetSaleCostOfGoodsSold_LeaseComponent = 0.00
,asi.AssetSaleCostOfGoodsSold_FinanceComponent = 0.00
FROM #AssetSaleInfo asi
INNER JOIN (
SELECT DISTINCT AssetId FROM AssetHistories WHERE SourceModule = 'ReceivableForTransfer' AND Status = 'InvestorLeased'
INTERSECT
SELECT DISTINCT AssetId FROM AssetHistories WHERE SourceModule = 'AssetSale' AND Status = 'Sold'
) AS t ON t.AssetId = asi.AssetId;

IF @IsSKU = 1
BEGIN
SET @Sql =
'SELECT
	AssetId
	,SUM(CASE WHEN IsLeaseComponent = 1 THEN EndBookValue_Amount ELSE 0.00 END) [AssetSaleCostOfGoodsSold_LeaseComponent]
	,SUM(CASE WHEN IsLeaseComponent = 0 THEN EndBookValue_Amount ELSE 0.00 END) [AssetSaleCostOfGoodsSold_FinanceComponent]
FROM (
SELECT
	ea.AssetId
	,avh.IsLeaseComponent
	,avh.EndBookValue_Amount
	,ROW_NUMBER() OVER (PARTITION BY ea.AssetId,avh.IsLeaseComponent
	ORDER BY avh.Id DESC) AS rn
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN AssetSaleDetails asd ON ea.AssetId = asd.AssetId
INNER JOIN AssetSales asl ON asd.AssetSaleId = asl.Id
AND asd.IsActive = 1 AND asl.Status = ''Completed''
WHERE avh.IncomeDate <= asl.TransactionDate
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND ea.IsSKU = 1
) AS t
WHERE t.rn = 1
GROUP BY AssetId'
INSERT INTO #AssetSaleInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetSaleInfo(AssetId);

BEGIN
INSERT INTO #AcquisitionCostInfo
SELECT 
	pin.AssetId
	,CASE
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_LeaseComponent]
	,CASE
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_FinanceComponent]
	,CASE
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0
		THEN pin.OtherCost_Amount
		ELSE 0.00
	END [OtherCost_LeaseComponent]
	,CASE
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN pin.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0
		THEN pin.OtherCost_Amount
		ELSE 0.00
	END [OtherCost_FinanceComponent]
FROM #PayableInvoiceInfo pin
INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId
AND p.EntityId = pin.Id AND p.EntityType = 'PI'
WHERE p.SourceTable = 'PayableInvoiceAsset'
AND p.IsGLPosted = 1 AND pin.IsSKU = 0 AND p.Status != 'Inactive'
AND pin.AssetStatus NOT IN ('Leased','InvestorLeased')
END;

BEGIN
INSERT INTO #AcquisitionCostInfo
SELECT 
	pin.AssetId
	,CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_LeaseComponent]
	,CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1
		THEN CAST (pin.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0
		THEN pin.AcquisitionCost_Amount
		ELSE 0.00
	END [AcquisitionCost_FinanceComponent]
	,CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1
		THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0
		THEN pin.OtherCost_Amount
		ELSE 0.00
	END [OtherCost_LeaseComponent]
	,CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1
		THEN CAST (pin.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0
		THEN pin.OtherCost_Amount
		ELSE 0.00
	END [OtherCost_FinanceComponent]
FROM #PayableInvoiceInfo pin
INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId
AND p.EntityId = pin.Id AND p.EntityType = 'PI'
INNER JOIN LeaseAssets la ON pin.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE p.SourceTable = 'PayableInvoiceAsset' AND lf.IsCurrent = 1 
AND la.IsActive = 1 AND pin.IsSKU = 0 AND p.IsGLPosted = 1 AND p.Status != 'Inactive'
AND pin.AssetStatus IN ('Leased','InvestorLeased')
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT 
	asku.AssetId
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount 
		ELSE 0.00 END) [AcquisitionCost_LeaseComponent]
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_FinanceComponent]
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 1 AND pin.IsForeignCurrency = 0 
		THEN pias.OtherCost_Amount
		ELSE 0.00 END) [OtherCost_LeaseComponent]
	,SUM(CASE 
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN asku.IsLeaseComponent = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.OtherCost_Amount
		ELSE 0.00 END) [OtherCost_FinanceComponent]
FROM #PayableInvoiceInfo pin
INNER JOIN AssetSKUs asku ON pin.AssetId = asku.AssetId
INNER JOIN PayableInvoiceAssetSKUs pias ON pias.AssetSKUId = asku.Id 
AND pias.PayableInvoiceAssetId = pin.PayableInvoiceAssetId
INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId AND p.EntityId = pin.Id
WHERE p.SourceTable = ''PayableInvoiceAsset'' AND p.EntityType = ''PI''
AND p.IsGLPosted = 1 AND pias.IsActive = 1 AND pin.IsSKU = 1 AND p.Status != ''Inactive''
AND pin.AssetStatus NOT IN (''Leased'')
GROUP BY asku.AssetId'
INSERT INTO #AcquisitionCostInfo
EXEC (@Sql)
END;

IF @IsSKU = 1
BEGIN
SET @Sql = 
'SELECT pin.AssetId
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_LeaseComponent]
	,SUM(CASE 
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.AcquisitionCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0 
		THEN pias.AcquisitionCost_Amount
		ELSE 0.00 END) [AcquisitionCost_FinanceComponent]
	,SUM(CASE 
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pin.IsForeignCurrency = 0 
		THEN pias.OtherCost_Amount 
		ELSE 0.00 END) [OtherCost_LeaseComponent]
	,SUM(CASE 
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 1 
		THEN CAST(pias.OtherCost_Amount * pin.InitialExchangeRate AS decimal (16,2))
		WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pin.IsForeignCurrency = 0 
		THEN pias.OtherCost_Amount 
		ELSE 0.00 END) [OtherCost_FinanceComponent]
FROM #PayableInvoiceInfo pin
INNER JOIN AssetSKUs asku ON pin.AssetId = asku.AssetId
INNER JOIN PayableInvoiceAssetSKUs pias ON pias.AssetSKUId = asku.Id 
AND pias.PayableInvoiceAssetId = pin.PayableInvoiceAssetId
INNER JOIN Payables p ON p.SourceId = pin.PayableInvoiceAssetId AND p.EntityId = pin.Id
INNER JOIN LeaseAssetSKUs las ON las.AssetSKUId = asku.Id
INNER JOIN LeaseAssets la ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE p.SourceTable = ''PayableInvoiceAsset'' AND p.EntityType = ''PI''
AND p.IsGLPosted = 1 AND p.Status != ''Inactive'' AND lf.IsCurrent = 1 AND la.IsActive = 1 AND pias.IsActive = 1
AND pin.IsSKU = 1 AND pin.AssetStatus IN (''Leased'') AND las.IsActive = 1
GROUP BY pin.AssetId'
INSERT INTO #AcquisitionCostInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #AcquisitionCostInfo(AssetId);

BEGIN
INSERT INTO #PayableInvoiceOtherCostInfo
SELECT
	ea.AssetId
	,ea.IsSKU
	,ea.IsLeaseComponent
	,ea.AssetStatus
	,pin.Id [PayableInvoiceId]
	,pin.IsForeignCurrency
	,pin.InitialExchangeRate
	,pioc.Id [PayableInvoiceOtherCostId]
	,pioc.Amount_Amount [SpecificCost_Amount]
	,0 [AssignOtherCostAtSKULevel]
	,p.IsGLPosted
FROM PayableInvoiceOtherCosts pioc
INNER JOIN #EligibleAssets ea ON pioc.AssetId = ea.AssetId AND pioc.IsActive = 1
INNER JOIN PayableInvoices pin ON pioc.PayableInvoiceId = pin.Id 
INNER JOIN Payables p ON p.EntityId = pin.Id AND pioc.Id = p.SourceId
WHERE pin.Status = 'Completed' AND pioc.IsActive = 1
AND pioc.AllocationMethod = 'SpecificCostAdjustment' AND EntityType = 'PI'
AND p.SourceTable = 'PayableInvoiceOtherCost' AND p.Status != 'Inactive'
END;

CREATE NONCLUSTERED INDEX IX_Id ON #PayableInvoiceOtherCostInfo(AssetId);

IF @IsSku = 1
BEGIN
SET @Sql =
'UPDATE pioci
SET pioci.AssignOtherCostAtSKULevel = 1
FROM #PayableInvoiceOtherCostInfo pioci
INNER JOIN PayableInvoiceOtherCosts pioc ON pioci.PayableInvoiceOtherCostId = pioc.Id 
WHERE pioc.AssignOtherCostAtSKULevel = 1;'
INSERT INTO #PayableInvoiceOtherCostInfo
EXEC (@Sql)
END;

BEGIN
INSERT INTO #SpecificCostInfo
SELECT
	pioc.AssetId
	,SUM(
		CASE 
			WHEN pioc.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 1 
			THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN pioc.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 0
			THEN pioc.SpecificCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_LeaseComponent]
	,SUM(
		CASE 
			WHEN pioc.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 1 
			THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN pioc.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 0
			THEN pioc.SpecificCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_FinanceComponent]
FROM #PayableInvoiceOtherCostInfo pioc
WHERE (pioc.IsSKU = 0 OR (pioc.IsSKU = 1 AND pioc.AssignOtherCostAtSKULevel = 0))
AND pioc.AssetStatus NOT IN ('Leased','InvestorLeased') AND pioc.IsGLPosted = 1
GROUP BY pioc.AssetId
END;

BEGIN
INSERT INTO #SpecificCostInfo
SELECT
	pioc.AssetId
	,SUM(
		CASE 
			WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pioc.IsForeignCurrency = 1 
			THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND pioc.IsForeignCurrency = 0
			THEN pioc.SpecificCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_LeaseComponent]
	,SUM(
		CASE 
			WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pioc.IsForeignCurrency = 1 
			THEN CAST (pioc.SpecificCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND pioc.IsForeignCurrency = 0
			THEN pioc.SpecificCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_FinanceComponent]
FROM #PayableInvoiceOtherCostInfo pioc
INNER JOIN LeaseAssets la ON la.AssetId = pioc.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE lf.IsCurrent = 1 AND la.IsActive = 1
AND (pioc.IsSKU = 0 OR (pioc.IsSKU = 1 AND pioc.AssignOtherCostAtSKULevel = 0))
AND pioc.AssetStatus IN ('Leased','InvestorLeased') AND pioc.IsGLPosted = 1
GROUP BY pioc.AssetId
END;

If @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	pioc.AssetId
	,SUM(
		CASE 
			WHEN asku.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 1 
			THEN CAST (piosku.OtherCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN asku.IsLeaseComponent = 1 AND pioc.IsForeignCurrency = 0
			THEN piosku.OtherCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_LeaseComponent]
	,SUM(
		CASE 
			WHEN asku.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 1 
			THEN CAST (piosku.OtherCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN asku.IsLeaseComponent = 0 AND pioc.IsForeignCurrency = 0
			THEN piosku.OtherCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_FinanceComponent]
FROM #PayableInvoiceOtherCostInfo pioc
INNER JOIN PayableInvoiceOtherCostSKUDetails piosku ON pioc.PayableInvoiceOtherCostId = piosku.PayableInvoiceOtherCostId
INNER JOIN PayableInvoiceAssetSKUs piasku ON piosku.PayableInvoiceAssetSKUId = piasku.Id
INNER JOIN AssetSKUs asku ON piasku.AssetSKUId = asku.Id
WHERE pioc.IsSKU = 1 AND pioc.AssignOtherCostAtSKULevel = 1
AND pioc.AssetStatus NOT IN (''Leased'') AND pioc.IsGLPosted = 1
GROUP BY pioc.AssetId'
INSERT INTO #SpecificCostInfo
EXEC (@Sql)
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	pioc.AssetId
	,SUM(
		CASE 
			WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pioc.IsForeignCurrency = 1 
			THEN CAST (piosku.OtherCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 AND pioc.IsForeignCurrency = 0
			THEN piosku.OtherCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_LeaseComponent]
	,SUM(
		CASE 
			WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pioc.IsForeignCurrency = 1 
			THEN CAST (piosku.OtherCost_Amount * pioc.InitialExchangeRate AS decimal (16,2))
			WHEN (las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1) AND pioc.IsForeignCurrency = 0
			THEN piosku.OtherCost_Amount
			ELSE 0.00
		END) AS [SpecificCostAdjustment_FinanceComponent]
FROM #PayableInvoiceOtherCostInfo pioc
INNER JOIN PayableInvoiceOtherCostSKUDetails piosku ON pioc.PayableInvoiceOtherCostId = piosku.PayableInvoiceOtherCostId
INNER JOIN PayableInvoiceAssetSKUs piasku ON piosku.PayableInvoiceAssetSKUId = piasku.Id
INNER JOIN LeaseAssetSKUs las ON las.AssetSKUId = piasku.AssetSKUId
INNER JOIN LeaseAssets la ON la.Id = las.LeaseAssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE lf.IsCurrent = 1 AND la.IsActive = 1 AND las.IsActive = 1 AND pioc.IsGLPosted = 1
AND pioc.IsSKU = 1 AND pioc.AssetStatus IN (''Leased'') AND pioc.AssignOtherCostAtSKULevel = 1
GROUP BY pioc.AssetId'
INSERT INTO #SpecificCostInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #SpecificCostInfo(AssetId);

SELECT 
	Distinct ea.AssetId
INTO #OverTerm
FROM #EligibleAssets ea
INNER JOIN AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseFinances lf ON lis.LeaseFinanceId = lf.Id
INNER JOIN #ContractInfo c ON lf.ContractId = c.ContractId
WHERE lis.IsSchedule = 1 AND lis.IncomeType = 'OverTerm' AND ais.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #OverTerm(AssetId);

SELECT Distinct 
	c.Id AS ContractId
	,lam.OriginalLeaseFinanceId 
	,lam.CurrentLeaseFinanceId
	,lam.AmendmentDate
INTO #LeaseAmendmentInfo
FROM Contracts c
INNER JOIN LeaseFinances lf ON c.Id = lf.ContractId
INNER JOIN LeaseAmendments lam ON lam.CurrentLeaseFinanceId = lf.Id
WHERE lam.AmendmentType = 'Renewal' AND lam.LeaseAmendmentStatus = 'Approved';

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAmendmentInfo(ContractId);

BEGIN
INSERT INTO #OTPReclass
SELECT
	DISTINCT ea.AssetId
FROM #EligibleAssets ea
INNER JOIN AssetIncomeSchedules ais ON ea.AssetId = ais.AssetId
INNER JOIN LeaseIncomeSchedules lis ON ais.LeaseIncomeScheduleId = lis.Id
INNER JOIN LeaseFinances lf ON lis.LeaseFinanceId = lf.Id
LEFT JOIN #LeaseAmendmentInfo lam ON lam.ContractId = lf.ContractId
WHERE lis.IsSchedule = 1 AND lis.IncomeType = 'OverTerm' 
AND ais.IsActive = 1 AND lis.IsLessorOwned = 1 AND lis.IsReclassOTP = 1
AND (lam.ContractId IS NULL OR (lam.ContractId IS NOT NULL AND lis.LeaseFinanceId >= lam.CurrentLeaseFinanceId))
END;

CREATE NONCLUSTERED INDEX IX_Id ON #OTPReclass(AssetId);

UPDATE la
	SET 
	la.BookedResidual_LeaseComponent = 
		(CASE 
			WHEN co.AssetId IS NULL
			THEN CAST(la.BookedResidual_LeaseComponent * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00
		END)
	,la.BookedResidual_FinanceComponent = 
		(CASE 
			WHEN co.AssetId IS NULL
			THEN CAST(la.BookedResidual_FinanceComponent * rft.RetainedPortion AS DECIMAL (16, 2))
			ELSE 0.00
		END)
FROM #EligibleAssets ea
INNER JOIN #LeaseAssetsAmountInfo la ON ea.AssetId = la.AssetId
INNER JOIN #ContractInfo c ON ea.AssetId = c.AssetId
LEFT JOIN #ChargeOffInfo co ON ea.AssetId = co.AssetId
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = c.ContractId
WHERE (co.AssetId IS NOT NULL 
		OR (rft.ContractId IS NOT NULL AND rft.ContractType = 'Lease' AND c.SyndicationType IN ('ParticipatedSale','FullSale')));

UPDATE la
	SET la.BookedResidual_LeaseComponent = 0.00
		,la.BookedResidual_FinanceComponent = 0.00
FROM #LeaseAssetsAmountInfo la 
INNER JOIN #OTPReclass otprc ON otprc.AssetId = la.AssetId;

BEGIN
INSERT INTO #BookDepId
SELECT
	t.AssetId
	,t.IsLeaseComponent
	,CASE WHEN t.MaxLastAmortRunDate IS NOT NULL THEN t.MaxBookDepId ELSE t.MinBookDepId END BookDepreciationId
FROM (
	SELECT
		bd.AssetId
		,ea.IsLeaseComponent
		,Min(bd.Id) MinBookDepId
		,Max(bd.Id) MaxBookDepId
		,Max(bd.LastAmortRunDate) MaxLastAmortRunDate
	FROM #EligibleAssets ea
	INNER JOIN BookDepreciations bd ON bd.AssetId = ea.AssetId
	WHERE ea.IsSKU = 0
	GROUP BY bd.AssetId,ea.IsLeaseComponent) AS t
END;

If @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,t.IsLeaseComponent
	,CASE WHEN t.MaxLastAmortRunDate IS NOT NULL THEN t.MaxBookDepId ELSE t.MinBookDepId END BookDepreciationId
FROM (
	SELECT
		bd.AssetId
		,bd.IsLeaseComponent
		,Min(bd.Id) MinBookDepId
		,Max(bd.Id) MaxBookDepId
		,Max(bd.LastAmortRunDate) MaxLastAmortRunDate
	FROM #EligibleAssets ea
	INNER JOIN BookDepreciations bd ON bd.AssetId = ea.AssetId
	WHERE ea.IsSKU = 1
	GROUP BY bd.AssetId,bd.IsLeaseComponent) AS t'
INSERT INTO #BookDepId
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #BookDepId(AssetId);

BEGIN
INSERT INTO #BookDepreciationInfo
SELECT
	ea.AssetId
	,CASE WHEN ea.IsLeaseComponent = 1 THEN bd.Salvage_Amount ELSE 0.00 END [BookedResidual_LeaseComponent]
	,CASE WHEN ea.IsLeaseComponent = 0 THEN bd.Salvage_Amount ELSE 0.00 END [BookedResidual_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN BookDepreciations bd ON bd.AssetId = ea.AssetId
INNER JOIN #BookDepId bdi ON bdi.BookDepreciationId = bd.Id
WHERE ea.AssetStatus NOT IN ('Leased','InvestorLeased','Sold','Scrap')
AND bd.TerminatedDate IS NULL AND bd.IsActive = 1 AND bd.ContractId IS NULL
and ea.IsSKU = 0
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	ea.AssetId
	,SUM(CASE WHEN bd.IsLeaseComponent = 1 THEN bd.Salvage_Amount ELSE 0.00 END) [BookedResidual_LeaseComponent]
	,SUM(CASE WHEN bd.IsLeaseComponent = 0 THEN bd.Salvage_Amount ELSE 0.00 END) [BookedResidual_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN BookDepreciations bd ON bd.AssetId = ea.AssetId
INNER JOIN #BookDepId bdi ON bdi.BookDepreciationId = bd.Id
AND bdi.AssetId = bd.AssetId
WHERE ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'',''Sold'',''Scrap'')
AND bd.TerminatedDate IS NULL AND bd.IsActive = 1 AND bd.ContractId IS NULL
and ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #BookDepreciationInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #BookDepreciationInfo(AssetId);

SELECT
	ea.AssetId
	,CASE
		WHEN ea.AssetStatus IN ('Leased','InvestorLeased') AND la.AssetId IS NOT NULL
		THEN la.BookedResidual_LeaseComponent
		WHEN ea.AssetStatus NOT IN ('Leased','InvestorLeased','Sold','Scrap') AND bd.AssetId IS NOT NULL
		THEN bd.BookedResidual_LeaseComponent
		WHEN ea.AssetStatus IN ('Sold','Scrap')
		THEN 0.00
		ELSE 0.00
	END [BookedResidual_LeaseComponent]
	,CASE
		WHEN ea.AssetStatus IN ('Leased','InvestorLeased') AND la.AssetId IS NOT NULL
		THEN la.BookedResidual_FinanceComponent
		WHEN ea.AssetStatus NOT IN ('Leased','InvestorLeased','Sold','Scrap') AND bd.AssetId IS NOT NULL
		THEN bd.BookedResidual_FinanceComponent
		WHEN ea.AssetStatus IN ('Sold','Scrap')
		THEN 0.00
		ELSE 0.00
	END [BookedResidual_FinanceComponent]
INTO #BookedResidualInfo
FROM #EligibleAssets ea
LEFT JOIN #LeaseAssetsAmountInfo la ON ea.AssetId = la.AssetId
LEFT JOIN #BookDepreciationInfo bd ON ea.AssetId = bd.AssetId;

SELECT DISTINCT
	bdi.AssetId
	,MAX(bd.RemainingLifeInMonths) AS RemainingLifeInMonths
INTO #RELBookDepInfo
FROM #BookDepId bdi
INNER JOIN BookDepreciations bd ON bdi.BookDepreciationId = bd.Id
WHERE bd.TerminatedDate IS NULL AND bd.IsActive = 1 AND bd.ContractId IS NULL
GROUP BY bdi.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #RELBookDepInfo(AssetId);

SELECT
	ea.AssetId
	,ea.AssetStatus
	,ea.HoldingStatus
	,CASE 
		WHEN la.AssetId IS NOT NULL THEN ea.TotalEconomicLife - CAST (la.RemainingEconomicLife AS decimal)
		WHEN ea.AssetStatus NOT IN ('Leased','InvestorLeased') AND rbd.AssetId IS NOT NULL THEN rbd.RemainingLifeInMonths
		WHEN pai.AssetId IS NOT NULL THEN ea.TotalEconomicLife - CAST (pai.RemainingEconomicLife AS decimal)
		ELSE 0 
	END [RemainingEconomicLife]
INTO #RemainingEconomicLifeInfo
FROM #EligibleAssets ea
LEFT JOIN #LeaseAssetsInfo la ON ea.AssetId = la.AssetId
LEFT JOIN #RELBookDepInfo rbd ON ea.AssetId = rbd.AssetId
LEFT JOIN #PayoffInfo pai ON ea.AssetId = pai.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #RemainingEconomicLifeInfo(AssetId);

UPDATE rel
SET rel.RemainingEconomicLife = 0
FROM #RemainingEconomicLifeInfo rel
WHERE rel.AssetStatus IN ('Sold','Scrap') 
OR rel.HoldingStatus = 'HFS' OR rel.RemainingEconomicLife < 0;

SELECT ah.AssetId, COUNT (DISTINCT ah.ContractId) [ContractCount] 
INTO #ContractCount
FROM #EligibleAssets ea
INNER JOIN AssetHistories ah ON ea.AssetId = ah.AssetId
GROUP BY ah.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #ContractCount(AssetId);

SELECT DISTINCT ah.AssetId,c.SequenceNumber
INTO #PreviousSeq
FROM AssetHistories ah
INNER JOIN Contracts c ON ah.ContractId = c.Id
LEFT JOIN #ContractInfo ci ON ah.AssetId = ci.AssetId
WHERE c.SequenceNumber != ci.SequenceNumber;

CREATE NONCLUSTERED INDEX IX_Id ON #PreviousSeq(AssetId);

SELECT 
	ps.AssetId
    ,STUFF(
		(SELECT ', ' + convert(nvarchar(100),ps1.SequenceNumber)
	    FROM #PreviousSeq ps1
	    WHERE ps1.AssetId = ps.AssetId
		FOR XML PATH('')), 1, 2, '') [PreviousSequenceNumber]
INTO #GroupedSeq
FROM #PreviousSeq ps
GROUP BY ps.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #GroupedSeq(AssetId);

BEGIN
INSERT INTO #BlendedItemInfo
SELECT 
	DISTINCT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE (bia.IsActive = 1 and bi.IsActive = 1)
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
AND lf.IsCurrent = 1 AND lf.ApprovalStatus IN ('Approved','InsuranceFollowup')
AND bi.IsETC = 1 AND ea.IsSKU = 0
END;

IF @IsSku = 1
BEGIN
SET @Sql = 
'SELECT
	DISTINCT
	ea.AssetId
	,SUM(CASE WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate >= lfd.CommencementDate))
AND lf.IsCurrent = 1 AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
AND las.IsActive = 1 AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #BlendedItemInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #BlendedItemInfo(AssetId);

IF @IsSku = 1
BEGIN
SET @Sql = 
'SELECT
	DISTINCT
	ea.AssetId
	,SUM(CASE WHEN las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1
	THEN las.ETCAdjustmentAmount_Amount ELSE 0.00 END) [ETCAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN #LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = la.LeaseFinanceId
WHERE la.IsActive = 1 AND las.IsActive = 1 AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #RenewalBlendedItemInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalBlendedItemInfo(AssetId);

MERGE #BlendedItemInfo bi
USING (
SELECT 
	DISTINCT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN bia.TaxCredit_Amount ELSE 0.00 END [ETCAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN BlendedItemAssets bia ON bia.LeaseAssetId = la.Id
INNER JOIN BlendedItems bi ON bia.BlendedItemId = bi.Id
INNER JOIN #LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = la.LeaseFinanceId
WHERE bia.IsActive = 1 and bi.IsActive = 1
AND la.IsActive = 1 AND bi.IsETC = 1 AND ea.IsSKU = 0) AS t
ON (bi.AssetId = t.AssetId)
WHEN MATCHED
THEN UPDATE
SET bi.ETCAmount_LeaseComponent += t.ETCAmount_LeaseComponent
,bi.ETCAmount_FinanceComponent += t.ETCAmount_FinanceComponent
WHEN NOT MATCHED
THEN INSERT (AssetId,ETCAmount_LeaseComponent,ETCAmount_FinanceComponent)
VALUES (t.AssetId,t.ETCAmount_LeaseComponent,t.ETCAmount_FinanceComponent);

MERGE #BlendedItemInfo bi
USING (SELECT * FROM #RenewalBlendedItemInfo) AS t
ON (bi.AssetId = t.AssetId)
WHEN MATCHED
THEN UPDATE
SET bi.ETCAmount_LeaseComponent += t.ETCAmount_LeaseComponent
,bi.ETCAmount_FinanceComponent += t.ETCAmount_FinanceComponent
WHEN NOT MATCHED
THEN INSERT (AssetId,ETCAmount_LeaseComponent,ETCAmount_FinanceComponent)
VALUES (t.AssetId,t.ETCAmount_LeaseComponent,t.ETCAmount_FinanceComponent);

BEGIN
INSERT INTO #BlendedItemCapitalizeInfo
SELECT
    ea.AssetId
    ,SUM(biac.Amount_Amount) AS [CapitalizedIDCAmount_LeaseComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN BlendedItemAssetLevelCapitalizations biac ON biac.LeaseAssetId = la.Id
INNER JOIN BlendedItems bi ON biac.BlendedItemId = bi.Id
AND bi.IsActive = 1 AND biac.IsActive = 1 
AND (la.IsActive = 1 OR (la.IsActive = 0 AND la.TerminationDate IS NOT NULL))
AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND ea.IsSKU = 0
GROUP BY ea.AssetId
END;

IF @IsSku = 1
BEGIN
SET @Sql = 
'SELECT 
	ea.AssetId
    ,SUM(las.CapitalizedIDC_amount) AS [CapitalizedIDCAmount_LeaseComponent]
from #EligibleAssets ea
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
AND lf.IsCurrent = 1 AND lf.ApprovalStatus IN (''Approved'',''InsuranceFollowup'')
AND (la.IsActive = 1 OR (la.IsActive = 0 and la.TerminationDate IS NOT NULL)) 
AND las.IsActive = 1 AND ea.IsSKU = 1 AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0
GROUP BY ea.AssetId'
INSERT INTO #BlendedItemCapitalizeInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #BlendedItemCapitalizeInfo(AssetId);

BEGIN
INSERT INTO #ValueChangeInfo
SELECT 
	ea.AssetId
	,SUM(CASE
		WHEN avsc.Reason != 'Impairment' AND ea.IsLeaseComponent = 1
		THEN (avscd.AdjustmentAmount_Amount)
		ELSE 0.00
	END) AS [ValueChangeAmount_LeaseComponent]
	,SUM(CASE
		WHEN avsc.Reason != 'Impairment' AND ea.IsLeaseComponent = 0
		THEN (avscd.AdjustmentAmount_Amount)
		ELSE 0.00 
	END) AS [ValueChangeAmount_FinanceComponent]
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN AssetValueHistories avh ON avscd.AssetId = avh.AssetId AND avh.SourceModuleId = avsc.Id
INNER JOIN #EligibleAssets ea ON ea.AssetId = avscd.AssetId
WHERE avsc.IsActive = 1 AND ea.AssetStatus NOT IN ('Leased','InvestorLeased')
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'AssetValueAdjustment'
GROUP BY ea.AssetId
END;

BEGIN
INSERT INTO #ValueChangeInfo
SELECT
	la.AssetId
	,SUM(CASE
		WHEN avsc.Reason != 'Impairment' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		THEN (avscd.AdjustmentAmount_Amount)
		ELSE 0.00
	END) AS [ValueChangeAmount_LeaseComponent]
	,SUM(CASE
		WHEN avsc.Reason != 'Impairment' AND (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1)
		THEN (avscd.AdjustmentAmount_Amount) 
		ELSE 0.00
	END) AS [ValueChangeAmount_FinanceComponent]
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN AssetValueHistories avh ON avscd.AssetId = avh.AssetId AND avh.SourceModuleId = avsc.Id
INNER JOIN #EligibleAssets ea ON ea.AssetId = avscd.AssetId
INNER JOIN #LeaseAssetsInfo la ON avscd.AssetId = la.AssetId
LEFT JOIN #ContractInfo ci ON la.AssetId = ci.AssetId
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = ci.ContractId
WHERE avsc.IsActive = 1 AND avsc.IsActive = 1 AND la.AssetStatus IN ('Leased','InvestorLeased')
AND ((rft.ContractId IS NULL) 
		OR (rft.ContractId IS NOT NULL AND rft.ContractType = 'Lease' 
			AND avsc.PostDate <= rft.EffectiveDate))
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'AssetValueAdjustment'
GROUP BY la.AssetId
END;

CREATE NONCLUSTERED INDEX IX_Id ON #ValueChangeInfo(AssetId);

SELECT 
	ea.AssetId
	,ea.IsSKU
	,MAX(avh.IncomeDate) AVHClearedTillDate
	,MAX(avh.Id) AVHClearedId
INTO #AVHClearedTillDate
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE avh.IsCleared = 1
AND avh.IsAccounted = 1
GROUP BY ea.AssetId,ea.IsSKU;

CREATE NONCLUSTERED INDEX IX_Id ON #AVHClearedTillDate(AssetId);

SELECT 
	ea.AssetId
   ,COUNT (CASE WHEN avh.Sourcemodule = 'FixedTermDepreciation' THEN avh.Id ELSE 0.00 END ) AS countfixedterm
INTO #AVHClearedTillDateFixedTerm
FROM #EligibleAssets ea
INNER JOIN #AVHClearedTillDate avc ON ea.AssetId = avc.assetid
INNER JOIN AssetValueHistories avh ON avh.assetid = avc.AssetId
WHERE avh.IsAccounted = 1 AND avh.GLJournalId is not NUll AND avh.ReversalGLJournalId is NULL 
AND avh.Id <= avc.AVHClearedId AND avh.IncomeDate <=avc.AVHClearedTillDate
 AND avh.Sourcemodule in ('FixedTermDepreciation') AND avh.AdjustmentEntry = 0 
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #AVHClearedTillDateFixedTerm (AssetId);

SELECT 
	ea.AssetId
   ,COUNT (CASE WHEN avh.Sourcemodule = 'OTPDepreciation' THEN avh.Id ELSE 0.00 END ) as countOTP
INTO #AVHClearedTillDateOTP
FROM #EligibleAssets ea
INNER JOIN #AVHClearedTillDate avc ON ea.AssetId = avc.assetid
INNER JOIN AssetValueHistories avh ON avh.assetid = avc.AssetId
WHERE avh.IsAccounted = 1 AND avh.GLJournalId is not NUll AND avh.ReversalGLJournalId is NULL 
AND avh.Id <= avc.AVHClearedId AND avh.IncomeDate <=avc.AVHClearedTillDate
 AND avh.Sourcemodule in ('OTPDepreciation') AND avh.AdjustmentEntry = 0 
GROUP BY ea.AssetId;  

CREATE NONCLUSTERED INDEX IX_Id ON #AVHClearedTillDateOTP (AssetId);

SELECT 
	ea.AssetId
	,ea.AssetStatus
	,ea.IsLeaseComponent
	,avh.SourceModuleId
	,avh.GLJournalId
	,avh.ReversalGLJournalId
	,MAX(avh.Id) AS AVHId
	,MAX(avh.IncomeDate) AS AVHIncomeDate
INTO #AssetImpairmentAVHInfo
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE avh.SourceModule = 'AssetImpairment' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
GROUP BY ea.AssetId,ea.AssetStatus,ea.IsLeaseComponent,avh.SourceModuleId,avh.GLJournalId,avh.ReversalGLJournalId;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetImpairmentAVHInfo(AssetId);

BEGIN
INSERT INTO #AssetImpairmentInfo
SELECT 
	avscd.AssetId
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 1 AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN aiavh.IsLeaseComponent = 0 AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_FinanceComponent]
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN #AssetImpairmentAVHInfo aiavh ON aiavh.AssetId = avscd.AssetId AND aiavh.SourceModuleId = avsc.Id
LEFT JOIN #AVHClearedTillDate avhc ON avhc.AssetId = aiavh.AssetId
WHERE avsc.IsActive = 1 AND aiavh.AssetStatus NOT IN ('Leased','InvestorLeased') AND avsc.Reason = 'Impairment'
GROUP BY avscd.AssetId
END;

BEGIN
INSERT INTO #AssetImpairmentInfo
SELECT 
	la.AssetId
	,SUM(CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
		AND avhc.AssetId IS NOT NULL AND aiavh.AVHIncomeDate <= avhc.AVHClearedTillDate AND aiavh.AVHId <= avhc.AVHClearedId
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [ClearedAssetImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0
		AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) 
		AND aiavh.GLJournalId IS NOT NULL AND aiavh.ReversalGLJournalId IS NULL
		THEN avscd.AdjustmentAmount_Amount
		ELSE 0.00
		END) AS [AccumulatedAssetImpairmentAmount_FinanceComponent]
FROM AssetsValueStatusChanges avsc
INNER JOIN AssetsValueStatusChangeDetails avscd ON avsc.Id = avscd.AssetsValueStatusChangeId
INNER JOIN #LeaseAssetsInfo la ON avscd.AssetId = la.AssetId
INNER JOIN #AssetImpairmentAVHInfo aiavh ON aiavh.AssetId = la.AssetId AND aiavh.SourceModuleId = avsc.Id
LEFT JOIN #ContractInfo ci ON la.AssetId = ci.AssetId
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = ci.ContractId
LEFT JOIN #AVHClearedTillDate avhc ON avhc.AssetId = aiavh.AssetId
WHERE avsc.IsActive = 1 AND la.AssetStatus IN ('Leased','InvestorLeased') AND avsc.Reason = 'Impairment'
AND ((rft.ContractId IS NULL) 
		OR (rft.ContractId IS NOT NULL AND rft.ContractType = 'Lease' 
			AND avsc.PostDate <= rft.EffectiveDate))
GROUP BY la.AssetId
END;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetImpairmentInfo(AssetId);

UPDATE ai
SET ai.AccumulatedAssetImpairmentAmount_LeaseComponent -= ai.ClearedAssetImpairmentAmount_LeaseComponent
	,ai.AccumulatedAssetImpairmentAmount_FinanceComponent -= ai.ClearedAssetImpairmentAmount_FinanceComponent
FROM #AssetImpairmentInfo ai
WHERE (ai.ClearedAssetImpairmentAmount_LeaseComponent != 0.00 OR ai.ClearedAssetImpairmentAmount_FinanceComponent != 0.00)

BEGIN
INSERT INTO #PaydownAVHInfo
SELECT 
	ea.AssetId
    ,SUM(avh.NetValue_Amount) AS [PaydownValueAmount]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN LoanPaydownAssetDetails lpad ON lpad.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'Paydown'
AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
AND ea.IsSKU = 0 AND lpad.isactive = 1 AND lpad.AssetPaydownStatus = 'Inventory'
GROUP BY ea.AssetId
END;

CREATE NONCLUSTERED INDEX IX_Id ON #PaydownAVHInfo(AssetId);

BEGIN
INSERT INTO #AssetInventoryAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN ea.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN ea.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 1 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN ea.IsLeaseComponent = 0 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = 'InventoryBookDepreciation'
AND ea.IsSKU = 0
GROUP BY ea.AssetId
END;

IF @IsSku = 1
BEGIN
SET @Sql = 
'SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN avh.IsLeaseComponent = 1 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 0
		AND avh.IncomeDate <= avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN avh.IsLeaseComponent = 0 AND avhc.AssetId IS NOT NULL AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedInventoryDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 1 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.IsLeaseComponent = 0 AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedInventoryDepreciationAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND avh.SourceModule = ''InventoryBookDepreciation''
AND ea.IsSKU = 1
GROUP BY ea.AssetId'
INSERT INTO #AssetInventoryAVHInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #AssetInventoryAVHInfo(AssetId);

UPDATE ai
SET ai.AccumulatedInventoryDepreciationAmount_LeaseComponent -= ai.ClearedInventoryDepreciationAmount_LeaseComponent
	,ai.AccumulatedInventoryDepreciationAmount_FinanceComponent -= ai.ClearedInventoryDepreciationAmount_FinanceComponent
FROM #AssetInventoryAVHInfo ai
WHERE (ai.ClearedInventoryDepreciationAmount_LeaseComponent != 0.00 OR ai.ClearedInventoryDepreciationAmount_FinanceComponent != 0.00)

INSERT INTO #AVHAssetsInfo
SELECT 
	DISTINCT
	ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE ea.PreviousSequenceNumber IS NULL

INSERT INTO #AVHAssetsInfo
SELECT
	DISTINCT
	ea.AssetId
	,la.IsLeaseAsset
	,la.IsFailedSaleLeaseback
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN
(SELECT 
	DISTINCT
	ea.AssetId
	,Max(la.LeaseFinanceId) LeaseFinanceId
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE ea.PreviousSequenceNumber IS NOT NULL
GROUP BY ea.AssetId) AS t ON t.AssetId = ea.AssetId AND t.LeaseFinanceId = la.LeaseFinanceId

CREATE NONCLUSTERED INDEX IX_Id ON #AVHAssetsInfo(AssetId);

SELECT
	ea.AssetId
	,co.ChargeOffDate
	,co.ContractId
	,co.Id AS ChargeOffId
INTO #ChargeOffAssetsInfo
FROM #EligibleAssets ea
INNER JOIN ChargeOffAssetDetails coa ON coa.AssetId = ea.AssetId
INNER JOIN ChargeOffs co ON co.Id = coa.ChargeOffId
WHERE co.IsActive = 1 AND co.Status = 'Approved'
AND co.IsRecovery = 0 AND co.ReceiptId IS NULL
AND coa.IsActive = 1;

CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOffAssetsInfo(AssetId);

IF @IsSKU = 1
BEGIN
SET @Sql =
'SELECT 
	ea.AssetId
	,avh.IsLeaseComponent
	,MAX(avh.IncomeDate) AVHClearedTillDate
	,MAX(avh.Id) AVHClearedId
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE avh.IsCleared = 1
AND avh.IsAccounted = 1
AND ea.IsSKU = 1
GROUP BY ea.AssetId,avh.IsLeaseComponent'
INSERT INTO #SKUAVHClearedTillDate
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #SKUAVHClearedTillDate(AssetId);

SELECT 
	ea.AssetId
	,MAX(p.LeaseFinanceId) AS PayoffLeaseFinanceId
	,MAX(p.PayoffEffectiveDate) AS PayoffEffectiveDate
INTO #PayoffAssetInfo
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN PayoffAssets pa ON pa.LeaseAssetId = la.Id
INNER JOIN Payoffs p ON pa.PayoffId = p.Id
AND p.Status = 'Activated' AND pa.IsActive = 1
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #PayoffAssetInfo(AssetId);

SELECT 
	ea.AssetId
	,lam.AmendmentDate
INTO #RenewedAssets
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
WHERE la.IsActive = 1

SELECT 
	ea.AssetId
	,rft.ParticipatedPortion
	,rft.EffectiveDate
	,rft.RetainedPortion 
	,rft.ReceivableForTransferType
INTO #SyndicatedAssets
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
AND la.LeaseFinanceId = rft.SyndicationLeaseFinanceId AND la.IsActive = 1

CREATE NONCLUSTERED INDEX IX_Id ON #SyndicatedAssets(AssetId);

SELECT
	ea.AssetId
	,avh.IncomeDate AS ChargeOffMaxClearedIncomeDate
INTO #ChargeOffMaxCleared
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE avh.SourceModule = 'ChargeOff';

CREATE NONCLUSTERED INDEX IX_Id ON #ChargeOffMaxCleared(AssetId);

SELECT
	ea.AssetId
	,MAX(CASE WHEN avh.SourceModule = 'FixedTermDepreciation'
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedFTDMaxSourceModuleId
	,MAX(CASE WHEN avh.SourceModule = 'OTPDepreciation'
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedOTPMaxSourceModuleId
	,MAX(CASE WHEN avh.SourceModule = 'NBVImpairment'
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedNBVMaxSourceModuleId
INTO #AVHMaxSourceModuleIdInfo
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #AVHClearedTillDate avhc ON avhc.AssetId = avh.AssetId
WHERE ea.IsSKU = 0 AND avh.IncomeDate <= avhc.AVHClearedTillDate
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND avh.SourceModule IN ('FixedTermDepreciation','OTPDepreciation','NBVImpairment')
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #AVHMaxSourceModuleIdInfo(AssetId);

IF @IsSku = 1
BEGIN
SET @Sql = 'SELECT
	ea.AssetId
	,avh.IsLeaseComponent
	,MAX(CASE WHEN avh.SourceModule = ''FixedTermDepreciation''
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedFTDMaxSourceModuleId
	,MAX(CASE WHEN avh.SourceModule = ''OTPDepreciation''
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedOTPMaxSourceModuleId
	,MAX(CASE WHEN avh.SourceModule = ''NBVImpairment''
			THEN avh.SourceModuleId
			ELSE 0 END) AS ClearedNBVMaxSourceModuleId
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #SKUAVHClearedTillDate avhc ON avhc.AssetId = avh.AssetId
WHERE ea.IsSKU = 0 AND avh.IncomeDate <= avhc.AVHClearedTillDate
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND avh.SourceModule IN (''FixedTermDepreciation'',''OTPDepreciation'',''NBVImpairment'')
GROUP BY ea.AssetId,avh.IsLeaseComponent;'
INSERT INTO #SKUAVHMaxSourceModuleIdInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #SKUAVHMaxSourceModuleIdInfo(AssetId);

SELECT avh.AssetId,avh.SourceModule
INTO #AVHMaxClearedSourceModule
FROM AssetValueHistories avh
INNER JOIN #AVHClearedTillDate avhc ON avhc.AVHClearedId = avh.Id
WHERE avhc.IsSKU = 0;

CREATE NONCLUSTERED INDEX IX_Id ON #AVHMaxClearedSourceModule(AssetId);

IF @IsSKU = 1
BEGIN
SET @Sql = '
SELECT avh.AssetId,savhc.IsLeaseComponent,avh.SourceModule
FROM AssetValueHistories avh
INNER JOIN #SKUAVHClearedTillDate savhc ON savhc.AVHClearedId = avh.Id
AND savhc.IsLeaseComponent = avh.IsLeaseComponent;'
INSERT INTO #SKUAVHMaxClearedSourceModule
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #SKUAVHMaxClearedSourceModule(AssetId);

BEGIN
INSERT INTO #AccumulatedAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND sa.AssetId IS NOT NULL AND poa.AssetId IS NULL 
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate < sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.ParticipatedPortion) AS decimal (16,2)) 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND sa.AssetId IS NOT NULL AND poa.AssetId IS NOT NULL 
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate < sa.EffectiveDate 
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.ParticipatedPortion) AS decimal (16,2))
		ELSE 0.00
		END)
	+ SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NULL
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NOT NULL
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.IncomeDate >= sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN avh.Value_Amount
		ELSE 0.00
		END)
	+ SUM(CASE 
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL AND sa.AssetId IS NOT NULL
			AND avhc.AssetId IS NOT NULL AND avhc.AVHClearedTillDate >= sa.EffectiveDate
			AND avh.IncomeDate < sa.EffectiveDate
			AND avh.AdjustmentEntry = 0 
			AND (ra.AssetId IS NULL OR (ra.AssetId IS NOT NULL AND avh.IncomeDate > ra.AmendmentDate))
			AND (co.AssetId IS NULL OR (co.AssetId IS NOT NULL AND sa.EffectiveDate > co.ChargeOffDate AND avh.IncomeDate > co.ChargeOffDate))
		THEN CAST((avh.Value_Amount * sa.RetainedPortion) AS decimal (16,2))
		ELSE 0.00
		END)
	+ SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= cmc.ChargeOffMaxClearedIncomeDate
			AND avh.AdjustmentEntry = 0
			AND co.AssetId IS NOT NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= ra.AmendmentDate
			AND avh.AdjustmentEntry = 0
			AND ra.AssetId IS NOT NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedFTDMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation'	And (avhcF.countfixedterm is not null and avhcF.countfixedterm > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'FixedTermDepreciation' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_FTD_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_FinanceComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedOTPMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedOTPMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_OTP_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'OTPDepreciation' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_OTP_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_FinanceComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedNBVMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_LeaseComponent]
	,SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedNBVMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END)  AS [ClearedNBVImpairmentAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetImpairmentAmount_NBV_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'NBVImpairments' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetImpairmentAmount_NBV_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN #AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDateFixedTerm	avhcF ON avhcF.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDateOTP avhcOTP ON avhcOTP.AssetId = ea.AssetId 
LEFT JOIN #PayoffAssetInfo poa ON poa.AssetId = ea.AssetId
LEFT JOIN #SyndicatedAssets sa ON sa.AssetId = ea.AssetId
LEFT JOIN #ChargeOffAssetsInfo co ON co.AssetId = ea.AssetId
LEFT JOIN #ChargeOffMaxCleared cmc ON cmc.AssetId = ea.AssetId
LEFT JOIN #RenewedAssets ra ON ra.AssetId = ea.AssetId
LEFT JOIN #AVHMaxSourceModuleIdInfo avhsi ON avhsi.AssetId = ea.AssetId
LEFT JOIN #ContractCount cc ON cc.AssetId = ea.AssetId
LEFT JOIN #AVHMaxClearedSourceModule avhms ON avhms.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
AND avh.SourceModule IN ('NBVImpairments','FixedTermDepreciation','OTPDepreciation')
GROUP BY ea.AssetId
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation''
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation''
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation'' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation''
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedFTDMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation'' And (avhcF.countfixedterm is not null and avhcF.countfixedterm > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedFixedTermDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''FixedTermDepreciation'' AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_FTD_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedOTPDepreciationAmount_PO_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedOTPMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedOTPMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			And (avhcOTP.CountOTP is not Null and avhcOTP.countOTP > 0)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedOTPDepreciationAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_OTP_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''OTPDepreciation'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetDepreciationAmount_OTP_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avhc.AssetId IS NOT NULL AND avh.IncomeDate <= avhc.AVHClearedTillDate AND avh.Id <= avhc.AVHClearedId
			AND ((avh.SourceModule = avhms.SourceModule) OR (avh.SourceModule != avhms.SourceModule AND avh.Id <= avhc.AVHClearedId))
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL 
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) 
			AND poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate
			AND avh.AdjustmentEntry = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedNBVImpairmentAmount_PO_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedNBVMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND avh.IncomeDate > poa.PayoffEffectiveDate
			AND ((cc.ContractCount <= 1) OR (cc.ContractCount > 1 AND avh.SourceModuleId <= avhsi.ClearedNBVMaxSourceModuleId))
		THEN avh.Value_Amount
		ELSE 0.00
	END)
	+ SUM (CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
			AND ((poa.AssetId IS NOT NULL AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.AdjustmentEntry = 1) 
				OR (poa.AssetId IS NULL AND avh.AdjustmentEntry = 1))
			AND avh.AdjustmentEntry = 1
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ClearedNBVImpairmentAmount_Adj_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetImpairmentAmount_NBV_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''NBVImpairments'' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1) AND poa.AssetId IS NOT NULL
			AND avh.IncomeDate <= poa.PayoffEffectiveDate AND avh.IncomeDate > avhc.AVHClearedTillDate
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AccumulatedAssetImpairmentAmount_NBV_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN #AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
LEFT JOIN #SKUAVHClearedTillDate avhc ON avhc.AssetId = ea.AssetId
AND avhc.IsLeaseComponent = avh.IsLeaseComponent
LEFT JOIN #AVHClearedTillDateFixedTerm	avhcF ON avhcF.AssetId = ea.AssetId
LEFT JOIN #AVHClearedTillDateOTP avhcOTP ON avhcOTP.AssetId = ea.AssetId
LEFT JOIN #PayoffAssetInfo poa ON poa.AssetId = ea.AssetId
LEFT JOIN #SKUAVHMaxSourceModuleIdInfo avhsi ON avhsi.AssetId = ea.AssetId
AND avhsi.IsLeaseComponent = avh.IsLeaseComponent
LEFT JOIN #SKUAVHMaxClearedSourceModule avhms ON avhms.AssetId = ea.AssetId
AND avhms.IsLeaseComponent = avh.IsLeaseComponent
LEFT JOIN #ContractCount cc ON cc.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 1
AND avh.SourceModule IN (''NBVImpairments'',''FixedTermDepreciation'',''OTPDepreciation'')
GROUP BY ea.AssetId'
INSERT INTO #AccumulatedAVHInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #AccumulatedAVHInfo(AssetId);

UPDATE a
SET a.ClearedFixedTermDepreciationAmount_LeaseComponent += a.ClearedFixedTermDepreciationAmount_Adj_LeaseComponent
	,a.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent += a.ClearedFixedTermDepreciationAmount_Adj_LeaseComponent
	,a.ClearedOTPDepreciationAmount_LeaseComponent += a.ClearedOTPDepreciationAmount_Adj_LeaseComponent
	,a.ClearedOTPDepreciationAmount_FinanceComponent += a.ClearedOTPDepreciationAmount_Adj_FinanceComponent
	,a.AccumulatedOTPDepreciationAmount_PO_LeaseComponent += a.ClearedOTPDepreciationAmount_Adj_LeaseComponent
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent += a.ClearedOTPDepreciationAmount_Adj_FinanceComponent
	,a.ClearedNBVImpairmentAmount_LeaseComponent += a.ClearedNBVImpairmentAmount_Adj_LeaseComponent
	,a.ClearedNBVImpairmentAmount_FinanceComponent += a.ClearedNBVImpairmentAmount_Adj_FinanceComponent
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent += a.ClearedNBVImpairmentAmount_Adj_LeaseComponent
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent += a.ClearedNBVImpairmentAmount_Adj_FinanceComponent
FROM #AccumulatedAVHInfo a

UPDATE ai
SET ai.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent = 0.00
	,ai.AccumulatedOTPDepreciationAmount_PO_LeaseComponent += ai.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent
FROM #AccumulatedAVHInfo ai
INNER JOIN LeaseAssets la ON ai.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
LEFT JOIN #OTPReclass otpr ON ai.AssetId = otpr.AssetId
WHERE (otpr.AssetId IS NULL AND la.IsActive = 0 AND la.TerminationDate > lfd.MaturityDate AND lf.BookingStatus != 'InActive')

UPDATE a
SET a.AccumulatedFixedTermDepreciationAmount_LeaseComponent = 
		CASE 
			WHEN poa.AssetId IS NOT NULL 
			THEN a.AccumulatedFixedTermDepreciationAmount_LeaseComponent - a.AccumulatedFixedTermDepreciationAmount_PO_LeaseComponent
			ELSE a.AccumulatedFixedTermDepreciationAmount_LeaseComponent - a.ClearedFixedTermDepreciationAmount_LeaseComponent
		END
	,a.AccumulatedOTPDepreciationAmount_LeaseComponent = 
		CASE
			WHEN poa.AssetId IS NOT NULL 
			THEN a.AccumulatedOTPDepreciationAmount_LeaseComponent - a.AccumulatedOTPDepreciationAmount_PO_LeaseComponent
			ELSE a.AccumulatedOTPDepreciationAmount_LeaseComponent - a.ClearedOTPDepreciationAmount_LeaseComponent
		END
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent = 
		CASE
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedOTPDepreciationAmount_FinanceComponent - a.AccumulatedOTPDepreciationAmount_PO_FinanceComponent
			ELSE a.AccumulatedOTPDepreciationAmount_FinanceComponent - a.ClearedOTPDepreciationAmount_FinanceComponent
		END
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent =
		CASE
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedNBVImpairmentAmount_LeaseComponent - a.AccumulatedNBVImpairmentAmount_PO_LeaseComponent
			ELSE a.AccumulatedNBVImpairmentAmount_LeaseComponent - a.ClearedNBVImpairmentAmount_LeaseComponent
		END
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent =
		CASE
			WHEN poa.AssetId IS NOT NULL
			THEN a.AccumulatedNBVImpairmentAmount_FinanceComponent - a.AccumulatedNBVImpairmentAmount_PO_FinanceComponent
			ELSE a.AccumulatedNBVImpairmentAmount_FinanceComponent - a.ClearedNBVImpairmentAmount_FinanceComponent
		END
FROM #AccumulatedAVHInfo a
LEFT JOIN #PayoffAssetInfo poa on a.AssetId = poa.AssetId

UPDATE ai
SET ai.AccumulatedFixedTermDepreciationAmount_LeaseComponent = 0.00
	,ai.AccumulatedOTPDepreciationAmount_LeaseComponent += ai.AccumulatedFixedTermDepreciationAmount_LeaseComponent
FROM #AccumulatedAVHInfo ai
INNER JOIN #OTPReclass otpr ON ai.AssetId = otpr.AssetId
WHERE otpr.AssetId IS NOT NULL

UPDATE a
SET a.AccumulatedFixedTermDepreciationAmount_LeaseComponent = 0.00
	,a.AccumulatedOTPDepreciationAmount_LeaseComponent = 0.00
	,a.AccumulatedOTPDepreciationAmount_FinanceComponent = 0.00
	,a.AccumulatedNBVImpairmentAmount_LeaseComponent = 0.00
	,a.AccumulatedNBVImpairmentAmount_FinanceComponent = 0.00
FROM #AccumulatedAVHInfo a
INNER JOIN #ChargeOffAssetsInfo co ON a.AssetId = co.AssetId

BEGIN
INSERT INTO #OtherAVHInfo
SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.SourceModule = 'ResidualReclass' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
		AND ea.AssetStatus IN ('Leased','InvestorLeased')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'ResidualReclass' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualReclassAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'ResidualReclass' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus IN ('Leased','InvestorLeased')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'ResidualReclass' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualReclassAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'ResidualRecapture'
		AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus IN ('Leased','InvestorLeased')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'ResidualRecapture'
		AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualRecaptureAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'ResidualRecapture' 
		AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus IN ('Leased','InvestorLeased')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = 'ResidualRecapture' 
		AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus NOT IN ('Leased','InvestorLeased')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualRecaptureAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'Syndications' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [SyndicationValueAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'Syndications' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [SyndicationValueAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'Payoff' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AssetAmortizedValueAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'Payoff' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AssetAmortizedValueAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'ChargeOff' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ChargeOffValueAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = 'ChargeOff' AND (ai.IsLeaseAsset = 0 OR ai.IsFailedSaleLeaseback = 1)
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ChargeOffValueAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN #AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
AND avh.SourceModule IN ('ResidualReclass','ResidualRecapture','Syndications','Payoff','ChargeOff')
GROUP BY ea.AssetId
END;

SELECT
	ea.AssetId
	,Max(avh.Id) AS MaxIdBeforeSynd
INTO #MaxBeforeSynd
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN #ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
WHERE lfd.LeaseContractType != 'Operating' AND (ea.AssetStatus IN ('Leased','InvestorLeased') OR rft.ReceivableForTransferType = 'FullSale')
AND lf.IsCurrent = 1 AND ea.IsSKU = 0
AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND avh.IncomeDate <= rft.EffectiveDate
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #MaxBeforeSynd(AssetId);

SELECT ea.AssetId,avh.IncomeDate
INTO #ResidualAVHInfo
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
WHERE avh.SourceModule = 'ResidualReclass' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1

CREATE NONCLUSTERED INDEX IX_Id ON #ResidualAVHInfo(AssetId);

SELECT
	ea.AssetId
	,SUM(CASE 
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -((((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS [SyndicationValueAmount_LeaseComponent]
	,SUM(CASE 
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN (la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1) AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -((((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - ISNULL(bi.ETCAmount_LeaseComponent,0.00)) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS [SyndicationValueAmount_FinanceComponent]
	,SUM(CASE 
		WHEN la.IsActive = 0 AND la.TerminationDate >= rft.EffectiveDate AND rft.ReceivableForTransferType != 'SaleOfPayments'
		THEN -((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		WHEN la.IsActive = 0 AND la.TerminationDate >= rft.EffectiveDate AND rft.ReceivableForTransferType = 'SaleOfPayments'
		THEN -(((la.NBV_Amount + la.OriginalCapitalizedAmount_Amount) - la.BookedResidual_Amount) * CAST(rft.ParticipatedPortion AS DECIMAL (16, 2)))
		ELSE 0.00
	END) AS SyndicationBeforePayoff
INTO #SyndicationAmountInfo
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN #ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
LEFT JOIN ChargeOffs co ON lf.ContractId = co.ContractId
LEFT JOIN ChargeOffAssetDetails coa ON coa.ChargeOffId = co.Id AND coa.AssetId = ea.AssetId
LEFT JOIN #BlendedItemInfo bi ON bi.AssetId = la.AssetId
WHERE lfd.LeaseContractType != 'Operating'
AND lf.IsCurrent = 1 AND ea.IsSKU = 0
AND (la.TerminationDate IS NULL OR (la.TerminationDate IS NOT NULL AND la.TerminationDate >= rft.EffectiveDate))
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationAmountInfo(AssetId);

UPDATE oavh
SET oavh.ResidualReclassAmount_LeaseComponent = 0.00
	,oavh.ResidualReclassAmount_FinanceComponent = 0.00
FROM #OtherAVHInfo oavh
INNER JOIN LeaseAssets la ON oavh.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN #ReceivableForTransfersInfo rft ON lf.ContractId = rft.ContractId
INNER JOIN #ResidualAVHInfo ravh ON ravh.AssetId = oavh.AssetId
WHERE lfd.LeaseContractType != 'Operating' AND lf.IsCurrent = 1
AND la.TerminationDate >= rft.EffectiveDate
AND rft.ReceivableForTransferType = 'SaleOfPayments'
AND ravh.IncomeDate > rft.EffectiveDate

MERGE #OtherAVHInfo ovah
USING (SELECT * FROM #SyndicationAmountInfo) AS t
ON (t.AssetId = ovah.AssetId)
WHEN MATCHED
THEN UPDATE 
SET ovah.SyndicationValueAmount_LeaseComponent += t.SyndicationValueAmount_LeaseComponent
,ovah.SyndicationValueAmount_FinanceComponent += t.SyndicationValueAmount_FinanceComponent
WHEN NOT MATCHED
THEN INSERT
(AssetId,ResidualReclassAmount_LeaseComponent,ResidualReclassAmount_FinanceComponent,ResidualRecaptureAmount_LeaseComponent,ResidualRecaptureAmount_FinanceComponent,SyndicationValueAmount_LeaseComponent,SyndicationValueAmount_FinanceComponent,AssetAmortizedValueAmount_LeaseComponent
,AssetAmortizedValueAmount_FinanceComponent,ChargeOffValueAmount_LeaseComponent,ChargeOffValueAmount_FinanceComponent)
VALUES(t.AssetId,0,0,0,0,t.SyndicationValueAmount_LeaseComponent,t.SyndicationValueAmount_FinanceComponent,0,0,0,0);

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	ea.AssetId
	,SUM(CASE
		WHEN avh.SourceModule = ''ResidualReclass'' 
		AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus IN (''Leased'',''InvestorLeased'')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = ''ResidualReclass'' 
		AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualReclassAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''ResidualReclass'' 
		AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus IN (''Leased'',''InvestorLeased'')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = ''ResidualReclass'' 
		AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualReclassAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''ResidualRecapture'' 
		AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus IN (''Leased'',''InvestorLeased'')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = ''ResidualRecapture'' 
		AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		AND ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualRecaptureAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''ResidualRecapture''
		AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus IN (''Leased'',''InvestorLeased'')
		AND avh.GLJournalId IS NOT NULL AND avh.ReversalGLJournalId IS NULL
		THEN avh.Value_Amount
		WHEN avh.SourceModule = ''ResidualRecapture''
		AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		AND ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'')
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ResidualRecaptureAmount_FinanceComponent]
	,CAST (0 AS Decimal (16,2)) AS [SyndicationValueAmount_LeaseComponent]
	,CAST (0 AS Decimal (16,2)) AS [SyndicationValueAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''Payoff'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AssetAmortizedValueAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''Payoff'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [AssetAmortizedValueAmount_FinanceComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''ChargeOff'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ChargeOffValueAmount_LeaseComponent]
	,SUM(CASE
		WHEN avh.SourceModule = ''ChargeOff'' AND (avh.IsLeaseComponent = 0 OR ai.IsFailedSaleLeaseback = 1)
		THEN avh.Value_Amount
		ELSE 0.00
	END) AS [ChargeOffValueAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN #AVHAssetsInfo ai ON ai.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 1
AND avh.SourceModule IN (''ResidualReclass'',''ResidualRecapture'',''Syndications'',''Payoff'',''ChargeOff'')
GROUP BY ea.AssetId'
INSERT INTO #OtherAVHInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #OtherAVHInfo(AssetId);

SELECT
	ea.AssetId
	,SUM(CASE WHEN ea.IsLeaseComponent = 1 THEN lai.PVOfAsset_Amount ELSE 0.00 END) AS [ResidualImpairmentAmount_LeaseComponent]
	,SUM(CASE WHEN ea.IsLeaseComponent = 0 THEN lai.PVOfAsset_Amount ELSE 0.00 END) AS [ResidualImpairmentAmount_FinanceComponent]
INTO #LeaseAmendmentImpairmentInfo
FROM #EligibleAssets ea
INNER JOIN LeaseAmendmentImpairmentAssetDetails lai ON lai.AssetId = ea.AssetId
INNER JOIN LeaseAmendments la ON la.Id = lai.LeaseAmendmentId
AND la.LeaseAmendmentStatus = 'Approved'
AND lai.IsActive = 1 AND la.AmendmentType = 'ResidualImpairment'
GROUP BY ea.AssetId;

CREATE NONCLUSTERED INDEX IX_Id ON #LeaseAmendmentImpairmentInfo(AssetId);

BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.RenewalAmortizedAmount_LeaseComponent) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(t.RenewalAmortizedAmount_FinanceComponent) [RenewalAmortizedAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN la.NBV_Amount ELSE 0.00 END [RenewalAmortizedAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN la.NBV_Amount ELSE 0.00 END [RenewalAmortizedAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lam.OriginalLeaseFinanceId
WHERE ea.IsSKU = 0 
AND ((lfd.LeaseContractType != ''Operating'' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0) OR la.IsLeaseAsset = 0)
UNION
SELECT
	ea.AssetId
	,CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN (la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount 
	- la.CapitalizedInterimInterest_Amount - la.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END [RenewalAmortizedAmount_LeaseComponent]
	,CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 
	THEN (la.NBV_Amount - la.CapitalizedSalesTax_Amount - la.CapitalizedInterimRent_Amount 
	- la.CapitalizedInterimInterest_Amount - la.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END [RenewalAmortizedAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
WHERE ea.IsSKU = 0 AND la.IsActive = 1
AND ((lfd.LeaseContractType != ''Operating'' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0) OR la.IsLeaseAsset = 0)) AS t GROUP BY t.AssetId'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','- la.CapitalizedAdditionalCharge_Amount');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO #RenewalAmortizeInfo
EXEC (@Sql)
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT
	t.AssetId
	,SUM(t.RenewalAmortizedAmount_LeaseComponent) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(t.RenewalAmortizedAmount_FinanceComponent) [RenewalAmortizedAmount_FinanceComponent]
FROM
(SELECT
	ea.AssetId
	,SUM(CASE WHEN lfd.LeaseContractType != ''Operating'' AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 THEN las.NBV_Amount ELSE 0.00 END) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1 THEN las.NBV_Amount ELSE 0.00 END)  [RenewalAmortizedAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lam.OriginalLeaseFinanceId
WHERE ea.IsSKU = 1
GROUP BY ea.AssetId
UNION
SELECT
	ea.AssetId
	,SUM(CASE WHEN lfd.LeaseContractType != ''Operating'' AND las.IsLeaseComponent = 1 AND la.IsFailedSaleLeaseback = 0 
	THEN (las.NBV_Amount - las.CapitalizedSalesTax_Amount - las.CapitalizedInterimRent_Amount 
	- las.CapitalizedInterimInterest_Amount	- las.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END) [RenewalAmortizedAmount_LeaseComponent]
	,SUM(CASE WHEN las.IsLeaseComponent = 0 OR la.IsFailedSaleLeaseback = 1 
	THEN (las.NBV_Amount - las.CapitalizedSalesTax_Amount - las.CapitalizedInterimRent_Amount 
	- las.CapitalizedInterimInterest_Amount - las.CapitalizedProgressPayment_Amount AdditionalCharge) * -1 
	ELSE 0.00 END) [RenewalAmortizedAmount_FinanceComponent]
FROM #EligibleAssets ea
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseAssetSKUs las ON las.LeaseAssetId = la.Id
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = la.LeaseFinanceId
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
WHERE ea.IsSKU = 1 AND la.IsActive = 1
GROUP BY ea.AssetId) AS t GROUP BY t.AssetId'
IF @AddCharge = 1
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','- las.CapitalizedAdditionalCharge_Amount');
END;
ELSE
BEGIN
	SET @Sql = REPLACE(@Sql,'AdditionalCharge','');
END;
INSERT INTO #RenewalAmortizeInfo
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalAmortizeInfo(AssetId);

UPDATE rai
SET rai.RenewalAmortizedAmount_LeaseComponent += bi.ETCAmount_LeaseComponent
,rai.RenewalAmortizedAmount_FinanceComponent += bi.ETCAmount_FinanceComponent
FROM #EligibleAssets ea
INNER JOIN #RenewalAmortizeInfo rai ON ea.AssetId = rai.AssetId
INNER JOIN #BlendedItemInfo bi ON ea.AssetId = bi.AssetId
WHERE ea.AssetStatus != 'Leased';

UPDATE rai
SET rai.RenewalAmortizedAmount_LeaseComponent = 0.00
,rai.RenewalAmortizedAmount_FinanceComponent = 0.00
FROM #EligibleAssets ea
INNER JOIN #RenewalAmortizeInfo rai ON ea.AssetId = rai.AssetId
INNER JOIN LeaseAssets la ON la.AssetId = ea.AssetId
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN #LeaseAmendmentInfo lam ON lam.OriginalLeaseFinanceId = lf.Id
WHERE lfd.LeaseContractType = 'Operating' AND la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 AND ea.IsSKU = 0

UPDATE rai
SET rai.RenewalAmortizedAmount_LeaseComponent = 0.00
,rai.RenewalAmortizedAmount_FinanceComponent = 0.00
FROM #EligibleAssets ea
INNER JOIN #RenewalAmortizeInfo rai ON ea.AssetId = rai.AssetId
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN PayoffAssets poa ON poa.LeaseAssetId = la.Id
INNER JOIN Payoffs p on poa.PayoffId = p.Id
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.CurrentLeaseFinanceId
WHERE p.LeaseFinanceId >= lam.CurrentLeaseFinanceId
AND la.TerminationDate <= lfd.MaturityDate

SELECT
	ea.AssetId
	,ea.Alias
	,ea.LegalEntityName
	,lob.Name [LineOfBusiness]
	,ea.CustomerName
	,ea.HoldingStatus
	,ea.AssetStatus
	,ea.SubStatus
	,ea.FinancialType
	,ea.AssetType
	,ea.AssetCategory
	,m.Name [ManufacturerName]
	,ea.IsSoft
	,ISNULL(csa.SoftAssetCapitalizedFor,'NA') [SoftAssetCapitalizedFor]
	,ISNULL(csa.CapitalizationType,'NA') [CapitalizationType]
	,ea.PlaceHolderAssetId
	,IIF(hca.ParentAsset IS NOT NULL,'Yes','No') [HasChildAssets]
	,ea.ParentAssetId
	,CASE 
		WHEN (ea.AssetStatus = 'Leased' AND lai.IsLeaseAsset = 1) OR (ea.AssetStatus != 'Leased' AND ea.IsLeaseComponent = 1) THEN 'Yes'
		WHEN (ea.AssetStatus = 'Leased' AND lai.IsLeaseAsset = 0) OR (ea.AssetStatus != 'Leased' AND ea.IsLeaseComponent = 0) THEN 'No'
		ELSE 'NA'
	END [IsLeaseAsset]
	,CASE
		WHEN @IsSKU = 1 AND ea.IsSKU = 1 THEN 'Yes'
		WHEN @IsSKU = 1 AND ea.IsSKU = 0 THEN 'No'
		ELSE 'NA'
	END [IsSKU]
	,IIF(@IsSku = 1 AND ea.IsSKU = 1,CAST(sc.LeaseComponentSKUCount AS NVARCHAR(10)),'NA') [LeaseComponentSKUCount]
	,IIF(@IsSku = 1 AND ea.IsSKU = 1,CAST(sc.FinanceComponentSKUCount AS NVARCHAR(10)),'NA') [FinanceComponentSKUCount]
	,ea.TotalEconomicLife
	,re.RemainingEconomicLife
	,ea.RemarketingVendorName
	,pit.InvoiceNumber [PayableInvoiceNumber]
	,pit.VendorName
	,cc.ContractCount
	,gs.PreviousSequenceNumber
	,ci.SequenceNumber [CurrentSequenceNumber]
	,ci.ContractType
	,ci.SyndicationType
	,IIF(ot.AssetId IS NOT NULL,'Yes','No') [IsInOTP]
	,IIF(co.AssetId IS NOT NULL,'Yes','No') [ChargedOff]
	,IIF(asp.AssetId IS NOT NULL,'Yes','No') [AssetSplit]
	,IIF(casp.AssetId IS NOT NULL,CAST(casp.OriginalAssetId AS nvarchar(10)),'No') [CreatedFromAssetSplit]
	,IIF(poa.IsPartiallyOwned IS NOT NULL,CAST(poa.IsPartiallyOwned AS nvarchar(5)),'NA') [IsPartiallyOwned]
	,IIF(asl.AssetId IS NOT NULL,'Yes','No') [AssetSale]
	,ISNULL(lai.LeasedAssetCost,0.00) [LeasedAssetCost]
	,ISNULL(ac.AcquisitionCost_LeaseComponent,0.00) [AcquisitionCost_LeaseComponent]
	,ISNULL(ac.AcquisitionCost_FinanceComponent,0.00) [AcquisitionCost_FinanceComponent]
	,ISNULL(ac.OtherCost_LeaseComponent,0.00) [OtherCost_LeaseComponent]
	,ISNULL(ac.OtherCost_FinanceComponent,0.00) [OtherCost_FinanceComponent]
	,ISNULL(sca.SpecificCostAdjustment_LeaseComponent,0.00) [SpecificCostAdjustment_LeaseComponent]
	,ISNULL(sca.SpecificCostAdjustment_FinanceComponent,0.00) [SpecificCostAdjustment_FinanceComponent]
	,ISNULL(la.FMVAmount_LeaseComponent,0.00) [FMVAmount_LeaseComponent]
	,ISNULL(cn.CurrentNBVAmount_LeaseComponent,0.00) [CurrentNBVAmount_LeaseComponent]
	,ISNULL(cn.CurrentNBVAmount_FinanceComponent,0.00) [CurrentNBVAmount_FinanceComponent]
	,ISNULL(bi.ETCAmount_LeaseComponent,0.00) [ETCAmount_LeaseComponent]
	,ISNULL(bi.ETCAmount_FinanceComponent,0.00) [ETCAmount_FinanceComponent]
	,- ISNULL(vc.ValueChangeAmount_LeaseComponent,0.00) [ValueChangeAmount_LeaseComponent]
	,- ISNULL(vc.ValueChangeAmount_FinanceComponent,0.00) [ValueChangeAmount_FinanceComponent]
	,- ISNULL(ai.ClearedAssetImpairmentAmount_LeaseComponent,0.00) [ClearedAssetImpairmentAmount_LeaseComponent]
	,- ISNULL(ai.ClearedAssetImpairmentAmount_FinanceComponent,0.00) [ClearedAssetImpairmentAmount_FinanceComponent]
	,- ISNULL(ai.AccumulatedAssetImpairmentAmount_LeaseComponent,0.00) [AccumulatedAssetImpairmentAmount_LeaseComponent]
	,- ISNULL(ai.AccumulatedAssetImpairmentAmount_FinanceComponent,0.00) [AccumulatedAssetImpairmentAmount_FinanceComponent]
	,ISNULL(bic.CapitalizedIDCAmount_LeaseComponent,0.00) [CapitalizedIDCAmount_LeaseComponent]
	,ISNULL(lci.TaxCapitalizedAmount_LeaseComponent,0.00) [TaxCapitalizedAmount_LeaseComponent]
	,ISNULL(lci.TaxCapitalizedAmount_FinanceComponent,0.00) [TaxCapitalizedAmount_FinanceComponent]
	,ISNULL(lci.InterimRentCapitalizationAmount_LeaseComponent,0.00) [InterimRentCapitalizationAmount_LeaseComponent]
	,ISNULL(lci.InterimRentCapitalizationAmount_FinanceComponent,0.00) [InterimRentCapitalizationAmount_FinanceComponent]
	,ISNULL(lci.InterimInterestCapitalizationAmount_LeaseComponent,0.00) [InterimInterestCapitalizationAmount_LeaseComponent]
	,ISNULL(lci.InterimInterestCapitalizationAmount_FinanceComponent,0.00) [InterimInterestCapitalizationAmount_FinanceComponent]
	,ISNULL(lci.AdditionalChargesCapitalizationAmount_LeaseComponent,0.00) [AdditionalChargesCapitalizationAmount_LeaseComponent]
	,ISNULL(lci.AdditionalChargesCapitalizationAmount_FinanceComponent,0.00) [AdditionalChargesCapitalizationAmount_FinanceComponent]
	,ISNULL(lci.ProgressPaymentCapitalizationAmount_LeaseComponent,0.00) [ProgressPaymentCapitalizationAmount_LeaseComponent]
	,ISNULL(lci.ProgressPaymentCapitalizationAmount_FinanceComponent,0.00) [ProgressPaymentCapitalizationAmount_FinanceComponent]
	,ISNULL(br.BookedResidual_LeaseComponent,0.00) [BookedResidual_LeaseComponent]
	,ISNULL(br.BookedResidual_FinanceComponent,0.00) [BookedResidual_FinanceComponent]
	,- ISNULL(aiavh.ClearedInventoryDepreciationAmount_LeaseComponent,0.00) [ClearedInventoryDepreciationAmount_LeaseComponent]
	,- ISNULL(aiavh.ClearedInventoryDepreciationAmount_FinanceComponent,0.00) [ClearedInventoryDepreciationAmount_FinanceComponent]
	,- ISNULL(aiavh.AccumulatedInventoryDepreciationAmount_LeaseComponent,0.00) [AccumulatedInventoryDepreciationAmount_LeaseComponent]
	,- ISNULL(aiavh.AccumulatedInventoryDepreciationAmount_FinanceComponent,0.00) [AccumulatedInventoryDepreciationAmount_FinanceComponent]
	,- ISNULL(aavh.ClearedFixedTermDepreciationAmount_LeaseComponent,0.00) [ClearedFixedTermDepreciationAmount_LeaseComponent]
	,- ISNULL(aavh.AccumulatedFixedTermDepreciationAmount_LeaseComponent,0.00) [AccumulatedFixedTermDepreciationAmount_LeaseComponent]
	,- ISNULL(aavh.ClearedOTPDepreciationAmount_LeaseComponent,0.00) [ClearedOTPDepreciationAmount_LeaseComponent]
	,- ISNULL(aavh.ClearedOTPDepreciationAmount_FinanceComponent,0.00) [ClearedOTPDepreciationAmount_FinanceComponent]
	,- ISNULL(aavh.AccumulatedOTPDepreciationAmount_LeaseComponent,0.00) [AccumulatedOTPDepreciationAmount_LeaseComponent]
	,- ISNULL(aavh.AccumulatedOTPDepreciationAmount_FinanceComponent,0.00) [AccumulatedOTPDepreciationAmount_FinanceComponent]
	,- ISNULL(aavh.AccumulatedAssetDepreciationAmount_FTD_LeaseComponent,0.00) + (-ISNULL(aavh.AccumulatedAssetDepreciationAmount_OTP_LeaseComponent,0.00)) [AccumulatedAssetDepreciationAmount_LeaseComponent]
	,- ISNULL(aavh.AccumulatedAssetDepreciationAmount_OTP_FinanceComponent,0.00) [AccumulatedAssetDepreciationAmount_FinanceComponent]
	,- ISNULL(oavh.ResidualReclassAmount_LeaseComponent,0.00) [ResidualReclassAmount_LeaseComponent]
	,- ISNULL(oavh.ResidualReclassAmount_FinanceComponent,0.00) [ResidualReclassAmount_FinanceComponent]
	,- ISNULL(oavh.ResidualRecaptureAmount_LeaseComponent,0.00) [ResidualRecaptureAmount_LeaseComponent]
	,- ISNULL(oavh.ResidualRecaptureAmount_FinanceComponent,0.00) [ResidualRecaptureAmount_FinanceComponent]
	,- ISNULL(aavh.ClearedNBVImpairmentAmount_LeaseComponent,0.00) [ClearedNBVImpairmentAmount_LeaseComponent]
	,- ISNULL(aavh.ClearedNBVImpairmentAmount_FinanceComponent,0.00) [ClearedNBVImpairmentAmount_FinanceComponent]
	,- ISNULL(aavh.AccumulatedNBVImpairmentAmount_LeaseComponent,0.00) [AccumulatedNBVImpairmentAmount_LeaseComponent]
	,- ISNULL(aavh.AccumulatedNBVImpairmentAmount_FinanceComponent,0.00) [AccumulatedNBVImpairmentAmount_FinanceComponent]
	,- ISNULL(aavh.AccumulatedAssetImpairmentAmount_NBV_LeaseComponent,0.00) [AccumulatedAssetImpairmentAmount_NBV_LeaseComponent]
	,- ISNULL(aavh.AccumulatedAssetImpairmentAmount_NBV_FinanceComponent,0.00) [AccumulatedAssetImpairmentAmount_NBV_FinanceComponent]
	,- ISNULL(laii.ResidualImpairmentAmount_LeaseComponent,0.00) [ResidualImpairmentAmount_LeaseComponent]
	,- ISNULL(laii.ResidualImpairmentAmount_FinanceComponent,0.00) [ResidualImpairmentAmount_FinanceComponent]
	,- ISNULL(oavh.SyndicationValueAmount_LeaseComponent,0.00) [SyndicationValueAmount_LeaseComponent]
	,- ISNULL(oavh.SyndicationValueAmount_FinanceComponent,0.00) [SyndicationValueAmount_FinanceComponent]
	,- ISNULL(oavh.AssetAmortizedValueAmount_LeaseComponent,0.00) [AssetAmortizedValueAmount_LeaseComponent]
	,- ISNULL(oavh.AssetAmortizedValueAmount_FinanceComponent,0.00) [AssetAmortizedValueAmount_FinanceComponent]
	,- ISNULL(pavh.PaydownValueAmount,0.00) [PaydownValueAmount]
	,- ISNULL(oavh.ChargeOffValueAmount_LeaseComponent,0.00) [ChargeOffValueAmount_LeaseComponent]
	,- ISNULL(oavh.ChargeOffValueAmount_FinanceComponent,0.00) [ChargeOffValueAmount_FinanceComponent]
	,- ISNULL(ri.RenewalAmortizedAmount_LeaseComponent,0.00) [RenewalAmortizedAmount_LeaseComponent]
	,- ISNULL(ri.RenewalAmortizedAmount_FinanceComponent,0.00) [RenewalAmortizedAmount_FinanceComponent]
	,ISNULL(boi.BuyoutCostOfGoodsSold_LeaseComponent,0.00) [BuyoutCostOfGoodsSold_LeaseComponent]
	,ISNULL(boi.BuyoutCostOfGoodsSold_FinanceComponent,0.00) [BuyoutCostOfGoodsSold_FinanceComponent]
	,ISNULL(asl.AssetSaleCostOfGoodsSold_LeaseComponent,0.00) [AssetSaleCostOfGoodsSold_LeaseComponent]
	,ISNULL(asl.AssetSaleCostOfGoodsSold_FinanceComponent,0.00) [AssetSaleCostOfGoodsSold_FinanceComponent]
INTO #ComputedValueCalculation
FROM #EligibleAssets ea
LEFT JOIN LineofBusinesses lob ON ea.LineofBusinessId = lob.Id
LEFT JOIN Manufacturers m ON ea.ManufacturerId = m.Id
LEFT JOIN #PayoffInfo poa ON poa.AssetId = ea.AssetId
LEFT JOIN #BuyoutInfo boi ON boi.AssetId = ea.AssetId
LEFT JOIN #HasChildAssets hca ON hca.ParentAsset = ea.AssetId
LEFT JOIN #CapitalizedSoftAssetInfo csa ON csa.AssetId = ea.AssetId
LEFT JOIN #LeaseAssetsInfo lai ON lai.AssetId = ea.AssetId
LEFT JOIN #LeaseAssetsAmountInfo la ON la.AssetId = ea.AssetId
LEFT JOIN #LeaseCapitalizedAmountInfo lci ON lci.AssetId = ea.AssetId
LEFT JOIN #CurrentNBVInfo cn ON cn.AssetId = ea.AssetId
LEFT JOIN #SKUComponentCount sc ON sc.AssetId = ea.AssetId
LEFT JOIN #PayableInvoiceInfo pit ON ea.AssetId = pit.AssetId
LEFT JOIN #ContractInfo ci ON ea.AssetId = ci.AssetId
LEFT JOIN #ChargeOffInfo co ON ea.AssetId = co.AssetId
LEFT JOIN #AssetSplitInfo asp ON asp.AssetId = ea.AssetId
LEFT JOIN #CreatedFromAssetSplit casp ON casp.AssetId = ea.AssetId
LEFT JOIN #AssetSaleInfo asl ON asl.AssetId = ea.AssetId
LEFT JOIN #AcquisitionCostInfo ac ON ea.AssetId = ac.AssetId
LEFT JOIN #SpecificCostInfo sca ON ea.AssetId = sca.AssetId
LEFT JOIN #BookedResidualInfo br ON ea.AssetId = br.AssetId
LEFT JOIN #RemainingEconomicLifeInfo re ON ea.AssetId = re.AssetId
LEFT JOIN #ContractCount cc ON ea.AssetId = cc.AssetId
LEFT JOIN #GroupedSeq gs ON ea.AssetId = gs.AssetId
LEFT JOIN #OverTerm ot ON ea.AssetId = ot.AssetId
LEFT JOIN #BlendedItemInfo bi ON ea.AssetId = bi.AssetId
LEFT JOIN #BlendedItemCapitalizeInfo bic ON ea.AssetId = bic.AssetId
LEFT JOIN #ValueChangeInfo vc ON vc.AssetId = ea.AssetId
LEFT JOIN #AssetImpairmentInfo ai ON ai.AssetId = ea.AssetId
LEFT JOIN #PaydownAVHInfo pavh ON pavh.AssetId = ea.AssetId
LEFT JOIN #AssetInventoryAVHInfo aiavh ON aiavh.AssetId = ea.AssetId
LEFT JOIN #AccumulatedAVHInfo aavh ON aavh.AssetId = ea.AssetId
LEFT JOIN #OtherAVHInfo oavh ON oavh.AssetId = ea.AssetId
LEFT JOIN #LeaseAmendmentImpairmentInfo laii ON laii.AssetId = ea.AssetId
LEFT JOIN #RenewalAmortizeInfo ri ON ri.AssetId = ea.AssetId

CREATE NONCLUSTERED INDEX IX_Id ON #ComputedValueCalculation(AssetId);

BEGIN
INSERT INTO #ActualValueCalculation
SELECT 
	ea.AssetId
	,ISNULL(avh.EndBookValue_Amount,0.00) AS ActualValue
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #AVHClearedTillDate avhc ON ea.AssetId = avhc.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
AND avh.IncomeDate = avhc.AVHClearedTillDate AND avh.Id = avhc.AVHClearedId
END;

IF @IsSku = 1
BEGIN
SET @Sql =
'SELECT 
	ea.AssetId
	,ISNULL(SUM(avh.EndBookValue_Amount),0.00) AS ActualValue
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #SKUAVHClearedTillDate savhc ON ea.AssetId = savhc.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 1
AND avh.IncomeDate = savhc.AVHClearedTillDate AND avh.Id = savhc.AVHClearedId
AND avh.IsLeaseComponent = savhc.IsLeaseComponent
GROUP BY ea.AssetId'
INSERT INTO #ActualValueCalculation
EXEC (@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #ActualValueCalculation(AssetId);

UPDATE avc
SET avc.ActualValue += (syn.SyndicationValueAmount_LeaseComponent + syn.SyndicationValueAmount_FinanceComponent)
FROM #EligibleAssets ea
INNER JOIN #ActualValueCalculation avc ON avc.AssetId = ea.AssetId
INNER JOIN #SyndicationAmountInfo syn ON avc.AssetId = syn.AssetId
INNER JOIN LeaseAssets la ON avc.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
INNER JOIN LeaseFinanceDetails lfd ON lfd.Id = lf.Id
INNER JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = lf.ContractId
WHERE lfd.LeaseContractType != 'Operating' AND lf.IsCurrent = 1
AND ((rft.ReceivableForTransferType != 'FullSale'AND la.TerminationDate IS NULL) OR rft.ReceivableForTransferType = 'FullSale')
AND ea.IsSKU = 0;

UPDATE avc
SET avc.ActualValue += t.ResidualRecaptureAmount
FROM #ActualValueCalculation avc
INNER JOIN (
SELECT ea.AssetId,SUM(avh.Value_Amount) AS ResidualRecaptureAmount
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN (SELECT avh.AssetId,avh.SourceModuleId,avhc.AVHClearedId
FROM AssetValueHistories avh
INNER JOIN #AVHClearedTillDate avhc ON avh.AssetId = avhc.AssetId AND avh.Id = avhc.AVHClearedId
WHERE (avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')) AS rmc ON avh.AssetId = rmc.AssetId
WHERE avh.SourceModule = 'ResidualRecapture'
AND avh.Id > rmc.AVHClearedId AND avh.IsAccounted = 1
AND avh.IsLessorOwned = 1 AND avh.SourceModuleId = rmc.SourceModuleId
AND ea.AssetStatus NOT IN ('Leased','InvestorLeased') AND ea.IsSKU = 0
GROUP BY ea.AssetId) AS t ON t.AssetId = avc.AssetId

IF @IsSKU = 1
BEGIN
SET @Sql =
'UPDATE avc
SET avc.ActualValue += t.ResidualRecaptureAmount
FROM #ActualValueCalculation avc
INNER JOIN (
SELECT ea.AssetId,SUM(avh.Value_Amount) AS ResidualRecaptureAmount
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN (SELECT avh.AssetId,avh.SourceModuleId,avhc.AVHClearedId,avh.IsLeaseComponent
FROM AssetValueHistories avh
INNER JOIN #SKUAVHClearedTillDate avhc ON avh.AssetId = avhc.AssetId 
	AND avh.Id = avhc.AVHClearedId AND avhc.IsLeaseComponent = avh.IsLeaseComponent
WHERE (avh.SourceModule = ''ResidualReclass'' OR avh.SourceModule = ''ResidualRecapture'')) AS rmc ON avh.AssetId = rmc.AssetId
WHERE avh.SourceModule = ''ResidualRecapture'' AND avh.IsLeaseComponent = rmc.IsLeaseComponent
AND avh.Id > rmc.AVHClearedId AND avh.IsAccounted = 1
AND avh.IsLessorOwned = 1 AND avh.SourceModuleId = rmc.SourceModuleId
AND ea.AssetStatus NOT IN (''Leased'',''InvestorLeased'') AND ea.IsSKU = 1
GROUP BY ea.AssetId) AS t ON t.AssetId = avc.AssetId'
INSERT INTO #ActualValueCalculation
EXEC (@Sql)
END;

SELECT
	DISTINCT ea.AssetId
INTO #PayoffAtInceptionSoftAssets
FROM #EligibleAssets ea
INNER JOIN #CapitalizedSoftAssetInfo coa ON ea.AssetId = coa.AssetId
INNER JOIN LeaseAssets la ON ea.AssetId = la.AssetId
INNER JOIN PayoffAssets po ON po.LeaseAssetId = la.Id
INNER JOIN Payoffs p ON po.PayoffId = p.Id
WHERE ea.AssetStatus = 'Scrap'
AND p.PayoffAtInception = 1

CREATE NONCLUSTERED INDEX IX_Id ON #PayoffAtInceptionSoftAssets(AssetId);

UPDATE avc
SET avc.ActualValue = 0.00
FROM #EligibleAssets ea
INNER JOIN #ActualValueCalculation avc ON ea.AssetId = avc.AssetId
LEFT JOIN #CapitalizedSoftAssetInfo coa ON ea.AssetId = coa.AssetId
LEFT JOIN #EligibleAssets cea ON coa.SoftAssetCapitalizedFor = cea.AssetId
LEFT JOIN #PayoffAtInceptionSoftAssets pos ON pos.AssetId = ea.AssetId
WHERE ea.AssetStatus = 'Sold' OR (coa.AssetId IS NOT NULL AND ea.AssetStatus = 'Scrap' AND pos.AssetId IS NOT NULL);

BEGIN
INSERT INTO #NotGLPostedPIInfo
SELECT DISTINCT pia.AssetId,p.EntityId
FROM PayableInvoices pin
INNER JOIN PayableInvoiceAssets pia ON pin.Id = pia.PayableInvoiceId
INNER JOIN #EligibleAssets ea ON pia.AssetId = ea.AssetId
INNER JOIN Payables p ON p.SourceId = pia.Id
AND p.EntityId = pin.Id AND p.EntityType = 'PI'
WHERE pin.Status = 'Completed' AND pia.IsActive = 1
AND p.SourceTable = 'PayableInvoiceAsset'
AND p.IsGLPosted = 0 AND p.Status != 'Inactive'
END;

BEGIN
INSERT INTO #NotGLPostedPIInfo
SELECT DISTINCT ea.AssetId,p.EntityId
FROM PayableInvoiceOtherCosts pioc
INNER JOIN #EligibleAssets ea ON pioc.AssetId = ea.AssetId AND pioc.IsActive = 1
INNER JOIN PayableInvoices pin ON pioc.PayableInvoiceId = pin.Id 
INNER JOIN Payables p ON p.EntityId = pin.Id AND pioc.Id = p.SourceId
WHERE pin.Status = 'Completed' AND pioc.IsActive = 1 AND p.IsGLPosted = 0
AND pioc.AllocationMethod = 'SpecificCostAdjustment' AND EntityType = 'PI'
AND p.SourceTable = 'PayableInvoiceOtherCost' AND p.Status != 'Inactive'
END;

CREATE NONCLUSTERED INDEX IX_Id ON #NotGLPostedPIInfo(AssetId);

UPDATE avc
SET avc.ActualValue -= t.PayableInvoiceAmount
FROM #ActualValueCalculation avc
INNER JOIN (
SELECT
	ea.AssetId
	,SUM(avh.Value_Amount) PayableInvoiceAmount
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #NotGLPostedPIInfo ngl ON ngl.AssetId = avh.AssetId AND avh.SourceModuleId = ngl.EntityId
WHERE avh.SourceModule = 'PayableInvoice' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
GROUP BY ea.AssetId) AS t ON avc.AssetId = t.AssetId;

UPDATE avc
SET avc.ActualValue += t.SyndicationAmount
FROM #ActualValueCalculation avc
INNER JOIN (
SELECT
	ea.AssetId
	,SUM(avh.Value_Amount) SyndicationAmount
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON ea.AssetId = avh.AssetId
INNER JOIN #AVHClearedTillDate avhc ON avhc.AssetId = avh.AssetId
WHERE avh.SourceModule = 'Syndications' AND avh.IsAccounted = 1 AND avh.IsLessorOwned = 1
AND avh.IncomeDate >= avhc.AVHClearedTillDate AND avh.Id > avhc.AVHClearedId
GROUP BY ea.AssetId) AS t ON avc.AssetId = t.AssetId;

UPDATE avc
SET avc.ActualValue += (rai.RenewalAmortizedAmount_LeaseComponent + rai.RenewalAmortizedAmount_FinanceComponent)
FROM #ActualValueCalculation avc
INNER JOIN #RenewalAmortizeInfo rai ON avc.AssetId = rai.AssetId
LEFT JOIN #PayoffAssetInfo pai ON avc.AssetId = pai.AssetId
WHERE pai.AssetId IS NULL;

UPDATE avc
SET avc.ActualValue -= avh.Value_Amount
FROM #EligibleAssets ea
INNER JOIN #ActualValueCalculation avc ON ea.AssetId = avc.AssetId
INNER JOIN #AVHClearedTillDate avhc ON avhc.AssetId = avc.AssetId
INNER JOIN AssetValueHistories avh ON avh.Id = avhc.AVHClearedId
WHERE (avh.SourceModule = 'ResidualReclass' OR avh.SourceModule = 'ResidualRecapture')
AND avh.GLJournalId IS NULL AND ea.IsSKU = 0
AND ea.AssetStatus IN ('Leased','InvestorLeased');

IF @IsSKU = 1
BEGIN
SET @Sql =
'UPDATE avc
SET avc.ActualValue -= t.Value_Amount
FROM #EligibleAssets ea
INNER JOIN #ActualValueCalculation avc ON ea.AssetId = avc.AssetId
INNER JOIN (
SELECT avhc.AssetId, SUM(avh.Value_Amount) AS Value_Amount
FROM #SKUAVHClearedTillDate avhc
INNER JOIN AssetValueHistories avh ON avh.Id = avhc.AVHClearedId AND avhc.AssetId = avh.AssetId
WHERE (avh.SourceModule = ''ResidualReclass'' OR avh.SourceModule = ''ResidualRecapture'')
AND avh.GLJournalId IS NULL AND avhc.IsLeaseComponent = avh.IsLeaseComponent
GROUP BY avhc.AssetId) AS t ON t.AssetId = ea.AssetId
AND ea.AssetStatus IN (''Leased'',''InvestorLeased'') AND ea.IsSKU = 1'
INSERT INTO #ActualValueCalculation
EXEC (@Sql)
END;

UPDATE avc
SET avc.ActualValue -= t.RetainedAmount
FROM #ActualValueCalculation avc
INNER JOIN (
SELECT
	ea.AssetId
	,SUM(CAST((avh.Value_Amount * sa.RetainedPortion) AS decimal (16,2))) RetainedAmount
FROM #EligibleAssets ea
INNER JOIN AssetValueHistories avh ON avh.AssetId = ea.AssetId
INNER JOIN #SyndicatedAssets sa ON sa.AssetId = ea.AssetId
LEFT JOIN #ChargeOffAssetsInfo co ON co.AssetId = ea.AssetId
WHERE avh.IsAccounted = 1 AND avh.IsLessorOwned = 1 AND ea.IsSKU = 0
AND avh.SourceModule IN ('FixedTermDepreciation') AND co.AssetId IS NULL
AND avh.IncomeDate < sa.EffectiveDate AND avh.AdjustmentEntry = 0
GROUP BY ea.AssetId) AS t ON avc.AssetId = t.AssetId

SELECT *
	,CASE 
		WHEN t.AssetValue_Difference != 0.00
		THEN 'Problem Record'
		ELSE 'Not Problem Record'
	END [Result]
INTO #ResultList
FROM (
SELECT cvc.*
	,(CASE WHEN cvc.AssetStatus NOT IN ('Leased','InvestorLeased')
	THEN (cvc.AcquisitionCost_LeaseComponent
	+ cvc.AcquisitionCost_FinanceComponent
	+ cvc.OtherCost_LeaseComponent
	+ cvc.OtherCost_FinanceComponent
	+ cvc.SpecificCostAdjustment_LeaseComponent
	+ cvc.SpecificCostAdjustment_FinanceComponent
	- cvc.ETCAmount_LeaseComponent
	- cvc.ETCAmount_FinanceComponent
	+ cvc.ValueChangeAmount_LeaseComponent
	+ cvc.ValueChangeAmount_FinanceComponent
	+ cvc.ClearedAssetImpairmentAmount_LeaseComponent
	+ cvc.ClearedAssetImpairmentAmount_FinanceComponent
	+ cvc.TaxCapitalizedAmount_LeaseComponent
	+ cvc.TaxCapitalizedAmount_FinanceComponent
	+ cvc.InterimRentCapitalizationAmount_LeaseComponent
	+ cvc.InterimRentCapitalizationAmount_FinanceComponent
	+ cvc.InterimInterestCapitalizationAmount_LeaseComponent
	+ cvc.InterimInterestCapitalizationAmount_FinanceComponent
	+ cvc.AdditionalChargesCapitalizationAmount_LeaseComponent
	+ cvc.AdditionalChargesCapitalizationAmount_FinanceComponent
	+ cvc.ProgressPaymentCapitalizationAmount_LeaseComponent
	+ cvc.ProgressPaymentCapitalizationAmount_FinanceComponent
	- cvc.ClearedInventoryDepreciationAmount_LeaseComponent
	- cvc.ClearedInventoryDepreciationAmount_FinanceComponent
	- cvc.ClearedFixedTermDepreciationAmount_LeaseComponent
	- cvc.ClearedOTPDepreciationAmount_LeaseComponent
	- cvc.ClearedOTPDepreciationAmount_FinanceComponent
	- cvc.ResidualReclassAmount_LeaseComponent
	- cvc.ResidualReclassAmount_FinanceComponent
	- cvc.ResidualRecaptureAmount_LeaseComponent
	- cvc.ResidualRecaptureAmount_FinanceComponent
	- cvc.ClearedNBVImpairmentAmount_LeaseComponent
	- cvc.ClearedNBVImpairmentAmount_FinanceComponent
	- cvc.SyndicationValueAmount_LeaseComponent
	- cvc.SyndicationValueAmount_FinanceComponent
	- cvc.AssetAmortizedValueAmount_LeaseComponent
	- cvc.AssetAmortizedValueAmount_FinanceComponent
	- cvc.PaydownValueAmount
	- cvc.ChargeOffValueAmount_LeaseComponent
	- cvc.ChargeOffValueAmount_FinanceComponent
	- cvc.RenewalAmortizedAmount_LeaseComponent
	- cvc.RenewalAmortizedAmount_FinanceComponent
	- cvc.BuyoutCostOfGoodsSold_LeaseComponent
	- cvc.BuyoutCostOfGoodsSold_FinanceComponent
	- cvc.AssetSaleCostOfGoodsSold_LeaseComponent
	- cvc.AssetSaleCostOfGoodsSold_FinanceComponent
	) ELSE 0.00 END) AS AssetValue_Computed
	,ISNULL((CASE WHEN cvc.AssetStatus NOT IN ('Leased','InvestorLeased')
	THEN avc.ActualValue ELSE 0.00 END),0.00) AS AssetValue_Actual
	,(CASE WHEN cvc.AssetStatus NOT IN ('Leased','InvestorLeased')
	THEN (cvc.AcquisitionCost_LeaseComponent
	+ cvc.AcquisitionCost_FinanceComponent
	+ cvc.OtherCost_LeaseComponent
	+ cvc.OtherCost_FinanceComponent
	+ cvc.SpecificCostAdjustment_LeaseComponent
	+ cvc.SpecificCostAdjustment_FinanceComponent
	- cvc.ETCAmount_LeaseComponent
	- cvc.ETCAmount_FinanceComponent
	+ cvc.ValueChangeAmount_LeaseComponent
	+ cvc.ValueChangeAmount_FinanceComponent
	+ cvc.ClearedAssetImpairmentAmount_LeaseComponent
	+ cvc.ClearedAssetImpairmentAmount_FinanceComponent
	+ cvc.TaxCapitalizedAmount_LeaseComponent
	+ cvc.TaxCapitalizedAmount_FinanceComponent
	+ cvc.InterimRentCapitalizationAmount_LeaseComponent
	+ cvc.InterimRentCapitalizationAmount_FinanceComponent
	+ cvc.InterimInterestCapitalizationAmount_LeaseComponent
	+ cvc.InterimInterestCapitalizationAmount_FinanceComponent
	+ cvc.AdditionalChargesCapitalizationAmount_LeaseComponent
	+ cvc.AdditionalChargesCapitalizationAmount_FinanceComponent
	+ cvc.ProgressPaymentCapitalizationAmount_LeaseComponent
	+ cvc.ProgressPaymentCapitalizationAmount_FinanceComponent
	- cvc.ClearedInventoryDepreciationAmount_LeaseComponent
	- cvc.ClearedInventoryDepreciationAmount_FinanceComponent
	- cvc.ClearedFixedTermDepreciationAmount_LeaseComponent
	- cvc.ClearedOTPDepreciationAmount_LeaseComponent
	- cvc.ClearedOTPDepreciationAmount_FinanceComponent
	- cvc.ResidualReclassAmount_LeaseComponent
	- cvc.ResidualReclassAmount_FinanceComponent
	- cvc.ResidualRecaptureAmount_LeaseComponent
	- cvc.ResidualRecaptureAmount_FinanceComponent
	- cvc.ClearedNBVImpairmentAmount_LeaseComponent
	- cvc.ClearedNBVImpairmentAmount_FinanceComponent
	- cvc.SyndicationValueAmount_LeaseComponent
	- cvc.SyndicationValueAmount_FinanceComponent
	- cvc.AssetAmortizedValueAmount_LeaseComponent
	- cvc.AssetAmortizedValueAmount_FinanceComponent
	- cvc.PaydownValueAmount
	- cvc.ChargeOffValueAmount_LeaseComponent
	- cvc.ChargeOffValueAmount_FinanceComponent
	- cvc.RenewalAmortizedAmount_LeaseComponent
	- cvc.RenewalAmortizedAmount_FinanceComponent
	- cvc.BuyoutCostOfGoodsSold_LeaseComponent
	- cvc.BuyoutCostOfGoodsSold_FinanceComponent
	- cvc.AssetSaleCostOfGoodsSold_LeaseComponent
	- cvc.AssetSaleCostOfGoodsSold_FinanceComponent
	) ELSE 0.00 END)
	- ISNULL((CASE WHEN cvc.AssetStatus NOT IN ('Leased','InvestorLeased')
	THEN avc.ActualValue ELSE 0.00 END),0.00) AS AssetValue_Difference
FROM #ComputedValueCalculation cvc
LEFT JOIN #ActualValueCalculation avc ON cvc.AssetId = avc.AssetId) AS t
ORDER BY t.AssetId

UPDATE rl
SET rl.LeasedAssetCost -= (rl.SyndicationValueAmount_LeaseComponent + rl.SyndicationValueAmount_FinanceComponent)
FROM #ResultList rl
WHERE rl.AssetStatus IN ('Leased','InvestorLeased')

UPDATE rl
SET rl.LeasedAssetCost = 0.00
FROM #ResultList rl
INNER JOIN #ChargeOffInfo co ON rl.AssetId = co.AssetId
WHERE rl.AssetStatus IN ('Leased','InvestorLeased');

CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(AssetId);

SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label, column_Id AS ColumnId
INTO #AssetSummary
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#ResultList')
AND Name LIKE '%Difference';

DECLARE @query NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(max);
WHILE EXISTS (SELECT 1 FROM #AssetSummary WHERE IsProcessed = 0)
BEGIN
SELECT TOP 1 @TableName = Name FROM #AssetSummary WHERE IsProcessed = 0

SET @query = 'UPDATE #AssetSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
				WHERE Name = '''+ @TableName+''' ;'
EXEC (@query)
END

UPDATE #AssetSummary SET 
							Label = CASE
										WHEN Name = 'AssetValue_Difference'
										THEN '1_Asset Value_Difference'
									END;

IF @IsFromLegalEntity = 0
BEGIN

SELECT Label AS Name, Count
FROM #AssetSummary
ORDER BY ColumnId

IF (@ResultOption = 'All')
BEGIN
SELECT *
FROM #ResultList
ORDER BY AssetId;
END

IF (@ResultOption = 'Failed')
BEGIN
SELECT *
FROM #ResultList
WHERE Result = 'Problem Record'
ORDER BY AssetId;
END

IF (@ResultOption = 'Passed')
BEGIN
SELECT *
FROM #ResultList
WHERE Result = 'Not Problem Record'
ORDER BY AssetId;
END

DECLARE @TotalCount BIGINT;
SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
DECLARE @InCorrectCount BIGINT;
SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
DECLARE @Messages StoredProcMessage
		
INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalAssets', (Select 'Assets=' + CONVERT(nvarchar(40), @TotalCount)))
INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('AssetsSuccessful', (Select 'AssetSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('AssetIncorrect', (Select 'AssetIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))
INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('AssetResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

SELECT * FROM @Messages

END;

SELECT
	rl.AssetId
	,- SUM(CASE WHEN avh.SourceModule = 'ResidualReclass' THEN avh.Value_Amount ELSE 0.00 END) ResidualReclassBeforePayoff
	,- SUM(CASE WHEN avh.SourceModule = 'ResidualRecapture' THEN avh.Value_Amount ELSE 0.00 END) ResidualRecaptureBeforePayoff
	,- SUM(CASE WHEN avh.SourceModule = 'Syndication' THEN avh.Value_Amount ELSE 0.00 END) SyndicationBeforePayoff
INTO #ResidualBeforePayoff
FROM #ResultList rl
INNER JOIN #PayoffAssetInfo poa ON rl.AssetId = poa.AssetId
INNER JOIN AssetValueHistories avh ON poa.AssetId = avh.AssetId
WHERE avh.IsLessorOwned = 1 AND avh.IsAccounted = 1
AND avh.IncomeDate <= poa.PayoffEffectiveDate
GROUP BY rl.AssetId;

MERGE #ResidualBeforePayoff rp
USING(
SELECT
	rl.AssetId
	,SUM(sa.SyndicationBeforePayoff) SyndicationBeforePayoff
FROM #ResultList rl
INNER JOIN #SyndicationAmountInfo sa ON rl.AssetId = sa.AssetId
GROUP BY rl.AssetId) AS t ON t.AssetId = rp.AssetId
WHEN MATCHED THEN UPDATE SET rp.SyndicationBeforePayoff += t.SyndicationBeforePayoff
WHEN NOT MATCHED THEN INSERT (AssetId,ResidualReclassBeforePayoff,ResidualRecaptureBeforePayoff,SyndicationBeforePayoff)
VALUES (t.AssetId,0,0,t.SyndicationBeforePayoff);

CREATE NONCLUSTERED INDEX IX_Id ON #ResidualBeforePayoff(AssetId);

SELECT 
	ea.AssetId
INTO #ActiveRenewedAssets
FROM #EligibleAssets ea
INNER JOIN #RenewedAssets ra ON ea.AssetId = ra.AssetId
LEFT JOIN #PayoffAssetInfo poa ON ea.AssetId = poa.AssetId
WHERE ea.AssetStatus IN ('Leased','InvestorLeased')
AND (poa.AssetId IS NULL OR (poa.AssetId IS NOT NULL AND ra.AmendmentDate > poa.PayoffEffectiveDate));

CREATE NONCLUSTERED INDEX IX_Id ON #ActiveRenewedAssets(AssetId);

INSERT INTO #OperatingLeaseChargeOff
SELECT
	rl.AssetId
	,-SUM(CASE 
			WHEN lfd.LeaseContractType = 'Operating' AND ai.IsLeaseAsset = 1 AND ai.IsFailedSaleLeaseback = 0 
			THEN avh.Value_Amount ELSE 0.00 
		END) AS OperatingLeaseChargeOff_Table
FROM #ResultList rl
INNER JOIN AssetValueHistories avh ON rl.AssetId = avh.AssetId
INNER JOIN #AVHAssetsInfo ai ON avh.AssetId = ai.AssetId
INNER JOIN ChargeOffs co ON co.Id = avh.SourceModuleId
INNER JOIN LeaseFinances lf ON lf.ContractId = co.ContractId AND lf.IsCurrent = 1
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE avh.IsLessorOwned = 1 AND avh.IsAccounted = 1
AND avh.SourceModule = 'ChargeOff' AND rl.IsSKU = 'No'
GROUP BY rl.AssetId;

IF @IsSku = 1
BEGIN
	SET @Sql =
	'SELECT
		rl.AssetId
		,-SUM(CASE 
				WHEN lfd.LeaseContractType = ''Operating'' AND avh.IsLeaseComponent = 1 AND ai.IsFailedSaleLeaseback = 0 
				THEN avh.Value_Amount ELSE 0.00 
			END) AS OperatingLeaseChargeOff_Table
	FROM #ResultList rl
	INNER JOIN AssetValueHistories avh ON rl.AssetId = avh.AssetId
	INNER JOIN #AVHAssetsInfo ai ON avh.AssetId = ai.AssetId
	INNER JOIN ChargeOffs co ON co.Id = avh.SourceModuleId
	INNER JOIN LeaseFinances lf ON lf.ContractId = co.ContractId AND lf.IsCurrent = 1
	INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
	WHERE avh.IsLessorOwned = 1 AND avh.IsAccounted = 1
	AND avh.SourceModule = ''ChargeOff'' AND rl.IsSKU = ''Yes''
	GROUP BY rl.AssetId'
INSERT INTO #OperatingLeaseChargeOff
EXEC (@Sql)
END

CREATE NONCLUSTERED INDEX IX_Id ON #OperatingLeaseChargeOff(AssetId);

SELECT
	rl.AssetId
	,SUM(CASE WHEN la.IsLeaseAsset = 1 AND la.IsFailedSaleLeaseback = 0 THEN la.NBV_Amount ELSE 0.00 END) AS RenewalPO_Inventory_LC
	,SUM(CASE WHEN la.IsLeaseAsset = 0 OR la.IsFailedSaleLeaseback = 1 THEN la.NBV_Amount ELSE 0.00 END) AS RenewalPO_Inventory_NLC
INTO #RenewalPaidOffInventory
FROM #ResultList rl
INNER JOIN LeaseAssets la ON la.AssetId = rl.AssetId
INNER JOIN #LeaseAmendmentInfo lam ON la.LeaseFinanceId = lam.OriginalLeaseFinanceId
GROUP BY rl.AssetId

CREATE NONCLUSTERED INDEX IX_Id ON #RenewalPaidOffInventory(AssetId);

SELECT
	DISTINCT rl.AssetId
INTO #ChargedOffCapitalLeaseAssetsInfo
FROM #ResultList rl
INNER JOIN #ChargeOffAssetsInfo coa ON coa.AssetId = rl.AssetId
INNER JOIN LeaseFinances lf ON coa.ContractId = lf.ContractId
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
WHERE rl.AssetStatus NOT IN ('Leased','InvestorLeased')
AND lfd.LeaseContractType != 'Operating';

CREATE NONCLUSTERED INDEX IX_Id ON #ChargedOffCapitalLeaseAssetsInfo(AssetId);

BEGIN
SET @Sql = '
SELECT
	ea.AssetId
	,-SUM(CASE WHEN rft.ContractId IS NOT NULL AND lfd.LeaseContractType != ''Operating''
			THEN CAST(avh.Value_Amount * rft.RetainedPortion AS DECIMAL(16,2))
			ELSE avh.Value_Amount
		END) AS FinanceChargeOffAmount
FROM #EligibleAssets ea
INNER JOIN #ChargeOffAssetsInfo coa ON ea.AssetId = coa.AssetId
INNER JOIN AssetValueHistories avh ON avh.SourceModuleId = coa.ChargeOffId AND avh.AssetId = coa.AssetId AND avh.AssetId = ea.AssetId
INNER JOIN LeaseFinances lf ON lf.ContractId = coa.ContractId AND lf.IsCurrent = 1
INNER JOIN LeaseFinanceDetails lfd ON lf.Id = lfd.Id
INNER JOIN 
	(SELECT DISTINCT c.Id AS ContractId,la.AssetId,la.IsLeaseAsset,la.IsFailedSaleLeaseback
	FROM Contracts c
	INNER JOIN LeaseFinances lf ON c.Id = lf.ContractId
	INNER JOIN LeaseAssets la ON la.LeaseFinanceId = lf.Id
	) AS t ON t.ContractId = coa.ContractId AND t.AssetId = avh.AssetId AND t.AssetId = ea.AssetId
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = coa.ContractId AND rft.ContractId = lf.ContractId
WHERE avh.SourceModule = ''ChargeOff''
AND (lfd.LeaseContractType != ''Operating'' OR (lfd.LeaseContractType = ''Operating'' AND ComponentCondition))
GROUP BY ea.AssetId'
IF @IsSku = 0
	BEGIN
	SET @Sql = REPLACE(@Sql,'ComponentCondition','t.IsLeaseAsset = 0 OR t.IsFailedSaleLeaseback = 1')
	END
ELSE
	BEGIN
	SET @Sql = REPLACE(@Sql,'ComponentCondition','avh.IsLeaseComponent = 0 OR t.IsFailedSaleLeaseback = 1')
	END
INSERT INTO #FinanceChargeOffAmount_Info
EXEC(@Sql)
END;

CREATE NONCLUSTERED INDEX IX_Id ON #FinanceChargeOffAmount_Info(AssetId);

SELECT la.AssetId
	,SUM(CASE WHEN rft.ContractId IS NOT NULL
			THEN CAST(la.LeasedAssetCost * rft.RetainedPortion AS DECIMAL (16,2))
			WHEN rft.ContractId IS NULL 
			THEN la.LeasedAssetCost
			ELSE 0.00
		END)
	- ISNULL(SUM(CASE WHEN la.AssetStatus IN ('Leased','InvestorLeased') AND rft.ContractId IS NOT NULL
			THEN CAST((bi.ETCAmount_LeaseComponent + bi.ETCAmount_FinanceComponent) * rft.RetainedPortion AS DECIMAL (16,2))
			WHEN la.AssetStatus IN ('Leased','InvestorLeased') AND rft.ContractId IS NULL 
			THEN (bi.ETCAmount_LeaseComponent + bi.ETCAmount_FinanceComponent)
			ELSE 0.00
		END),0.00) LeasedChargedOff_Table
INTO #LeasedChargedOffTableInfo
FROM #LeaseAssetsInfo la
INNER JOIN #ChargeOffAssetsInfo coa ON la.AssetId = coa.AssetId AND la.LeaseContractId = coa.ContractId
LEFT JOIN #ReceivableForTransfersInfo rft ON rft.ContractId = coa.ContractId
LEFT JOIN #BlendedItemInfo bi ON bi.AssetId = la.AssetId
GROUP BY la.AssetId

CREATE NONCLUSTERED INDEX IX_Id ON #LeasedChargedOffTableInfo(AssetId);

SELECT
	DISTINCT rl.AssetId
INTO #SoldAssetsPostChargeOff
FROM #ResultList rl
INNER JOIN LeaseAssets la ON rl.AssetId = la.AssetId
INNER JOIN LeaseFinances lf ON lf.Id = la.LeaseFinanceId
INNER JOIN PayoffAssets poa ON poa.LeaseAssetId = la.Id
INNER JOIN Payoffs p on poa.PayoffId = p.Id
INNER JOIN #ChargeOffAssetsInfo coa ON coa.ContractId = lf.ContractId AND coa.AssetId = la.AssetId
WHERE rl.AssetStatus IN ('Sold')

CREATE NONCLUSTERED INDEX IX_Id ON #SoldAssetsPostChargeOff(AssetId);

IF @IsFromLegalEntity = 1
BEGIN

SELECT
	rl.LegalEntityName
	,ISNULL(SUM(rl.AcquisitionCost_LeaseComponent
	+ rl.AcquisitionCost_FinanceComponent
	+ rl.OtherCost_LeaseComponent
	+ rl.OtherCost_FinanceComponent
	+ rl.SpecificCostAdjustment_LeaseComponent
	+ rl.SpecificCostAdjustment_FinanceComponent),0.00) AS AcquisitionCost_Table
	,ISNULL(SUM(CASE WHEN rl.AssetStatus NOT IN ('Leased','InvestorLeased')
	THEN rl.AcquisitionCost_LeaseComponent
	+ rl.AcquisitionCost_FinanceComponent
	+ rl.OtherCost_LeaseComponent
	+ rl.OtherCost_FinanceComponent
	+ rl.SpecificCostAdjustment_LeaseComponent
	+ rl.SpecificCostAdjustment_FinanceComponent
	ELSE 0.00 END),0.00) AS AcquisitionCostTable_GL
	,ISNULL(SUM(rl.ETCAmount_LeaseComponent
	+ rl.ETCAmount_FinanceComponent),0.00) AS ETC_Table
	,ISNULL(SUM(rl.TaxCapitalizedAmount_LeaseComponent
	+ rl.TaxCapitalizedAmount_FinanceComponent
	+ rl.InterimRentCapitalizationAmount_LeaseComponent
	+ rl.InterimRentCapitalizationAmount_FinanceComponent
	+ rl.InterimInterestCapitalizationAmount_LeaseComponent
	+ rl.InterimInterestCapitalizationAmount_FinanceComponent
	+ rl.AdditionalChargesCapitalizationAmount_LeaseComponent
	+ rl.AdditionalChargesCapitalizationAmount_FinanceComponent
	+ rl.ProgressPaymentCapitalizationAmount_LeaseComponent
	+ rl.ProgressPaymentCapitalizationAmount_FinanceComponent),0.00) AS CapitalizedCost_Table
	,ISNULL(SUM(rl.ValueChangeAmount_LeaseComponent
	+ rl.ValueChangeAmount_FinanceComponent),0.00) AS AssetBookValueAdjustment_Table
	,ISNULL(SUM(rl.PaydownValueAmount),0.00) AS ReturnedToInventory_Paydown_Table
	,ISNULL(SUM(rl.LeasedAssetCost),0.00) AS LeasedAssetCost_Table
	,ISNULL(SUM(rl.AssetAmortizedValueAmount_LeaseComponent
	+ rl.AssetAmortizedValueAmount_FinanceComponent
	+ rl.RenewalAmortizedAmount_LeaseComponent
	+ rl.RenewalAmortizedAmount_FinanceComponent
	),0.00)
	+ ISNULL(SUM(CASE WHEN rl.AssetStatus NOT IN ('Leased','InvestorLeased')
		THEN rl.ResidualReclassAmount_LeaseComponent
			+ rl.ResidualReclassAmount_FinanceComponent
			+ rl.ResidualRecaptureAmount_LeaseComponent
			+ rl.ResidualRecaptureAmount_FinanceComponent
		ELSE 0.00 END),0.00)
	+ ISNULL(SUM(foc.FinanceChargeOffAmount),0.00) AS AssetAmortizedValue_Table
	,ISNULL(SUM(rl.ClearedInventoryDepreciationAmount_LeaseComponent
	+ rl.ClearedInventoryDepreciationAmount_FinanceComponent
	+ rl.ClearedFixedTermDepreciationAmount_LeaseComponent
	+ rl.ClearedOTPDepreciationAmount_LeaseComponent
	+ rl.ClearedOTPDepreciationAmount_FinanceComponent),0.00) AS ClearedDepreciation_Table
	,ISNULL(SUM(rl.ClearedNBVImpairmentAmount_LeaseComponent
	+ rl.ClearedNBVImpairmentAmount_FinanceComponent
	- rl.ClearedAssetImpairmentAmount_LeaseComponent
	- rl.ClearedAssetImpairmentAmount_FinanceComponent),0.00) AS ClearedImpairment_Table
	,ISNULL(SUM(rl.AccumulatedFixedTermDepreciationAmount_LeaseComponent),0.00) AS AccumulatedFixedTermDepreciation_Table
	,ISNULL(SUM(rl.AccumulatedOTPDepreciationAmount_LeaseComponent
	+ rl.AccumulatedOTPDepreciationAmount_FinanceComponent),0.00) AS AccumulatedOTPDepreciation_Table
	,ISNULL(SUM(rl.AccumulatedAssetDepreciationAmount_LeaseComponent
	+ rl.AccumulatedAssetDepreciationAmount_FinanceComponent
	+ rl.AccumulatedInventoryDepreciationAmount_LeaseComponent
	+ rl.AccumulatedInventoryDepreciationAmount_FinanceComponent),0.00) AS AccumulatedAssetDepreciation_Table
	,ISNULL(SUM(rl.AccumulatedNBVImpairmentAmount_LeaseComponent
	+ rl.AccumulatedNBVImpairmentAmount_FinanceComponent),0.00) AS AccumulatedNBVImpairment_Table
	,ISNULL(SUM(rl.AccumulatedAssetImpairmentAmount_NBV_LeaseComponent
	+ rl.AccumulatedAssetImpairmentAmount_NBV_FinanceComponent
	- rl.AccumulatedAssetImpairmentAmount_LeaseComponent
	- rl.AccumulatedAssetImpairmentAmount_FinanceComponent),0.00) AS AccumulatedAssetImpairment_Table
	,ISNULL(SUM(CASE WHEN spc.AssetId IS NULL
		THEN rl.BuyoutCostOfGoodsSold_LeaseComponent + rl.BuyoutCostOfGoodsSold_FinanceComponent
		ELSE 0.00
		END),0.00)
	+ ISNULL(SUM(rl.SyndicationValueAmount_LeaseComponent
	+ rl.SyndicationValueAmount_FinanceComponent
	+ rl.AssetSaleCostOfGoodsSold_LeaseComponent
	+ rl.AssetSaleCostOfGoodsSold_FinanceComponent),0.00) AS CostOfGoodsSold_Table
	,ISNULL(SUM(CASE 
				WHEN poa.AssetId IS NOT NULL AND rl.AssetStatus NOT IN ('Leased','InvestorLeased') 
				THEN rl.AssetValue_Computed
				ELSE 0.00
				END),0.00)
	+ ISNULL(SUM(CASE
				WHEN rl.AssetStatus IN ('Leased','InvestorLeased')
				THEN rl.SyndicationValueAmount_LeaseComponent + rl.SyndicationValueAmount_FinanceComponent
				ELSE 0.00
				END),0.00)
	+ ISNULL(SUM(CASE
				WHEN ara.AssetId IS NOT NULL
				THEN rl.LeasedAssetCost
				ELSE 0.00
				END),0.00)
	+ ISNULL(SUM(CASE
				WHEN rl.AssetStatus = 'Sold' 
					AND (rl.BuyoutCostOfGoodsSold_LeaseComponent != 0.00 OR rl.BuyoutCostOfGoodsSold_FinanceComponent != 0.00)
				THEN rl.BuyoutCostOfGoodsSold_LeaseComponent + rl.BuyoutCostOfGoodsSold_FinanceComponent
				WHEN rl.AssetStatus = 'Sold' 
					AND (rl.BuyoutCostOfGoodsSold_LeaseComponent = 0.00 OR rl.BuyoutCostOfGoodsSold_FinanceComponent = 0.00)
				THEN (rl.AcquisitionCost_LeaseComponent + rl.AcquisitionCost_FinanceComponent + rl.OtherCost_LeaseComponent + rl.OtherCost_FinanceComponent + rl.SpecificCostAdjustment_LeaseComponent + rl.SpecificCostAdjustment_FinanceComponent) - (rl.AssetAmortizedValueAmount_LeaseComponent - rl.AssetAmortizedValueAmount_FinanceComponent)
				ELSE 0.00
				END),0.00) AS ReturnToInventory_Lease_Table
	, ISNULL(SUM(oc.OperatingLeaseChargeOff_Table),0.00) AS ChargeOff_Table
	, ISNULL(SUM(CASE WHEN rl.AssetStatus IN ('Leased','InvestorLeased') THEN rpo.RenewalPO_Inventory_LC + rpo.RenewalPO_Inventory_NLC ELSE 0.00 END),0.00) AS RenewalAmortizedValue_Table
	, ISNULL(SUM(loc.LeasedChargedOff_Table),0.00) AS LeasedChargedOff_Table
FROM #ResultList rl
LEFT JOIN #ResidualBeforePayoff rp ON rl.AssetId = rp.AssetId
LEFT JOIN #PayoffAssetInfo poa ON rl.AssetId = poa.AssetId
LEFT JOIN #ActiveRenewedAssets ara ON ara.AssetId = rl.AssetId
LEFT JOIN #LeaseAssetsInfo la ON la.AssetId = rl.AssetId
LEFT JOIN #BlendedItemInfo bi ON bi.AssetId = rl.AssetId
LEFT JOIN #OperatingLeaseChargeOff oc ON oc.AssetId = rl.AssetId
LEFT JOIN #RenewalPaidOffInventory rpo ON rpo.AssetId = rl.AssetId
LEFT JOIN #ChargedOffCapitalLeaseAssetsInfo co ON co.AssetId = rl.AssetId
LEFT JOIN #FinanceChargeOffAmount_Info foc ON foc.AssetId = rl.AssetId
LEFT JOIN #LeasedChargedOffTableInfo loc ON loc.AssetId = rl.AssetId
LEFT JOIN #SoldAssetsPostChargeOff spc ON spc.AssetId = rl.AssetId
GROUP BY rl.LegalEntityName
ORDER BY rl.LegalEntityName;

END;

DROP TABLE #ReceivableForTransfersInfo;
DROP TABLE #InvestorLeasedAssets;
DROP TABLE #CollateralLoanScrapedAssets;
DROP TABLE #EligibleAssets;
DROP TABLE #PayoffInfo;
DROP TABLE #BuyoutInfo;
DROP TABLE #HasChildAssets;
DROP TABLE #CapitalizedSoftAssetInfo;
DROP TABLE #LeaseAssetsInfo;
DROP TABLE #LeaseAssetsAmountInfo;
DROP TABLE #LeaseCapitalizedAmountInfo;
DROP TABLE #CurrentNBVInfo;
DROP TABLE #SKUComponentCount;
DROP TABLE #PayableInvoiceInfo;
DROP TABLE #ContractInfo;
DROP TABLE #ChargeOffInfo;
DROP TABLE #AssetSplitInfo;
DROP TABLE #CreatedFromAssetSplit;
DROP TABLE #AssetSaleInfo;
DROP TABLE #AcquisitionCostInfo;
DROP TABLE #PayableInvoiceOtherCostInfo;
DROP TABLE #SpecificCostInfo;
DROP TABLE #OverTerm;
DROP TABLE #LeaseAmendmentInfo;
DROP TABLE #OTPReclass;
DROP TABLE #BookDepId;
DROP TABLE #BookDepreciationInfo;
DROP TABLE #BookedResidualInfo;
DROP TABLE #RELBookDepInfo;
DROP TABLE #RemainingEconomicLifeInfo;
DROP TABLE #ContractCount;
DROP TABLE #PreviousSeq;
DROP TABLE #GroupedSeq;
DROP TABLE #BlendedItemInfo;
DROP TABLE #RenewalBlendedItemInfo;
DROP TABLE #BlendedItemCapitalizeInfo;
DROP TABLE #AVHClearedTillDate;
DROP TABLE #AVHClearedTillDateFixedTerm;
DROP TABLE #AVHClearedTillDateOTP;
DROP TABLE #AssetImpairmentAVHInfo;
DROP TABLE #ValueChangeInfo;
DROP TABLE #AssetImpairmentInfo;
DROP TABLE #PaydownAVHInfo;
DROP TABLE #AssetInventoryAVHInfo;
DROP TABLE #AVHAssetsInfo;
DROP TABLE #ChargeOffAssetsInfo;
DROP TABLE #SKUAVHClearedTillDate;
DROP TABLE #PayoffAssetInfo;
DROP TABLE #SyndicatedAssets;
DROP TABLE #ChargeOffMaxCleared;
DROP TABLE #RenewedAssets;
DROP TABLE #AVHMaxSourceModuleIdInfo;
DROP TABLE #SKUAVHMaxSourceModuleIdInfo;
DROP TABLE #AVHMaxClearedSourceModule;
DROP TABLE #SKUAVHMaxClearedSourceModule;
DROP TABLE #AccumulatedAVHInfo;
DROP TABLE #MaxBeforeSynd;
DROP TABLE #ResidualAVHInfo;
DROP TABLE #SyndicationAmountInfo;
DROP TABLE #OtherAVHInfo;
DROP TABLE #LeaseAmendmentImpairmentInfo;
DROP TABLE #RenewalAmortizeInfo;
DROP TABLE #ComputedValueCalculation;
DROP TABLE #ActualValueCalculation;
DROP TABLE #PayoffAtInceptionSoftAssets;
DROP TABLE #NotGLPostedPIInfo;
DROP TABLE #ResultList;
DROP TABLE #ResidualBeforePayoff;
DROP TABLE #ActiveRenewedAssets;
DROP TABLE #OperatingLeaseChargeOff;
DROP TABLE #RenewalPaidOffInventory;
DROP TABLE #ChargedOffCapitalLeaseAssetsInfo;
DROP TABLE #FinanceChargeOffAmount_Info;
DROP TABLE #LeasedChargedOffTableInfo;
DROP TABLE #SoldAssetsPostChargeOff;
DROP TABLE #AssetSummary;

END

GO
