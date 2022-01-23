SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertSalesTaxReversalTaxExemptDetails]
(
@ContractTaxExemptRule NVARCHAR(27),
@AssetTaxExemptRule NVARCHAR(27),
@LocationTaxExemptRule NVARCHAR(27),
@ReceivableCodeTaxExemptRule NVARCHAR(27),
@UnknownTaxExemptRule NVARCHAR(27),
@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_DistinctReceivableInfo AS
(
SELECT DISTINCT AssetId,ReceivableDetailId FROM ReversalReceivableDetail_Extract WHERE ErrorCode IS NULL AND IsVertexSupported = 1 AND JobStepInstanceId = @JobStepInstanceId
)
INSERT INTO ReversalTaxExemptDetail_Extract
(ReceivableDetailId, AssetId, CountryTaxExempt, StateTaxExempt, CityTaxExempt, CountyTaxExempt, CountryTaxExemptRule,
StateTaxExemptRule, CityTaxExemptRule, CountyTaxExemptRule, CreatedById, CreatedTime, JobStepInstanceId)
SELECT
RI.ReceivableDetailId,
RI.AssetId,
CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CountryTaxExempt,
CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) StateTaxExempt,
CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CityTaxExempt,
CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CountyTaxExempt,
CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN @ContractTaxExemptRule
WHEN AssetRule.IsCountryTaxExempt = 1 THEN @AssetTaxExemptRule
WHEN LocationRule.IsCountryTaxExempt = 1 THEN @LocationTaxExemptRule
WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
ELSE @UnknownTaxExemptRule END AS CountryTaxExemptRule,
CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN @ContractTaxExemptRule
WHEN AssetRule.IsStateTaxExempt = 1 THEN @AssetTaxExemptRule
WHEN LocationRule.IsStateTaxExempt = 1 THEN @LocationTaxExemptRule
WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
ELSE @UnknownTaxExemptRule END AS StateTaxExemptRule,
CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN @ContractTaxExemptRule
WHEN AssetRule.IsCityTaxExempt = 1 THEN @AssetTaxExemptRule
WHEN LocationRule.IsCityTaxExempt = 1 THEN @LocationTaxExemptRule
WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
ELSE @UnknownTaxExemptRule END AS CityTaxExemptRule,
CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN @ContractTaxExemptRule
WHEN AssetRule.IsCountyTaxExempt = 1 THEN @AssetTaxExemptRule
WHEN LocationRule.IsCountyTaxExempt = 1 THEN @LocationTaxExemptRule
WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN @ReceivableCodeTaxExemptRule
ELSE @UnknownTaxExemptRule END AS CountyTaxExemptRule,
CreatedById = 1,
CreatedTime = SYSDATETIMEOFFSET(),
@JobStepInstanceId
FROM CTE_DistinctReceivableInfo DRI
INNER JOIN ReversalReceivableDetail_Extract RI ON DRI.ReceivableDetailId = RI.ReceivableDetailId AND (DRI.AssetId = RI.AssetId OR DRI.AssetId IS NULL) AND RI.JobStepInstanceId = @JobStepInstanceId
INNER JOIN ReversalLocationDetail_Extract LI ON RI.LocationId = LI.LocationId AND LI.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN ReceivableCodeTaxExemptRules RCT ON RI.ReceivableCodeId = RCT.ReceivableCodeId
AND LI.StateId = RCT.StateId AND RCT.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON RCT.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN Assets Asset ON Asset.Id = RI.AssetId
LEFT JOIN TaxExemptRules AssetRule ON Asset.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances LF ON RI.ContractId = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations Location ON RI.LocationId = Location.Id
LEFT JOIN TaxExemptRules LocationRule ON Location.TaxExemptRuleId = LocationRule.Id
WHERE ErrorCode IS NULL AND IsVertexSupported = 1
END

GO
