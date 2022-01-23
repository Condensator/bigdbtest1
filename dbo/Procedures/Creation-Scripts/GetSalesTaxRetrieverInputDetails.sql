SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetSalesTaxRetrieverInputDetails]
(  
 @CustomerId    BIGINT,  
 @CommencementDate  DATE,  
 @LegalEntityId   BIGINT,  
 @ContractId    BIGINT,  
 @AssetDetails   TaxAssetIdTableType READONLY,  
 @TaxAssessmentLevel  NVARCHAR(40) = NULL,  
 @DealProductName NVARCHAR(40) = NULL,
 @IsCountryTaxExempt BIT ,  
 @IsStateTaxExempt BIT ,  
 @IsCountyTaxExempt BIT ,  
 @IsCityTaxExempt BIT,
 @AssetMultipleSerialNumberType NVARCHAR(10)
)  
AS  
BEGIN  
SET NOCOUNT ON;  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex  = 'Vertex';

SELECT * INTO #AssetDetails FROM @AssetDetails
Create Index IX_Id On #AssetDetails (Id)

DECLARE @DueDate DATE = @CommencementDate;  
Declare @ContractType NVARCHAR(40) = NULL;  
Declare @ReceivableTypeName NVARCHAR(100) = NULL;  
Declare @ReceivableTypeId BIGINT;

SELECT   
 @ContractType = Case WHEN CapitalLeaseType ='ConditionalSales' THEN 'CSC' ELSE 'FMV' END  
FROM DealProductTypes   
JOIN DealTypes on DealProductTypes.DealTypeId = DealTypes.Id  
WHERE DealProductTypes.Name= @DealProductName AND DealTypes.Name='Lease';  
  
SELECT   
 @ReceivableTypeName =   
  Case WHEN CapitalLeaseType ='ConditionalSales' OR CapitalLeaseType = 'DirectFinance'   
   THEN 'CapitalLeaseRental'   
  ELSE 'OperatingLeaseRental' END  
FROM DealProductTypes   
JOIN DealTypes on DealProductTypes.DealTypeId = DealTypes.Id  
WHERE DealProductTypes.Name= @DealProductName AND DealTypes.Name='Lease';  

SELECT @ReceivableTypeId = Id From ReceivableTypes Where Name In (@ReceivableTypeName)
  
CREATE TABLE #AssetLevelLoactionDetails  
(  
EffectiveFromDate			DATE,  
DueDate						DATE,  
LocationId					BIGINT INDEX IX_LocationId,  
AssetId						BIGINT,  
SaleLeasebackCode			NVARCHAR(40),  
IsElectronicallyDelivered	BIT,  
ReciprocityAmount_Amount	DECIMAL,  
LienCredit_Amount			DECIMAL,  
GrossVehicleWeight			INT,  
IsMultiComponent			BIT,
UpfrontTaxAssessedInLegacySystem BIT NOT NULL
)   
  
CREATE TABLE #LeaseAssetFromLocations  
(  
 RowNumber   INT NULL,  
 AssetId    BIGINT NULL INDEX IX_AssetId,
 ShortName   NVARCHAR(100) NULL,  
 TaxJurisdictionId   BIGINT NULL
)  
  
IF @TaxAssessmentLevel <> 'Customer'  
BEGIN  
SELECT  
AL.EffectiveFromDate AS EffectiveFromDate,  
@DueDate DueDate,  
AL.LocationId AS LocationId,  
AL.AssetId AS AssetId,  
AL.Id AS AssetLocationId,
AL.ReciprocityAmount_Amount,
AL.LienCredit_Amount,
AL.TaxBasisType,
AL.UpfrontTaxAssessedInLegacySystem
INTO #LeaseAssetLocations  
FROM  
#AssetDetails AIds  
INNER JOIN AssetLocations AL ON AL.AssetId = AIds.Id AND AL.IsActive = 1;
  
SELECT  
MAXAL.AssetId  
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
,MAXAL.DueDate
INTO #UniqueLeaseAssetLocations  
FROM  #LeaseAssetLocations MAXAL  
WHERE MAXAL.EffectiveFromDate <= @CommencementDate  
GROUP BY  
MAXAL.AssetId, MAXAL.DueDate;  
  
INSERT INTO #UniqueLeaseAssetLocations  
SELECT  
MINAL.AssetId  
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
,MINAL.DueDate
FROM #LeaseAssetLocations MINAL  
WHERE MINAL.EffectiveFromDate > @CommencementDate  
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #UniqueLeaseAssetLocations)  
GROUP BY  
MINAL.AssetId, MINAL.DueDate;  
  
CREATE NONCLUSTERED INDEX IX_AssetIdEffectiveDate ON #UniqueLeaseAssetLocations(AssetId,EffectiveFromDate)  
    
INSERT INTO #AssetLevelLoactionDetails  
	(
		EffectiveFromDate,  
		DueDate,  
		LocationId,  
		AssetId,  
		SaleLeasebackCode,  
		IsElectronicallyDelivered,  
		ReciprocityAmount_Amount,  
		LienCredit_Amount,  
		GrossVehicleWeight,  
		IsMultiComponent,
		UpfrontTaxAssessedInLegacySystem
	) 
SELECT  
UAL.EffectiveFromDate  
,UAL.DueDate  
,AL.LocationId  
,UAL.AssetId  
,SLBC.Code  
,A.IsElectronicallyDelivered  
,AL.ReciprocityAmount_Amount  
,AL.LienCredit_Amount  
,A.GrossVehicleWeight  
,A.IsParent
,AL.UpfrontTaxAssessedInLegacySystem
FROM #UniqueLeaseAssetLocations UAL  
INNER JOIN #LeaseAssetLocations AL ON AL.AssetId = UAL.AssetId AND AL.DueDate = UAL.DueDate AND AL.EffectiveFromDate = UAL.EffectiveFromDate 
INNER JOIN Assets A ON A.Id = AL.AssetId  
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id;  
  
INSERT INTO #LeaseAssetFromLocations  
SELECT  
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber   
,MAXAL.AssetId
,S.ShortName  
,L.JurisdictionId  
FROM #LeaseAssetLocations MAXAL    
JOIN #UniqueLeaseAssetLocations AL ON   
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate  
JOIN Locations L ON L.Id = MAXAL.LocationId  
JOIN States S ON S.Id = L.StateId
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate  
;   
  
END  
ELSE  
BEGIN  
SELECT  
CL.EffectiveFromDate AS EffectiveFromDate,  
@DueDate DueDate,  
CL.LocationId AS LocationId,  
AIds.Id AS AssetId,  
CL.Id AS CustomerLocationId
INTO #LeaseCustomerLocations  
FROM  
#AssetDetails AIds  
CROSS JOIN CustomerLocations CL   
WHERE CL.IsActive = 1 AND CL.CustomerId = @CustomerId;  
  
SELECT  
MAXCL.AssetId  
,MAX(MAXCL.EffectiveFromDate) AS EffectiveFromDate
,MAXCL.DueDate
INTO #UniqueLeaseCustomerLocations  
FROM  #LeaseCustomerLocations MAXCL  
WHERE MAXCL.EffectiveFromDate <= @CommencementDate  
GROUP BY  
MAXCL.AssetId, MAXCL.DueDate;  
  
INSERT INTO #UniqueLeaseCustomerLocations  
SELECT  
MINCL.AssetId  
,MIN(MINCL.EffectiveFromDate) AS EffectiveFromDate
,MINCL.DueDate
FROM #LeaseCustomerLocations MINCL  
WHERE MINCL.EffectiveFromDate > @CommencementDate  
AND MINCL.AssetId NOT IN(SELECT AssetId FROM #UniqueLeaseCustomerLocations)  
GROUP BY  
MINCL.AssetId, MINCL.DueDate;  
  
INSERT INTO #AssetLevelLoactionDetails  
	(
		EffectiveFromDate,  
		DueDate,  
		LocationId,  
		AssetId,  
		SaleLeasebackCode,  
		IsElectronicallyDelivered,  
		ReciprocityAmount_Amount,  
		LienCredit_Amount,  
		GrossVehicleWeight,  
		IsMultiComponent,
		UpfrontTaxAssessedInLegacySystem
	) 
SELECT  
UCL.EffectiveFromDate  
,UCL.DueDate  
,CL.LocationId  
,UCL.AssetId  
,SLBC.Code  
,A.IsElectronicallyDelivered  
,0.00  
,0.00  
,A.GrossVehicleWeight  
,A.IsParent
,ISNULL(CCL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT))
FROM #UniqueLeaseCustomerLocations UCL  
INNER JOIN #LeaseCustomerLocations CL ON CL.AssetId = UCL.AssetId AND CL.EffectiveFromDate = UCL.EffectiveFromDate 
INNER JOIN Assets A ON A.Id = UCL.AssetId  
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN ContractCustomerLocations CCL ON CL.CustomerLocationId = CCL.CustomerLocationId AND CCL.ContractId = @ContractId
		AND CCL.UpfrontTaxAssessedInLegacySystem = 1;  
  
INSERT INTO #LeaseAssetFromLocations  
SELECT  
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber   
,MAXAL.AssetId 
,S.ShortName  
,L.JurisdictionId 
FROM #LeaseCustomerLocations MAXAL  
JOIN #UniqueLeaseCustomerLocations AL ON   
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate 
JOIN Locations L ON L.Id = MAXAL.LocationId  
JOIN States S ON S.Id = L.StateId   
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate  
END;  
  
DELETE FROM #LeaseAssetFromLocations  
WHERE RowNumber <> 1  
;  
  
WITH CTE_AssetLocations As  
(  
SELECT  
	CTE.LocationId AS LocationId  
	,states.ShortName AS MainDivision  
	,countries.ShortName AS Country  
	,Loc.City AS City  
	,Loc.IsActive AS IsLocationActive  
	,CTE.EffectiveFromDate AS EffectiveFromDate  
	,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported 
	,CTE.SaleLeasebackCode  
	,CTE.IsElectronicallyDelivered  
	,CTE.ReciprocityAmount_Amount  
	,CTE.LienCredit_Amount  
	,CTE.GrossVehicleWeight  
	,CTE.IsMultiComponent  
	,CTE.AssetId  
	,Loc.JurisdictionId AS TaxJurisdictionId  
	,Loc.Code
	,Loc.TaxExemptRuleId  
	,CTE.UpfrontTaxAssessedInLegacySystem
FROM  
#AssetLevelLoactionDetails CTE  
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id  
INNER JOIN States states ON Loc.StateId = states.Id  
INNER JOIN Countries countries ON states.CountryId = countries.Id  
)  
SELECT  
      ROW_NUMBER() OVER (PARTITION BY Loc.AssetId ORDER BY   
    CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,  
    CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,   
    CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num 
   ,P.TaxAreaEffectiveDate
   ,P.TaxAreaId
   ,Loc.LocationId  
   ,Loc.MainDivision  
   ,Loc.City  
   ,Loc.Country  
   ,Loc.EffectiveFromDate
   ,Loc.IsLocationActive  
   ,Loc.IsVertexSupported
   ,Loc.SaleLeasebackCode  
   ,Loc.IsElectronicallyDelivered  
   ,Loc.ReciprocityAmount_Amount  
   ,Loc.LienCredit_Amount  
   ,Loc.GrossVehicleWeight  
   ,Loc.IsMultiComponent  
   ,Loc.AssetId  
   ,Loc.TaxJurisdictionId  
   ,Loc.Code  
   ,Loc.TaxExemptRuleId
   ,Loc.UpfrontTaxAssessedInLegacySystem
 INTO #AllTaxAreaIdsForLocation  
 FROM CTE_AssetLocations Loc  
 LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId  
;  
  
CREATE NONCLUSTERED INDEX IX_AssetId ON #AllTaxAreaIdsForLocation(AssetId)  
  
SELECT   
 ContractId, BusinessCode   
 INTO #SalesTaxGLOrgStructureConfigs   
FROM   
(SELECT TOP 1 @ContractId ContractId, GLOrgStructureConfigs.BusinessCode As BusinessCode  
FROM LeaseFinances  
 INNER JOIN GLOrgStructureConfigs  
  ON GLOrgStructureConfigs.LegalEntityId = LeaseFinances.LegalEntityId  
  AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId  
  AND GLOrgStructureConfigs.LineofBusinessId = LeaseFinances.LineofBusinessId  
  AND GLOrgStructureConfigs.IsActive = 1  
WHERE LeaseFinances.ContractId = @ContractId AND LeaseFinances.IsCurrent = 1  
UNION  
SELECT TOP 1 @ContractId ContractId, GLOrgStructureConfigs.BusinessCode As BusinessCode  
FROM LoanFinances  
 INNER JOIN GLOrgStructureConfigs  
  ON GLOrgStructureConfigs.LegalEntityId = LoanFinances.LegalEntityId  
  AND GLOrgStructureConfigs.CostCenterId = LoanFinances.CostCenterId  
  AND GLOrgStructureConfigs.LineofBusinessId = LoanFinances.LineofBusinessId  
  AND GLOrgStructureConfigs.IsActive = 1  
WHERE LoanFinances.ContractId = @ContractId AND LoanFinances.IsCurrent = 1) AS TEMP;  
;  

SELECT AD.Id AS AssetId,
AD.AcquisitionLocationId,
L.TaxAreaId AS AcquisitionLocationTaxAreaId,
L.City AS AcquisitionLocationCity,
S.ShortName AS AcquisitionLocationMainDivision,
C.ShortName AS AcquisitionLocationCountry
INTO #SellerLocationDetails
FROM #AssetDetails AD
INNER JOIN Locations L ON L.Id = AD.AcquisitionLocationId 
INNER JOIN States S  ON S.Id = L.StateId
INNER JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
 
;WITH CTE_TaxAreaIdForLocationAsOfDueDate AS  
(  
 SELECT 
    TaxAreaEffectiveDate 
   ,TaxAreaId
   ,LocationId  
   ,MainDivision  
   ,City  
   ,Country  
   ,EffectiveFromDate
   ,IsLocationActive  
   ,IsVertexSupported
   ,SaleLeasebackCode    
   ,IsElectronicallyDelivered  
   ,ReciprocityAmount_Amount  
   ,LienCredit_Amount  
   ,GrossVehicleWeight  
   ,IsMultiComponent  
   ,AssetId  
   ,TaxJurisdictionId  
   ,Code  
   ,TaxExemptRuleId
   ,UpfrontTaxAssessedInLegacySystem
 FROM #AllTaxAreaIdsForLocation  
 WHERE Row_Num = 1  
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM #AssetDetails A
JOIN AssetSerialNumbers ASN on A.Id = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)  
SELECT 
    ISNULL(CCo.ISO,'USD') AS Currency  
   ,LE.TaxPayer AS Company  
   ,ACC.ClassCode AS Product
   ,P.PartyNumber AS CustomerCode
   ,Loc.LocationId AS LocationId  
   ,Loc.MainDivision AS MainDivision  
   ,Loc.Country AS Country  
   ,Loc.City AS City  
   ,Loc.TaxAreaId AS TaxAreaId  
   ,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate  
   ,Loc.IsLocationActive  
   ,Loc.IsVertexSupported AS IsVertexSupportedLocation  
   ,ISNULL(@ContractType,Case WHEN CapitalLeaseType ='ConditionalSales' THEN 'CSC' ELSE 'FMV' END) AS ContractType   
   ,A.Id AS AssetId 
   ,TTC.TransferCode AS TitleTransferCode  
   ,Loc.EffectiveFromDate AS LocationEffectiveDate  
   ,@ReceivableTypeName  AS ReceivableType
   ,ToState.ShortName ToState  
   ,Fromloc.ShortName FromState  
   ,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType  
   ,CAST(Loc.SaleLeasebackCode AS NVARCHAR) AS SaleLeasebackCode  
   ,ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered  
   ,Loc.LienCredit_Amount  
   ,Loc.ReciprocityAmount_Amount  
   ,ISNULL(Loc.GrossVehicleWeight ,0) GrossVehicleWeight  
   ,Loc.IsMultiComponent   
   ,Loc.Code LocationCode  
   ,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel  
   ,ISNULL(Loc.TaxJurisdictionId,FromLoc.TaxJurisdictionId) AS TaxJurisdictionId  
   ,@TaxAssessmentLevel TaxAssessmentLevel  
   ,STOrg.BusinessCode BusCode  
   ,DTTFRT.TaxTypeId  
   ,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber  
   ,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode  
   ,@ReceivableTypeName AS TaxReceivableName  
   ,AU.Usage   
   ,cont.DealProductTypeId
   ,CASE WHEN @IsCityTaxExempt =1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN CAST (1 AS bit) ELSE CAST (0 AS bit) END As IsCityTaxExempt
   ,CASE WHEN @IsCountryTaxExempt = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN CAST (1 AS bit) ELSE  CAST (0 AS bit) END As IsCountryTaxExempt
   ,CASE WHEN @IsCountyTaxExempt =1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN CAST (1 AS bit) ELSE CAST (0 AS bit) END As IsCountyTaxExempt
   ,CASE WHEN @IsStateTaxExempt =1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN CAST (1 AS bit) ELSE CAST (0 AS bit) END As IsStateTaxExempt
   ,@ReceivableTypeId AS ReceivableTypeId
   ,AT.Id [AssetTypeId]
   ,AT.Name [AssetTypeName]
   ,A.IsTaxExempt [IsAssetTaxExempt]
   ,CC.Class As ClassCode
   ,AC.CollateralCode
   ,SALD.AcquisitionLocationId
   ,SALD.AcquisitionLocationTaxAreaId
   ,SALD.AcquisitionLocationCity
   ,SALD.AcquisitionLocationMainDivision
   ,SALD.AcquisitionLocationCountry
   ,ISNULL(A.UsageCondition,'_') as AssetUsageCondition
   ,ISNULL(ASN.SerialNumber,'_') as AssetSerialOrVIN
   ,L.IsAssessSalesTaxAtSKULevel
   ,Loc.UpfrontTaxAssessedInLegacySystem
FROM  
   #AssetDetails AD   
   INNER JOIN Assets A ON AD.Id = A.Id
   INNER JOIN LegalEntities L ON A.LegalEntityId = L.Id
   INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
   LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
   LEFT JOIN CTE_AssetSerialNumberDetails ASN ON A.Id =  ASN.AssetId 
   LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
   LEFT JOIN Contracts cont ON cont.Id = @ContractId  
   LEFT JOIN Currencies CR ON Cont.CurrencyId =  CR.Id   
   LEFT JOIN CurrencyCodes CCo ON CR.CurrencyCodeId = CCo.Id
   LEFT JOIN LegalEntities LE ON @LegalEntityId = LE.Id  
   LEFT JOIN Customers LeaseCust ON LeaseCust.Id = @CustomerId
   LEFT JOIN Parties P ON LeaseCust.Id = P.Id  
   LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id  
   LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id  
   LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON A.Id = Loc.AssetId  
   LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id  
   LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id  
   LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON ToState.CountryId = DTTFRT.CountryId AND DTTFRT.ReceivableTypeId = @ReceivableTypeId
   LEFT JOIN #LeaseAssetFromLocations FromLoc ON  A.Id = FromLoc.AssetId 
   LEFT JOIN CustomerClasses CC ON LeaseCust.CustomerClassId = CC.Id
   LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id  
   LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id  
   LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id  
   LEFT JOIN #SalesTaxGLOrgStructureConfigs STOrg ON STOrg.ContractId = @ContractId  
   LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId  
   LEFT JOIN TaxExemptRules AssetRule ON A.TaxExemptRuleId = AssetRule.Id   
   LEFT JOIN TaxExemptRules LocationRule ON Loc.TaxExemptRuleId = LocationRule.Id
   LEFT JOIN #SellerLocationDetails SALD ON SALD.AssetId = A.Id
;

DROP TABLE #SellerLocationDetails;
END

GO
