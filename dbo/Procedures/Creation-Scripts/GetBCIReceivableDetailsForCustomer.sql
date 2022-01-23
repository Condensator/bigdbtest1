SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[GetBCIReceivableDetailsForCustomer]
(
@BCIContractTableForCustomer BCIContractTableTypeForCustomer READONLY,
@BCILocationTableForCustomer BCILocationTableTypeForCustomer READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

CREATE TABLE #LocationDetailsForLeaseAsset
(
AssetId					  BIGINT,
AssetLocationId			  BIGINT,
LocationEffectiveDate     DATETIME,
LocationId				  BIGINT,
TaxAreaId				  BIGINT,
TaxAreaEffectiveDate	  DATE,
MainDivision			  NVARCHAR(100),
City					  NVARCHAR(100),
Country					  NVARCHAR(100),
LocationStatus			  NVARCHAR(100),
IsLocationActive		  BIT,
CustomerCost			  DECIMAL(16,2),
AssetType				  NVARCHAR(100),
Currency				  NVARCHAR(100),
IsTaxExempt				  BIT,
TitleTransferCode		  NVARCHAR(100),
LeaseAssetId			  BIGINT,
IsVertexSupportedLocation BIT,
ContractId       BIGINT,
TaxJurisdictionId BIGINT
)
CREATE TABLE #AssetsInLease
(
AssetId							  BIGINT,
CustomerCost_Amount				  DECIMAL(16,2),
CustomerCost_Currency			  NVARCHAR(6),
FixedTermRentalAmount_Amount      DECIMAL(16,2),
FixedTermRentalAmount_Currency    NVARCHAR(6),
LeaseAssetId					  BIGINT,
ContractId       BIGINT
)
CREATE TABLE #ReceivableIds(
ReceivableDetailId BIGINT,
ReceivableId     BIGINT,
DueDate          DATETIME,
LocationId       BIGINT,
ContractId       BIGINT,
LegalEntityId    BIGINT,
ReceivableCodeId BIGINT,
CustomerId		 BIGINT,
EntityId		 BIGINT,
IsActive		 BIT,
SourceId		 BIGINT,
EntityType		 NVARCHAR(100),
SourceTable 	 NVARCHAR(100),
PaymentScheduleId BIGINT,
)
CREATE TABLE #AssetLevelReceivableDetails
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
SalesTaxExemptionLevel NVARCHAR(100),
AssetLocationTaxBasisType NVARCHAR(4),
CustomerLocationId    BIGINT,
)
INSERT INTO #ReceivableIds
(	ReceivableDetailId,
ReceivableId,
DueDate,
LocationId,
ContractId,
LegalEntityId,
ReceivableCodeId,
CustomerId,
EntityId,
IsActive,
SourceId,
EntityType,
SourceTable,
PaymentScheduleId
)
SELECT
Rd.Id,
R.Id,
R.DueDate,
R.LocationId,
R.EntityId,
R.LegalEntityId,
R.ReceivableCodeId,
R.CustomerId,
R.EntityId,
R.IsActive,
R.SourceId,
R.EntityType,
R.SourceTable,
R.PaymentScheduleId
FROM Receivables R Join ReceivableDetails Rd on R.Id = Rd.ReceivableId
JOIN @BCIContractTableForCustomer CT ON R.CustomerId = CT.CustomerId
WHERE R.DueDate <= CT.DueDate
AND R.IsActive = 1
AND CT.CustomerId = R.CustomerId
AND ((CT.ContractId IS NULL AND R.EntityType = 'CU' ) OR (CT.ContractId = R.EntityId AND R.EntityType = 'CT'))
;
SELECT
R.Id ReceivableId,
MAX(GLT.Id) GLTemplateId
INTO #SalesTaxGLTemplateDetail
FROM #ReceivableIds RDs
INNER JOIN Receivables R ON R.Id = RDs.ReceivableId
INNER JOIN LegalEntities LE ON LE.Id = R.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
GROUP BY
R.Id
;
SELECT
RD.Id,
R.DueDate,
RD.ReceivableId,
RD.Amount_Amount,
RD.Amount_Currency,
RD.AssetId,
RD.IsActive,
RD.AdjustmentBasisReceivableDetailId,
RD.IsTaxAssessed
INTO #ReceivableDetails_Temp
FROM ReceivableDetails RD
JOIN #ReceivableIds R ON RD.ReceivableId = R.ReceivableId
;
--Asset Based START
SELECT * INTO #ReceivableDetailsWithAssets
FROM #ReceivableDetails_Temp WHERE AssetId IS NOT NULL
;
--DELETE FROM #ReceivableIds WHERE ReceivableId IN (SELECT ReceivableId FROM #ReceivableDetails_Temp WHERE AssetId IS NOT NULL)
--;
--DELETE FROM #ReceivableDetails_Temp WHERE AssetId IS NOT NULL
--;
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
RD.DueDate,
AL.LocationId AS LocationId,
AL.AssetId AS AssetId,
AL.Id AS AssetLocationId,
RD.Id ReceivableDetailId
INTO #SalesTaxLeaseAssetLocations
FROM #ReceivableDetailsWithAssets RD
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id JOIN @BCIContractTableForCustomer CT ON L.CustomerId = CT.CustomerId
;
INSERT INTO #AssetLevelReceivableDetails
(
EffectiveFromDate
,DueDate
,LocationId
,AssetId
,ReceivableDetailId
,AssetLocationId
,SaleLeasebackCode
,IsElectronicallyDelivered
,ReciprocityAmount_Currency
,ReciprocityAmount_Amount
,LienCredit_Amount
,LienCredit_Currency
,GrossVehicleWeight
,IsMultiComponent
,SalesTaxExemptionLevel
,AssetLocationTaxBasisType)
SELECT
GAL.EffectiveFromDate
,RId.DueDate
,AL.LocationId
,GAL.AssetId
,GAL.ReceivableDetailId
,GAL.AssetLocationId
,SLBC.Code
,A.IsElectronicallyDelivered
,AL.ReciprocityAmount_Currency
,AL.ReciprocityAmount_Amount
,AL.LienCredit_Amount
,AL.LienCredit_Currency
,A.GrossVehicleWeight
,A.IsParent
,STELC.Name
,AL.TaxBasisType
FROM @BCILocationTableForCustomer GAL
JOIN #ReceivableIds RId on GAL.ReceivableDetailId = RId.ReceivableId
INNER JOIN AssetLocations AL ON AL.Id = GAL.AssetLocationId
INNER JOIN Assets A ON A.Id = AL.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id;
;
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
,CTE.SalesTaxExemptionLevel
,CTE.AssetLocationTaxBasisType
,CTE.CustomerLocationId AS CustomerLocationId
,states.ShortName StateShortName
,Loc.JurisdictionId TaxJurisdictionId
,Loc.IsActive
,Loc.Code LocationCode
,Loc.UpfrontTaxMode
,CTE.DueDate
FROM
#AssetLevelReceivableDetails CTE
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
)
SELECT
ROW_NUMBER() OVER (PARTITION BY Loc.ReceivableDetailId ORDER BY
CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate
,P.TaxAreaId
,Loc.LocationId
,Loc.MainDivision
,Loc.City
,Loc.Country
,Loc.EffectiveFromDate
,Loc.ReceivableDetailId
,Loc.AssetLocationId
,Loc.LocationStatus
,Loc.IsLocationActive
,Loc.IsVertexSupported
,Loc.SaleLeasebackCode
,Loc.IsElectronicallyDelivered
,Loc.ReciprocityAmount_Currency
,Loc.ReciprocityAmount_Amount
,Loc.LienCredit_Amount
,Loc.LienCredit_Currency
,Loc.GrossVehicleWeight
,Loc.IsMultiComponent
,Loc.SalesTaxExemptionLevel
,Loc.AssetLocationTaxBasisType
,Loc.CustomerLocationId
,Loc.StateShortName
,Loc.TaxJurisdictionId
,Loc.IsActive
,Loc.LocationCode
,Loc.UpfrontTaxMode
INTO #AllTaxAreaIdsForAssetLocation
FROM CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
;
SELECT *
INTO #TaxAreaIdForAssetLocationAsOfDueDate
FROM #AllTaxAreaIdsForAssetLocation
WHERE Row_Num = 1
;
SELECT *
INTO #FromTaxAreaIdForAssetLocationAsOfDueDate
FROM #AllTaxAreaIdsForAssetLocation
WHERE Row_Num = 2
;
--Asset Based END
SELECT
ROW_NUMBER() OVER (PARTITION BY p.LocationId ORDER BY CASE WHEN DATEDIFF(DAY,CT.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
P.LocationId,
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END AS [negative],
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END AS [positive],
Loc.UpfrontTaxMode
INTO #CTE_AllTaxAreaIdForLocation
FROM LocationTaxAreaHistories p
INNER JOIN #ReceivableIds RId ON RId.LocationId = P.LocationId
JOIN @BCIContractTableForCustomer CT on CT.CustomerId = RId.CustomerId
INNER JOIN Locations Loc ON RId.LocationId = Loc.id
;
WITH CTE_TaxAreaId AS
(
SELECT *
FROM #CTE_AllTaxAreaIdForLocation
WHERE Row_Num = 1
)
,CTE_FromTaxAreaId AS
(
SELECT *
FROM #CTE_AllTaxAreaIdForLocation
WHERE Row_Num = 2
)
SELECT
RD.Id AS ReceivableDetailId
,RD.ReceivableId AS ReceivableId
,R.DueDate AS DueDate
,RT.IsRental AS IsRental
,CASE WHEN (RT.IsRental = 1 AND R.EntityType = 'CT') THEN ACC.ClassCode ELSE RT.Name END AS Product
,0.00 AS FairMarketValue
,0.00 AS Cost
,0.00 AS 'AmountBilledToDate'
,RD.Amount_Amount 'ExtendedPrice'
,RD.Amount_Currency 'Currency'
,CASE WHEN RD.AssetId IS NULL OR RD.AssetId = '' THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS IsAssetBased
,CONVERT(BIT,0) AS'IsLeaseBased'
,ISNULL(A.IsTaxExempt,CAST(0 AS BIT)) AS IsExemptAtAsset
,CASE WHEN (RT.Name = 'BuyOut' OR RT.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS 'TransactionType'
,LE.TaxPayer AS 'Company'
,P.PartyNumber AS 'CustomerCode'
,C.Id  AS 'CustomerId'
,CC.Class  'ClassCode'
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.LocationId ELSE R.LocationId END AS LocationId
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.LocationCode ELSE L.Code END AS LocationCode
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.MainDivision ELSE ST.ShortName END AS MainDivision
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.Country ELSE country.ShortName END AS Country
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.City ELSE L.City END AS City
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.LocationStatus ELSE L.ApprovalStatus END AS LocationStatus
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.IsActive,CAST(0 AS BIT))
ELSE ISNULL(L.IsActive,CAST(0 AS BIT)) END AS IsLocationActive
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.TaxAreaId ELSE TAID.TaxAreaId END AS TaxAreaId
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.TaxAreaEffectiveDate ELSE TAID.TaxAreaEffectiveDate END AS TaxAreaEffectiveDate
,CASE WHEN R.EntityType= 'CT' THEN R.EntityId ELSE NULL END ContractId
,NULL 'RentAccrualStartDate'
,NULL 'MaturityDate'
,0.0 AS 'CustomerCost'
,CONVERT(BIT,0) AS 'IsExemptAtLease'
,0.0 AS 'LessorRisk'
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.AssetLocationId ELSE CAST(NULL AS BIGINT) END AS AssetLocationId
,CONVERT(BIT, ISNULL(ISNULL(S.IsTaxExempt,SR.IsTaxExempt),0)) 'IsExemptAtSundry'
,RecT.Id AS ReceivableTaxId
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.IsVertexSupported, CAST(0 AS BIT)) ELSE ISNULL(CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT), CAST(0 AS BIT)) END AS IsVertexSupportedLocation
,ISNULL(A.IsParent,CONVERT(BIT,0)) AS IsMulticomponent
--flex fields
,CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END 'ContractType'
,cont.SequenceNumber  'LeaseUniqueId'
,RC.Name 'SundryReceivableCode'
,ACC.ClassCode 'AssetType'
--,CONVERT(BIT,0) 'IsPurchaseLeaseBack'
,DPT.LeaseType 'LeaseType'
,0.00 'LeaseTerm'
--,NULL AS 'InstallDate'
,TTC.TransferCode AS 'TitleTransferCode'
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.EffectiveFromDate ELSE CAST(NULL AS DATE) END AS LocationEffectiveDate
,RT.Name 'ReceivableType'
,LE.Id 'LegalEntityId'
,CAST(NULL AS DATE) AS CommencementDate
,RC.IsTaxExempt IsExemptAtReceivableCode
,cont.ContractType ContractTypeValue
,STGL.GLTemplateId GlTemplateId
,CAST(NULL AS NVARCHAR) AS TaxBasisType
,CAST(NULL AS NVARCHAR) AS TransactionCode
,CAST(0 AS BIT) AS IsManuallyAssessed
,CAST(NULL AS NVARCHAR) AS AssetLocationTaxBasisType
,CAST(0 AS BIGINT) AssetTypeId
,CAST(0 AS BIT) IsCapitalizedSalesTaxAsset
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN  ISNULL(AssetLoc.TaxJurisdictionId,CAST(0 AS BIGINT))
ELSE ISNULL(L.JurisdictionId,CAST(0 AS BIGINT)) END AS TaxJurisdictionId
,RC.ReceivableTypeId AS ReceivableTypeId
,RC.Id ReceivableCodeId
--User Defined Flex Fields
,CAST(SLBC.Code AS NVARCHAR) AS SaleLeasebackCode
,ISNULL(A.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
,REPLACE(LE.TaxRemittancePreference, 'Based','') TaxRemittanceType
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.StateShortName ELSE ToState.ShortName END ToState
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN AssetLoc.StateShortName ELSE FromState.ShortName END FromState
,ISNULL(A.GrossVehicleWeight ,0) GrossVehicleWeight
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.LienCredit_Amount,0.00) ELSE 0.00 END AS LienCredit_Amount
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.LienCredit_Currency,'USD') ELSE 'USD' END AS  LienCredit_Currency
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.ReciprocityAmount_Amount,0.00) ELSE 0.00 END AS ReciprocityAmount_Amount
,CASE WHEN RD.AssetId IS NOT NULL AND R.EntityType = 'CU' THEN ISNULL(AssetLoc.ReciprocityAmount_Currency,'USD') ELSE 'USD' END AS ReciprocityAmount_Currency
,RD.AssetId 'AssetId'
,CASE WHEN cont.SyndicationType != NULL AND cont.SyndicationType != 'None' THEN CAST(1 AS BIT)  ELSE CAST(0 AS BIT) END IsSyndicated
,CAST('' AS NVARCHAR(40)) AS BusCode
,CAST(NULL AS NVARCHAR) AS EngineType
,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel
,CAST(NULL AS NVARCHAR) AS AssetCatalogNumber
,'_' TaxAssessmentLevel
,CAST(0 AS BIT) IsRentalReceivableOnSameDate
,CASE WHEN PT.LienDate IS NULL THEN CAST (NULL AS DATE) ELSE PT.LienDate END AS LienDate
,CAST(0 AS BIT) AS IsContractCapitalizeUpfront
,CAST(0 AS BIT) IsPrepaidUpfrontTax
,COALESCE(DTTFRT.TaxTypeId,DDTTFRT.TaxTypeId,AssetLocDTTFRT.TaxTypeId) TaxTypeId
,NULL StateTaxTypeId
,NULL CountyTaxTypeId
,NULL CityTaxTypeId
,COALESCE(ToState.Id,ST.Id,AssetLocState.Id) StateId
,ISNULL(TAID.UpfrontTaxMode, AssetLoc.UpfrontTaxMode) UpfrontTaxMode
,cont.DealProductTypeId
,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
,ISNULL(cont.SyndicationType,'_') SyndicationType
INTO #ReceivableDetailsForCustomers
FROM
#ReceivableIds R
INNER JOIN #ReceivableDetails_Temp RD ON RD.ReceivableId = R.ReceivableId
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
INNER JOIN Customers C ON R.CustomerId = C.Id
INNER JOIN Parties P ON C.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN Locations L ON R.LocationId = L.Id
LEFT JOIN States ST ON L.StateId = ST.Id
LEFT JOIN Countries country ON ST.CountryId = country.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DDTTFRT ON RT.Id = DDTTFRT.ReceivableTypeId AND country.Id = DDTTFRT.CountryId
LEFT JOIN Contracts cont ON R.EntityId = cont.Id AND R.EntityType='CT'
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN Sundries S ON R.ReceivableId = S.ReceivableId
LEFT JOIN SundryRecurringPaymentSchedules SRPS ON R.ReceivableId = SRPS.ReceivableId AND SRPS.IsActive = 1
LEFT JOIN SundryRecurrings SR ON SRPS.SundryRecurringId = SR.Id AND SR.IsActive = 1
LEFT JOIN ReceivableTaxes RecT ON R.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
LEFT JOIN Assets A ON RD.AssetId = A.Id
LEFT JOIN AssetTypes AT ON RD.AssetId = A.TypeId
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN CTE_TaxAreaId TAID ON R.LocationId = TAID.LocationId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
LEFT JOIN Locations ToLocation ON TAID.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RT.Id = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
LEFT JOIN CTE_FromTaxAreaId FromTAID ON R.LocationId = FromTAID.LocationId
LEFT JOIN Locations FromLocation ON FromTAID.LocationId = FromLocation.Id
LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON R.ReceivableId = STGL.ReceivableId
LEFT JOIN PropertyTaxes PT ON PT.PropTaxReceivableId = RD.ReceivableId AND PT.IsActive = 1
LEFT JOIN #TaxAreaIdForAssetLocationAsOfDueDate AssetLoc ON AssetLoc.ReceivableDetailId = RD.Id
LEFT JOIN #TaxAreaIdForAssetLocationAsOfDueDate FromAssetLoc ON FromAssetLoc.ReceivableDetailId = RD.Id
LEFT JOIN States AssetLocState ON AssetLoc.StateShortName = AssetLocState.ShortName
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes AssetLocDTTFRT ON RT.Id = AssetLocDTTFRT.ReceivableTypeId AND AssetLocState.CountryId = AssetLocDTTFRT.CountryId
WHERE RD.IsActive = 1 AND RD.IsTaxAssessed = 0
ORDER BY R.DueDate;
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
ELSE '' END AS CountyTaxExemptRule
INTO #ReceivableDetailsForCustomer
FROM
#ReceivableDetailsForCustomers lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
UPDATE
#ReceivableDetailsForCustomer
SET
#ReceivableDetailsForCustomer.BusCode = GLOrgStructureConfigs.BusinessCode
FROM
#ReceivableDetailsForCustomer ReceivableDetailsForCustomer
INNER JOIN Contracts
ON Contracts.Id = ReceivableDetailsForCustomer.ContractId
INNER JOIN LeaseFinances
ON LeaseFinances.ContractId = Contracts.Id
AND LeaseFinances.IsCurrent = 1
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = ReceivableDetailsForCustomer.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = Contracts.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
UPDATE
#ReceivableDetailsForCustomer
SET
#ReceivableDetailsForCustomer.BusCode = GLOrgStructureConfigs.BusinessCode
FROM
#ReceivableDetailsForCustomer ReceivableDetailsForCustomer
INNER JOIN Contracts
ON Contracts.Id = ReceivableDetailsForCustomer.ContractId
INNER JOIN LoanFinances
ON  LoanFinances.ContractId = Contracts.Id
AND LoanFinances.IsCurrent = 1
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = ReceivableDetailsForCustomer.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LoanFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = Contracts.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
SELECT * FROM #ReceivableDetailsForCustomer ORDER BY DueDate ASC;
WITH CTE_RentalReceivableWithStateDetails AS
(
SELECT
RD.ExtendedPrice RevenueBilledToDate_Amount
,RD.Currency RevenueBilledToDate_Currency
,L.StateId
,RD.AssetId
,RD.Currency CumulativeAmount_Currency
,RD.ReceivableDetailId
,RD.DueDate
,RD.ReceivableId
,RD.ContractId
FROM #ReceivableDetailsForCustomer RD
JOIN Locations L ON RD.LocationId = L.Id
WHERE RD.IsRental = 1 AND RD.AssetId IS NOT NULL
AND RD.ContractId IS NOT NULL
)
SELECT
ISNULL(RD.RevenueBilledToDate_Amount,0.00) RevenueBilledToDate_Amount
,RD.RevenueBilledToDate_Currency
,RD.StateId
,RD.AssetId
,ISNULL((SELECT ISNULL(SUM(BRR.RevenueBilledToDate_Amount),0.00) FROM BilledRentalReceivables BRR
WHERE RD.AssetId = BRR.AssetId AND RD.StateId = BRR.StateId AND BRR.IsActive = 1
AND RD.ContractId = BRR.ContractId),0.00) BilledRentalReceivable_Amount
,RD.CumulativeAmount_Currency
,RD.ReceivableDetailId
,RD.DueDate
,RD.ContractId
,ROW_NUMBER() OVER (ORDER BY RD.DueDate, RD.ReceivableId, RD.ReceivableDetailId) RowNumber
INTO #BilledRentalReceivableDetail
FROM CTE_RentalReceivableWithStateDetails RD
;
SELECT
RD.RevenueBilledToDate_Amount
,RD.RevenueBilledToDate_Currency
,RD.StateId
,RD.AssetId
,RD.BilledRentalReceivable_Amount + ISNULL((SELECT SUM(RevenueBilledToDate_Amount) FROM #BilledRentalReceivableDetail CRD
WHERE RD.AssetId = CRD.AssetId AND RD.StateId = CRD.StateId AND CRD.RowNumber <= RD.RowNumber),0.00) CumulativeAmount_Amount
,RD.CumulativeAmount_Currency
,RD.ReceivableDetailId
,RD.DueDate
,RD.ContractId
FROM #BilledRentalReceivableDetail RD
;
SELECT * INTO #LeaseBasedReceivable
FROM #ReceivableDetailsForCustomer
EXCEPT
SELECT * FROM  #ReceivableDetailsForCustomer
WHERE IsAssetBased = 1 OR IsLeaseBased = 0;
IF(EXISTS(SELECT * FROM #LeaseBasedReceivable))
BEGIN
INSERT INTO #AssetsInLease
SELECT
LA.AssetId
,LA.NBV_Amount CustomerCost_Amount
,LA.NBV_Currency CustomerCost_Currency
,LA.TaxBasisAmount_Amount FixedTermRentalAmount_Amount
,LA.TaxBasisAmount_Currency FixedTermRentalAmount_Currency
,LA.Id LeaseAssetId
,LBR.ContractId
FROM #LeaseBasedReceivable LBR
INNER JOIN Contracts C ON LBR.ContractId = C.Id
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND La.IsActive = 1
INNER JOIN Assets A ON LA.AssetId = A.Id AND A.FinancialType = 'Real'
;
WITH CTE_AllLeaseAssetLocations
AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY AL.AssetId ORDER BY AL.AssetId,
CASE WHEN DATEDIFF(DAY, CT.DueDate, AL.EffectiveFromDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.DueDate, AL.EffectiveFromDate) < 0 THEN AL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.DueDate, AL.EffectiveFromDate) > 0 THEN AL.EffectiveFromDate END  ASC) Row_Num,
AL.EffectiveFromDate 'LocationEffectiveDate',
AL.LocationId 'LocationId',
AL.Id 'AssetLocationId',
LA.AssetId 'AssetId',
LA.CustomerCost_Amount 'CustomerCost',
LA.Id 'LeaseAssetId',
LF.ContractId
FROM
LeaseFinances LF
JOIN @BCIContractTableForCustomer CT ON LF.CustomerId = CT.CustomerId
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetLocations AL ON A.Id = AL.AssetId AND AL.IsActive = 1
WHERE A.FinancialType = 'Real' AND LA.IsActive = 1
AND LF.ContractId IN (SELECT ContractId FROM #LeaseBasedReceivable)
)
,CTE_LeaseAssetLocationsAsOfDueDate AS
(
SELECT *
FROM CTE_AllLeaseAssetLocations
WHERE Row_Num = 1
)
,
CTE_AllTaxAreaIdsForLocation AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY AssetLoc.AssetLocationId ORDER BY
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate 'TaxAreaEffectiveDate',
P.TaxAreaId 'TaxAreaId',
AssetLoc.AssetLocationId 'AssetLocationId',
AssetLoc.AssetId 'AssetId',
AssetLoc.LocationEffectiveDate 'LocationEffectiveDate',
AssetLoc.CustomerCost 'CustomerCost',
AssetLoc.LocationId 'LocationId',
AssetLoc.LeaseAssetId 'LeaseAssetId',
AssetLoc.ContractId
FROM
CTE_LeaseAssetLocationsAsOfDueDate AssetLoc
JOIN @BCIContractTableForCustomer CT ON CT.ContractId = AssetLoc.ContractId
LEFT JOIN LocationTaxAreaHistories p ON P.LocationId = AssetLoc.LocationId
)
SELECT * INTO #CTE_TaxAreaIdAsOfDueDate
FROM CTE_AllTaxAreaIdsForLocation;
INSERT INTO #LocationDetailsForLeaseAsset
SELECT
CTE.AssetId,
CTE.AssetLocationId,
CTE.LocationEffectiveDate,
L.Id 'LocationId',
CTE.TaxAreaId,
CTE.TaxAreaEffectiveDate,
S.ShortName 'MainDivision',
L.City 'City',
C.ShortName 'Country',
L.ApprovalStatus 'LocationStatus',
L.IsActive 'IsLocationActive',
CTE.CustomerCost,
ACC.ClassCode 'AssetType',
A.CurrencyCode 'Currency',
A.IsTaxExempt 'IsTaxExempt',
TTC.TransferCode 'TitleTransferCode',
CTE.LeaseAssetId 'LeaseAssetId',
CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) 'IsVertexSupportedLocation' ,
CTE.ContractId,
ISNULL(L.JurisdictionId,0) 'TaxJurisdictionId'
FROM
#CTE_TaxAreaIdAsOfDueDate CTE
INNER JOIN Assets A ON CTE.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN Locations L ON CTE.LocationId = L.Id
LEFT JOIN States S ON L.StateId =S.Id
LEFT JOIN Countries C ON S.CountryId = C.Id
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
END
SELECT * FROM #AssetsInLease;
SELECT * FROM #LocationDetailsForLeaseAsset;
--_ucReceivableInfo
SELECT
DISTINCT
R.DueDate,
RD.AssetId,
RD.ReceivableId,
R.EntityId ContractId,
R.CustomerId CustomerId,
RD.Id ReceivableDetailId,
RD.AdjustmentBasisReceivableDetailId
FROM #ReceivableDetailsForCustomer CBRD
JOIN #ReceivableIds R ON CBRD.ReceivableId = R.ReceivableId
JOIN #ReceivableDetails_Temp RD ON R.ReceivableId = RD.ReceivableId AND RD.AssetId = CBRD.AssetId
WHERE CBRD.IsRental = 1 AND CBRD.AssetId IS NOT NULL
-- _urReceivableInfo
SELECT
DISTINCT
R.DueDate,
RD.AssetId,
RD.ReceivableId,
RD.Id ReceivableDetailId,
RD.AdjustmentBasisReceivableDetailId
FROM #ReceivableDetailsForCustomer CBRD
JOIN #ReceivableIds R ON CBRD.ReceivableId = R.ReceivableId
JOIN #ReceivableDetails_Temp RD ON R.ReceivableId = RD.ReceivableId
WHERE R.EntityType = 'CT' AND CBRD.IsRental = 1
;
--UC Value
SELECT
R.DueDate,
AIS.AssetId,
R.ReceivableId,
0.00 ReceivableAmount,
AIS.BeginNetBookValue_Amount BeginNetBookValueAmount,
AIS.OperatingBeginNetBookValue_Amount OperatingBeginNetBookValueAmount
FROM AssetIncomeSchedules AIS
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
JOIN LeasePaymentSchedules LPS ON LIS.IncomeDate = LPS.EndDate
JOIN #ReceivableIds R ON LPS.Id = R.PaymentScheduleId
WHERE AIS.IsActive = 1 AND LPS.IsActive = 1
--UR Value
SELECT
R.DueDate,
RD.AssetId,
R.ReceivableId,
RD.Amount_Amount ReceivableAmount,
0.00 BeginNetBookValueAmount,
0.00 OperatingBeginNetBookValueAmount
FROM #ReceivableIds R
JOIN #ReceivableDetails_Temp RD ON R.ReceivableId = RD.ReceivableId
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE RT.Name = 'CapitalLeaseRental'
OR RT.Name = 'OperatingLeaseRental'
DROP TABLE #LocationDetailsForLeaseAsset
DROP TABLE #AssetsInLease
DROP TABLE #ReceivableIds
DROP TABLE #AssetLevelReceivableDetails
END

GO
