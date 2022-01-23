SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetInputForAutoPayoffSalesTaxAssessment]
(
@PayoffReceivableDetails PayoffReceivableDetail READONLY,
@GLTransactionType_SalesTax NVARCHAR(10),
@TaxAssessmentLevel_Customer NVARCHAR(10),
@TaxAssessmentLevel_Asset NVARCHAR(10),
@ReceivableType_Buyout NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

SELECT DISTINCT(LegalEntityId) AS LegalEntityId
INTO #DistinctLegalEntities
FROM @PayoffReceivableDetails;

SELECT
LegalEntityId = DistinctLE.LegalEntityId,
GLTemplateId = MAX(GLT.Id)
INTO #SalesTaxGLTemplateDetails
FROM #DistinctLegalEntities DistinctLE
INNER JOIN LegalEntities LE ON DistinctLE.LegalEntityId = LE.Id
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.[Name] = @GLTransactionType_SalesTax
GROUP BY DistinctLE.LegalEntityId;

SELECT
ReceivableDetailKey = RecInfo.ReceivableDetailKey,
Row_Num =  ROW_NUMBER() OVER (PARTITION BY RecInfo.ReceivableDetailKey
ORDER BY
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) <= 0 THEN AL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) > 0 THEN AL.EffectiveFromDate END ASC,
AL.Id DESC),
LocationId = AL.LocationId,
AssetLocationId = AL.Id,
EffectiveFromDate = AL.EffectiveFromDate,
ReciprocityAmount_Currency = ISNULL(AL.ReciprocityAmount_Currency, RecInfo.Currency),
ReciprocityAmount_Amount = ISNULL(AL.ReciprocityAmount_Amount, CAST(0.00 AS DECIMAL(16,2))),
LienCredit_Currency = ISNULL(AL.LienCredit_Currency, RecInfo.Currency),
LienCredit_Amount = ISNULL(AL.LienCredit_Amount, CAST(0.00 AS DECIMAL(16,2))),
ISNULL(AL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT)) AS UpfrontTaxAssessedInLegacySystem
INTO #AssetBasedReceivables_UnfilteredAssetLocations
FROM @PayoffReceivableDetails RecInfo
JOIN Contracts C ON RecInfo.ContractId = C.Id
JOIN Assets A ON RecInfo.AssetId = A.Id
LEFT JOIN AssetLocations AL ON AL.AssetId = RecInfo.AssetId AND AL.IsActive = 1
WHERE C.TaxAssessmentLevel = @TaxAssessmentLevel_Asset
AND RecInfo.IsLeaseBased = 0;

INSERT INTO #AssetBasedReceivables_UnfilteredAssetLocations
SELECT
ReceivableDetailKey = RecInfo.ReceivableDetailKey,
Row_Num = ROW_NUMBER() OVER (PARTITION BY RecInfo.ReceivableDetailKey
ORDER BY
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  CL.EffectiveFromDate ) <= 0 THEN CL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  CL.EffectiveFromDate ) > 0 THEN CL.EffectiveFromDate END ASC,
CL.Id DESC),
LocationId = CL.LocationId,
AssetLocationId = CL.Id,
EffectiveFromDate = CL.EffectiveFromDate,
ReciprocityAmount_Currency = RecInfo.Currency,
ReciprocityAmount_Amount = 0,
LienCredit_Currency = RecInfo.Currency,
LienCredit_Amount = 0,
ISNULL(CCL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT)) AS UpfrontTaxAssessedInLegacySystem
FROM @PayoffReceivableDetails RecInfo
JOIN Contracts C ON RecInfo.ContractId = C.Id
LEFT JOIN CustomerLocations CL ON RecInfo.CustomerId = CL.CustomerId AND CL.IsActive = 1
LEFT JOIN ContractCustomerLocations CCL ON CL.Id = CCL.CustomerLocationId AND C.Id = CCL.ContractId AND CCL.UpfrontTaxAssessedInLegacySystem = 1
WHERE C.TaxAssessmentLevel = @TaxAssessmentLevel_Customer
AND RecInfo.IsLeaseBased = 0;

SELECT
ReceivableDetailKey,
LocationId,
AssetLocationId,
EffectiveFromDate,
ReciprocityAmount_Currency,
ReciprocityAmount_Amount,
LienCredit_Currency,
LienCredit_Amount,
Loc.Code,
StateId = States.Id,
StateShortName = States.ShortName,
CountryId = Countries.Id,
CountryShortName = Countries.ShortName,
City = Loc.City,
LocationStatus = Loc.ApprovalStatus,
IsLocationActive = Loc.IsActive,
CAST(CASE WHEN Countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported,
Loc.UpfrontTaxMode,
JurisdictionId = ISNULL(Loc.JurisdictionId, CAST(0 AS BIGINT)),
Loc.TaxExemptRuleId,
UL.UpfrontTaxAssessedInLegacySystem
INTO #AssetBasedReceivables_LocationDetails
FROM #AssetBasedReceivables_UnfilteredAssetLocations UL
JOIN Locations Loc ON UL.LocationId = Loc.Id
JOIN States ON Loc.StateId = States.Id
JOIN Countries ON States.CountryId = Countries.Id
WHERE UL.Row_Num = 1;

SELECT
ReceivableDetailKey = RecInfo.ReceivableDetailKey,
Row_Num = ROW_NUMBER() OVER (PARTITION BY RecInfo.ReceivableDetailKey
ORDER BY
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, TAH.TaxAreaEffectiveDate) <= 0 THEN TAH.TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, TAH.TaxAreaEffectiveDate) > 0 THEN TAH.TaxAreaEffectiveDate END ASC),
TAH.TaxAreaEffectiveDate,
TAH.TaxAreaId,
LD.UpfrontTaxAssessedInLegacySystem
INTO #AssetBasedReceivables_UnfilteredTaxAreaDetails
FROM #AssetBasedReceivables_LocationDetails LD
JOIN @PayoffReceivableDetails RecInfo ON LD.ReceivableDetailKey = RecInfo.ReceivableDetailKey
LEFT JOIN LocationTaxAreaHistories TAH ON LD.LocationId = TAH.LocationId;

SELECT
ReceivableDetailKey,
TaxAreaEffectiveDate,
TaxAreaId,
UpfrontTaxAssessedInLegacySystem
INTO #AssetBasedReceivables_TaxAreaDetails
FROM #AssetBasedReceivables_UnfilteredTaxAreaDetails
WHERE Row_Num = 1;

SELECT
UL.ReceivableDetailKey,
StateShortName = S.ShortName
INTO #AssetBasedReceivables_FromStateInfo
FROM #AssetBasedReceivables_UnfilteredAssetLocations UL
JOIN Locations L ON UL.LocationId = L.Id
JOIN States S ON L.StateId = S.Id
WHERE Row_Num = 2;

-- #ReceivablesInfo
SELECT
LineItemNumber = RecInfo.ReceivableDetailKey,
ReceivableDetailId = RecInfo.ReceivableDetailKey,
ReceivableId = RecInfo.ReceivableKey,
DueDate = RecInfo.DueDate,
IsRental = RT.IsRental,
Product = ACC.ClassCode,
FairMarketValue = 0.00,
Cost = 0.00,
AmountBilledToDate = 0.00,
ExtendedPrice = RecInfo.Amount,
Currency = RecInfo.Currency,
IsAssetBased = CONVERT(BIT, CASE WHEN RecInfo.IsLeaseBased = 1 THEN 0 ELSE 1 END),
IsLeaseBased = RecInfo.IsLeaseBased,
IsExemptAtAsset = A.IsTaxExempt,
TransactionType = CAST(CASE WHEN RT.[Name] = @ReceivableType_Buyout THEN 'SALE' ELSE 'LEASE' END AS NVARCHAR(5)),
Company = LE.TaxPayer,
CustomerCode = P.PartyNumber,
CustomerId = Cust.Id,
ClassCode = CC.Class,
AssetTypeId = A.TypeId,
TaxAreaId = TaxArea.TaxAreaId,
TaxAreaEffectiveDate = TaxArea.TaxAreaEffectiveDate,
ContractId = RecInfo.ContractId,
RentAccrualStartDate = NULL,
MaturityDate = LFD.MaturityDate,
CustomerCost = LA.CustomerCost_Amount,
IsExemptAtLease = LF.IsSalesTaxExempt,
LessorRisk = (LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount),
IsExemptAtSundry = CONVERT(BIT,0),
ReceivableTaxId = CAST(NULL AS BIGINT),
ContractType = CAST(CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END AS NVARCHAR(3)),
LeaseUniqueId = cont.SequenceNumber,
SundryReceivableCode = CAST(CASE WHEN (RT.IsRental = 1) THEN '' ELSE RC.[Name] END AS  NVARCHAR(40)),
AssetType = ACC.ClassCode,
LeaseType = DPT.LeaseType,
LeaseTerm = ISNULL(CAST((DATEDIFF(DAY,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00),
TitleTransferCode = CAST(NULL AS NVARCHAR(40)),
ReceivableType = RT.[Name],
LegalEntityId = LE.Id,
Id = 0,
IsManuallyAssessed = CAST(0 AS BIT),
TransactionCode = '_',
TaxBasisType = '_',
IsMultiComponent = A.IsParent,
GlTemplateId = STGL.GLTemplateId,
IsExemptAtReceivableCode = RC.IsTaxExempt,
ContractTypeValue = cont.ContractType,
ReceivableTypeId = RC.ReceivableTypeId,
ReceivableCodeId = RC.Id,
BusCode = CAST('' AS NVARCHAR(40)),
Usage = AU.Usage,
SalesTaxRemittanceResponsibility = CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= RecInfo.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE LA.SalesTaxRemittanceResponsibility END,
AcquisitionLocationId = CAST(LA.AcquisitionLocationId AS BIGINT),
UpfrontTaxAssessedInLegacySystem = TaxArea.UpfrontTaxAssessedInLegacySystem
INTO #ReceivablesInfo
FROM
@PayoffReceivableDetails RecInfo
JOIN #AssetBasedReceivables_TaxAreaDetails TaxArea ON RecInfo.ReceivableDetailKey = TaxArea.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND RecInfo.AssetId = LA.AssetId AND (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL)
JOIN Assets A ON RecInfo.AssetId = A.Id
JOIN AssetTypes AT ON A.TypeId = AT.Id
JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
JOIN LegalEntities LE ON RecInfo.LegalEntityId = LE.Id
JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
JOIN Customers Cust ON RecInfo.CustomerId = Cust.Id
JOIN Parties P ON Cust.Id = P.Id
LEFT JOIN CustomerClasses CC ON Cust.CustomerClassId = CC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN #SalesTaxGLTemplateDetails STGL ON RecInfo.LegalEntityId = STGL.LegalEntityId
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = A.Id AND LF.ContractId = STRH.ContractId
LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id
WHERE RecInfo.IsLeaseBased = 0;

-- #ExemptedInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
CountryTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCountryTaxExempt,AssetRule.IsCountryTaxExempt,LeaseRule.IsCountryTaxExempt,LocationRule.IsCountryTaxExempt) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
StateTaxExempt =  CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsStateTaxExempt,AssetRule.IsStateTaxExempt,LeaseRule.IsStateTaxExempt,LocationRule.IsStateTaxExempt) THEN  CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CityTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCityTaxExempt,AssetRule.IsCityTaxExempt,LeaseRule.IsCityTaxExempt,LocationRule.IsCityTaxExempt) THEN  CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CountyTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCountyTaxExempt,AssetRule.IsCountyTaxExempt,LeaseRule.IsCountyTaxExempt,LocationRule.IsCountyTaxExempt) THEN  CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CountryTaxExemptAtContract = ISNULL(LeaseRule.IsCountryTaxExempt, CAST(0 AS BIT)),
StateTaxExemptAtContract = ISNULL(LeaseRule.IsStateTaxExempt, CAST(0 AS BIT)),
CityTaxExemptAtContract = ISNULL(LeaseRule.IsCityTaxExempt, CAST(0 AS BIT)),
CountyTaxExemptAtContract = ISNULL(LeaseRule.IsCountyTaxExempt, CAST(0 AS BIT)),
CountryTaxExemptRule = CASE  WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN AssetRule.IsCountryTaxExempt = 1 THEN 'AssetTaxExemptRule'
WHEN LocationRule.IsCountryTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
StateTaxExemptRule = CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN AssetRule.IsStateTaxExempt = 1 THEN 'AssetTaxExemptRule'
WHEN LocationRule.IsStateTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
CityTaxExemptRule = CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN AssetRule.IsCityTaxExempt = 1 THEN 'AssetTaxExemptRule'
WHEN LocationRule.IsCityTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
CountyTaxExemptRule = CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN AssetRule.IsCountyTaxExempt = 1 THEN 'AssetTaxExemptRule'
WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END
INTO #ExemptedInfo
FROM
@PayoffReceivableDetails RecInfo
JOIN #AssetBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN Assets A ON RecInfo.AssetId = A.Id
LEFT JOIN ReceivableCodeTaxExemptRules rct ON RecInfo.ReceivableCodeId = rct.ReceivableCodeId AND Loc.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN TaxExemptRules AssetRule ON A.TaxExemptRuleId = AssetRule.Id
LEFT JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN TaxExemptRules LocationRule ON Loc.TaxExemptRuleId = LocationRule.Id
WHERE RecInfo.IsLeaseBased = 0;

-- #UserDefinedFlexInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
--User Defined Flex Fields
SaleLeasebackCode = '',
IsElectronicallyDelivered = A.IsElectronicallyDelivered,
TaxRemittanceType = REPLACE(cont.SalesTaxRemittanceMethod, 'Based',''),
ToState = Loc.StateShortName,
FromState = FromState.StateShortName,
GrossVehicleWeight = A.GrossVehicleWeight,
LienCredit_Amount = Loc.LienCredit_Amount,
LienCredit_Currency = Loc.LienCredit_Currency,
ReciprocityAmount_Amount = Loc.ReciprocityAmount_Amount,
ReciprocityAmount_Currency = Loc.ReciprocityAmount_Currency,
AssetId = RecInfo.AssetId,
EngineType = CAST(NULL AS NVARCHAR),
HorsePower = CAST(0.00 as DECIMAL(16,2)),
SalesTaxExemptionLevel = STEL.[Name],
TaxAssessmentLevel = cont.TaxAssessmentLevel,
TaxTypeId = DefaultTaxType.TaxTypeId,
StateTaxTypeId = LA.StateTaxTypeId,
CountyTaxTypeId = LA.CountyTaxTypeId,
CityTaxTypeId = LA.CityTaxTypeId,
StateId = Loc.StateId,
UpfrontTaxMode = ISNULL(Loc.UpfrontTaxMode,'_'),
TaxRegistrationNumber = ISNULL(P.VATRegistrationNumber, NULL),
ISOCountryCode = ISNULL(IncorporationCountry.ShortName, NULL)
INTO #UserDefinedFlexInfo
FROM
@PayoffReceivableDetails RecInfo
JOIN #AssetBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey
JOIN #AssetBasedReceivables_TaxAreaDetails TaxArea ON RecInfo.ReceivableDetailKey = TaxArea.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND RecInfo.AssetId = LA.AssetId AND (LA.IsActive = 1 OR LA.TerminationDate IS NOT NULL)
JOIN Assets A ON RecInfo.AssetId = A.Id
JOIN AssetTypes AT ON A.TypeId = AT.Id
JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN Customers Cust ON RecInfo.CustomerId = Cust.Id
JOIN Parties P ON Cust.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN DefaultTaxTypeForReceivableTypes DefaultTaxType ON RT.Id = DefaultTaxType.ReceivableTypeId AND Loc.CountryId = DefaultTaxType.CountryId
LEFT JOIN #AssetBasedReceivables_FromStateInfo FromState ON RecInfo.ReceivableDetailKey = FromState.ReceivableDetailKey
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STEL ON A.SalesTaxExemptionLevelId = STEL.Id
WHERE RecInfo.IsLeaseBased = 0;

-- #LocationInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
LocationCode = Loc.Code,
LocationId = Loc.LocationId,
MainDivision = Loc.StateShortName,
Country = Loc.CountryShortName,
City = Loc.City,
IsLocationActive = Loc.IsLocationActive,
AssetLocationId = Loc.AssetLocationId,
LocationStatus = Loc.LocationStatus,
IsVertexSupportedLocation = Loc.IsVertexSupported,
LocationEffectiveDate = Loc.EffectiveFromDate,
TaxJurisdictionId = Loc.JurisdictionId
INTO #LocationInfo
FROM
@PayoffReceivableDetails RecInfo
JOIN #AssetBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey

SELECT
ReceivableDetailKey,
LocationId,
Loc.Code,
StateId = States.Id,
StateShortName = States.ShortName,
CountryId = Countries.Id,
CountryShortName = Countries.ShortName,
City = Loc.City,
LocationStatus = Loc.ApprovalStatus,
IsLocationActive = Loc.IsActive,
CAST(CASE WHEN Countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported,
Loc.UpfrontTaxMode,
JurisdictionId = ISNULL(Loc.JurisdictionId, CAST(0 AS BIGINT)),
Loc.TaxExemptRuleId
INTO #LeaseBasedReceivables_LocationDetails
FROM @PayoffReceivableDetails PRD
JOIN Locations Loc ON PRD.LocationId = Loc.Id
JOIN States ON Loc.StateId = States.Id
JOIN Countries ON States.CountryId = Countries.Id
WHERE PRD.IsLeaseBased = 1;

SELECT
RecInfo.ReceivableDetailKey,
Row_Num = ROW_NUMBER() OVER (PARTITION BY RecInfo.ReceivableDetailKey
ORDER BY
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, TAH.TaxAreaEffectiveDate) <= 0 THEN TAH.TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, TAH.TaxAreaEffectiveDate) > 0 THEN TAH.TaxAreaEffectiveDate END ASC),
TAH.TaxAreaEffectiveDate,
TAH.TaxAreaId
INTO #LeaseBasedReceivables_UnfilteredTaxAreaDetails
FROM #LeaseBasedReceivables_LocationDetails Loc
JOIN @PayoffReceivableDetails RecInfo ON Loc.ReceivableDetailKey = RecInfo.ReceivableDetailKey
LEFT JOIN LocationTaxAreaHistories TAH ON Loc.LocationId = TAH.LocationId

SELECT
ReceivableDetailKey,
TaxAreaEffectiveDate,
TaxAreaId
INTO #LeaseBasedReceivables_TaxAreaDetails
FROM #LeaseBasedReceivables_UnfilteredTaxAreaDetails
WHERE Row_Num = 1;

INSERT INTO #ReceivablesInfo
SELECT
LineItemNumber = RecInfo.ReceivableDetailKey,
ReceivableDetailId = RecInfo.ReceivableDetailKey,
ReceivableId = RecInfo.ReceivableKey,
DueDate = RecInfo.DueDate,
IsRental = RT.IsRental,
Product = RT.[Name],
FairMarketValue = 0.00,
Cost = 0.00,
AmountBilledToDate = 0.00,
ExtendedPrice = RecInfo.Amount,
Currency = RecInfo.Currency,
IsAssetBased = CONVERT(BIT, CASE WHEN RecInfo.IsLeaseBased = 1 THEN 0 ELSE 1 END),
IsLeaseBased = RecInfo.IsLeaseBased,
IsExemptAtAsset = CONVERT(BIT,0),
TransactionType = 'LEASE',
Company = LE.TaxPayer,
CustomerCode = P.PartyNumber,
CustomerId = Cust.Id,
ClassCode = CC.Class,
AssetTypeId = 0,
TaxAreaId = TaxArea.TaxAreaId,
TaxAreaEffectiveDate = TaxArea.TaxAreaEffectiveDate,
ContractId = RecInfo.ContractId,
RentAccrualStartDate = NULL,
MaturityDate = LFD.MaturityDate,
CustomerCost = 0.00,
IsExemptAtLease = LF.IsSalesTaxExempt,
LessorRisk = (LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount),
IsExemptAtSundry = CAST(0 AS BIT),
ReceivableTaxId = NULL,
ContractType = CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END,
LeaseUniqueId = cont.SequenceNumber,
SundryReceivableCode = CASE WHEN (RT.IsRental = 1) THEN '' ELSE RC.[Name] END,
AssetType = '',
LeaseType = DPT.LeaseType,
LeaseTerm = ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00),
TitleTransferCode = CAST(NULL AS NVARCHAR(40)),
ReceivableType = RT.[Name],
LegalEntityId = LE.Id,
Id = 0,
IsManuallyAssessed = CAST(0 AS BIT),
TransactionCode = '_',
TaxBasisType = '_',
IsMultiComponent = CAST(0 AS BIT),
GlTemplateId = STGL.GLTemplateId,
IsExemptAtReceivableCode = RC.IsTaxExempt,
ContractTypeValue = cont.ContractType,
ReceivableTypeId = RC.ReceivableTypeId,
ReceivableCodeId = RC.Id,
BusCode = CAST('' AS NVARCHAR(40)),
Usage = CAST(NULL AS NVARCHAR(40)),
SalesTaxRemittanceResponsibility = CAST('_' AS NVARCHAR(8)),
AcquisitionLocationId = CAST(NULL AS BIGINT),
UpfrontTaxAssessedInLegacySystem = CAST(0 AS BIT)
FROM @PayoffReceivableDetails RecInfo
JOIN #LeaseBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey
JOIN #LeaseBasedReceivables_TaxAreaDetails TaxArea ON RecInfo.ReceivableDetailKey = TaxArea.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN LegalEntities LE ON RecInfo.LegalEntityId = LE.Id
JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Customers Cust ON RecInfo.CustomerId = Cust.Id
JOIN Parties P ON Cust.Id = P.Id
LEFT JOIN CustomerClasses CC ON Cust.CustomerClassId = CC.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DefaultTaxType ON RT.Id = DefaultTaxType.ReceivableTypeId AND Loc.CountryId = DefaultTaxType.CountryId
LEFT JOIN #SalesTaxGLTemplateDetails STGL ON RecInfo.LegalEntityId = STGL.LegalEntityId
WHERE RecInfo.IsLeaseBased = 1;

INSERT INTO #ExemptedInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
CountryTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCountryTaxExempt,LeaseRule.IsCountryTaxExempt,LocationRule.IsCountryTaxExempt) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
StateTaxExempt =  CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsStateTaxExempt,LeaseRule.IsStateTaxExempt,LocationRule.IsStateTaxExempt) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CityTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCityTaxExempt,LeaseRule.IsCityTaxExempt,LocationRule.IsCityTaxExempt) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CountyTaxExempt = CASE WHEN CAST(1 AS BIT) IN (ReceivableCodeRule.IsCountyTaxExempt,LeaseRule.IsCountyTaxExempt,LocationRule.IsCountyTaxExempt) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
CountryTaxExemptAtContract = ISNULL(LeaseRule.IsCountryTaxExempt, CAST(0 AS BIT)),
StateTaxExemptAtContract = ISNULL(LeaseRule.IsStateTaxExempt, CAST(0 AS BIT)),
CityTaxExemptAtContract = ISNULL(LeaseRule.IsCityTaxExempt, CAST(0 AS BIT)),
CountyTaxExemptAtContract = ISNULL(LeaseRule.IsCountyTaxExempt, CAST(0 AS BIT)),
CountryTaxExemptRule = CASE  WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN LocationRule.IsCountryTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
StateTaxExemptRule = CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN LocationRule.IsStateTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
CityTaxExemptRule = CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN LocationRule.IsCityTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END,
CountyTaxExemptRule = CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END
FROM @PayoffReceivableDetails RecInfo
JOIN #LeaseBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN ReceivableCodeTaxExemptRules rct ON RecInfo.ReceivableCodeId = rct.ReceivableCodeId AND Loc.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN TaxExemptRules LocationRule ON Loc.TaxExemptRuleId = LocationRule.Id
WHERE RecInfo.IsLeaseBased = 1;

INSERT INTO #UserDefinedFlexInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
--User Defined Flex Fields
SaleLeasebackCode = '',
IsElectronicallyDelivered = CAST(0 AS BIT),
TaxRemittanceType = REPLACE(cont.SalesTaxRemittanceMethod, 'Based',''),
ToState = Loc.StateShortName,
FromState = Loc.StateShortName,
GrossVehicleWeight = 0,
LienCredit_Amount = 0.00,
LienCredit_Currency = RecInfo.Currency,
ReciprocityAmount_Amount = 0.00,
ReciprocityAmount_Currency = RecInfo.Currency,
AssetId = NULL,
EngineType = CAST(NULL AS NVARCHAR),
HorsePower = CAST(0.00 as DECIMAL(16,2)),
SalesTaxExemptionLevel = '',
TaxAssessmentLevel = cont.TaxAssessmentLevel,
TaxTypeId = DefaultTaxType.TaxTypeId,
StateTaxTypeId = NULL,
CountyTaxTypeId = NULL,
CityTaxTypeId = NULL,
StateId = Loc.StateId,
UpfrontTaxMode = ISNULL(Loc.UpfrontTaxMode,'_'),
TaxRegistrationNumber = ISNULL(P.VATRegistrationNumber, NULL),
ISOCountryCode = ISNULL(IncorporationCountry.ShortName, NULL)
FROM @PayoffReceivableDetails RecInfo
JOIN #LeaseBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey
JOIN Contracts cont ON RecInfo.ContractId = cont.Id
JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN Customers Cust ON RecInfo.CustomerId = Cust.Id
JOIN Parties P ON Cust.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DefaultTaxType ON RT.Id = DefaultTaxType.ReceivableTypeId AND Loc.CountryId = DefaultTaxType.CountryId
WHERE RecInfo.IsLeaseBased = 1;

INSERT INTO #LocationInfo
SELECT
ReceivableDetailId = RecInfo.ReceivableDetailKey,
LocationCode = Loc.Code,
LocationId = Loc.LocationId,
MainDivision = Loc.StateShortName,
Country = Loc.CountryShortName,
City = Loc.City,
IsLocationActive = Loc.IsLocationActive,
AssetLocationId = NULL,
LocationStatus = Loc.LocationStatus,
IsVertexSupportedLocation = Loc.IsVertexSupported,
LocationEffectiveDate = NULL,
TaxJurisdictionId = Loc.JurisdictionId
FROM @PayoffReceivableDetails RecInfo
JOIN #LeaseBasedReceivables_LocationDetails Loc ON RecInfo.ReceivableDetailKey = Loc.ReceivableDetailKey

UPDATE RecInfo SET RecInfo.BusCode = GLOrgStructureConfigs.BusinessCode
FROM #ReceivablesInfo RecInfo
JOIN Contracts ON Contracts.Id = RecInfo.ContractId
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id AND LeaseFinances.IsCurrent = 1
JOIN GLOrgStructureConfigs ON GLOrgStructureConfigs.LegalEntityId = RecInfo.LegalEntityId
AND GLOrgStructureConfigs.CurrencyId = Contracts.CurrencyId
AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = LeaseFinances.LineofBusinessId;

SELECT
RecInfo.ReceivableDetailId,
AcquisitionLocationTaxAreaId = L.TaxAreaId,
AcquisitionLocationCity = L.City,
AcquisitionLocationMainDivision = S.ShortName,
AcquisitionLocationCountry = C.ShortName
INTO #AcquisitionLocationDetails
FROM #ReceivablesInfo RecInfo
JOIN Locations L ON RecInfo.AcquisitionLocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL;
/* Result Set*/
SELECT
RecInfo.LineItemNumber, RecInfo.ReceivableDetailId, RecInfo.ReceivableId, RecInfo.DueDate, RecInfo.IsRental, RecInfo.Product,
RecInfo.FairMarketValue, RecInfo.Cost, RecInfo.AmountBilledToDate, RecInfo.ExtendedPrice,  RecInfo.Currency, RecInfo.IsAssetBased,
RecInfo.IsLeaseBased, RecInfo.IsExemptAtAsset,RecInfo.TransactionType,RecInfo.Company, RecInfo.CustomerCode,RecInfo.CustomerId,
RecInfo.ClassCode, RecInfo.AssetTypeId,LocationInfo.LocationCode,LocationInfo.LocationId,LocationInfo.MainDivision,
LocationInfo.City, LocationInfo.Country,RecInfo.TaxAreaEffectiveDate, RecInfo.TaxAreaId,LocationInfo.IsLocationActive,RecInfo.ContractId,
RecInfo.RentAccrualStartDate,RecInfo.MaturityDate, RecInfo.CustomerCost,RecInfo.IsExemptAtLease,RecInfo.LessorRisk,	LocationInfo.AssetLocationId, 
LocationInfo.LocationStatus,RecInfo.IsExemptAtSundry,RecInfo.ReceivableTaxId, LocationInfo.IsVertexSupportedLocation, RecInfo.ContractType,
RecInfo.LeaseUniqueId, RecInfo.SundryReceivableCode,RecInfo.AssetType,RecInfo.LeaseType,RecInfo.LeaseTerm,RecInfo.TitleTransferCode,
LocationInfo.LocationEffectiveDate,RecInfo.ReceivableType, RecInfo.LegalEntityId, RecInfo.Id,RecInfo.IsManuallyAssessed,RecInfo.TransactionCode,
RecInfo.TaxBasisType, RecInfo.IsMultiComponent, RecInfo.GlTemplateId,RecInfo.IsExemptAtReceivableCode, RecInfo.ContractTypeValue, 
LocationInfo.TaxJurisdictionId, RecInfo.ReceivableTypeId, RecInfo.ReceivableCodeId,RecInfo.BusCode,RecInfo.Usage,RecInfo.SalesTaxRemittanceResponsibility,
RecInfo.AcquisitionLocationId, ExemptedInfo.CountryTaxExempt, ExemptedInfo.StateTaxExempt,ExemptedInfo.CityTaxExempt,ExemptedInfo.CountyTaxExempt,
 ExemptedInfo.CountryTaxExemptAtContract, ExemptedInfo.StateTaxExemptAtContract,ExemptedInfo.CityTaxExemptAtContract,ExemptedInfo.CountyTaxExemptAtContract,
 ExemptedInfo.CountryTaxExemptRule,ExemptedInfo.StateTaxExemptRule,ExemptedInfo.CityTaxExemptRule,ExemptedInfo.CountyTaxExemptRule,
 UserDefinedFlexInfo.SaleLeasebackCode,UserDefinedFlexInfo.IsElectronicallyDelivered,UserDefinedFlexInfo.TaxRemittanceType,
 UserDefinedFlexInfo.ToState,UserDefinedFlexInfo.FromState,UserDefinedFlexInfo.GrossVehicleWeight,UserDefinedFlexInfo.LienCredit_Amount,UserDefinedFlexInfo.LienCredit_Currency,
 UserDefinedFlexInfo.ReciprocityAmount_Amount,UserDefinedFlexInfo.ReciprocityAmount_Currency,UserDefinedFlexInfo.AssetId,UserDefinedFlexInfo.EngineType, 
 UserDefinedFlexInfo.HorsePower,  UserDefinedFlexInfo.SalesTaxExemptionLevel,UserDefinedFlexInfo.TaxAssessmentLevel,UserDefinedFlexInfo.TaxTypeId,
 UserDefinedFlexInfo.StateTaxTypeId,UserDefinedFlexInfo.CountyTaxTypeId,UserDefinedFlexInfo.CityTaxTypeId,UserDefinedFlexInfo.StateId, 
  UserDefinedFlexInfo.UpfrontTaxMode,UserDefinedFlexInfo.TaxRegistrationNumber,   UserDefinedFlexInfo.ISOCountryCode,
AcquisitionLocationTaxAreaId,
AcquisitionLocationCity,
AcquisitionLocationMainDivision,
AcquisitionLocationCountry,
RecInfo.UpfrontTaxAssessedInLegacySystem
FROM #ReceivablesInfo RecInfo
JOIN #ExemptedInfo ExemptedInfo ON RecInfo.ReceivableDetailId = ExemptedInfo.ReceivableDetailId
JOIN #UserDefinedFlexInfo UserDefinedFlexInfo ON ExemptedInfo.ReceivableDetailId = UserDefinedFlexInfo.ReceivableDetailId
JOIN #LocationInfo LocationInfo ON UserDefinedFlexInfo.ReceivableDetailId = LocationInfo.ReceivableDetailId
LEFT JOIN #AcquisitionLocationDetails AL ON RecInfo.ReceivableDetailId = AL.ReceivableDetailId
DROP TABLE #DistinctLegalEntities;
DROP TABLE #SalesTaxGLTemplateDetails;
DROP TABLE #AssetBasedReceivables_UnfilteredAssetLocations;
DROP TABLE #AssetBasedReceivables_LocationDetails;
DROP TABLE #AssetBasedReceivables_UnfilteredTaxAreaDetails;
DROP TABLE #AssetBasedReceivables_TaxAreaDetails;
DROP TABLE #AssetBasedReceivables_FromStateInfo;
DROP TABLE #LeaseBasedReceivables_LocationDetails;
DROP TABLE #LeaseBasedReceivables_UnfilteredTaxAreaDetails;
DROP TABLE #LeaseBasedReceivables_TaxAreaDetails;
DROP TABLE #ReceivablesInfo;
DROP TABLE #AcquisitionLocationDetails;
DROP TABLE #ExemptedInfo
DROP TABLE #UserDefinedFlexInfo
DROP TABLE #LocationInfo
END

GO
