SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceivableDetailsForManualSalesTaxReversal]
(
@ReceivableDetailIds NVARCHAR(MAX),
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex  = 'Vertex';


CREATE TABLE #ReceivableDetails
(
Id BIGINT INDEX IX_Id NONCLUSTERED NOT NULL
)
INSERT INTO #ReceivableDetails (Id) SELECT Id FROM ConvertCSVToBigIntTable(@ReceivableDetailIds, ',');
WITH CTE_SundryRecurringDetails as
(
SELECT DISTINCT
RD.ReceivableId
,SundryRecurrings.IsTaxExempt
,SundryRecurrings.IsAssetBased
FROM
ReceivableDetails RD
JOIN #ReceivableDetails RDIds ON RD.Id = RdIds.Id
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN SundryRecurringPaymentSchedules  AS SRPS  ON RD.ReceivableId = SRPS.ReceivableId
JOIN SundryRecurrings ON SundryRecurrings.Id = SRPS.SundryRecurringId
AND SundryRecurrings.IsActive = 1
AND ((SundryRecurrings.LocationId IS NOT NULL) OR (SundryRecurrings.LocationId IS NULL AND SundryRecurrings.IsAssetBased = 0))
WHERE R.SourceTable <> 'LateFee' AND R.IsActive = 1 --Why do we need source table condition -RS
)
SELECT
R.DueDate AS DueDate,
RT.Id AS ReceivableTaxId,
R.Id AS ReceivableId,
RTD.ReceivableDetailId AS ReceivableDetailId,
CC.Class AS ClassCode,
P.PartyNumber AS CustomerCode,
RTD.Revenue_Currency AS Currency,
RTD.TaxAreaId AS TaxAreaId,
L.City AS City,
countries.ShortName AS Country,
S.ShortName AS MainDivision,
RTD.ManuallyAssessed 'IsManuallyAssessed',
RTRD.IsExemptAtLease,
RTRD.IsExemptAtAsset,
RTRD.IsExemptAtSundry,
RTRD.Company,
RTRD.Product,
RTRD.ContractType,
RTRD.AssetType,
RTRD.LeaseType,
RTRD.LeaseTerm,
RTRD.TitleTransferCode,
RTRD.TransactionCode,
RTRD.AmountBilledToDate,
RTD.Cost_Amount AS Cost,
RTD.Revenue_Amount AS ExtendedPrice,
RTD.FairMarketValue_Amount AS FairMarketValue,
RTD.TaxBasisType AS TaxBasisType,
cont.SequenceNumber AS LeaseUniqueId,
RC.Name AS SundryReceivableCode,
CASE WHEN (RecType.Name = 'BuyOut' OR RecType.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS TransactionType
,LE.Id 'LegalEntityId'
,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupportedLocation
,CASE WHEN cont.ContractType = 'Lease' THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsLeaseBased
,CASE WHEN RD.AssetId IS NULL OR RD.AssetId = '' THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS IsAssetBased
,RTRD.AssetLocationId
,ISNULL(A.IsParent,CONVERT(BIT,0)) IsMultiComponent
,CASE WHEN Loan.Id IS NOT NULL THEN Loan.CommencementDate ELSE LFD.CommencementDate END AS CommencementDate
,RecType.Name ReceivableType
,RC.IsTaxExempt IsExemptAtReceivableCode
,cont.ContractType ContractTypeValue
,RecType.IsRental
,AL.EffectiveFromDate AS LocationEffectiveDate
--User Defined Flex Fields
,SLBC.Code AS SaleLeasebackCode
,ISNULL(A.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
,RTRD.ToStateName ToState
,RTRD.FromStateName FromState
,ISNULL(A.GrossVehicleWeight ,0) GrossVehicleWeight
,ISNULL(AL.LienCredit_Amount, 0.00) LienCredit_Amount
,ISNULL(AL.LienCredit_Currency,'USD') LienCredit_Currency
,ISNULL(AL.ReciprocityAmount_Amount, 0.00) ReciprocityAmount_Amount
,ISNULL(AL.ReciprocityAmount_Currency,'USD') ReciprocityAmount_Currency,
RTD.AssetId As AssetId
,CAST(NULL AS NVARCHAR) AS EngineType
,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel
,ISNULL(LA.IsPrepaidUpfrontTax,CAST(0 AS BIT)) IsPrepaidUpfrontTax
,DTTFRT.TaxTypeId
,LA.StateTaxTypeId
,LA.CountyTaxTypeId
,LA.CityTaxTypeId
,S.Id StateId
,RTD.LocationId
,cont.ID ContractId
,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
,R.ReceivableCodeId
,CASE WHEN RD.BilledStatus = 'Invoiced' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsInvoiced
,CASE WHEN (RT.Balance_Amount != RT.Amount_Amount) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsCashPosted
,AU.Usage
,RTD.UpfrontTaxSundryId
,LA.AcquisitionLocationId
,A.UsageCondition AS AssetUsageCondition
,CASE WHEN Loan.Id IS NOT NULL THEN Loan.MaturityDate ELSE LFD.MaturityDate END AS MaturityDate
,RTRD.SalesTaxRemittanceResponsibility
,ISNULL(RTRD.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT)) AS UpfrontTaxAssessedInLegacySystem
,RTRD.BusCode
INTO #ReceivableInfo
FROM
ReceivableTaxes RT
INNER JOIN ReceivableTaxDetails RTD ON RT.Id = RTD.ReceivableTaxId AND RTD.IsActive = 1
INNER JOIN Receivables R ON RT.ReceivableId = R.Id AND R.IsActive = 1
INNER JOIN ReceivableDetails RD ON RTD.ReceivableDetailId = RD.Id AND RD.IsActive = 1 AND RD.IsTaxAssessed = 1
INNER JOIN #ReceivableDetails RDIds ON RD.Id = RDIds.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RecType ON RC.ReceivableTypeId = RecType.Id
INNER JOIN Customers C ON R.CustomerId = C.Id
INNER JOIN Parties P ON R.CustomerId = P.Id
LEFT JOIN ReceivableTaxReversalDetails RTRD ON RTD.Id = RTRD.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN Locations L ON RTD.LocationId = L.Id
LEFT JOIN States S ON L.StateId = S.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RecType.Id = DTTFRT.ReceivableTypeId AND S.CountryId = DTTFRT.CountryId
LEFT JOIN Countries countries ON S.CountryId = countries.Id
LEFT JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
LEFT JOIN Assets A ON RTRD.AssetId = A.Id
LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN AssetLocations AL ON RTRD.AssetLocationId = AL.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN Contracts cont ON R.EntityId = cont.Id AND R.EntityType = 'CT'
LEFT JOIN LeaseFinances LF ON Cont.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN LeaseAssets LA ON RTRD.AssetId = LA.AssetId AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL)) AND LA.LeaseFinanceId = LF.Id
LEFT JOIN Sundries sundry ON RT.ReceivableId = sundry.ReceivableId
LEFT JOIN CTE_SundryRecurringDetails SR ON R.Id = SR.ReceivableId
Left JOIN SecurityDeposits SD ON R.Id = SD.ReceivableId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
LEFT JOIN LeaseFinanceDetails LFD ON LFD.ID = LF.Id
LEFT JOIN LoanFinances Loan ON Loan.ContractId = cont.Id AND Loan.IsCurrent = 1;

SELECT 
L.Id,
L.City AS AcquisitionLocationCity,
L.TaxAreaId AS AcquisitionLocationTaxAreaId,
S.ShortName AS AcquisitionLocationMainDivision,
C.ShortName AS AcquisitionLocationCountry
INTO #AssetAcquisitionLocationDetails
FROM #ReceivableInfo RD
JOIN Locations L ON RD.AcquisitionLocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL

;WITH CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM #ReceivableInfo WHERE AssetId IS NOT NULL
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT DISTINCT
lm.*,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt,
AL.AcquisitionLocationTaxAreaId,
AL.AcquisitionLocationCity,
AL.AcquisitionLocationCountry,
AL.AcquisitionLocationMainDivision,
ASN.SerialNumber AS AssetSerialOrVIN
FROM
#ReceivableInfo lm
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON lm.AssetId = ASN.AssetId
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ON rct.TaxExemptRuleId = TaxExemptRules.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id
LEFT JOIN #AssetAcquisitionLocationDetails AL ON AL.Id = lm.AcquisitionLocationId
DROP TABLE #AssetAcquisitionLocationDetails;
END

GO
