SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetSalesTaxDetailsForLeaseAssumption]
(
@CustomerId BIGINT,
@AssumptionDate DATE,
@LegalEntityId BIGINT,
@ContractId BIGINT,
@AssetDetails AssetTableType READONLY,
@TaxAssessmentLevel	NVARCHAR(40),
@OldCustomerId BIGINT,
@DealProductName NVARCHAR(40) = NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex  = 'Vertex';

Declare @ContractType NVARCHAR(40) = NULL;
Declare @ReceivableTypeName NVARCHAR(100) = NULL;
SELECT
@ContractType = Case WHEN CapitalLeaseType ='ConditionalSales' THEN 'CSC' ELSE 'FMV' END
FROM DealProductTypes
JOIN DealTypes on DealProductTypes.DealTypeId = DealTypes.Id
WHERE DealProductTypes.Name= @DealProductName AND DealTypes.Name='Lease'
;
SELECT
@ReceivableTypeName =
Case WHEN CapitalLeaseType ='ConditionalSales' OR CapitalLeaseType = 'DirectFinance'
THEN 'CapitalLeaseRental'
ELSE 'OperatingLeaseRental' END
FROM DealProductTypes
JOIN DealTypes on DealProductTypes.DealTypeId = DealTypes.Id
WHERE DealProductTypes.Name= @DealProductName AND DealTypes.Name='Lease'
;
DECLARE @AssetLevelReceivableDetails TABLE
(
EffectiveFromDate  DATE,
DueDate            DATE,
LocationId         BIGINT,
AssetId            BIGINT,
AssetLocationId    BIGINT,
SaleLeasebackCode  NVARCHAR(40),
IsElectronicallyDelivered BIT,
ReciprocityAmount_Amount DECIMAL(9,2),
ReciprocityAmount_Currency NVARCHAR(20),
LienCredit_Amount DECIMAL(9,2),
LienCredit_Currency	NVARCHAR(20),
GrossVehicleWeight INT,
IsMultiComponent BIT
)

INSERT INTO @AssetLevelReceivableDetails(
EffectiveFromDate,
DueDate,
LocationId,
AssetId,
AssetLocationId,
SaleLeasebackCode,
IsElectronicallyDelivered,
ReciprocityAmount_Currency,
ReciprocityAmount_Amount,
LienCredit_Amount,
LienCredit_Currency,
GrossVehicleWeight,
IsMultiComponent
)
SELECT
GETDATE() EffectiveFromDate
,GETDATE() DueDate
,AD.LocationId
,AD.AssetId
,AD.AssetId AssetLocationId
,SLBC.Code
,A.IsElectronicallyDelivered
,A.PropertyTaxCost_Currency ReciprocityAmount_Currency
,CAST(0.00 AS DECIMAL(9,2)) ReciprocityAmount_Amount
,CAST(0.00 AS DECIMAL(9,2)) LienCredit_Amount
,A.PropertyTaxCost_Currency LienCredit_Currency
,A.GrossVehicleWeight
,A.IsParent
FROM @AssetDetails AD
INNER JOIN Assets A ON A.Id = AD.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id;
;
CREATE TABLE #LeaseAssetFromLocations
(
ROWNUMBER			BIGINT,
AssetId				BIGINT NULL,
EffectiveFromDate	DATE NULL,
LocationId			BIGINT NULL,
ShortName			NVARCHAR(100) NULL,
TaxJurisdictionId   BIGINT NULL,
TaxBasisType		NVARCHAR(5) NULL
)
;
IF @TaxAssessmentLevel <> 'Customer'
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@AssumptionDate DueDate,
AL.LocationId AS LocationId,
AL.AssetId AS AssetId,
AL.Id AS AssetLocationId,
AL.TaxBasisType
INTO #LeaseAssetLocations
FROM
@AssetDetails AIds
INNER JOIN AssetLocations AL ON AL.AssetId = AIds.AssetId AND AL.IsActive = 1 AND AL.EffectiveFromDate <= @AssumptionDate;
INSERT INTO #LeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.JurisdictionId
,MAXAL.TaxBasisType
FROM #LeaseAssetLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN @AssetLevelReceivableDetails AL ON
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
;
END
ELSE
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@AssumptionDate DueDate,
AL.LocationId AS LocationId,
AIds.AssetId AS AssetId,
AL.Id AS AssetLocationId,
AL.TaxBasisType
INTO #LeaseCustomerLocations
FROM
@AssetDetails AIds
CROSS JOIN CustomerLocations AL
WHERE AL.IsActive = 1 AND AL.CustomerId = @OldCustomerId;
INSERT INTO #LeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.JurisdictionId
,MAXAL.TaxBasisType
FROM #LeaseCustomerLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN @AssetLevelReceivableDetails AL ON
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
;
END
SELECT L.Id AS AcquisitionLocationId,
L.TaxAreaId AS AcquisitionLocationTaxAreaId,
L.City AS AcquisitionLocationCity,
S.ShortName AS AcquisitionLocationMainDivision,
C.ShortName AS AcquisitionLocationCountry,
Ad.AssetId
INTO #SellerAssetDetails
FROM @AssetDetails AD 
JOIN LeaseAssets LA ON AD.AssetId = LA.AssetId AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
JOIN LeaseFinances LF ON LF.ID = LA.LeaseFinanceId
JOIN Contracts Co ON Co.Id = LF.ContractId
JOIN Locations L ON L.Id = LA.AcquisitionLocationId
JOIN States S ON S.Id = L.StateId
JOIN Countries C ON C.Id = S.CountryId
WHERE Co.Id = @ContractId AND L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
DELETE FROM #LeaseAssetFromLocations
WHERE RowNumber <> 1
;
WITH CTE_AssetLocations AS
(
SELECT
CTE.LocationId AS LocationId
,states.ShortName AS MainDivision
,countries.ShortName AS Country
,Loc.City AS City
,Loc.ApprovalStatus AS LocationStatus
,Loc.IsActive AS IsLocationActive
,CTE.EffectiveFromDate AS EffectiveFromDate
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
,CTE.AssetId
FROM
@AssetLevelReceivableDetails CTE
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
),
CTE_AllTaxAreaIdsForLocation AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY Loc.AssetId ORDER BY
CASE WHEN DATEDIFF(DAY, @AssumptionDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, @AssumptionDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, @AssumptionDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num
,P.TaxAreaEffectiveDate
,P.TaxAreaId
,Loc.LocationId
,Loc.MainDivision
,Loc.City
,Loc.Country
,Loc.EffectiveFromDate
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
,Loc.AssetId
FROM CTE_AssetLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
)
,CTE_TaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM CTE_AllTaxAreaIdsForLocation
WHERE Row_Num = 1
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM @AssetDetails A
JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)
SELECT 
	   0 AS ReceivableDetailId
	  ,0 AS ReceivableId
	  ,@AssumptionDate AS DueDate
	  ,CAST(1 AS BIT) AS IsRental
	  ,ACC.ClassCode AS Product
	  ,0.00 AS FairMarketValue
	  ,0.00 AS Cost
	  ,0.00 AS AmountBilledToDate
	  ,0.00 AS ExtendedPrice
	  ,'USD' AS Currency
	  ,CONVERT (BIT,1) IsAssetBased
	  ,CONVERT(BIT,0) IsLeaseBased
	  ,CASE WHEN A.IsTaxExempt IS NULL THEN CAST(0 AS BIT) ELSE A.IsTaxExempt END AS IsExemptAtAsset
	  ,CASE WHEN ISNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCountyTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCountyTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS CountyTaxExempt
	  ,CASE WHEN ISNULL(AssetRule.IsCityTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCityTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCityTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS CityTaxExempt
	  ,CASE WHEN ISNULL(AssetRule.IsStateTaxExempt,0) = 1 OR ISNULL(LocationRule.IsStateTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsStateTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS StateTaxExempt
	  ,CASE WHEN ISNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCountryTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCountryTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE  CAST (0 AS BIT) END AS CountryTaxExempt
	  ,'LEASE' AS TransactionType
	  ,LE.TaxPayer AS Company
	  ,P.PartyNumber AS CustomerCode
	  ,C.Id  AS CustomerId
	  ,CC.Class AS ClassCode
	  ,Loc.LocationId AS LocationId
	  ,Loc.MainDivision AS MainDivision
	  ,Loc.Country AS Country
	  ,Loc.City AS City
	  ,Loc.TaxAreaId AS TaxAreaId
	  ,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	  ,Loc.IsLocationActive
	  ,cont.Id AS ContractId
	  ,NULL AS RentAccrualStartDate
	  ,CASE WHEN LFD.ID IS NOT NULL THEN LFD.MaturityDate ELSE Loan.MaturityDate END AS MaturityDate	   
	  ,CASE WHEN LA.NBV_Amount IS NULL THEN 0.00
	   ELSE LA.NBV_Amount END AS CustomerCost
	  ,LF.IsSalesTaxExempt AS IsExemptAtLease
	  ,(LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount) AS LessorRisk
	  ,Loc.AssetLocationId AS AssetLocationId
	  ,Loc.LocationStatus AS LocationStatus
	  ,CAST(0 AS BIT) AS IsExemptAtSundry
	  ,NULL AS ReceivableTaxId
	  ,Loc.IsVertexSupported AS IsVertexSupportedLocation
	  --flex fields
	  ,ISNULL(@ContractType,Case WHEN CapitalLeaseType ='ConditionalSales' THEN 'CSC' ELSE 'FMV' END) AS ContractType  
	  ,cont.SequenceNumber AS LeaseUniqueId
	  ,'' AS SundryReceivableCode
	  ,ACC.ClassCode AS AssetType
	  ,AT.Id AS AssetTypeId
	  ,A.Id AS AssetId
	  ,DPT.LeaseType AS LeaseType
	  ,ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00) AS LeaseTerm
	  ,TTC.TransferCode AS TitleTransferCode
	  ,Loc.EffectiveFromDate AS LocationEffectiveDate
	  ,@ReceivableTypeName AS ReceivableType
	  ,LE.Id LegalEntityId
	  ,0 Id
	  ,CAST(0 AS BIT) IsManuallyAssessed
	  ,NULL TransactionCode
	   ,ISNULL(ToLocation.TaxBasisType,FromLoc.TaxBasisType) TaxBasisType
      ,ToState.ShortName ToState
	  ,FromLoc.ShortName FromState
	  ,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
	  ,CAST(Loc.SaleLeasebackCode AS NVARCHAR) AS SaleLeaseback
	  ,ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
	  ,Loc.LienCredit_Amount
	  ,Loc.LienCredit_Currency
	  ,Loc.ReciprocityAmount_Amount
	  ,Loc.ReciprocityAmount_Currency
	  ,ISNULL(Loc.GrossVehicleWeight ,0) GrossVehicleWeight
	  ,Loc.IsMultiComponent 
	  ,ToLocation.Code LocationCode
	  ,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel
	  ,CASE WHEN LFD.ID IS NOT NULL THEN LFD.CommencementDate ELSE Loan.CommencementDate END  AS CommencementDate
	  ,ToLocation.JurisdictionId TaxJurisdictionId
	  ,AD.LeaseTaxAssetId
	  ,LF.Id LeaseFinanceId
	  ,@TaxAssessmentLevel TaxAssessmentLevel
	  ,AD.StateTaxTypeId 
	  ,AD.CountyTaxTypeId
	  ,AD.CityTaxTypeId
	  ,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	  ,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
	  ,AU.Usage
	  ,SLAD.AcquisitionLocationId
	  ,SLAD.AcquisitionLocationTaxAreaId
	  ,SLAD.AcquisitionLocationCity
	  ,SLAD.AcquisitionLocationMainDivision
	  ,SLAD.AcquisitionLocationCountry
	  ,ASN.SerialNumber AS AssetSerialOrVIN
	  ,ISNULL(A.UsageCondition,'_') AS AssetUsageCondition
	  ,ISNULL(LA.SalesTaxRemittanceResponsibility,'_') AS SalesTaxRemittanceResponsibility
	  ,CASE WHEN (LE.IsAssessSalestaxatSKUlevel = 0 ) THEN 0 ELSE CONVERT(BIT,A.IsSKU) END AS 'IsSKU'
	  ,NULL as AssetSKUId
	  ,CAST (0 AS BIT) AS UpfrontTaxAssessedInLegacySystem
	INTO 
	  #AssetBasedReceivableDetils
	FROM
	  @AssetDetails AD 
	  JOIN Assets A ON AD.AssetId = A.Id
	  LEFT JOIN CTE_AssetSerialNumberDetails ASN ON  A.Id = ASN.AssetId
	  LEFT JOIN Contracts cont ON cont.Id = @ContractId
	  LEFT JOIN LoanFinances Loan ON Loan.ContractId = cont.Id AND loan.IsCurrent = 1
	  LEFT JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
	  LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
	  LEFT JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND AD.AssetId = LA.AssetId AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
	  LEFT JOIN AssetTypes AT ON A.TypeId = AT.Id
	  LEFT JOIN AssetUsages AU ON AU.Id =A.AssetUsageId
	  LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
	  LEFT JOIN LegalEntities LE ON @LegalEntityId = LE.Id
	  LEFT JOIN Customers C ON C.Id = @CustomerId
	  LEFT JOIN Parties P ON C.Id = P.Id
	  LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
	  LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
	  LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON A.Id = Loc.AssetId
      LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
      LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
      LEFT JOIN #LeaseAssetFromLocations FromLoc ON  A.Id = FromLoc.AssetId
	  LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id 
	  LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
	  LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
	  LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id	 
	  LEFT JOIN #SellerAssetDetails SLAD ON SLAD.AssetId = AD.AssetId
	  LEFT JOIN TaxExemptRules AssetRule ON A.TaxExemptRuleId = AssetRule.Id
	  LEFT JOIN TaxExemptRules LocationRule ON ToLocation.TaxExemptRuleId = LocationRule.Id
	  LEFT JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id

SELECT 
	   0 AS ReceivableDetailId
	  ,0 AS ReceivableId
	  ,@AssumptionDate AS DueDate
	  ,CAST(1 AS BIT) AS IsRental
	  ,ACC.ClassCode AS Product
	  ,0.00 AS FairMarketValue
	  ,0.00 AS Cost
	  ,0.00 AS AmountBilledToDate
	  ,0.00 AS ExtendedPrice
	  ,'USD' AS Currency
	  ,CONVERT (BIT,1) IsAssetBased
	  ,CONVERT(BIT,0) IsLeaseBased
	  ,CASE WHEN ASKU.IsSalesTaxExempt IS NULL THEN CAST(0 AS BIT) ELSE ASKU.IsSalesTaxExempt END AS IsExemptAtAsset
	  ,A.CountyTaxExempt
	  ,A.CityTaxExempt
	  ,A.StateTaxExempt
	  ,A.CountryTaxExempt
	  ,'LEASE' AS TransactionType
	  ,A.Company AS Company
	  ,A.CustomerCode AS CustomerCode
	  ,A.CustomerId  AS CustomerId
	  ,A.ClassCode AS ClassCode
	  ,A.LocationId AS LocationId
	  ,A.MainDivision AS MainDivision
	  ,A.Country AS Country
	  ,A.City AS City
	  ,A.TaxAreaId AS TaxAreaId
	  ,A.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	  ,A.IsLocationActive
	  ,A.ContractId AS ContractId
	  ,A.RentAccrualStartDate AS RentAccrualStartDate
	  ,A.MaturityDate AS MaturityDate	   
	  ,CASE WHEN LASKU.NBV_Amount IS NULL THEN 0.00
	   ELSE LASKU.NBV_Amount END AS CustomerCost
	  ,A.IsExemptAtLease AS IsExemptAtLease
	  ,A.LessorRisk AS LessorRisk
	  ,A.AssetLocationId AS AssetLocationId
	  ,A.LocationStatus AS LocationStatus
	  ,A.IsExemptAtSundry AS IsExemptAtSundry
	  ,A.ReceivableTaxId AS ReceivableTaxId
	  ,A.IsVertexSupportedLocation AS IsVertexSupportedLocation
	  --flex fields
	  ,A.ContractType AS ContractType  
	  ,A.LeaseUniqueId AS LeaseUniqueId
	  ,A.SundryReceivableCode AS SundryReceivableCode
	  ,ACC.ClassCode AS AssetType
	  ,AT.Id AS AssetTypeId
	  ,A.AssetId AS AssetId
	  ,A.LeaseType AS LeaseType
	  ,A.LeaseTerm AS LeaseTerm
	  ,A.TitleTransferCode AS TitleTransferCode
	  ,A.LocationEffectiveDate AS LocationEffectiveDate
	  ,A.ReceivableType AS ReceivableType
	  ,A.LegalEntityId LegalEntityId
	  ,0 Id
	  ,A.IsManuallyAssessed IsManuallyAssessed
	  ,A.TransactionCode
	  ,A.TaxBasisType
      ,A.ToState
	  ,A.FromState
	  ,A.TaxRemittanceType
	  ,A.SaleLeaseback
	  ,A.IsElectronicallyDelivered
	  ,A.LienCredit_Amount
	  ,A.LienCredit_Currency
	  ,A.ReciprocityAmount_Amount
	  ,A.ReciprocityAmount_Currency
	  ,A.GrossVehicleWeight
	  ,A.IsMultiComponent 
	  ,A.LocationCode
	  ,A.SalesTaxExemptionLevel
	  ,A.CommencementDate
	  ,A.TaxJurisdictionId
	  ,A.LeaseTaxAssetId
	  ,A.LeaseFinanceId
	  ,@TaxAssessmentLevel TaxAssessmentLevel
	  ,A.StateTaxTypeId 
	  ,A.CountyTaxTypeId
	  ,A.CityTaxTypeId
	  ,A.TaxRegistrationNumber
	  ,A.ISOCountryCode
	  ,A.Usage
	  ,A.AcquisitionLocationId
	  ,A.AcquisitionLocationTaxAreaId
	  ,A.AcquisitionLocationCity
	  ,A.AcquisitionLocationMainDivision
	  ,A.AcquisitionLocationCountry
	  ,ASKU.SerialNumber AS AssetSerialOrVIN
	  ,A.AssetUsageCondition
	  ,A.SalesTaxRemittanceResponsibility
	  ,A.IsSKU IsSKU
	  ,ASKU.Id as AssetSKUId
	  ,CAST(0 AS BIT) UpfrontTaxAssessedInLegacySystem
	INTO 
	  #SKUBasedReceivableDetils
	FROM
	  #AssetBasedReceivableDetils A
	  JOIN AssetSKUs ASKU on ASKU.AssetId = A.AssetId AND ASKU.IsActive = 1
	  JOIN LeaseAssetSKUs LASKU on LASKU.AssetSKUId = ASKU.Id AND LASKU.IsActive = 1
	  LEFT JOIN AssetTypes AT ON ASKU.TypeId = AT.Id
	  LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
	  where A.IsSKU=1

	SELECT * from (
		SELECT * FROM #AssetBasedReceivableDetils WHERE IsSKU=0
		UNION
		SELECT * FROM #SKUBasedReceivableDetils
		) salesTaxReceivableDetailInfo;

DROP TABLE #SellerAssetDetails
END

GO
