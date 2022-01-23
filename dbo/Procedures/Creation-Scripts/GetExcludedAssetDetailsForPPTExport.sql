SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetExcludedAssetDetailsForPPTExport]
(
@ExportDate DATE,
@IsAllLegelEntities BIT,
@LegalEntityIds NVARCHAR(MAX),
@CurrentPortfolioId BIGINT
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #Output
(
NumberOfAssets BIGINT,
RejectionReason NVARCHAR(MAX),
TotalPPTBasisAmount DECIMAL,
TotalPPTBasisCurrency NVARCHAR(3),
StateId BIGINT,
LegalEntityId BIGINT
)
CREATE TABLE #ExcludedAssetDetails
(
AssetId BIGINT,
RejectionReason NVARCHAR(MAX),
StateId BIGINT
)
CREATE TABLE #ApplicableLegalEntities
(
LegalEntityId BIGINT
)
INSERT INTO #ApplicableLegalEntities
SELECT ID FROM ConvertCSVToBigIntTable(@LegalEntityIds, ',')
SELECT
StateId,
IsReportInventory,
IsReportCSAs
INTO #ValidPropertyTaxStateSetting
FROM
PropertyTaxStateSettings
WHERE IsActive = 1
AND IsExempt = 0
AND EffectiveFromDate <= @ExportDate AND EffectiveToDate >= @ExportDate
AND (AssessmentMonth < DATENAME(MONTH, @ExportDate) OR (AssessmentMonth = DATENAME(MONTH, @ExportDate) AND AssessmentDay <= DAY(@ExportDate)))
AND PortfolioId = @CurrentPortfolioId
SELECT
Assets.Id AS AssetId
INTO #LeaseLevelOverridableAssets
FROM
Assets
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN #ValidPropertyTaxStateSetting ON Locations.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN PropertyTaxLeaseLevelSettings ON Contracts.Id = PropertyTaxLeaseLevelSettings.ContractId
WHERE AssetLocations.IsActive = 1
AND AssetLocations.IsCurrent = 1
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND PropertyTaxLeaseLevelSettings.IsActive = 1
AND (PropertyTaxLeaseLevelSettings.IncludeInExtract = 1 OR PropertyTaxLeaseLevelSettings.IncludeAllPPTExemptCodes = 1 OR PropertyTaxLeaseLevelSettings.IsReportCSA = 1)
SELECT
Assets.Id AS AssetId,
Assets.TypeId AS AssetTyepId,
States.Id AS StateId,
Assets.Status AS Status,
Assets.PropertyTaxReportCodeId AS PropertyTaxReportCodeId
INTO #ValidAssets
FROM
Assets
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN States ON Locations.StateId = States.Id
LEFT JOIN #LeaseLevelOverridableAssets ON Assets.Id = #LeaseLevelOverridableAssets.AssetId
WHERE AssetLocations.IsActive = 1
AND AssetLocations.IsCurrent = 1
AND #LeaseLevelOverridableAssets.AssetId IS NULL
/* Lease Level Override Exclusion Details */
INSERT INTO #ExcludedAssetDetails
SELECT
Assets.Id,
'Lease Level Exceptions',
#ValidPropertyTaxStateSetting.StateId
FROM
Assets
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN #ValidPropertyTaxStateSetting ON Locations.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN LeaseAssets ON Assets.Id = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
JOIN PropertyTaxLeaseLevelSettings ON Contracts.Id = PropertyTaxLeaseLevelSettings.ContractId
WHERE AssetLocations.IsActive = 1
AND AssetLocations.IsCurrent = 1
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND PropertyTaxLeaseLevelSettings.IsActive = 1
AND (PropertyTaxLeaseLevelSettings.IncludeInExtract = 0 AND PropertyTaxLeaseLevelSettings.IncludeAllPPTExemptCodes = 0 AND PropertyTaxLeaseLevelSettings.IsReportCSA = 0)
/* State Settings Exclusion Details */
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : State Not Applicable',
#ValidAssets.StateId
FROM #ValidAssets
LEFT JOIN PropertyTaxStateSettings ON #ValidAssets.StateId = PropertyTaxStateSettings.StateId AND PropertyTaxStateSettings.IsActive = 1
WHERE PropertyTaxStateSettings.Id IS NULL
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : State is Tax Exempted',
#ValidAssets.StateId
FROM #ValidAssets
JOIN PropertyTaxStateSettings ON #ValidAssets.StateId = PropertyTaxStateSettings.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxStateSettings.IsActive = 1
AND PropertyTaxStateSettings.IsExempt = 1
AND PropertyTaxStateSettings.PortfolioId = @CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : Export Date is not within Effective Dates',
#ValidAssets.StateId
FROM #ValidAssets
JOIN PropertyTaxStateSettings ON #ValidAssets.StateId = PropertyTaxStateSettings.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxStateSettings.IsActive = 1
AND PropertyTaxStateSettings.IsExempt = 0
AND (PropertyTaxStateSettings.EffectiveFromDate > @ExportDate OR PropertyTaxStateSettings.EffectiveToDate < @ExportDate)
AND PropertyTaxStateSettings.PortfolioId =@CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : Assessment Date in Future',
#ValidAssets.StateId
FROM #ValidAssets
JOIN PropertyTaxStateSettings ON #ValidAssets.StateId = PropertyTaxStateSettings.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxStateSettings.IsActive = 1
AND PropertyTaxStateSettings.IsExempt = 0
AND PropertyTaxStateSettings.EffectiveFromDate <= @ExportDate AND PropertyTaxStateSettings.EffectiveToDate >= @ExportDate
AND (PropertyTaxStateSettings.AssessmentMonth > DATENAME(MONTH, @ExportDate) OR (PropertyTaxStateSettings.AssessmentMonth = DATENAME(MONTH, @ExportDate) AND PropertyTaxStateSettings.AssessmentDay > DAY(@ExportDate)))
AND PropertyTaxStateSettings.PortfolioId =@CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : Invertory Assets Not Reportable',
#ValidAssets.StateId
FROM #ValidAssets
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND #ValidPropertyTaxStateSetting.IsReportInventory = 0
AND #ValidAssets.Status = 'Inventory'
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Setting : Conditional Sales Assets Not Reportable',
#ValidAssets.StateId
FROM LeaseFinances
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN #ValidAssets ON LeaseAssets.AssetId = #ValidAssets.AssetId
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND #ValidPropertyTaxStateSetting.IsReportCSAs = 0
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND LeaseFinanceDetails.LeaseContractType = 'ConditionalSales'
/* Contract Settings Exclusion Details */
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'Contract Setting : Contract Type Not Applicable',
#ValidAssets.StateId
FROM LeaseFinances
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN #ValidAssets ON LeaseAssets.AssetId = #ValidAssets.AssetId
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
LEFT JOIN PropertyTaxContractSettings ON LeaseFinanceDetails.LeaseContractType = PropertyTaxContractSettings.LeaseContractType AND PropertyTaxContractSettings.IsActive = 1
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxContractSettings.Id IS NULL
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'Contract Setting : Export Date is not within Effective Dates',
#ValidAssets.StateId
FROM LeaseFinances
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN #ValidAssets ON LeaseAssets.AssetId = #ValidAssets.AssetId
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxContractSettings ON LeaseFinanceDetails.LeaseContractType = PropertyTaxContractSettings.LeaseContractType
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxContractSettings.IsActive = 1
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND (PropertyTaxContractSettings.EffectiveFromDate > @ExportDate OR PropertyTaxContractSettings.EffectiveToDate < @ExportDate)
AND PropertyTaxContractSettings.PortfolioId= @CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'Contract Setting : Bank Qualified Not Reportable',
#ValidAssets.StateId
FROM LeaseFinances
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN #ValidAssets ON LeaseAssets.AssetId = #ValidAssets.AssetId
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxContractSettings ON LeaseFinanceDetails.LeaseContractType = PropertyTaxContractSettings.LeaseContractType
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxContractSettings.IsActive = 1
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND LeaseFinances.BankQualified = 'BankQualified'
AND PropertyTaxContractSettings.IsBankQualified = 0
AND PropertyTaxContractSettings.PortfolioId =@CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'Contract Setting : Federal Income Tax Exempt Not Reportable',
#ValidAssets.StateId
FROM LeaseFinances
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseFinances.Id = LeaseAssets.LeaseFinanceId
JOIN #ValidAssets ON LeaseAssets.AssetId = #ValidAssets.AssetId
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxContractSettings ON LeaseFinanceDetails.LeaseContractType = PropertyTaxContractSettings.LeaseContractType
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxContractSettings.IsActive = 1
AND LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND LeaseFinances.IsFederalIncomeTaxExempt = 1
AND PropertyTaxContractSettings.IsFederalIncomeTaxExempt = 0
AND PropertyTaxContractSettings.PortfolioId = @CurrentPortfolioId
/* States Class Code Setting Exclusion Details */
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Class Code Setting : Asset Class Code Not Applicable',
#ValidAssets.StateId
FROM #ValidAssets
JOIN AssetTypes ON #ValidAssets.AssetTyepId = AssetTypes.Id
JOIN AssetClassCodes ON AssetTypes.AssetClassCodeId = AssetClassCodes.Id
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxStateClassCodes ON #ValidPropertyTaxStateSetting.StateId = PropertyTaxStateClassCodes.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxStateClassCodes.IsActive = 1
AND AssetClassCodes.Id = PropertyTaxStateClassCodes.AssetClassCodeId
AND PropertyTaxStateClassCodes.PortfolioId = @CurrentPortfolioId
--AND (PropertyTaxStateClassCodes.EffectiveFromDate <= @ExportDate AND PropertyTaxStateClassCodes.EffectiveToDate >= @ExportDate)
/* State Exemption Code Setting Exclusion Details */
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Exemption Code Setting : Property Tax Report Code Not Applicable',
#ValidAssets.StateId
FROM #ValidAssets
JOIN PropertyTaxReportCodeConfigs ON #ValidAssets.PropertyTaxReportCodeId = PropertyTaxReportCodeConfigs.Id
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxExemptCodes ON #ValidPropertyTaxStateSetting.StateId = PropertyTaxExemptCodes.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxExemptCodes.IsActive = 1
AND PropertyTaxReportCodeConfigs.Id != PropertyTaxExemptCodes.PropertyTaxReportCodeId
AND PropertyTaxExemptCodes.PortfolioId = @CurrentPortfolioId
INSERT INTO #ExcludedAssetDetails
SELECT
#ValidAssets.AssetId,
'State Exemption Code Setting : Export Date is not within Effective Dates',
#ValidAssets.StateId
FROM #ValidAssets
JOIN PropertyTaxReportCodeConfigs ON #ValidAssets.PropertyTaxReportCodeId = PropertyTaxReportCodeConfigs.Id
JOIN #ValidPropertyTaxStateSetting ON #ValidAssets.StateId = #ValidPropertyTaxStateSetting.StateId
JOIN PropertyTaxExemptCodes ON #ValidPropertyTaxStateSetting.StateId = PropertyTaxExemptCodes.StateId
LEFT JOIN #ExcludedAssetDetails ON #ValidAssets.AssetId = #ExcludedAssetDetails.AssetId
WHERE #ExcludedAssetDetails.AssetId IS NULL
AND PropertyTaxExemptCodes.IsActive = 1
AND PropertyTaxReportCodeConfigs.Id = PropertyTaxExemptCodes.PropertyTaxReportCodeId
AND (PropertyTaxExemptCodes.EffectiveFromDate > @ExportDate OR PropertyTaxExemptCodes.EffectiveToDate < @ExportDate)
AND PropertyTaxExemptCodes.PortfolioId = @CurrentPortfolioId
/* Output */
INSERT INTO #Output
SELECT
CASE WHEN COUNT(#ExcludedAssetDetails.AssetId) IS NULL THEN 0 ELSE COUNT(#ExcludedAssetDetails.AssetId) END,
#ExcludedAssetDetails.RejectionReason,
CASE WHEN SUM(Assets.PropertyTaxCost_Amount) IS NULL THEN 0.00 ELSE SUM(Assets.PropertyTaxCost_Amount) END,
Assets.PropertyTaxCost_Currency,
#ExcludedAssetDetails.StateId,
LegalEntities.Id
FROM #ExcludedAssetDetails
JOIN Assets ON #ExcludedAssetDetails.AssetId = Assets.Id
JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
LEFT JOIN #ApplicableLegalEntities ON LegalEntities.Id = #ApplicableLegalEntities.LegalEntityId
WHERE (@IsAllLegelEntities = 1 OR #ApplicableLegalEntities.LegalEntityId IS NOT NULL)
GROUP BY Assets.PropertyTaxCost_Currency, LegalEntities.Id, #ExcludedAssetDetails.StateId, #ExcludedAssetDetails.RejectionReason
SELECT
NumberOfAssets,
RejectionReason,
TotalPPTBasisAmount,
TotalPPTBasisCurrency,
StateId,
LegalEntityId
FROM #Output
DROP TABLE
#ValidPropertyTaxStateSetting,
#LeaseLevelOverridableAssets,
#ValidAssets,
#ExcludedAssetDetails,
#ApplicableLegalEntities,
#Output
SET NOCOUNT OFF
END

GO
