SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[GetReceivableDetailsForPayoffReversalSalesTaxAssessment]
(
@PayoffId BIGINT,
@IsRepossessionPayoff BIT,
@PayoffReceivableSourceTable NVARCHAR(20),
@SundryReceivableTypeName NVARCHAR(20) = NULL,
@PropertyTaxReceivableTypeName NVARCHAR(20) = NULL,
@ReceivableIds NVARCHAR(Max) = NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

SELECT ID INTO #ReceivableIds FROM ConvertCSVToBigIntTable(@ReceivableIds, ',')
DECLARE @AssetLevelReceivableDetails TABLE
(
EffectiveFromDate  DATETIME,
DueDate            DATETIME,
LocationId         BIGINT,
AssetId            BIGINT,
ReceivableDetailId BIGINT PRIMARY KEY,
AssetLocationId    BIGINT,
SaleLeasebackCode	   NVARCHAR(40),
IsElectronicallyDelivered BIT,
ReciprocityAmount_Amount DECIMAL,
ReciprocityAmount_Currency NVARCHAR(20),
LienCredit_Amount DECIMAL,
LienCredit_Currency	NVARCHAR(20),
GrossVehicleWeight INT,
IsMultiComponent BIT,
UpfrontTaxAssessedInLegacySystem BIT,
TaxBasisType NVARCHAR(10)
)
CREATE TABLE #TE_LeaseAssetLocations_Asset
(
Row_Num INT,
EffectiveFromDate DATE,
DueDate DATE,
LocationId BIGINT,
AssetId BIGINT,
ReceivableDetailId BIGINT,
AssetLocationId BIGINT,
SaleLeasebackCode NVARCHAR(100),
IsElectronicallyDelivered BIT,
ReciprocityAmount_Amount DECIMAL,
ReciprocityAmount_Currency NVARCHAR(10),
LienCredit_Amount DECIMAL,
LienCredit_Currency NVARCHAR(10),
GrossVehicleWeight INT,
IsMultiComponent BIT,
TaxAssessmentLevel NVARCHAR(20),
UpfrontTaxAssessedInLegacySystem BIT,
TaxBasisType NVARCHAR(10)
)
SELECT
ReceivableId = R.Id,
DueDate = R.DueDate,
LocationId = R.LocationId,
ContractId = R.EntityId,
LegalEntityId = R.LegalEntityId,
ReceivableCodeId = R.ReceivableCodeId,
IsLeaseBased = CASE WHEN R.ReceivableCodeId IN (PF.PayoffReceivableCodeId, PF.BuyoutReceivableCodeId, PF.PropertyTaxEscrowReceivableCodeId)
THEN CONVERT(BIT, 0)
ELSE CONVERT(BIT, 1) END ,
C.TaxAssessmentLevel
INTO #ReceivablesInfo
FROM Receivables R
INNER JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = 'CT'
LEFT JOIN Payoffs PF ON R.SourceId = PF.Id AND R.SourceTable = @PayoffReceivableSourceTable AND PF.Id = @PayoffId
WHERE R.Id IN(SELECT ID FROM #ReceivableIds)
AND R.IsActive = 1 ;
DECLARE @TaxAssessmentLevel NVARCHAR(20)
SELECT @TaxAssessmentLevel = TaxAssessmentLevel FROM #ReceivablesInfo
SELECT
R.Id ReceivableId,
MAX(GLT.Id) GLTemplateId
INTO #SalesTaxGLTemplateDetail
FROM #ReceivablesInfo RDs
INNER JOIN Receivables R ON R.Id = RDs.ReceivableId
INNER JOIN LegalEntities LE ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
GROUP BY
R.Id
;
IF @TaxAssessmentLevel = 'Customer'
BEGIN
INSERT INTO #TE_LeaseAssetLocations_Asset
(
Row_Num,
EffectiveFromDate,
DueDate,
LocationId,
AssetId,
ReceivableDetailId,
AssetLocationId,
SaleLeasebackCode,
IsElectronicallyDelivered,
ReciprocityAmount_Amount,
ReciprocityAmount_Currency,
LienCredit_Amount,
LienCredit_Currency,
GrossVehicleWeight,
IsMultiComponent,
TaxAssessmentLevel,
UpfrontTaxAssessedInLegacySystem,
TaxBasisType
)
SELECT
Row_Num = CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId THEN 1
ELSE ROW_NUMBER() OVER (PARTITION BY A.Id, RD.Id ORDER BY A.Id,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) < 0 THEN CL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) > 0 THEN CL.EffectiveFromDate END  ASC) END,
EffectiveFromDate =  CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId THEN R.DueDate
ELSE CL.EffectiveFromDate END,
DueDate = R.DueDate,
LocationId = CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId AND PA.DropOffLocationId IS NOT NULL THEN PA.DropOffLocationId
ELSE
CL.LocationId
END,
AssetId = A.Id,
ReceivableDetailId = RD.Id,
AssetLocationId = CL.Id ,
SaleLeasebackCode = SLBC.Code,
IsElectronicallyDelivered = A.IsElectronicallyDelivered,
ReciprocityAmount_Amount = 0,
ReciprocityAmount_Currency = PF.BuyoutAmount_Currency,
LienCredit_Amount = 0,
LienCredit_Currency = PF.BuyoutAmount_Currency,
GrossVehicleWeight = ISNULL(A.GrossVehicleWeight,0),
IsMultiComponent = ISNULL(A.IsParent,CONVERT(BIT,0)) 	,
RecInfo.TaxAssessmentLevel,
CASE WHEN PA.UpfrontTaxAssessedCustomerLocationId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END UpfrontTaxAssessedInLegacySystem,
CCL.TaxBasisType
FROM
#ReceivablesInfo RecInfo
JOIN Receivables R ON RecInfo.ReceivableId = R.Id
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Assets A ON A.Id = RD.AssetId
INNER JOIN LeaseAssets LA ON A.Id = LA.AssetId
INNER JOIN PayoffAssets PA ON LA.Id = PA.LeaseAssetId AND PA.IsActive = 1
INNER JOIN Payoffs PF ON PA.PayoffId = PF.Id AND PF.Id = @PayoffId
LEFT JOIN CustomerLocations CL ON CL.CustomerId = R.CustomerId
AND CL.IsActive = 1
AND (@IsRepossessionPayoff = 0 OR (R.ReceivableCodeId <> ISNULL(PF.BuyoutReceivableCodeId,0) OR PA.DropOffLocationId IS NULL))
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN ContractCustomerLocations CCL ON CL.Id = CCL.CustomerLocationId AND RecInfo.ContractId = CCL.ContractId
WHERE RecInfo.IsLeaseBased = 0
END
ELSE
BEGIN
INSERT INTO #TE_LeaseAssetLocations_Asset
(
Row_Num,
EffectiveFromDate,
DueDate,
LocationId,
AssetId,
ReceivableDetailId,
AssetLocationId,
SaleLeasebackCode,
IsElectronicallyDelivered,
ReciprocityAmount_Amount,
ReciprocityAmount_Currency,
LienCredit_Amount,
LienCredit_Currency,
GrossVehicleWeight,
IsMultiComponent,
TaxAssessmentLevel,
UpfrontTaxAssessedInLegacySystem,
TaxBasisType
)
SELECT
Row_Num = CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId THEN 1
ELSE ROW_NUMBER() OVER (PARTITION BY AL.AssetId, RD.Id ORDER BY AL.AssetId,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, AL.EffectiveFromDate ) < 0 THEN AL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) > 0 THEN AL.EffectiveFromDate END  ASC) END,
EffectiveFromDate =  CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId THEN R.DueDate
ELSE AL.EffectiveFromDate END,
DueDate = R.DueDate,
LocationId = CASE WHEN @IsRepossessionPayoff = 1 AND R.ReceivableCodeId = PF.BuyoutReceivableCodeId AND PA.DropOffLocationId IS NOT NULL THEN PA.DropOffLocationId
ELSE
AL.LocationId
END,
AssetId = A.Id,
ReceivableDetailId = RD.Id,
AssetLocationId = AL.Id ,
SaleLeasebackCode = SLBC.Code,
IsElectronicallyDelivered = A.IsElectronicallyDelivered,
ReciprocityAmount_Amount = ISNULL(AL.ReciprocityAmount_Amount, 0),
ReciprocityAmount_Currency = ISNULL(AL.ReciprocityAmount_Currency, PF.BuyoutAmount_Currency),
LienCredit_Amount = ISNULL(AL.LienCredit_Amount, 0),
LienCredit_Currency = ISNULL(AL.LienCredit_Currency,PF.BuyoutAmount_Currency),
GrossVehicleWeight = ISNULL(A.GrossVehicleWeight,0),
IsMultiComponent = ISNULL(A.IsParent,CONVERT(BIT,0)) 	,
RecInfo.TaxAssessmentLevel,
CASE WHEN PA.UpfrontTaxAssessedAssetLocationId IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END UpfrontTaxAssessedInLegacySystem,
AL.TaxBasisType
FROM
#ReceivablesInfo RecInfo
JOIN Receivables R ON RecInfo.ReceivableId = R.Id
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Assets A ON A.Id = RD.AssetId
INNER JOIN LeaseAssets LA ON A.Id = LA.AssetId
INNER JOIN PayoffAssets PA ON LA.Id = PA.LeaseAssetId AND PA.IsActive = 1
INNER JOIN Payoffs PF ON PA.PayoffId = PF.Id AND PF.Id = @PayoffId
LEFT JOIN AssetLocations AL ON AL.AssetId = RD.AssetId
AND AL.IsActive = 1
AND (@IsRepossessionPayoff = 0 OR (R.ReceivableCodeId <> ISNULL(PF.BuyoutReceivableCodeId,0) OR PA.DropOffLocationId IS NULL))
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
WHERE RecInfo.IsLeaseBased = 0
END
INSERT INTO @AssetLevelReceivableDetails
(EffectiveFromDate,
DueDate,
LocationId,
AssetId,
ReceivableDetailId,
AssetLocationId,
SaleLeasebackCode,
IsElectronicallyDelivered,
ReciprocityAmount_Currency,
ReciprocityAmount_Amount,
LienCredit_Amount,
LienCredit_Currency,
GrossVehicleWeight,
IsMultiComponent,
UpfrontTaxAssessedInLegacySystem,
TaxBasisType)
SELECT  LAL.EffectiveFromDate,
LAL.DueDate,
LAL.LocationId,
LAL.AssetId,
LAL.ReceivableDetailId,
LAL.AssetLocationId,
LAL.SaleLeasebackCode,
LAL.IsElectronicallyDelivered,
LAL.ReciprocityAmount_Currency,
LAL.ReciprocityAmount_Amount,
LAL.LienCredit_Amount,
LAL.LienCredit_Currency,
LAL.GrossVehicleWeight,
LAL.IsMultiComponent,
LAL.UpfrontTaxAssessedInLegacySystem,
LAL.TaxBasisType
FROM   #TE_LeaseAssetLocations_Asset AS LAL
WHERE  LAL.Row_Num = 1;
WITH CTE_ReceivableLocations As
(
SELECT
CTE.LocationId AS LocationId
,states.ShortName AS MainDivision
,countries.ShortName AS Country
,Loc.City AS City
,Loc.ApprovalStatus AS LocationStatus
,Loc.IsActive AS IsLocationActive
,CTE.EffectiveFromDate AS EffectiveFromDate
,CTE.ReceivableDetailId AS ReceivableDetailId
,CTE.AssetLocationId AS AssetLocationId
,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
,CTE.SaleLeasebackCode
,CTE.IsElectronicallyDelivered
,CTE.ReciprocityAmount_Currency
,CTE.ReciprocityAmount_Amount
,CTE.LienCredit_Amount
,CTE.LienCredit_Currency
,CTE.GrossVehicleWeight
,CTE.IsMultiComponent
,Loc.UpfrontTaxMode
,CTE.DueDate
,CTE.UpfrontTaxAssessedInLegacySystem
,CTE.TaxBasisType
FROM
@AssetLevelReceivableDetails CTE
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
),
CTE_AllTaxAreaIdsForLocation AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY Loc.ReceivableDetailId ORDER BY
CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
Loc.LocationId,
Loc.MainDivision,
Loc.City,
Loc.Country,
Loc.EffectiveFromDate,
Loc.ReceivableDetailId,
Loc.AssetLocationId,
Loc.LocationStatus,
Loc.IsLocationActive,
Loc.IsVertexSupported,
Loc.SaleLeasebackCode
,Loc.IsElectronicallyDelivered
,Loc.ReciprocityAmount_Currency
,Loc.ReciprocityAmount_Amount
,Loc.LienCredit_Amount
,Loc.LienCredit_Currency
,Loc.GrossVehicleWeight
,Loc.IsMultiComponent
,Loc.UpfrontTaxMode
,Loc.UpfrontTaxAssessedInLegacySystem
,Loc.TaxBasisType
FROM	CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
)
,CTE_TaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 1
)
,CTE_FromTaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM #TE_LeaseAssetLocations_Asset
WHERE Row_Num = 2
)

SELECT 
	   RD.Id AS ReceivableDetailId
	  ,RD.ReceivableId AS ReceivableId
	  ,RecInfo.DueDate AS DueDate
	  ,RT.IsRental AS IsRental
	  ,ACC.ClassCode AS Product
	  ,0.00 AS FairMarketValue
	  ,0.00 AS Cost
	  ,0.00 AS AmountBilledToDate
	  ,RD.Amount_Amount AS ExtendedPrice
	  ,RD.Amount_Currency AS Currency
	  ,CONVERT(BIT,1) AS IsAssetBased
	  ,CONVERT(BIT,0) AS IsLeaseBased
	  ,CASE WHEN CONVERT(BIT,1) IN (A.IsTaxExempt,PA.UtilitySaleAtAuction) THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsExemptAtAsset
	  ,CASE WHEN RT.Name = 'BuyOut' THEN 'SALE' ELSE 'LEASE' END AS TransactionType
	  ,LE.TaxPayer AS Company
	  ,P.PartyNumber AS CustomerCode
	  ,C.Id  AS CustomerId
	  ,CC.Class AS ClassCode
	  ,ToLocation.Code AS LocationCode
	  ,Loc.LocationId AS LocationId
	  ,Loc.MainDivision AS MainDivision
	  ,Loc.Country AS Country
	  ,Loc.City AS City
	  ,Loc.TaxAreaId AS TaxAreaId
	  ,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	  ,Loc.IsLocationActive
	  ,RecInfo.ContractId AS ContractId
	  ,NULL AS RentAccrualStartDate
	  ,LFD.MaturityDate AS MaturityDate	   
	  ,CASE WHEN LA.CustomerCost_Amount IS NULL THEN 0.00
	   ELSE LA.CustomerCost_Amount END AS CustomerCost
	  ,LF.IsSalesTaxExempt AS IsExemptAtLease
	  ,(LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount) AS LessorRisk
	  ,Loc.AssetLocationId AS AssetLocationId
	  ,Loc.LocationStatus AS LocationStatus
	  ,CONVERT(BIT,0) AS IsExemptAtSundry
	  ,RecT.Id AS ReceivableTaxId
	  ,Loc.IsVertexSupported AS IsVertexSupportedLocation
	  ,CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END AS ContractType
	  ,cont.SequenceNumber AS LeaseUniqueId
	  ,CASE WHEN (RT.IsRental = 1) THEN '' ELSE RC.Name END AS SundryReceivableCode
	  ,ACC.ClassCode AS AssetType
	  ,DPT.LeaseType AS LeaseType
	  ,ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00) AS LeaseTerm
	  ,TTC.TransferCode AS TitleTransferCode
	  ,Loc.EffectiveFromDate AS LocationEffectiveDate
	  ,RT.Name AS ReceivableType
	  ,LE.Id 'LegalEntityId'
	  ,0 'Id'
	  ,CAST(0 AS BIT) 'IsManuallyAssessed'
	  ,CAST('_' AS NVARCHAR(10)) 'TransactionCode'
	  ,Loc.TaxBasisType 'TaxBasisType' 
	  ,Loc.IsMultiComponent AS IsMultiComponent
	  ,STGL.GLTemplateId GlTemplateId
	  ,RC.IsTaxExempt IsExemptAtReceivableCode	
	  ,cont.ContractType ContractTypeValue
	  ,ISNULL(ToLocation.JurisdictionId,CAST(0 AS BIGINT)) AS TaxJurisdictionId
	  ,RC.ReceivableTypeId AS ReceivableTypeId
	  ,RC.Id ReceivableCodeId

	  --User Defined Flex Fields
	  ,CAST(Loc.SaleLeasebackCode AS NVARCHAR(100)) AS SaleLeasebackCode  
	  ,ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
	  ,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
      ,ToState.ShortName ToState
	  ,FromState.ShortName FromState
	  ,Loc.GrossVehicleWeight GrossVehicleWeight
	  ,Loc.LienCredit_Amount LienCredit_Amount
	  ,Loc.LienCredit_Currency LienCredit_Currency
	  ,Loc.ReciprocityAmount_Amount ReciprocityAmount_Amount
	  ,Loc.ReciprocityAmount_Currency ReciprocityAmount_Currency
	  ,RD.AssetId AS AssetId
	  ,CAST(CASE WHEN cont.SyndicationType ='None' THEN 0 ELSE 1 END AS BIT) AS IsSyndicated
	  ,CAST(NULL AS NVARCHAR) AS EngineType
	  ,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
	  ,STEL.Name SalesTaxExemptionLevel
	  ,cont.TaxAssessmentLevel
	  ,DTTFRT.TaxTypeId
	  ,LA.StateTaxTypeId
	  ,LA.CountyTaxTypeId
	  ,LA.CityTaxTypeId
	  ,ToState.Id StateId
	  ,CAST(ISNULL(Loc.UpfrontTaxMode,'_') AS NVARCHAR(100)) UpfrontTaxMode
	  ,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	  ,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
	  ,LFD.CommencementDate AS CommencementDate
	  ,null as AssetSKUId
	  ,null as ReceivableSKUId
	  ,CASE WHEN LE.IsAssessSalesTaxAtSKULevel = 0 THEN 0 ELSE CONVERT(BIT,A.IsSKU) END as 'HasSKU'
	  ,Loc.UpfrontTaxAssessedInLegacySystem
	  INTO #AssetBasedReceivablesInfos
FROM
#ReceivablesInfo RecInfo
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Contracts cont ON RecInfo.ContractId = cont.Id
LEFT JOIN LeaseFinances LF ON cont.Id = LF.ContractId
LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
LEFT JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND RD.AssetId = LA.AssetId
LEFT JOIN PayoffAssets PA ON LA.Id = PA.LeaseAssetId AND PA.PayoffId = @PayoffId
LEFT JOIN Payoffs PF ON PA.PayoffId = PF.Id AND PF.Id = @PayoffId
LEFT JOIN Assets A ON RD.AssetId = A.Id
LEFT JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN LegalEntities LE ON RecInfo.LegalEntityId = LE.Id
LEFT JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
LEFT JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN Customers C ON PF.BillToCustomerId = C.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN Parties P ON C.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON RD.Id = Loc.ReceivableDetailId
LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RT.Id = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
LEFT JOIN CTE_FromTaxAreaIdForLocationAsOfDueDate FromLoc ON RD.Id = FromLoc.ReceivableDetailId
LEFT JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN Sundries S ON RecInfo.ReceivableId = S.ReceivableId AND S.IsActive = 1
LEFT JOIN SecurityDeposits SD on RecInfo.ReceivableId = SD.ReceivableId AND SD.IsActive = 1
LEFT JOIN ReceivableTaxes RecT ON RecInfo.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
LEFT JOIN SalesTaxExemptionLevelConfigs STEL ON A.SalesTaxExemptionLevelId = STEL.Id
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RecInfo.ReceivableId = STGL.ReceivableId
WHERE (S.Id IS NULL OR S.LocationId IS NULL)  AND (SD.Id IS NULL OR (SD.LocationId is null))
AND LF.IsCurrent = 1
AND RecInfo.IsLeaseBased = 0
;
SELECT DISTINCT
	   lm.*,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt,
	   CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCountryTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCountryTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CountryTaxExemptRule,
	   CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsStateTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsStateTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS StateTaxExemptRule,
	   CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCityTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCityTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CityTaxExemptRule,
	   CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCountyTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CountyTaxExemptRule,
		CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= lm.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE LA.SalesTaxRemittanceResponsibility END AS SalesTaxRemittanceResponsibility,
		LA.AcquisitionLocationId AS AcquisitionLocationId,
		A.UsageCondition AS AssetUsageCondition,
		AU.Usage AS Usage
		,CAST('' AS NVARCHAR(40)) AS BusCode
	   INTO #AssetBasedReceivablesInfo
    FROM  
    #AssetBasedReceivablesInfos lm
    LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
    LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
    LEFT JOIN Assets a ON a.Id = lm.AssetId
	LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id
    LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id 
    LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
    LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
    LEFT JOIN Locations l ON lm.LocationId = l.Id
    LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id
	LEFT JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.ID AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL)) AND lm.AssetId = LA.AssetId
	LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = A.Id AND LF.ContractId = STRH.ContractId;

	SELECT 
	   A.ReceivableDetailId AS ReceivableDetailId
	  ,A.ReceivableId AS ReceivableId
	  ,A.DueDate AS DueDate
	  ,A.IsRental AS IsRental
	  ,ACC.ClassCode AS Product
	  ,0.00 AS FairMarketValue
	  ,0.00 AS Cost
	  ,0.00 AS AmountBilledToDate
	  ,RSKU.Amount_Amount AS ExtendedPrice
	  ,RSKU.Amount_Currency AS Currency
	  ,CONVERT(BIT,1) AS IsAssetBased
	  ,CONVERT(BIT,0) AS IsLeaseBased
	  ,ASKU.IsSalesTaxExempt AS IsExemptAtAsset
	  ,A.TransactionType As TransactionType
	  ,A.Company AS Company
	  ,A.CustomerCode AS CustomerCode
	  ,A.CustomerId AS CustomerId
	  ,A.ClassCode AS ClassCode
	  ,A.LocationCode AS LocationCode
	  ,A.LocationId AS LocationId
	  ,A.MainDivision AS MainDivision
	  ,A.Country AS Country
	  ,A.City AS City
	  ,A.TaxAreaId AS TaxAreaId
	  ,A.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	  ,A.IsLocationActive AS IsLocationActive
	  ,A.ContractId AS ContractId
	  ,A.RentAccrualStartDate AS RentAccrualStartDate
	  ,A.MaturityDate AS MaturityDate	
	  ,CASE WHEN LASKU.CustomerCost_Amount IS NULL THEN 0.00
	   ELSE LASKU.CustomerCost_Amount END AS CustomerCost
	  ,A.IsExemptAtLease AS IsExemptAtLease
	  ,A.LessorRisk AS LessorRisk
	  ,A.AssetLocationId AS AssetLocationId
	  ,A.LocationStatus AS LocationStatus
	  ,A.IsExemptAtSundry AS IsExemptAtSundry
	  ,A.ReceivableTaxId AS ReceivableTaxId
	  ,A.IsVertexSupportedLocation AS IsVertexSupportedLocation
	  ,A.ContractType AS ContractType
	  ,A.LeaseUniqueId AS LeaseUniqueId
	  ,A.SundryReceivableCode AS SundryReceivableCode
	  ,ACC.ClassCode AS AssetType
	  ,A.LeaseType AS LeaseType
	  ,A.LeaseTerm AS LeaseTerm
	  ,A.TitleTransferCode AS TitleTransferCode 
	  ,A.LocationEffectiveDate AS LocationEffectiveDate
	  ,A.ReceivableType AS ReceivableType
	  ,A.LegalEntityId
	  ,A.Id
	  ,A.IsManuallyAssessed 'IsManuallyAssessed'
	  ,A.TransactionCode 'TransactionCode'
	  ,A.TaxBasisType 'TaxBasisType' 
	  ,A.IsMultiComponent AS IsMultiComponent
	  ,A.GlTemplateId GlTemplateId
	  ,A.IsExemptAtReceivableCode IsExemptAtReceivableCode	
	  ,A.ContractTypeValue ContractTypeValue
	  ,A.TaxJurisdictionId AS TaxJurisdictionId
	  ,A.ReceivableTypeId AS ReceivableTypeId
	  ,A.ReceivableCodeId ReceivableCodeId
	  --User Defined Flex Fields
	  ,A.SaleLeasebackCode SaleLeasebackCode
	  ,A.IsElectronicallyDelivered AS IsElectronicallyDelivered
	  ,A.TaxRemittanceType As TaxRemittanceType
      ,A.ToState AS ToState
	  ,A.FromState AS FromState
	  ,A.GrossVehicleWeight GrossVehicleWeight
	  ,A.LienCredit_Amount AS LienCredit_Amount
	  ,A.LienCredit_Currency AS LienCredit_Currency
	  ,A.ReciprocityAmount_Amount AS ReciprocityAmount_Amount
	  ,A.ReciprocityAmount_Currency AS ReciprocityAmount_Currency
	  ,A.AssetId AS AssetId
	  ,A.IsSyndicated
	  ,A.EngineType AS EngineType
	  ,A.HorsePower AS HorsePower
	  ,A.SalesTaxExemptionLevel AS  SalesTaxExemptionLevel
	  ,A.TaxAssessmentLevel
	  ,A.TaxTypeId
	  ,A.StateTaxTypeId
	  ,A.CountyTaxTypeId
	  ,A.CityTaxTypeId
	  ,A.StateId StateId
	  ,A.UpfrontTaxMode UpfrontTaxMode
	  ,A.TaxRegistrationNumber AS TaxRegistrationNumber
	  ,A.ISOCountryCode AS ISOCountryCode
	  ,A.CommencementDate AS CommencementDate
	  ,ASKU.Id as AssetSKUId
	  ,RSKU.Id as ReceivableSKUId
	  ,CONVERT(BIT,1) 'HasSKU'
	  ,A.UpfrontTaxAssessedInLegacySystem
	  ,A.CountryTaxExempt
	  ,A.StateTaxExempt
	  ,A.CityTaxExempt
	  ,A.CountyTaxExempt
	  ,A.CountryTaxExemptRule
	  ,A.StateTaxExemptRule
	  ,A.CityTaxExemptRule
	  ,A.CountyTaxExemptRule
	  ,A.SalesTaxRemittanceResponsibility
	  ,A.AcquisitionLocationId
	  ,A.AssetUsageCondition AS AssetUsageCondition
	  ,A.Usage
		,CAST('' AS NVARCHAR(40)) AS BusCode
	  INTO #SKUBasedReceivablesInfo
	  From #AssetBasedReceivablesInfo A
	  INNER JOIN ReceivableSKUs RSKU ON A.ReceivableDetailId = RSKU.ReceivableDetailId AND A.HasSKU=1
	  INNER JOIN AssetSKUs ASKU on RSKU.AssetSKUId = ASKU.Id
	  INNER JOIN AssetTypes AT ON ASKU.TypeId=AT.Id
	  INNER JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
	  INNER JOIN LeaseAssetSKUs LASKU ON LASKU.AssetSKUId = ASKU.Id;

WITH CTE_ReceivableLocations AS
(
SELECT
R.LocationId AS LocationId
,R.DueDate
,R.ReceivableId
,states.ShortName AS MainDivision
,countries.ShortName AS Country
,Loc.City AS City
,Loc.ApprovalStatus AS LocationStatus
,Loc.IsActive AS IsLocationActive
,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
,Loc.UpfrontTaxMode
FROM
#ReceivablesInfo R
LEFT JOIN Locations Loc ON R.LocationId = Loc.Id
LEFT JOIN States states ON Loc.StateId = states.Id
LEFT JOIN Countries countries ON states.CountryId = countries.Id
WHERE R.IsLeaseBased = 1
)
,CTE_AllTaxAreaIdsForLocation AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY P.LocationId,Loc.ReceivableId ORDER BY CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
Loc.LocationId,
Loc.MainDivision,
Loc.City,
Loc.Country,
Loc.LocationStatus,
Loc.IsLocationActive,
Loc.ReceivableId,
Loc.IsVertexSupported
,Loc.UpfrontTaxMode
FROM	CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
)
,CTE_TaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 1
)
,CTE_FromTaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 2
)
SELECT
RD.Id AS ReceivableDetailId
,RD.ReceivableId AS ReceivableId
,RecInfo.DueDate AS DueDate
,RT.IsRental AS IsRental
,RT.Name AS Product
,0.00 AS FairMarketValue
,0.00 AS Cost
,0.00 AS AmountBilledToDate
,RD.Amount_Amount AS ExtendedPrice
,RD.Amount_Currency AS Currency
,CONVERT(BIT,0) AS IsAssetBased
,CONVERT(BIT,1) AS IsLeaseBased
,CONVERT(BIT,0) AS IsExemptAtAsset
,'LEASE' AS TransactionType
,LE.TaxPayer AS Company
,P.PartyNumber AS CustomerCode
,P.Id  AS CustomerId
,CC.Class AS ClassCode
,ToLocation.Code AS LocationCode
,Loc.LocationId AS LocationId
,Loc.MainDivision AS MainDivision
,Loc.Country AS Country
,Loc.City AS City
,Loc.TaxAreaId AS TaxAreaId
,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
,Loc.IsLocationActive
,RecInfo.ContractId AS ContractId
,NULL AS RentAccrualStartDate
,LFD.MaturityDate AS MaturityDate
,0.0 AS CustomerCost
,LF.IsSalesTaxExempt AS IsExemptAtLease
,(LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount) AS LessorRisk
,NULL AS AssetLocationId
,Loc.LocationStatus AS LocationStatus
,ISNULL(S.IsTaxExempt,CONVERT(BIT,0)) AS IsExemptAtSundry
,RecT.Id AS ReceivableTaxId
,Loc.IsVertexSupported AS IsVertexSupportedLocation
,CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END AS ContractType
,cont.SequenceNumber AS LeaseUniqueId
,CASE WHEN (RT.IsRental = 1) THEN '' ELSE RC.Name END AS SundryReceivableCode
,CAST(NULL AS NVARCHAR(80)) AS AssetType
,DPT.LeaseType AS LeaseType
,ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00) AS LeaseTerm
,CAST(NULL AS NVARCHAR(20)) AS TitleTransferCode
,NULL AS LocationEffectiveDate,
RT.Name AS ReceivableType
,LE.Id 'LegalEntityId'
,0 'Id'
,CAST(0 AS BIT) 'IsManuallyAssessed'
,CAST(NULL AS NVARCHAR(10)) 'TransactionCode'
,CAST(NULL AS NVARCHAR(10)) 'TaxBasisType'
,CAST(0 AS BIT) AS IsMultiComponent
,STGL.GLTemplateId GlTemplateId
,RC.IsTaxExempt IsExemptAtReceivableCode
,cont.ContractType ContractTypeValue
,ISNULL(ToLocation.JurisdictionId,CAST(0 AS BIGINT)) AS TaxJurisdictionId
,RC.ReceivableTypeId AS ReceivableTypeId
,RC.Id ReceivableCodeId
--User Defined Flex Fields
,CAST(NULL AS NVARCHAR(100)) AS SaleLeasebackCode
,CAST(0 AS BIT) AS IsElectronicallyDelivered
,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
,ToState.ShortName ToState
,FromState.ShortName FromState
,0 GrossVehicleWeight
,0.00 LienCredit_Amount
,'USD' LienCredit_Currency
,0.00 ReciprocityAmount_Amount
,'USD' ReciprocityAmount_Currency
,RD.AssetId AS AssetId
,CAST(CASE WHEN cont.SyndicationType ='None' THEN 0 ELSE 1 END AS BIT) AS IsSyndicated
,CAST(NULL AS NVARCHAR) AS EngineType
,CAST(0 AS BIGINT) AS HorsePower
,CAST(NULL AS NVARCHAR) AS SalesTaxExemptionLevel
,cont.TaxAssessmentLevel
,DTTFRT.TaxTypeId
,NULL StateTaxTypeId
,NULL CountyTaxTypeId
,NULL CityTaxTypeId
,ToState.Id StateId
,CAST(ISNULL(Loc.UpfrontTaxMode,'_') AS NVARCHAR(100)) UpfrontTaxMode
,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
,LFD.CommencementDate  AS CommencementDate
,null as AssetSKUId
,null as ReceivableSKUId
,CONVERT(BIT,0) 'HasSKU'
,CAST(0 AS BIT) AS UpfrontTaxAssessedInLegacySystem
INTO #LeaseBasedReceivablesInfos
FROM
#ReceivablesInfo RecInfo
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Contracts cont ON RecInfo.ContractId = cont.Id
INNER JOIN LegalEntities LE ON RecInfo.LegalEntityId = LE.Id
INNER JOIN ReceivableCodes RC ON RecInfo.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN Sundries S ON RecInfo.ReceivableId = S.ReceivableId AND S.IsActive = 1
LEFT JOIN SundryRecurringPaymentSchedules SRPS ON RecInfo.ReceivableId = SRPS.ReceivableId
LEFT JOIN LeaseFinances LF ON cont.Id = LF.ContractId
LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
LEFT JOIN Payoffs PF ON LF.Id = PF.LeaseFinanceId AND PF.Id = @PayoffId
LEFT JOIN Customers Cust ON PF.BillToCustomerId= Cust.Id
LEFT JOIN Parties P ON Cust.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN CustomerClasses CC ON Cust.CustomerClassId = CC.Id
LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON RecInfo.ReceivableId = Loc.ReceivableId
LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RT.Id = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
LEFT JOIN CTE_FromTaxAreaIdForLocationAsOfDueDate FromLoc ON RD.Id = FromLoc.ReceivableId
LEFT JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RecInfo.ReceivableId = STGL.ReceivableId
LEFT JOIN ReceivableTaxes RecT ON RecInfo.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
WHERE (LF.IsCurrent = 1 AND RecInfo.IsLeaseBased = 1);
SELECT DISTINCT
	   lm.*,
	 CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
	   CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt,
	   CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCountryTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCountryTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CountryTaxExemptRule,
	   CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsStateTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsStateTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS StateTaxExemptRule,
	   CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCityTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCityTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CityTaxExemptRule,
	   CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule' 
			WHEN AssetRule.IsCountyTaxExempt = 1 THEN 'AssetTaxExemptRule'
			WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
			WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
			ELSE '' END AS CountyTaxExemptRule,
		CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= lm.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE LA.SalesTaxRemittanceResponsibility END AS SalesTaxRemittanceResponsibility,
		LA.AcquisitionLocationId AS AcquisitionLocationId,
		A.UsageCondition AS AssetUsageCondition,
		AU.Usage AS Usage,
		CAST('' AS NVARCHAR(40)) AS BusCode
	   INTO #LeaseBasedReceivablesInfo
    FROM  
    #LeaseBasedReceivablesInfos lm
    LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
    LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
    LEFT JOIN Assets a ON a.Id = lm.AssetId
	LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id
    LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id 
    LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
	LEFT JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.ID AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL)) AND lm.AssetId = LA.AssetId
	LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = A.Id AND LF.ContractId = STRH.ContractId
    LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
    LEFT JOIN Locations l ON lm.LocationId = l.Id
    LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;

	
UPDATE
#AssetBasedReceivablesInfo
SET
#AssetBasedReceivablesInfo.BusCode = RTRD.BusCode
FROM
#AssetBasedReceivablesInfo AssetBasedReceivablesInfo
INNER JOIN ReceivableDetails RD ON RD.Id = AssetBasedReceivablesInfo.ReceivableDetailId AND RD.IsActive = 1
INNER JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.AdjustmentBasisReceivableDetailId 
INNER JOIN ReceivableTaxReversalDetails RTRD ON RTRD.Id= RTD.Id AND RTD.IsActive=1;

UPDATE
#LeaseBasedReceivablesInfo
SET
#LeaseBasedReceivablesInfo.BusCode = RTRD.BusCode
FROM
#LeaseBasedReceivablesInfo TE_LeaseBasedReceivablesInfo
INNER JOIN ReceivableDetails RD ON RD.Id = TE_LeaseBasedReceivablesInfo.ReceivableDetailId AND RD.IsActive = 1
INNER JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.AdjustmentBasisReceivableDetailId 
INNER JOIN ReceivableTaxReversalDetails RTRD ON RTRD.Id= RTD.Id AND RTD.IsActive=1;

UPDATE
#SKUBasedReceivablesInfo
SET
#SKUBasedReceivablesInfo.BusCode = RTRD.BusCode
FROM
#SKUBasedReceivablesInfo TE_LeaseBasedReceivablesInfo
INNER JOIN ReceivableDetails RD ON RD.Id = TE_LeaseBasedReceivablesInfo.ReceivableDetailId AND RD.IsActive = 1
INNER JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.AdjustmentBasisReceivableDetailId 
INNER JOIN ReceivableTaxReversalDetails RTRD ON RTRD.Id= RTD.Id AND RTD.IsActive=1;



SELECT * INTO #ReceivableDetailsForPayoff FROM (
SELECT * FROM #AssetBasedReceivablesInfo A Where A.HasSKU=0
UNION
SELECT * FROM #SKUBasedReceivablesInfo
UNION
SELECT * FROM #LeaseBasedReceivablesInfo
) AS ReceivableDetailsForPayoff 

;WITH CTE_AcquisitionLocationDetails
AS 
(
SELECT DISTINCT L.Id AS AcquisitionLocationId,
		L.TaxAreaId AS AcquisitionLocationTaxAreaId,
		L.City AS AcquisitionLocationCity,
		S.ShortName AS AcquisitionLocationMainDivision,
		C.ShortName AS AcquisitionLocationCountry,
		RD.ReceivableDetailId AS ReceivableDetailId
FROM #ReceivableDetailsForPayoff RD 
JOIN  Locations L ON RD.AcquisitionLocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
),
CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM #ReceivableDetailsForPayoff WHERE AssetId IS NOT NULL
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

SELECT DISTINCT RD.*,
		AD.AcquisitionLocationTaxAreaId,
		AD.AcquisitionLocationCity,
		AD.AcquisitionLocationMainDivision,
		AD.AcquisitionLocationCountry,
		ROW_NUMBER() OVER (ORDER BY RD.Id) as LineItemNumber,
		ASN.SerialNumber AS AssetSerialOrVIN
FROM #ReceivableDetailsForPayoff RD
LEFT JOIN CTE_AcquisitionLocationDetails AD ON AD.AcquisitionLocationId = RD.AcquisitionLocationId AND AD.ReceivableDetailId=RD.ReceivableDetailId
LEFT JOIN CTE_AssetSerialNumberDetails ASN on RD.AssetId = ASN.AssetId


DROP TABLE #AssetBasedReceivablesInfo
DROP TABLE #SKUBasedReceivablesInfo
DROP TABLE #LeaseBasedReceivablesInfo
DROP TABLE #ReceivablesInfo
END

GO
