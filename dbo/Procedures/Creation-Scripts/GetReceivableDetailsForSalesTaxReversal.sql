SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetReceivableDetailsForSalesTaxReversal]
(
@CustomerId BIGINT,
@LegalEntityIds NVARCHAR(MAX) = NULL,
@ContractId BIGINT = null,
@SundryId BIGINT = null,
@DiscountingId BIGINT = null,
@SundryRecurringId BIGINT = null,
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET = null
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

WITH CTE_SundryRecurringDetails as
(
SELECT DISTINCT
RD.ReceivableId
,SundryRecurrings.IsTaxExempt
,SundryRecurrings.IsAssetBased
FROM
ReceivableDetails RD
JOIN Receivables R ON RD.ReceivableId = R.Id
JOIN SundryRecurringPaymentSchedules  AS SRPS  ON RD.ReceivableId = SRPS.ReceivableId
JOIN SundryRecurrings ON SundryRecurrings.Id = SRPS.SundryRecurringId
AND SundryRecurrings.IsActive = 1
AND ((SundryRecurrings.LocationId IS NOT NULL) OR (SundryRecurrings.LocationId IS NULL AND SundryRecurrings.IsAssetBased = 0))
WHERE R.SourceTable <> 'LateFee' AND R.IsActive = 1
AND R.DueDate >= @FromDate
AND (@ContractId IS NULL OR (R.EntityId = @ContractId AND R.EntityType = 'CT')
OR (R.EntityId = @DiscountingId AND R.EntityType = 'DT'))
AND (@ToDate IS NULL OR R.DueDate <= @ToDate)
AND R.IsActive = 1 AND RD.IsActive = 1
AND RD.IsTaxAssessed = 1
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
RTD.Cost_Amount AS Cost,
RTD.Revenue_Amount AS ExtendedPrice,
RTD.FairMarketValue_Amount AS FairMarketValue,
RTRD.AmountBilledToDate,
RTD.TaxBasisType AS TaxBasisType,
cont.SequenceNumber AS LeaseUniqueId,
RC.Name AS SundryReceivableCode,
CASE WHEN (RecType.Name = 'BuyOut' OR RecType.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS TransactionType
,LE.Id 'LegalEntityId'
,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupportedLocation
,CASE WHEN RD.BilledStatus = 'Invoiced' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsInvoiced
,CASE WHEN (RT.Balance_Amount != RT.Amount_Amount) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsCashPosted
,CASE WHEN cont.ContractType = 'Lease' THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsLeaseBased
,CASE WHEN sundry.IsAssetBased IS NOT NULL
THEN sundry.IsAssetBased
ELSE (CASE WHEN SR.IsAssetBased IS NOT NULL THEN SR.IsAssetBased ELSE (CASE WHEN SD.Id IS NOT NULL THEN CONVERT (BIT,0) ELSE ((CASE WHEN RecType.IsRental = 1 THEN CONVERT (BIT,1) ELSE CONVERT (BIT,0) END))END)
END) END AS IsAssetBased
,RTRD.AssetLocationId
,ISNULL(A.IsParent,CONVERT(BIT,0)) IsMultiComponent
,CAST(NULL AS DATE) AS CommencementDate
,RecType.Name ReceivableType
,RC.IsTaxExempt IsExemptAtReceivableCode
,cont.ContractType ContractTypeValue
,RecType.IsRental AS IsRental
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
RTD.AssetId 'AssetId'
,CAST(NULL AS NVARCHAR) AS EngineType
,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel
,ISNULL(LA.IsPrepaidUpfrontTax,CAST(0 AS BIT)) IsPrepaidUpfrontTax
,cont.TaxAssessmentLevel
,DTTFRT.TaxTypeId
,LA.StateTaxTypeId
,LA.CountyTaxTypeId
,LA.CityTaxTypeId
,LF.ContractId
,S.Id StateId
,R.ReceivableCodeId
,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
,RTD.LocationId INTO #RecInfo
FROM
ReceivableTaxes RT
INNER JOIN ReceivableTaxDetails RTD ON RT.Id = RTD.ReceivableTaxId
INNER JOIN Receivables R ON RT.ReceivableId = R.Id
INNER JOIN ReceivableDetails RD ON RTD.ReceivableDetailId = RD.Id
INNER JOIN ReceivableTaxReversalDetails RTRD ON RTD.Id = RTRD.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RecType ON RC.ReceivableTypeId = RecType.Id
INNER JOIN Customers C ON R.CustomerId = C.Id
INNER JOIN Parties P ON R.CustomerId = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN Locations L ON RTD.LocationId = L.Id
LEFT JOIN States S ON L.StateId = S.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RecType.Id = DTTFRT.ReceivableTypeId AND S.CountryId = DTTFRT.CountryId
LEFT JOIN Countries countries ON S.CountryId = countries.Id
LEFT JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
LEFT JOIN Assets A ON RTRD.AssetId = A.Id
LEFT JOIN AssetLocations AL ON RTRD.AssetLocationId = AL.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN Contracts cont ON R.EntityId = cont.Id AND R.EntityType = 'CT'
LEFT JOIN LeaseFinances LF ON Cont.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN LeaseAssets LA ON RTRD.AssetId = LA.AssetId AND LA.IsActive = 1 AND LA.LeaseFinanceId = LF.Id
LEFT JOIN Discountings disc ON R.EntityId = disc.Id AND R.EntityType = 'DT'
LEFT JOIN DiscountingFinances discFin ON disc.Id = discFin.DiscountingId AND discFin.IsCurrent = 1 AND discFin.ApprovalStatus = 'Approved'
LEFT JOIN Sundries sundry ON RT.ReceivableId = sundry.ReceivableId
LEFT JOIN SundryRecurringPaymentSchedules SRPS ON RT.ReceivableId = SRPS.ReceivableId
LEFT JOIN CTE_SundryRecurringDetails SR ON R.Id = SR.ReceivableId
LEFT JOIN SecurityDeposits SD ON R.Id = SD.ReceivableId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
WHERE @CustomerId = C.Id
AND (@LegalEntityIds IS NULL OR LE.ID IN (SELECT ID FROM dbo.ConvertCSVToBigIntTable(@LegalEntityIds,',') ccbit))
AND R.DueDate >= @FromDate
AND (@ContractId IS NULL OR cont.Id = @ContractId)
AND (@DiscountingId IS NULL OR disc.Id = @DiscountingId)
AND (@SundryId IS NULL OR sundry.Id = @SundryId)
AND (@SundryRecurringId IS NULL OR SRPS.SundryRecurringId = @SundryRecurringId)
AND (@ToDate IS NULL OR R.DueDate <= @ToDate)
AND R.IsActive = 1 AND RD.IsActive = 1 AND RTD.IsActive = 1
AND RD.IsTaxAssessed = 1;
SELECT DISTINCT
lm.*,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CountryTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) StateTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CityTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT) CountyTaxExempt
FROM
#RecInfo lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ON rct.TaxExemptRuleId = TaxExemptRules.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
END

GO
