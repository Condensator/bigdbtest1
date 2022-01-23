SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetDetailsForLeaseTaxAssessment]
(
@CustomerId				BIGINT,
@AssessmentDate		DATE,
@LegalEntityId			BIGINT,
@ContractId				BIGINT,
@LeaseType				NVARCHAR(40) = NULL,
@MaturityDate			DATE = NULL,
@AssetDetails			LeaseTaxAssetIdTableType READONLY,
@TaxAssessmentLevel		NVARCHAR(40) = NULL,
@BusCode				NVARCHAR(100) = NULL,
@SequenceNumber		    NVARCHAR(80) = NULL,
@DealProductName NVARCHAR(40) = NULL,
@IsSalesTaxExempt BIT = 0,
@CommencementDate		DATE,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex  = 'Vertex';
CREATE TABLE #AssetSerialNumbers
	(
		AssetId BIGINT,
		SerialNumber nvarchar(100)
	)

	INSERT INTO 
		#AssetSerialNumbers
	SELECT 
		AssetId  , 
		CASE WHEN COUNT(ASN.SerialNumber) =1 THEN MAX(ASN.SerialNumber) ELSE @AssetMultipleSerialNumberType END  as SerialNumber 
	FROM 
		AssetSerialNumbers ASN 
		INNER JOIN @AssetDetails Asset ON ASN.AssetId = Asset.Id 
	WHERE
		ASN.IsActive = 1  group by AssetId


DECLARE @DueDate DATE = @AssessmentDate;
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
CREATE TABLE #AssetLevelReceivableDetails
(
EffectiveFromDate  DATE,
DueDate            DATE,
LocationId         BIGINT INDEX IX_LocationId,
AssetId            BIGINT,
AssetLocationId    BIGINT,
SaleLeasebackCode  NVARCHAR(40),
IsElectronicallyDelivered BIT,
ReciprocityAmount_Amount DECIMAL,
ReciprocityAmount_Currency NVARCHAR(20),
LienCredit_Amount DECIMAL,
LienCredit_Currency	NVARCHAR(20),
GrossVehicleWeight INT,
IsMultiComponent BIT,
TaxBasisType NVARCHAR(5)
)
CREATE TABLE #LeaseAssetFromLocations
(
RowNumber			INT NULL,
AssetId				BIGINT NULL INDEX IX_AssetId,
EffectiveFromDate	DATE NULL,
LocationId			BIGINT NULL,
ShortName			NVARCHAR(100) NULL,
TaxJurisdictionId   BIGINT NULL,
TaxBasisType		NVARCHAR(5) NULL
)
IF @TaxAssessmentLevel <> 'Customer'
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@DueDate DueDate,
AL.LocationId AS LocationId,
AL.AssetId AS AssetId,
AL.Id AS AssetLocationId,
AL.TaxBasisType
INTO #LeaseAssetLocations
FROM
@AssetDetails AIds
INNER JOIN AssetLocations AL ON AL.AssetId = AIds.Id AND AL.IsActive = 1;
SELECT
MAXAL.AssetId
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #UniqueLeaseAssetLocations
FROM  #LeaseAssetLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= @AssessmentDate
GROUP BY
MAXAL.AssetId;
INSERT INTO #UniqueLeaseAssetLocations
SELECT
MINAL.AssetId
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #LeaseAssetLocations MINAL
WHERE MINAL.EffectiveFromDate > @AssessmentDate
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #UniqueLeaseAssetLocations)
GROUP BY
MINAL.AssetId;
CREATE NONCLUSTERED INDEX IX_AssetIdEffectiveDate ON #UniqueLeaseAssetLocations(AssetId,EffectiveFromDate)
;WITH CTE_AssetLocation AS
(
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.AssetLocationId) AssetLocationId
,LAL.DueDate
FROM #UniqueLeaseAssetLocations AS GAL
JOIN #LeaseAssetLocations LAL ON GAL.AssetId = LAL.AssetId AND GAL.EffectiveFromDate = LAL.EffectiveFromDate
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
)
INSERT INTO #AssetLevelReceivableDetails
(EffectiveFromDate,
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
IsMultiComponent,
TaxBasisType)
SELECT
GAL.EffectiveFromDate
,GAL.DueDate
,AL.LocationId
,GAL.AssetId
,GAL.AssetLocationId
,SLBC.Code
,A.IsElectronicallyDelivered
,AL.ReciprocityAmount_Currency
,AL.ReciprocityAmount_Amount
,AL.LienCredit_Amount
,AL.LienCredit_Currency
,A.GrossVehicleWeight
,A.IsParent
,AL.TaxBasisType
FROM CTE_AssetLocation GAL
INNER JOIN AssetLocations AL ON AL.Id = GAL.AssetLocationId
INNER JOIN Assets A ON A.Id = AL.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id;
INSERT INTO #LeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.EffectiveFromDate AS EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.JurisdictionId
,MAXAL.TaxBasisType
FROM #LeaseAssetLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN #UniqueLeaseAssetLocations AL ON
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
;
END
ELSE
BEGIN
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
@DueDate DueDate,
AL.LocationId AS LocationId,
AIds.Id AS AssetId,
AL.Id AS AssetLocationId,
AL.TaxBasisType
INTO #LeaseCustomerLocations
FROM
@AssetDetails AIds
CROSS JOIN CustomerLocations AL
WHERE AL.IsActive = 1 AND AL.CustomerId = @CustomerId;
SELECT
MAXAL.AssetId
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #UniqueLeaseCustomerLocations
FROM  #LeaseCustomerLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= @AssessmentDate
GROUP BY
MAXAL.AssetId;
INSERT INTO #UniqueLeaseCustomerLocations
SELECT
MINAL.AssetId
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #LeaseCustomerLocations MINAL
WHERE MINAL.EffectiveFromDate > @AssessmentDate
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #UniqueLeaseCustomerLocations)
GROUP BY
MINAL.AssetId;
WITH CTE_CustomerLocation AS
(
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.AssetLocationId) AssetLocationId
,LAL.DueDate
FROM #UniqueLeaseCustomerLocations AS GAL
JOIN #LeaseCustomerLocations LAL ON GAL.EffectiveFromDate = LAL.EffectiveFromDate AND GAL.AssetId = LAL.AssetId
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
)
INSERT INTO #AssetLevelReceivableDetails
(EffectiveFromDate,
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
IsMultiComponent,
TaxBasisType)
SELECT
GAL.EffectiveFromDate
,GAL.DueDate
,AL.LocationId
,GAL.AssetId
,GAL.AssetLocationId
,SLBC.Code
,A.IsElectronicallyDelivered
,A.PropertyTaxCost_Currency
,0.00
,0.00
,A.PropertyTaxCost_Currency
,A.GrossVehicleWeight
,A.IsParent
,AL.TaxBasisType
FROM CTE_CustomerLocation GAL
INNER JOIN CustomerLocations AL ON AL.Id = GAL.AssetLocationId
INNER JOIN Assets A ON A.Id = GAL.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id;
INSERT INTO #LeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId ORDER BY MAXAL.EffectiveFromDate DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.EffectiveFromDate AS EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.JurisdictionId
,MAXAL.TaxBasisType
FROM #LeaseCustomerLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN #UniqueLeaseCustomerLocations AL ON
MAXAL.AssetId = AL.AssetId AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
END;
DELETE FROM #LeaseAssetFromLocations
WHERE RowNumber <> 1
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
,CTE.AssetLocationId AS AssetLocationId,
CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
,CTE.SaleLeasebackCode
,CTE.IsElectronicallyDelivered
,CTE.ReciprocityAmount_Currency
,CTE.ReciprocityAmount_Amount
,CTE.LienCredit_Amount
,CTE.LienCredit_Currency
,CTE.GrossVehicleWeight
,CTE.IsMultiComponent
,CTE.AssetId
,Loc.JurisdictionId AS TaxJurisdictionId
,CTE.TaxBasisType
,Loc.Code
FROM
#AssetLevelReceivableDetails CTE
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
)
SELECT
ROW_NUMBER() OVER (PARTITION BY Loc.AssetId ORDER BY
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
Loc.LocationId,
Loc.MainDivision,
Loc.City,
Loc.Country,
Loc.EffectiveFromDate,
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
,Loc.AssetId
,Loc.TaxJurisdictionId
,Loc.TaxBasisType
,Loc.Code
INTO #AllTaxAreaIdsForLocation
FROM CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
;
CREATE NONCLUSTERED INDEX IX_AssetId ON #AllTaxAreaIdsForLocation(AssetId)
SELECT
*
INTO #SalesTaxGLOrgStructureConfigs
FROM
(SELECT TOP 1 @ContractId ContractId, ISNULL(GLOrgStructureConfigs.BusinessCode,@BusCode) BusinessCode
FROM LeaseFinances
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = LeaseFinances.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = LeaseFinances.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
WHERE LeaseFinances.ContractId = @ContractId AND LeaseFinances.IsCurrent = 1
UNION
SELECT TOP 1 @ContractId ContractId, ISNULL(GLOrgStructureConfigs.BusinessCode,@BusCode) BusinessCode
FROM LoanFinances
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = LoanFinances.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LoanFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = LoanFinances.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
WHERE LoanFinances.ContractId = @ContractId AND LoanFinances.IsCurrent = 1) AS TEMP;
;
SELECT DISTINCT RD.AssetId, CAST(1 AS BIT) IsUCTaxExempt
INTO #UpfrontAssetDetails FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN #AllTaxAreaIdsForLocation CBRD ON RD.AssetId = CBRD.AssetId
JOIN AssetLocations AL ON CBRD.AssetLocationId = AL.Id
JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
JOIN LeaseFinances LF ON LF.ContractId = R.EntityId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Contracts CT ON LF.ContractId = CT.Id
WHERE RT.IsRental = 1 AND CBRD.AssetId IS NOT NULL AND R.IsActive = 1
AND AL.TaxBasisType = 'UC' AND R.DueDate  <= LFD.CommencementDate
AND CBRD.Row_Num = 1
AND CT.SequenceNumber <> @SequenceNumber
SELECT AD.Id AS AssetId,
AD.AcquisitionLocationId,
L.TaxAreaId AS AcquisitionLocationTaxAreaId,
L.City AS AcquisitionLocationCity,
S.ShortName AS AcquisitionLocationMainDivision,
C.ShortName AS AcquisitionLocationCountry
INTO #SellerLocationDetails
FROM @AssetDetails AD
INNER JOIN Locations L ON L.Id = AD.AcquisitionLocationId
INNER JOIN States S  ON S.Id = L.StateId
INNER JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
;WITH CTE_TaxAreaIdForLocationAsOfDueDate AS
(
SELECT *
FROM #AllTaxAreaIdsForLocation
WHERE Row_Num = 1
)
SELECT DISTINCT
	   0 AS ReceivableDetailId
	  ,0 AS ReceivableId
	  ,@DueDate AS DueDate
	  ,AD.IsRental AS IsRental
	  ,CASE WHEN AD.IsRental = 1 THEN ACC.ClassCode ELSE AD.ReceivableType END AS Product
	  ,0.00 AS FairMarketValue
	  ,0.00 AS Cost
	  ,0.00 AS AmountBilledToDate
	  ,0.00 AS ExtendedPrice
	  ,ISNULL(CCo.ISO,'USD') AS Currency
	  ,CONVERT (BIT,1) IsAssetBased
	  ,CONVERT(BIT,0) IsLeaseBased
	  ,CASE WHEN A.IsTaxExempt IS NULL THEN CAST(0 AS BIT) ELSE A.IsTaxExempt END AS IsExemptAtAsset
	  ,CASE WHEN (AD.ReceivableType = 'BuyOut' OR AD.ReceivableType = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS TransactionType
	  ,LE.TaxPayer AS Company
	  ,P.PartyNumber AS CustomerCode
	  ,LeaseCust.Id  AS CustomerId
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
	  ,ISNULL(@MaturityDate,LFD.MaturityDate) AS MaturityDate	   
	  ,CASE WHEN LA.NBV_Amount IS NULL THEN 0.00
	   ELSE LA.NBV_Amount END AS CustomerCost
	  ,ISNULL(LF.IsSalesTaxExempt,@IsSalesTaxExempt) AS IsExemptAtLease
	  ,(LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount) AS LessorRisk
	  ,Loc.AssetLocationId AS AssetLocationId
	  ,Loc.LocationStatus AS LocationStatus
	  ,CAST(0 AS BIT) AS IsExemptAtSundry
	  ,NULL AS ReceivableTaxId
	  ,Loc.IsVertexSupported AS IsVertexSupportedLocation
	  ,ISNULL(@ContractType,Case WHEN CapitalLeaseType ='ConditionalSales' THEN 'CSC' ELSE 'FMV' END) AS ContractType 
	  ,ISNULL(cont.SequenceNumber,@SequenceNumber) AS LeaseUniqueId
	  ,AD.ReceivableCode AS SundryReceivableCode
	  ,ACC.ClassCode AS AssetType
	  ,A.Id AS AssetId
	  ,CASE WHEN @LeaseType IS NULL OR @LeaseType = '' THEN DPT.LeaseType ELSE @LeaseType END AS LeaseType
	  ,CASE WHEN AD.IsRental = 1 THEN 
			ISNULL(CAST((DATEDIFF(day,ISNULL(@AssessmentDate,LFD.CommencementDate),ISNULL(@MaturityDate,LFD.MaturityDate)) + 1) AS DECIMAL(10,2)), 0.00) 
	   ELSE CAST(0.00 AS DECIMAL(10,2))  END AS LeaseTerm
	  ,TTC.TransferCode AS TitleTransferCode
	  ,Loc.EffectiveFromDate AS LocationEffectiveDate
	  ,CASE WHEN AD.ReceivableType IS NULL OR AD.ReceivableType = '' THEN  @ReceivableTypeName
	   ELSE AD.ReceivableType END AS ReceivableType
	  ,RT.Id ReceivableTypeId
	  ,LE.Id LegalEntityId
	  ,0 Id
	  ,CAST(0 AS BIT) IsManuallyAssessed
	  ,NULL TransactionCode
	  ,ISNULL(Loc.TaxBasisType,FromLoc.TaxBasisType) TaxBasisType
      ,ToState.ShortName ToState
	  ,Fromloc.ShortName FromState
	  ,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
	  ,CAST(Loc.SaleLeasebackCode AS NVARCHAR) AS SaleLeasebackCode
	  ,ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
	  ,Loc.LienCredit_Amount
	  ,Loc.LienCredit_Currency
	  ,Loc.ReciprocityAmount_Amount
	  ,Loc.ReciprocityAmount_Currency
	  ,ISNULL(Loc.GrossVehicleWeight ,0) GrossVehicleWeight
	  ,Loc.IsMultiComponent 
	  ,Loc.Code LocationCode
	  ,CAST(STELC.Name AS NVARCHAR) AS SalesTaxExemptionLevel
	  ,ISNULL(@CommencementDate,LFD.CommencementDate) AS CommencementDate
	  ,ISNULL(AD.AssetTypeId, AT.Id) AssetTypeId
	  ,AD.LeaseTaxAssetId
	  ,ISNULL(Loc.TaxJurisdictionId,FromLoc.TaxJurisdictionId) AS TaxJurisdictionId
	  ,LF.Id LeaseFinanceId
	  ,@TaxAssessmentLevel TaxAssessmentLevel
	  ,STOrg.BusinessCode BusCode
	  ,DTTFRT.TaxTypeId
	  ,AD.StateTaxTypeId
	  ,AD.CountyTaxTypeId
	  ,AD.CityTaxTypeId
	  ,ISNULL(AC.CollateralCode,AD.AssetCollateralCode)  AS AssetCatalogNumber
	  ,UA.IsUCTaxExempt
	  ,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	  ,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
	  ,@ReceivableTypeName AS TaxReceivableName
	  ,AU.Usage
	  ,SALD.AcquisitionLocationId
	  ,SALD.AcquisitionLocationTaxAreaId
	  ,SALD.AcquisitionLocationCity
	  ,SALD.AcquisitionLocationMainDivision
	  ,SALD.AcquisitionLocationCountry
	  ,A.UsageCondition AS AssetUsageCondition
	  ,ASN.SerialNumber AS AssetSerialOrVIN
	  ,AD.SalesTaxRemittanceResponsibility AS SalesTaxRemittanceResponsibility
FROM
@AssetDetails AD
INNER JOIN Assets A ON AD.Id = A.Id
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN ReceivableTypes RT ON AD.ReceivableType = RT.Name
LEFT JOIN Contracts cont ON cont.Id = @ContractId
LEFT JOIN Currencies CR ON Cont.CurrencyId =  CR.Id
LEFT JOIN CurrencyCodes CCo ON CR.CurrencyCodeId = CCo.Id
LEFT JOIN LeaseFinances LF ON cont.Id = LF.ContractId AND LF.IsCurrent = 1
LEFT JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
LEFT JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND AD.Id = LA.AssetId
LEFT JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN LegalEntities LE ON @LegalEntityId = LE.Id
LEFT JOIN Customers LeaseCust ON (LeaseCust.Id = @CustomerId OR LF.CustomerId = LeaseCust.Id)
LEFT JOIN Parties P ON LeaseCust.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN CTE_TaxAreaIdForLocationAsOfDueDate Loc ON A.Id = Loc.AssetId
LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RT.Id = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
LEFT JOIN #LeaseAssetFromLocations FromLoc ON  A.Id = FromLoc.AssetId
LEFT JOIN CustomerClasses CC ON LeaseCust.CustomerClassId = CC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id
LEFT JOIN #SalesTaxGLOrgStructureConfigs STOrg ON STOrg.ContractId = @ContractId
LEFT JOIN #UpfrontAssetDetails UA ON AD.Id= UA.AssetId
LEFT JOIN AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN #SellerLocationDetails SALD ON SALD.AssetId = A.Id
LEFT JOIN #AssetSerialNumbers ASN ON A.Id =  ASN.AssetId 
;
DROP TABLE #SellerLocationDetails;
DROP TABLE #AssetSerialNumbers;

END

GO
