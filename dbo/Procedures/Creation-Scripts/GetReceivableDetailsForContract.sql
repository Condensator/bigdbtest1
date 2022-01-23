SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROC [dbo].[GetReceivableDetailsForContract]
(
@ContractTable ContractTableType READONLY,
@CapitalizedSalesTaxAssetType NVARCHAR(200) = NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

--DECLARE @CapitalizedSalesTaxAssetTypeValue NVARCHAR(200) = NULL;
--SET @CapitalizedSalesTaxAssetTypeValue = (SELECT Value FROM GlobalParameters
--										  WHERE Category = 'LeaseAsset'
--										  AND Name = 'CapitalizedSalesTaxAssetType')
SELECT * INTO #ContractIdTable FROM @ContractTable
CREATE INDEX IX_ContractID ON #ContractIdTable(ContractId,CustomerId)
CREATE TABLE #LocationDetailsForLeaseAssets
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
CustomerId       BIGINT,
TaxJurisdictionId BIGINT,
TaxTypeId			BIGINT,
StateTaxTypeId		BIGINT,
CountyTaxTypeId		BIGINT,
CityTaxTypeId		BIGINT,
StateId				BIGINT,
ReceivableCodeId	BIGINT,
LocationCode NVARCHAR(100)
)
CREATE INDEX IX_ReceivableCodeId ON #LocationDetailsForLeaseAssets(ReceivableCodeId)
CREATE TABLE #AssetsInLease
(
AssetId							  BIGINT,
CustomerCost				  DECIMAL(16,2),
FixedTermRentalAmount      DECIMAL(16,2),
LeaseAssetId					  BIGINT,
ContractId       BIGINT,
CustomerId       BIGINT
)
CREATE TABLE #ReceivableIds
(
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
TaxAssessmentLevel NVARCHAR(15)
)
CREATE CLUSTERED INDEX IX_ReceivableId ON #ReceivableIds(ReceivableId);
CREATE TABLE #AssetLocation
(   AssetId            BIGINT,
EffectiveFromDate  DATETIME,
AssetLocationId    BIGINT,
DueDate          DATETIME,
ReceivableDetailId BIGINT
)
CREATE TABLE #CustomerLocation
(   AssetId            BIGINT,
EffectiveFromDate  DATETIME,
CustomerLocationId    BIGINT,
DueDate          DATETIME,
ReceivableDetailId BIGINT
)
CREATE TABLE #AssetLevelReceivableDetails
(
EffectiveFromDate  DATETIME,
DueDate            DATETIME,
LocationId         BIGINT,
AssetId            BIGINT,
ReceivableDetailId BIGINT,
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
AssetLocationTaxBasisType NVARCHAR(10),
CustomerLocationId    BIGINT,
)
CREATE TABLE #ContractBasedReceivableDetail
(
	   ReceivableDetailId				BIGINT,
	   ReceivableId						BIGINT,
	   DueDate							DATE,
	   IsRental							BIT,
	   Product							NVARCHAR(100),
	   FairMarketValue					DECIMAL(16,2),
	   Cost								DECIMAL(16,2),
	   AmountBilledToDate				DECIMAL(16,2),
	   ExtendedPrice					DECIMAL(16,2),
	   Currency							NVARCHAR(20),
	   IsAssetBased						BIT,
	   IsLeaseBased						BIT,
	   IsExemptAtAsset					BIT,
	   TransactionType					NVARCHAR(100),
	   Company							NVARCHAR(100),
	   CustomerCode						NVARCHAR(100),
	   CustomerId						BIGINT,
	   ClassCode						NVARCHAR(100),
	   LocationId						BIGINT,
	   LocationCode						NVARCHAR(200),
	   MainDivision						NVARCHAR(100),
	   Country							NVARCHAR(100),
	   City								NVARCHAR(100),
	   TaxAreaId						BIGINT,
	   TaxAreaEffectiveDate				DATE,
	   IsLocationActive					BIT,
	   ContractId						BIGINT,
	   RentAccrualStartDate				DATE,
	   MaturityDate						DATE,
	   CustomerCost						DECIMAL(16,2),
	   IsExemptAtLease					BIT,
	   LessorRisk						DECIMAL(16,2),
	   AssetLocationId					BIGINT,
	   LocationStatus					NVARCHAR(100),
	   IsExemptAtSundry					BIT,
	   ReceivableTaxId					BIGINT,
	   IsVertexSupportedLocation		BIT,
	   ContractType						NVARCHAR(100),
	   LeaseUniqueId					NVARCHAR(100),
	   SundryReceivableCode				NVARCHAR(100),
	   AssetType						NVARCHAR(100),
	   AssetId							BIGINT,
	   LeaseType						NVARCHAR(100),
	   LeaseTerm						DECIMAL(16,2),
	   TitleTransferCode				NVARCHAR(100),
	   LocationEffectiveDate			DATE,
	   ReceivableType					NVARCHAR(100),
	   LegalEntityId					BIGINT,
	   Id								BIGINT,
	   IsManuallyAssessed				BIT,
	   TransactionCode					NVARCHAR(100),
	   TaxBasisType						NVARCHAR(100),
       ToState							NVARCHAR(100),
	   FromState						NVARCHAR(100),
	   TaxRemittanceType				NVARCHAR(100),
	   SaleLeasebackCode				NVARCHAR(100),
	   IsElectronicallyDelivered		BIT,
	   LienCredit_Amount				DECIMAL(16,2),
	   LienCredit_Currency				NVARCHAR(10),
	   ReciprocityAmount_Amount			DECIMAL(16,2),
	   ReciprocityAmount_Currency		NVARCHAR(10),
	   GrossVehicleWeight				INT,
	   IsMultiComponent					BIT,
	   SalesTaxExemptionLevel			NVARCHAR(20),
	   CommencementDate					DATE,
	   IsExemptAtReceivableCode			BIT,
	   ContractTypeValue				NVARCHAR(100),
	   GlTemplateId						BIGINT,
	   AssetLocationTaxBasisType		NVARCHAR(100),
	   AssetTypeId						BIGINT,
	   AssetTypeName					NVARCHAR(1000),
	   IsCapitalizedSalesTaxAsset		BIT,
	   BusCode							NVARCHAR(40),
	   IsSyndicated						BIT,
	   TaxJurisdictionId				BIGINT,
	   ReceivableTypeId					BIGINT,
	   HorsePower						DECIMAL(16,2),
	   EngineType						NVARCHAR(100),
	   ReceivableCodeId					BIGINT,
	   AssetCatalogNumber				NVARCHAR(100),
	   CustomerLocationId				BIGINT,
	   TaxAssessmentLevel				NVARCHAR(100),
	   IsRentalReceivableOnSameDate		BIT,
	   LienDate							DATE,
	   IsContractCapitalizeUpfront		BIT,
	   IsPrepaidUpfrontTax				BIT,
	   TaxTypeId						BIGINT NULL,
	   StateTaxTypeId					BIGINT NULL,
	   CountyTaxTypeId					BIGINT NULL,
	   CityTaxTypeId					BIGINT NULL,
	   StateId							BIGINT NULL,
	   UpfrontTaxMode					NVARCHAR(100),
	   DealProductTypeId				BIGINT NULL,
	   TaxRegistrationNumber			NVARCHAR(100),
	   ISOCountryCode					NVARCHAR(100),
	   SyndicationType					NVARCHAR(100),
	   CountryTaxExempt					BIT,
	   StateTaxExempt					BIT,
	   CityTaxExempt					BIT,
	   CountyTaxExempt					BIT,
	   CountryTaxExemptRule				NVARCHAR(200),
	   StateTaxExemptRule				NVARCHAR(200),
	   CityTaxExemptRule				NVARCHAR(200),
	   CountyTaxExemptRule				NVARCHAR(200),
	   PreviousTaxBasisType				NVARCHAR(10) NULL,
	   PreviousUpfrontTaxMode			NVARCHAR(12) NULL,
	   SalesTaxRemittanceResponsibility NVARCHAR(8),
	   AssetSerialOrVIN NVARCHAR(100) NULL,
	   AssetUsageCondition NVARCHAR(4),
	   AcquisitionLocationId BIGINT NULL,
	   AcquisitionLocationTaxAreaId BIGINT NULL,
	   AcquisitionLocationCity NVARCHAR(100) NULL,
	   AcquisitionLocationMainDivision NVARCHAR(100) NULL,
	   AcquisitionLocationCountry NVARCHAR(100) NULL,
	   Usage NVARCHAR(40) NULL
)
CREATE TABLE #NonAssetBasedReceivableDetail
(
	   ReceivableDetailId				BIGINT,
	   ReceivableId						BIGINT,
	   DueDate							DATE,
	   IsRental							BIT,
	   Product							NVARCHAR(100),
	   FairMarketValue					DECIMAL(16,2),
	   Cost								DECIMAL(16,2),
	   AmountBilledToDate				DECIMAL(16,2),
	   ExtendedPrice					DECIMAL(16,2),
	   Currency							NVARCHAR(20),
	   IsAssetBased						BIT,
	   IsLeaseBased						BIT,
	   IsExemptAtAsset					BIT,
	   TransactionType					NVARCHAR(100),
	   Company							NVARCHAR(100),
	   CustomerCode						NVARCHAR(100),
	   CustomerId						BIGINT,
	   ClassCode						NVARCHAR(100),
	   LocationId						BIGINT,
	   LocationCode						NVARCHAR(200),
	   MainDivision						NVARCHAR(100),
	   Country							NVARCHAR(100),
	   City								NVARCHAR(100),
	   TaxAreaId						BIGINT,
	   TaxAreaEffectiveDate				DATE,
	   IsLocationActive					BIT,
	   ContractId						BIGINT,
	   RentAccrualStartDate				DATE,
	   MaturityDate						DATE,
	   CustomerCost						DECIMAL(16,2),
	   IsExemptAtLease					BIT,
	   LessorRisk						DECIMAL(16,2),
	   AssetLocationId					BIGINT,
	   LocationStatus					NVARCHAR(100),
	   IsExemptAtSundry					BIT,
	   ReceivableTaxId					BIGINT,
	   IsVertexSupportedLocation		BIT,
	   ContractType						NVARCHAR(100),
	   LeaseUniqueId					NVARCHAR(100),
	   SundryReceivableCode				NVARCHAR(100),
	   AssetType						NVARCHAR(100),
	   AssetId							BIGINT,
	   LeaseType						NVARCHAR(100),
	   LeaseTerm						DECIMAL(16,2),
	   TitleTransferCode				NVARCHAR(100),
	   LocationEffectiveDate			DATE,
	   ReceivableType					NVARCHAR(100),
	   LegalEntityId					BIGINT,
	   Id								BIGINT,
	   IsManuallyAssessed				BIT,
	   TransactionCode					NVARCHAR(100),
	   TaxBasisType						NVARCHAR(100),
       ToState							NVARCHAR(100),
	   FromState						NVARCHAR(100),
	   TaxRemittanceType				NVARCHAR(100),
	   SaleLeasebackCode				NVARCHAR(100),
	   IsElectronicallyDelivered		BIT,
	   LienCredit_Amount				DECIMAL(16,2),
	   LienCredit_Currency				NVARCHAR(10),
	   ReciprocityAmount_Amount			DECIMAL(16,2),
	   ReciprocityAmount_Currency		NVARCHAR(10),
	   GrossVehicleWeight				INT,
	   IsMultiComponent					BIT,
	   SalesTaxExemptionLevel			NVARCHAR(20),
	   CommencementDate					DATE,
	   IsExemptAtReceivableCode			BIT,
	   ContractTypeValue				NVARCHAR(100),
	   GlTemplateId						BIGINT,
	   AssetLocationTaxBasisType		NVARCHAR(100),
	   AssetTypeId						BIGINT,
	   AssetTypeName					NVARCHAR(1000),
	   IsCapitalizedSalesTaxAsset		BIT,
	   BusCode							NVARCHAR(40),
	   IsSyndicated						BIT,
	   TaxJurisdictionId				BIGINT,
	   ReceivableTypeId					BIGINT,
	   HorsePower						DECIMAL(16,2),
	   EngineType						NVARCHAR(100),
	   ReceivableCodeId					BIGINT,
	   AssetCatalogNumber				NVARCHAR(100),
	   CustomerLocationId				BIGINT,
	   TaxAssessmentLevel				NVARCHAR(100),
	   IsRentalReceivableOnSameDate		BIT,
	   LienDate							DATE,
	   IsContractCapitalizeUpfront		BIT,
	   IsPrepaidUpfrontTax				BIT,
	   TaxTypeId						BIGINT NULL,
	   StateTaxTypeId					BIGINT NULL,
	   CountyTaxTypeId					BIGINT NULL,
	   CityTaxTypeId					BIGINT NULL,
	   StateId							BIGINT NULL,
	   UpfrontTaxMode					NVARCHAR(100),
	   DealProductTypeId				BIGINT NULL,
	   TaxRegistrationNumber			NVARCHAR(100),
	   ISOCountryCode					NVARCHAR(100),
	   SyndicationType					NVARCHAR(100),
	   CountryTaxExempt					BIT,
	   StateTaxExempt					BIT,
	   CityTaxExempt					BIT,
	   CountyTaxExempt					BIT,
	   CountryTaxExemptRule				NVARCHAR(200),
	   StateTaxExemptRule				NVARCHAR(200),
	   CityTaxExemptRule				NVARCHAR(200),
	   CountyTaxExemptRule				NVARCHAR(200),
	   SalesTaxRemittanceResponsibility NVARCHAR(8),
	   AssetSerialOrVIN NVARCHAR(100),
	   AssetUsageCondition NVARCHAR(4),
	   AcquisitionLocationId BIGINT NULL,
	   AcquisitionLocationTaxAreaId BIGINT NULL,
	   AcquisitionLocationCity NVARCHAR(100) NULL,
	   AcquisitionLocationMainDivision NVARCHAR(100) NULL,
	   AcquisitionLocationCountry NVARCHAR(100) NULL,
	   Usage NVARCHAR(40) NULL
)
CREATE CLUSTERED INDEX IX_AssetLevelReceivableDetails ON #AssetLevelReceivableDetails(LocationId,ReceivableDetailId);
INSERT INTO #ReceivableIds
(ReceivableId,
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
PaymentScheduleId,
TaxAssessmentLevel
)
SELECT
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
R.PaymentScheduleId,
C.TaxAssessmentLevel
FROM   Receivables R
JOIN #ContractIdTable CT ON R.EntityId = CT.ContractId
JOIN Contracts C ON CT.ContractId = C.Id AND R.CustomerId = CT.CustomerId
WHERE
(R.ID BETWEEN CT.ReceivableStartId AND ReceivableEndId)
AND R.IsActive = 1
AND R.EntityType = 'CT'
AND R.DueDate <= CT.InvoiceDueDate
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
RD.ReceivableId,
RD.Amount_Amount,
RD.Amount_Currency,
RD.AssetId,
RD.IsActive,
RD.AdjustmentBasisReceivableDetailId,
RD.IsTaxAssessed
INTO #ReceivableDetails_Temp FROM ReceivableDetails RD
JOIN #ReceivableIds R ON RD.ReceivableId = R.ReceivableId
;
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
RIds.DueDate,
RIds.ContractId As ContractId,
AL.LocationId AS LocationId,
AL.AssetId AS AssetId,
AL.Id AS AssetLocationId,
RD.Id ReceivableDetailId,
L.CustomerId As CustomerId
INTO #SalesTaxLeaseAllAssetLocations
FROM #ReceivableIds RIds
INNER JOIN #ReceivableDetails_Temp RD ON RD.ReceivableId = RIds.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN AssetLocations AL ON AL.AssetId = RD.AssetId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id
WHERE RIds.TaxAssessmentLevel <> 'Customer'
;
SELECT
EffectiveFromDate,
DueDate,
LocationId,
AssetId,
AssetLocationId,
ReceivableDetailId
INTO #SalesTaxLeaseAssetLocations
FROM #SalesTaxLeaseAllAssetLocations RIds
JOIN #ContractIdTable CT ON (CT.CustomerId = RIds.CustomerId OR RIds.CustomerID IS NULL)
;
SELECT
MAXAL.AssetId
,MAXAL.DueDate
,MAXAL.ReceivableDetailId
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #SalesTaxUniqueLeaseAssetLocations
FROM  #SalesTaxLeaseAssetLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
GROUP BY
MAXAL.AssetId
,MAXAL.DueDate
,MAXAL.ReceivableDetailId;
;
INSERT INTO #SalesTaxUniqueLeaseAssetLocations
SELECT
MINAL.AssetId
,MINAL.DueDate
,MINAL.ReceivableDetailId
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #SalesTaxLeaseAssetLocations MINAL
WHERE MINAL.EffectiveFromDate > MINAL.DueDate
AND MINAL.AssetId NOT IN(SELECT AssetId FROM #SalesTaxUniqueLeaseAssetLocations)
GROUP BY
MINAL.AssetId
,MINAL.DueDate
,MINAL.ReceivableDetailId;
INSERT INTO #AssetLocation
(
AssetId,
EffectiveFromDate,
AssetLocationId,
DueDate,
ReceivableDetailId
)
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.AssetLocationId) AssetLocationId
,LAL.DueDate
,GAL.ReceivableDetailId
FROM #SalesTaxUniqueLeaseAssetLocations AS GAL
JOIN #SalesTaxLeaseAssetLocations LAL ON GAL.EffectiveFromDate = LAL.EffectiveFromDate
AND GAL.AssetId = LAL.AssetId  AND GAL.ReceivableDetailId = LAL.ReceivableDetailId
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
,GAL.ReceivableDetailId
;
INSERT INTO #AssetLevelReceivableDetails
(EffectiveFromDate
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
,GAL.DueDate
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
FROM #AssetLocation GAL
INNER JOIN AssetLocations AL ON AL.Id = GAL.AssetLocationId
INNER JOIN Assets A ON A.Id = AL.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id;
;
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId, MAXAL.ReceivableDetailId ORDER BY MAXAL.EffectiveFromDate DESC, MAXAL.AssetLocationId DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.ReceivableDetailId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.TaxBasisType AS PreviousTaxBasisType
,L.UpfrontTaxMode AS PreviousUpfrontTaxMode
INTO #SalesLeaseAssetFromLocations
FROM #SalesTaxLeaseAllAssetLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN #SalesTaxUniqueLeaseAssetLocations AL ON
MAXAL.ReceivableDetailId = AL.ReceivableDetailId AND MAXAL.AssetId = AL.AssetId
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
;
INSERT INTO #SalesLeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId, MAXAL.ReceivableDetailId ORDER BY MAXAL.EffectiveFromDate DESC, MAXAL.AssetLocationId DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.ReceivableDetailId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.TaxBasisType AS PreviousTaxBasisType
,L.UpfrontTaxMode AS PreviousUpfrontTaxMode
FROM #SalesTaxLeaseAllAssetLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
WHERE MAXAL.ReceivableDetailId NOT IN (SELECT ReceivableDetailId FROM
(SELECT ReceivableDetailId FROM #SalesLeaseAssetFromLocations
UNION
SELECT ReceivableDetailId FROM #SalesTaxUniqueLeaseAssetLocations
) AS TEMP)
;
SELECT
AL.EffectiveFromDate AS EffectiveFromDate,
RIds.DueDate,
AL.LocationId AS LocationId,
RD.AssetId AS AssetId,
AL.Id AS CustomerLocationId,
RD.Id ReceivableDetailId,
L.CustomerId As CustomerId,
RIds.ContractId As ContractId
INTO #SalesTaxLeaseAllCustomerLocations
FROM #ReceivableIds RIds
INNER JOIN #ReceivableDetails_Temp RD ON RD.ReceivableId = RIds.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN CustomerLocations AL ON AL.CustomerId = RIds.CustomerId AND AL.IsActive = 1
INNER JOIN Locations L ON AL.LocationId = L.Id
WHERE RIds.TaxAssessmentLevel = 'Customer' AND RD.AssetId IS NOT NULL
;
SELECT
EffectiveFromDate,
DueDate,
LocationId,
AssetId,
CustomerLocationId,
ReceivableDetailId
INTO #SalesTaxLeaseCustomerLocations
FROM #SalesTaxLeaseAllCustomerLocations RIds
JOIN #ContractIdTable CT ON  CT.CustomerId = RIds.CustomerId
;
SELECT
MAXAL.AssetId
,MAXAL.DueDate
,MAXAL.ReceivableDetailId
,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
INTO #SalesTaxUniqueLeaseCustomerLocations
FROM  #SalesTaxLeaseCustomerLocations MAXAL
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
GROUP BY
MAXAL.AssetId
,MAXAL.DueDate
,MAXAL.ReceivableDetailId;
INSERT INTO #SalesTaxUniqueLeaseCustomerLocations
SELECT
MINAL.AssetId
,MINAL.DueDate
,MINAL.ReceivableDetailId
,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
FROM #SalesTaxLeaseCustomerLocations MINAL
WHERE MINAL.EffectiveFromDate > MINAL.DueDate
AND MINAL.ReceivableDetailId NOT IN(SELECT ReceivableDetailId FROM #SalesTaxUniqueLeaseCustomerLocations)
GROUP BY
MINAL.AssetId
,MINAL.DueDate
,MINAL.ReceivableDetailId;
INSERT INTO #CustomerLocation
(
AssetId,
EffectiveFromDate,
CustomerLocationId,
DueDate,
ReceivableDetailId
)
SELECT
GAL.AssetId
,GAL.EffectiveFromDate
,MAX(LAL.CustomerLocationId) CustomerLocationId
,LAL.DueDate
,GAL.ReceivableDetailId
FROM #SalesTaxUniqueLeaseCustomerLocations AS GAL
JOIN #SalesTaxLeaseCustomerLocations LAL ON GAL.EffectiveFromDate = LAL.EffectiveFromDate
AND GAL.AssetId = LAL.AssetId  AND GAL.ReceivableDetailId = LAL.ReceivableDetailId
GROUP BY
GAL.AssetId
,GAL.EffectiveFromDate
,LAL.DueDate
,GAL.ReceivableDetailId
;
INSERT INTO #AssetLevelReceivableDetails
(EffectiveFromDate
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
,AssetLocationTaxBasisType
,CustomerLocationId)
SELECT
GAL.EffectiveFromDate
,GAL.DueDate
,AL.LocationId
,GAL.AssetId
,GAL.ReceivableDetailId
,GAL.CustomerLocationId
,SLBC.Code
,A.IsElectronicallyDelivered
,A.PropertyTaxCost_Currency
,0.0
,0.0
,A.PropertyTaxCost_Currency
,A.GrossVehicleWeight
,A.IsParent
,STELC.Name
,AL.TaxBasisType
,GAL.CustomerLocationId
FROM #CustomerLocation GAL
INNER JOIN CustomerLocations AL ON AL.Id = GAL.CustomerLocationId
INNER JOIN Assets A ON A.Id = GAL.AssetId
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STELC ON A.SalesTaxExemptionLevelId = STELC.Id;
INSERT INTO #SalesLeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId,MAXAL.ReceivableDetailId ORDER BY MAXAL.EffectiveFromDate DESC, MAXAL.CustomerLocationId DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.ReceivableDetailId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.TaxBasisType AS PreviousTaxBasisType
,L.UpfrontTaxMode AS PreviousUpfrontTaxMode
FROM #SalesTaxLeaseAllCustomerLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
JOIN #SalesTaxUniqueLeaseCustomerLocations AL ON
MAXAL.ReceivableDetailId = AL.ReceivableDetailId AND MAXAL.AssetId = AL.AssetId
AND MAXAL.EffectiveFromDate <> AL.EffectiveFromDate
WHERE MAXAL.EffectiveFromDate <= MAXAL.DueDate
;
INSERT INTO #SalesLeaseAssetFromLocations
SELECT
ROW_NUMBER() OVER(PARTITION BY MAXAL.AssetId, MAXAL.ReceivableDetailId ORDER BY MAXAL.EffectiveFromDate DESC, MAXAL.CustomerLocationId DESC) AS RowNumber
,MAXAL.AssetId
,MAXAL.ReceivableDetailId
,MAXAL.EffectiveFromDate
,MAXAL.LocationId
,S.ShortName
,L.TaxBasisType AS PreviousTaxBasisType
,L.UpfrontTaxMode AS PreviousUpfrontTaxMode
FROM #SalesTaxLeaseAllCustomerLocations MAXAL
JOIN Locations L ON L.Id = MAXAL.LocationId
JOIN States S ON S.Id = L.StateId
WHERE MAXAL.ReceivableDetailId NOT IN (SELECT ReceivableDetailId FROM
(SELECT ReceivableDetailId FROM #SalesLeaseAssetFromLocations
UNION
SELECT ReceivableDetailId FROM #SalesTaxUniqueLeaseCustomerLocations
) AS TEMP)
;
DELETE FROM #SalesLeaseAssetFromLocations
WHERE RowNumber <> 1
;
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
,Loc.UpfrontTaxMode
,CTE.DueDate
INTO #CTE_ReceivableLocations
FROM
#AssetLevelReceivableDetails CTE
INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
;
SELECT
ROW_NUMBER() OVER (PARTITION BY Loc.ReceivableDetailId ORDER BY CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
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
,Loc.UpfrontTaxMode
INTO #AllTaxAreaIdsForLocation
FROM #CTE_ReceivableLocations Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
;
SELECT DISTINCT
RId.ReceivableId
,RC.IsTaxExempt
,SundryRecurrings.IsAssetBased
,SundryRecurrings.LocationId
,SundryRecurrings.Id
INTO #SundryRecurringDetails
FROM #ReceivableIds as RId
JOIN Receivables R on R.Id = RId.ReceivableId
JOIN ReceivableCodes RC on RC.Id = R.ReceivableCodeId
JOIN SundryRecurringPaymentSchedules  AS SRPS  ON 	R.SourceId = SRPS.Id AND R.SourceTable = 'SundryRecurring'
JOIN SundryRecurrings ON SundryRecurrings.Id = SRPS.SundryRecurringId
AND (SundryRecurrings.Id IS NULL OR (SundryRecurrings.LocationId IS NULL AND SundryRecurrings.IsAssetBased = 1))
;
INSERT INTO #ContractBasedReceivableDetail
(ReceivableDetailId, ReceivableId, DueDate, IsRental, FairMarketValue, Cost, AmountBilledToDate, ExtendedPrice, Currency,
IsAssetBased, IsLeaseBased, TransactionType, CustomerCode, CustomerId, ClassCode, ContractId, IsExemptAtSundry,
LeaseUniqueId, SundryReceivableCode, AssetId, LeaseType, ReceivableType, LegalEntityId, Id,
IsManuallyAssessed, TransactionCode, TaxBasisType, TaxRemittanceType, IsExemptAtReceivableCode, ContractTypeValue,
GlTemplateId, AssetTypeId, IsRentalReceivableOnSameDate, IsExemptAtLease,
IsContractCapitalizeUpfront, IsExemptAtAsset, IsCapitalizedSalesTaxAsset, LeaseTerm, LessorRisk,
CustomerCost, IsVertexSupportedLocation, IsLocationActive, LienCredit_Amount, LienCredit_Currency,
ReciprocityAmount_Amount, ReciprocityAmount_Currency, GrossVehicleWeight, IsElectronicallyDelivered, IsMultiComponent,
BusCode, IsSyndicated, ReceivableTypeId,  HorsePower, EngineType, ReceivableCodeId, TaxAssessmentLevel,
LienDate, IsPrepaidUpfrontTax, DealProductTypeId, TaxRegistrationNumber, SyndicationType, ISOCountryCode)
SELECT
RD.Id AS ReceivableDetailId
,RD.ReceivableId AS ReceivableId
,RId.DueDate AS DueDate
,RT.IsRental AS IsRental
,0.00 AS FairMarketValue
,0.00 AS Cost
,0.00 AS AmountBilledToDate
,RD.Amount_Amount AS ExtendedPrice
,RD.Amount_Currency AS Currency
,CASE WHEN RD.AssetId IS NULL OR RD.AssetId = '' THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS IsAssetBased
,CASE WHEN (cont.ContractType = 'Lease' OR RT.Name = 'SecurityDeposit') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsLeaseBased
,CASE WHEN (RT.Name = 'BuyOut' OR RT.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS TransactionType
,P.PartyNumber AS CustomerCode
,P.Id  AS CustomerId
,CC.Class AS ClassCode
,CASE WHEN RId.EntityType = 'CT' THEN RId.ContractId ELSE NULL END AS ContractId
,ISNULL(S.IsTaxExempt,ISNULL(SR.IsTaxExempt,CONVERT(BIT,0))) AS IsExemptAtSundry
,cont.SequenceNumber AS LeaseUniqueId
,RC.Name AS SundryReceivableCode
,RD.AssetId AS AssetId
,DPT.LeaseType AS LeaseType
,RT.Name AS ReceivableType
,RId.LegalEntityId
,0 'Id'
,CAST(0 AS BIT) 'IsManuallyAssessed'
,'_' 'TransactionCode'
,'_' 'TaxBasisType'
,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
,RC.IsTaxExempt IsExemptAtReceivableCode
,cont.ContractType ContractTypeValue
,STGL.GLTemplateId GlTemplateId
,CAST(0 AS BIGINT) AssetTypeId
,CAST(0 AS BIT) IsRentalReceivableOnSameDate
,CAST(0 AS BIT) IsExemptAtLease
,CAST(0 AS BIT) IsContractCapitalizeUpfront
,CAST(0 AS BIT) IsExemptAtAsset
,CAST(0 AS BIT) IsCapitalizedSalesTaxAsset
,CAST(0.00 AS DECIMAL(16,2)) LeaseTerm
,CAST(0.00 AS DECIMAL(16,2)) LessorRisk
,CAST(0.00 AS DECIMAL(16,2)) CustomerCost
,CAST(0 AS BIT) IsVertexSupportedLocation
,CAST(0 AS BIT) IsLocationActive
,CAST(0.00 AS DECIMAL(16,2)) LienCredit_Amount
,'USD' LienCredit_Currency
,CAST(0.00 AS DECIMAL(16,2)) ReciprocityAmount_Amount
,'USD' ReciprocityAmount_Currency
,CAST(0 AS BIT) GrossVehicleWeight
,CAST(0 AS BIT) IsElectronicallyDelivered
,CAST(0 AS BIT) IsMultiComponent
,CAST('' AS NVARCHAR(40)) AS BusCode
,CASE WHEN cont.SyndicationType != 'None' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsSyndicated
,RC.ReceivableTypeId AS ReceivableTypeId
,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
,CAST(NULL AS NVARCHAR) AS EngineType
,RC.Id ReceivableCodeId
,cont.TaxAssessmentLevel
,CAST (NULL AS DATE) AS LienDate
,CAST(0 AS BIT) IsPrepaidUpfrontTax
,DPT.Id AS DealProductTypeId
,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
,ISNULL(cont.SyndicationType,'_') SyndicationType
,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
FROM
#ReceivableIds RId
INNER JOIN #ReceivableDetails_Temp RD ON RD.ReceivableId = RId.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Contracts cont ON RId.ContractId = cont.Id
INNER JOIN LeaseFinances LF ON cont.Id = LF.ContractId
INNER JOIN ReceivableCodes RC ON RId.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
INNER JOIN Customers Customer ON RId.CustomerId= Customer.Id
INNER JOIN Parties P ON Customer.Id = P.Id
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN #SalesLeaseAssetFromLocations FromLoc ON RD.Id = FromLoc.ReceivableDetailId
LEFT JOIN CustomerClasses CC ON Customer.CustomerClassId = CC.Id
LEFT JOIN Sundries S ON RId.SourceId = S.Id AND RId.SourceTable = 'Sundry'
LEFT JOIN SundryRecurringPaymentSchedules SRPS ON RId.ReceivableId = SRPS.ReceivableId
LEFT JOIN SecurityDeposits SD on RId.ReceivableId = SD.ReceivableId
LEFT JOIN #SundryRecurringDetails SR ON RId.ReceivableId= SR.ReceivableId
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RId.ReceivableId = STGL.ReceivableId
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
WHERE (S.Id IS NULL AND RId.SourceTable <> 'Sundry' OR (S.LocationId IS NULL AND S.IsAssetBased = 1))
AND (SD.Id IS NULL OR (SD.LocationId is null)) AND (LF.IsCurrent = 1)
AND (SR.Id IS NULL AND RId.SourceTable <> 'SundryRecurring' OR (SR.LocationId IS NULL AND SR.IsAssetBased = 1) )
;
UPDATE #ContractBasedReceivableDetail
SET ReceivableTaxId = RecT.Id
FROM #ContractBasedReceivableDetail CB
JOIN ReceivableTaxes RecT ON CB.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
;
UPDATE #ContractBasedReceivableDetail
SET LienDate = CASE WHEN PT.LienDate IS NULL THEN CAST (NULL AS DATE) ELSE PT.LienDate END
FROM #ContractBasedReceivableDetail CB
JOIN #ReceivableIds RId ON CB.ReceivableId = RId.ReceivableId
JOIN PropertyTaxes PT ON PT.Id = RId.SourceId AND RId.SourceTable = 'PropertyTax'
;
UPDATE #ContractBasedReceivableDetail
SET IsExemptAtLease = ISNULL(LF.IsSalesTaxExempt,CAST(0 AS BIT)), RentAccrualStartDate = LFD.RentAccrualDate,
MaturityDate = LFD.MaturityDate, CommencementDate = LFD.CommencementDate,
IsContractCapitalizeUpfront = ISNULL(LFD.CapitalizeUpfrontSalesTax,CAST(0 AS BIT)),
LeaseTerm = ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00),
LessorRisk = ISNULL((LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount), 0.00),
Company = LE.TaxPayer
FROM #ContractBasedReceivableDetail CB
JOIN LeaseFinances LF ON CB.ContractId = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id AND LF.IsCurrent = 1
JOIN LegalEntities LE ON CB.LegalEntityId = LE.Id
;

;WITH CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM #ContractBasedReceivableDetail WHERE AssetId IS NOT NULL
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
INNER JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)

UPDATE #ContractBasedReceivableDetail
	SET CustomerCost = CASE WHEN LA.NBV_Amount IS NULL THEN 0.00 ELSE LA.NBV_Amount END, AssetTypeName = AT.Name ,
		IsExemptAtAsset =CASE WHEN A.IsTaxExempt IS NULL THEN CAST(0 AS BIT) ELSE A.IsTaxExempt END,
		Product = CASE WHEN (CB.IsRental = 1) THEN ACC.ClassCode ELSE ReceivableType END, 
		AssetType = ACC.ClassCode, Company = LE.TaxPayer, TitleTransferCode = TTC.TransferCode,
	    IsCapitalizedSalesTaxAsset = CASE WHEN AT.Name = @CapitalizedSalesTaxAssetType THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
		AssetCatalogNumber = AC.CollateralCode, StateTaxTypeId = LA.StateTaxTypeId, CountyTaxTypeId = LA.CountyTaxTypeId,
		CityTaxTypeId = LA.CityTaxTypeId, IsPrepaidUpfrontTax = ISNULL(LA.IsPrepaidUpfrontTax,CAST(0 AS BIT)),
		ContractType = CASE WHEN CB.IsRental = 1 THEN 
							CASE WHEN LA.IsTaxDepreciable = 1 THEN 'FMV' ELSE 'CSC' END 
						ELSE ''  END,
		SalesTaxRemittanceResponsibility = CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= CB.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE LA.SalesTaxRemittanceResponsibility END ,
		AcquisitionLocationId = LA.AcquisitionLocationId,
		AssetSerialORVIN = ASN.SerialNumber,
		AssetUsageCondition = A.UsageCondition,
		Usage = AU.Usage
FROM #ContractBasedReceivableDetail CB 
JOIN LeaseFinances LF ON CB.ContractId = LF.ContractId
JOIN LeaseAssets LA ON LF.Id = LA.LeaseFinanceId AND CB.AssetId = LA.AssetId AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
JOIN Assets A ON LA.AssetId = A.Id
JOIN AssetTypes AT ON A.TypeId = AT.Id
JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
JOIN LegalEntities LE ON CB.LegalEntityId = LE.Id
LEFT JOIN CTE_AssetSerialNumberDetails ASN on CB.AssetId = ASN.AssetId
LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = A.Id AND LF.ContractId = STRH.ContractId
LEFT JOIN AssetUsages AU ON A.AssetUsageId = AU.Id

;
UPDATE #ContractBasedReceivableDetail
SET LocationId = Loc.LocationId, MainDivision = Loc.MainDivision, Country = Loc.Country, City = Loc.City,
TaxAreaId = Loc.TaxAreaId, TaxAreaEffectiveDate = Loc.TaxAreaEffectiveDate, AssetLocationId = Loc.AssetLocationId,
IsLocationActive = ISNULL(Loc.IsLocationActive,CAST(0 AS BIT)), LocationEffectiveDate = Loc.EffectiveFromDate,
IsVertexSupportedLocation = ISNULL(Loc.IsVertexSupported,CAST(0 AS BIT)), LocationStatus = Loc.LocationStatus,
SaleLeasebackCode = CAST(Loc.SaleLeasebackCode AS NVARCHAR), LienCredit_Amount = ISNULL(Loc.LienCredit_Amount,0.00),
SalesTaxExemptionLevel = Loc.SalesTaxExemptionLevel, AssetLocationTaxBasisType = Loc.AssetLocationTaxBasisType,
ReciprocityAmount_Currency = ISNULL(Loc.ReciprocityAmount_Currency,'USD'), LienCredit_Currency = ISNULL(Loc.LienCredit_Currency,'USD'),
IsMultiComponent = ISNULL(Loc.IsMultiComponent,CONVERT(BIT,0)), GrossVehicleWeight = ISNULL(Loc.GrossVehicleWeight ,0),
IsElectronicallyDelivered = ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)), ToState = ToState.ShortName,
ReciprocityAmount_Amount = ISNULL(Loc.ReciprocityAmount_Amount,0.00),
TaxJurisdictionId = ISNULL(ToLocation.JurisdictionId,CAST(0 AS BIGINT)), LocationCode = ToLocation.Code,
CustomerLocationId = Loc.CustomerLocationId, UpfrontTaxMode = ISNULL(Loc.UpfrontTaxMode,'_'), TaxTypeId = DTTFRT.TaxTypeId
FROM #ContractBasedReceivableDetail CB
JOIN #AllTaxAreaIdsForLocation Loc ON CB.ReceivableDetailId = Loc.ReceivableDetailId
JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
JOIN States ToState ON ToLocation.StateId = ToState.Id AND Loc.Row_Num = 1
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON CB.ReceivableTypeId = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
;
UPDATE #ContractBasedReceivableDetail
SET FromState = FromState.ShortName
,PreviousTaxBasisType = FromLoc.PreviousTaxBasisType
,PreviousUpfrontTaxMode = FromLoc.PreviousUpfrontTaxMode
FROM #ContractBasedReceivableDetail CB
JOIN #SalesLeaseAssetFromLocations FromLoc ON CB.ReceivableDetailId = FromLoc.ReceivableDetailId
JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
JOIN States FromState ON FromLocation.StateId = FromState.Id
;
UPDATE #ContractBasedReceivableDetail
SET CountryTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
StateTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CityTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CountyTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CountryTaxExemptRule = CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule'
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
FROM
#ContractBasedReceivableDetail lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
DELETE FROM #ContractBasedReceivableDetail WHERE AssetId IS NULL;
;
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
,Loc.JurisdictionId
INTO #CTE_ReceivableLocationsTemp
FROM
#ReceivableIds R
LEFT JOIN Locations Loc ON R.LocationId = Loc.Id
LEFT JOIN States states ON Loc.StateId = states.Id
LEFT JOIN Countries countries ON states.CountryId = countries.Id
;
SELECT
ROW_NUMBER() OVER (PARTITION BY P.LocationId,Loc.ReceivableId ORDER BY CASE WHEN DATEDIFF(DAY,Loc.DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, Loc.DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num
,P.TaxAreaEffectiveDate
,P.TaxAreaId
,CASE WHEN Loc.JurisdictionId IS NOT NULL THEN Loc.LocationId ELSE P.LocationId END LocationId
,Loc.MainDivision
,Loc.City
,Loc.Country
,Loc.LocationStatus
,Loc.IsLocationActive
,Loc.ReceivableId
,Loc.IsVertexSupported
,Loc.UpfrontTaxMode
INTO #AllTaxAreaIdsForLocationWithoutLocation
FROM #CTE_ReceivableLocationsTemp Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
;
SELECT DISTINCT
RId.ReceivableId
,RC.IsTaxExempt
,SundryRecurrings.IsAssetBased
,0 AS LocationId
INTO #SundryRecurringDetailsWithoutLocation
FROM #ReceivableIds as RId
join Receivables R on R.Id = RId.ReceivableId
Join ReceivableCodes RC on RC.Id = R.ReceivableCodeId
JOIN SundryRecurringPaymentSchedules  AS SRPS  ON 	R.SourceId = SRPS.Id AND R.SourceTable = 'SundryRecurring'
JOIN SundryRecurrings ON SundryRecurrings.Id = SRPS.SundryRecurringId
AND ((SundryRecurrings.LocationId IS NOT NULL) OR (SundryRecurrings.LocationId IS NULL AND SundryRecurrings.IsAssetBased = 0))
WHERE RId.SourceTable <> 'LateFee' AND RId.IsActive = 1
;
SELECT DISTINCT
RId.ReceivableId
,SDS.LocationId
,CONVERT(BIT,0) AS IsTaxExempt
,CONVERT(BIT,0) AS IsAssetBased
INTO #SecurityDepositsWithoutLocation
FROM #ReceivableIds as RId
JOIN SecurityDeposits  AS SDS  ON 	RId.ReceivableId = SDS.ReceivableId
WHERE RId.IsActive = 1
;
SELECT DISTINCT
RId.ReceivableId,
RId.LocationId
,CONVERT(BIT,0) AS IsTaxExempt
,CONVERT(BIT,0) AS IsAssetBased
INTO #LateFeesWithoutLocation
FROM #ReceivableIds as RId
JOIN LateFeeReceivables  AS LFR  ON LFR.Id = RId.SourceId and RId.SourceTable = 'LateFee'
WHERE RId.IsActive = 1
;
SELECT * INTO #CombinedReceivableWithoutLocation FROM
(
SELECT * from  #SundryRecurringDetailsWithoutLocation
UNION
SELECT * from  #SecurityDepositsWithoutLocation
UNION
SELECT * from #LateFeesWithoutLocation
UNION
SELECT
RId.ReceivableId
,0 LocationId
,CONVERT(BIT,0) AS IsTaxExempt
,CONVERT(BIT,0) AS IsAssetBased
FROM #ReceivableIds RId
JOIN Sundries S ON RId.SourceId = S.Id AND RId.SourceTable = 'Sundry'
AND (S.Type = 'Sundry' OR S.TYPE = 'PPTEscrow' OR  S.TYPE = 'Scrape')
)AS TMP
;
SELECT *
INTO #TaxAreaIdForLocationAsOfDueDateWithoutLocation
FROM #AllTaxAreaIdsForLocationWithoutLocation
WHERE Row_Num = 1
;
INSERT INTO #NonAssetBasedReceivableDetail
SELECT
	 RD.Id AS ReceivableDetailId
	,RD.ReceivableId AS ReceivableId
	,RId.DueDate AS DueDate
	,RT.IsRental AS IsRental
	,RT.Name AS Product
	,0.00 AS FairMarketValue
	,0.00 AS Cost
	,0.00 AS AmountBilledToDate
	,RD.Amount_Amount AS ExtendedPrice
	,RD.Amount_Currency AS Currency
	,CASE WHEN RD.AssetId IS NULL OR RD.AssetId = '' THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS IsAssetBased
	,CASE WHEN (cont.ContractType = 'Lease' OR RT.Name = 'SecurityDeposit') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsLeaseBased
	,CONVERT(BIT,0) AS IsExemptAtAsset
	,CASE WHEN (RT.Name = 'BuyOut' OR RT.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS TransactionType
	,LE.TaxPayer AS Company
	,P.PartyNumber AS CustomerCode
	,P.Id  AS CustomerId
	,CC.Class AS ClassCode
	,CAST(NULL AS BIGINT) LocationId
	,CAST(NULL AS NVARCHAR(100)) LocationCode
	,CAST(NULL AS NVARCHAR(100)) MainDivision
	,CAST(NULL AS NVARCHAR(100)) Country
	,CAST(NULL AS NVARCHAR(100)) City
	,CAST(NULL AS BIGINT) TaxAreaId
	,CAST(NULL AS DATE) TaxAreaEffectiveDate 
	,CAST(0 AS BIT) IsLocationActive 
	,RId.ContractId AS ContractId
	,CAST(NULL AS DATE) RentAccrualStartDate
	,CAST(NULL AS DATE) MaturityDate
	,0.0 AS CustomerCost
	,CAST(0 AS BIT) IsExemptAtLease
	,0.00 AS LessorRisk 
	,NULL AS AssetLocationId
	,CAST(NULL AS NVARCHAR(100)) LocationStatus
	,ISNULL(S.IsTaxExempt,ISNULL(SR.IsTaxExempt,CONVERT(BIT,0))) AS IsExemptAtSundry
	,CAST(NULL AS BIGINT) AS ReceivableTaxId
	,CAST(0 AS BIT) IsVertexSupportedLocation 
	,CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END AS ContractType
	,cont.SequenceNumber AS LeaseUniqueId
	,RC.Name AS SundryReceivableCode
	,CAST(NULL AS NVARCHAR) AS AssetType
	,RD.AssetId AS AssetId
	,DPT.LeaseType AS LeaseType
	,0.00 AS LeaseTerm 
	,CAST(NULL AS NVARCHAR) AS TitleTransferCode
	,NULL AS LocationEffectiveDate
	,RT.Name AS ReceivableType
	,LE.Id 'LegalEntityId'
	,0 'Id'
	,CAST(0 AS BIT) 'IsManuallyAssessed'
	,'_' 'TransactionCode'
	,'_' 'TaxBasisType'  
	,CAST(NULL AS NVARCHAR(10)) ToState
	,CAST(NULL AS NVARCHAR(10)) FromState
	,REPLACE(cont.SalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
	,CAST(NULL AS NVARCHAR) AS SaleLeasebackCode
	,CAST(0 AS BIT) AS IsElectronicallyDelivered
	,0.00 LienCredit_Amount
	,'USD' LienCredit_Currency
	,0.00 ReciprocityAmount_Amount
	,'USD' ReciprocityAmount_Currency
	,0 GrossVehicleWeight
	,CAST(0 AS BIT) AS IsMultiComponent
	,CAST(NULL AS NVARCHAR) AS SalesTaxExemptionLevel
	,CAST(NULL AS DATE) CommencementDate
	,RC.IsTaxExempt IsExemptAtReceivableCode	
	,cont.ContractType ContractTypeValue
	,STGL.GLTemplateId GlTemplateId
	,CAST(NULL AS NVARCHAR) AS AssetLocationTaxBasisType
	,CAST(0 AS BIGINT) AssetTypeId
	,CAST(NULL AS NVARCHAR) AssetTypeName
	,CAST(0 AS BIT) IsCapitalizedSalesTaxAsset
	,CAST('' AS NVARCHAR(40)) AS BusCode
	,CASE WHEN cont.SyndicationType != 'None' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsSyndicated
	,CAST(0 AS BIGINT) AS TaxJurisdictionId
	,RC.ReceivableTypeId AS ReceivableTypeId
	,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
	,CAST(NULL AS NVARCHAR) AS EngineType
	,RC.Id ReceivableCodeId
	,CAST(NULL AS NVARCHAR) AssetCatalogNumber
	,NULL AS CustomerLocationId
	,cont.TaxAssessmentLevel
	,CAST(0 AS BIT) IsRentalReceivableOnSameDate
	,CAST(NULL AS DATE)AS LienDate
	,CAST(0 AS BIT) IsContractCapitalizeUpfront 
	,CAST(0 AS BIT) IsPrepaidUpfrontTax
	,CAST(0 AS BIGINT) TaxTypeId
    ,NULL StateTaxTypeId
    ,NULL CountyTaxTypeId
    ,NULL CityTaxTypeId
	,CAST(0 AS BIGINT) StateId
	,CAST(NULL AS NVARCHAR) UpfrontTaxMode
	,DPT.Id AS DealProductTypeId
	,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
	,ISNULL(cont.SyndicationType,'_') SyndicationType
	,CAST(0 AS BIT) CountryTaxExempt
	,CAST(0 AS BIT) StateTaxExempt
	,CAST(0 AS BIT) CityTaxExempt
	,CAST(0 AS BIT) CountyTaxExempt
	,CAST(NULL AS NVARCHAR) CountryTaxExemptRule	
	,CAST(NULL AS NVARCHAR) StateTaxExemptRule
	,CAST(NULL AS NVARCHAR) CityTaxExemptRule
	,CAST(NULL AS NVARCHAR) CountyTaxExemptRule
	,'_' SalesTaxRemittanceResponsibility
	,'_' AssetUsageCondition
	,NULL AcquisitionLocationId
	,NULL AcquisitionLocationTaxAreaId
	,NULL AcquisitionLocationCity 
	,NULL AcquisitionLocationMainDivision
	,NULL AcquisitionLocationCountry
	,NULL Usage
	,NULL AssetSerialOrVIN
FROM
#ReceivableIds RId
INNER JOIN #ReceivableDetails_Temp RD ON RD.ReceivableId = RId.ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
INNER JOIN Contracts cont ON RId.ContractId = cont.Id
INNER JOIN LegalEntities LE ON RId.LegalEntityId = LE.Id
INNER JOIN ReceivableCodes RC ON RId.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
INNER JOIN #CombinedReceivableWithoutLocation CR ON RId.ReceivableId =  CR.ReceivableId
INNER JOIN Customers Customer ON RId.CustomerId= Customer.Id
INNER JOIN Parties P ON Customer.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
LEFT JOIN DealProductTypes DPT ON cont.DealProductTypeId = DPT.Id
LEFT JOIN CustomerClasses CC ON Customer.CustomerClassId = CC.Id
LEFT JOIN #SundryRecurringDetailsWithoutLocation SR ON RId.ReceivableId = SR.ReceivableId
LEFT JOIN #SecurityDepositsWithoutLocation SD ON RId.ReceivableId = SD.ReceivableId
LEFT JOIN #LateFeesWithoutLocation lateFee ON RId.ReceivableId = lateFee.ReceivableId
LEFT JOIN Sundries S ON RId.ReceivableId = S.ReceivableId AND S.IsActive = 1
LEFT JOIN SundryRecurringPaymentSchedules SRPS ON RId.ReceivableId = SRPS.ReceivableId
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RId.ReceivableId = STGL.ReceivableId
;
UPDATE #NonAssetBasedReceivableDetail
SET ReceivableTaxId = RecT.Id
FROM #NonAssetBasedReceivableDetail CB
JOIN ReceivableTaxes RecT ON CB.ReceivableId = RecT.ReceivableId AND RecT.IsActive = 1
;
UPDATE #NonAssetBasedReceivableDetail
SET LienDate = CASE WHEN PT.LienDate IS NULL THEN CAST (NULL AS DATE) ELSE PT.LienDate END
FROM #NonAssetBasedReceivableDetail CB
JOIN #ReceivableIds RId ON CB.ReceivableId = RId.ReceivableId
JOIN PropertyTaxes PT ON PT.Id = RId.SourceId AND RId.SourceTable = 'PropertyTax'
;
UPDATE #NonAssetBasedReceivableDetail
SET IsExemptAtLease = ISNULL(LF.IsSalesTaxExempt,CAST(0 AS BIT)),
LeaseTerm = ISNULL(CAST((DATEDIFF(day,LFD.CommencementDate,LFD.MaturityDate) + 1) AS DECIMAL(10,2)),0.00),
RentAccrualStartDate = LFD.RentAccrualDate, MaturityDate = LFD.MaturityDate, CommencementDate = LFD.CommencementDate,
IsContractCapitalizeUpfront = ISNULL(LFD.CapitalizeUpfrontSalesTax,CAST(0 AS BIT)),
LessorRisk = ISNULL((LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount), 0.00)
FROM #NonAssetBasedReceivableDetail CB
JOIN LeaseFinances LF ON CB.ContractId = LF.ContractId
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
WHERE LF.IsCurrent = 1
;
UPDATE #NonAssetBasedReceivableDetail
SET LocationId = Loc.LocationId, MainDivision = Loc.MainDivision, Country = Loc.Country, City = Loc.City,
TaxAreaId = Loc.TaxAreaId, TaxAreaEffectiveDate = Loc.TaxAreaEffectiveDate, LocationStatus = Loc.LocationStatus,
IsLocationActive = ISNULL(Loc.IsLocationActive,CAST(0 AS BIT)), ToState = ToState.ShortName,
IsVertexSupportedLocation = ISNULL(Loc.IsVertexSupported,CAST(0 AS BIT)), LocationCode = ToLocation.Code,
TaxJurisdictionId = ISNULL(ToLocation.JurisdictionId,CAST(0 AS BIGINT)), CustomerLocationId = 0,
UpfrontTaxMode = ISNULL(Loc.UpfrontTaxMode,'_'), TaxTypeId = DTTFRT.TaxTypeId
FROM #NonAssetBasedReceivableDetail CB
JOIN #AllTaxAreaIdsForLocationWithoutLocation Loc ON CB.ReceivableId = Loc.ReceivableId
JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id AND Loc.Row_Num = 1
JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON CB.ReceivableTypeId = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
;
UPDATE #NonAssetBasedReceivableDetail
SET FromState = FromState.ShortName
FROM #NonAssetBasedReceivableDetail CB
JOIN #SalesLeaseAssetFromLocations FromLoc ON CB.ReceivableDetailId = FromLoc.ReceivableDetailId
JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
JOIN States FromState ON FromLocation.StateId = FromState.Id
;
UPDATE #NonAssetBasedReceivableDetail
SET CountryTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
StateTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CityTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CountyTaxExempt = CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT),
CountryTaxExemptRule = CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule'
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
CountyTaxExemptRule =CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule'
WHEN AssetRule.IsCountyTaxExempt = 1 THEN 'AssetTaxExemptRule'
WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
ELSE '' END
FROM  #ContractBasedReceivableDetail lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
;
;WITH CTE_CTE_DistinctAssetIds AS(
	SELECT DISTINCT AssetId FROM #NonAssetBasedReceivableDetail WHERE AssetId IS NOT NULL
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM CTE_CTE_DistinctAssetIds A
INNER JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId
)
UPDATE CB SET
			AssetUsageCondition =ISNULL(A.UsageCondition,'_'),
			AssetSerialOrVIN = ASN.SerialNumber,
			Usage = AU.Usage,
		SalesTaxRemittanceResponsibility = CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= CB.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE LA.SalesTaxRemittanceResponsibility END ,
		AcquisitionLocationId = LA.AcquisitionLocationId
FROM  #NonAssetBasedReceivableDetail CB 
JOIN Assets A ON A.Id = CB.AssetID
JOIN LeaseFinances LF ON LF.ContractId = CB.ContractId AND LF.IsCurrent=1
JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL)) AND CB.AssetId = LA.AssetId
LEFT JOIN CTE_AssetSerialNumberDetails ASN ON CB.AssetId = ASN.AssetId
LEFT JOIN  AssetUsages AU ON AU.Id = A.AssetUsageId
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = A.Id AND LF.ContractId = STRH.ContractId

INSERT INTO #ContractBasedReceivableDetail
SELECT *, NULL as PreviousTaxBasisType, NULL as PreviousUpfrontTaxMode
FROM #NonAssetBasedReceivableDetail
WHERE (((LocationId IS NOT NULL) OR (LocationId IS NULL AND (AssetId IS NULL OR AssetId = ''))) AND IsRental = 0)
;


;WITH CTE_AcquisitionLocationDetails
AS 
(
SELECT DISTINCT L.Id AS AcquisitionLocationId,
		L.TaxAreaId AS AcquisitionLocationTaxAreaId,
		L.City AS AcquisitionLocationCity,
		S.ShortName AS AcquisitionLocationMainDivision,
		C.ShortName AS AcquisitionLocationCountry,
		CB.ReceivableDetailId AS ReceivableDetailId
FROM #ContractBasedReceivableDetail CB 
JOIN  Locations L ON CB.AcquisitionLocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
) 
UPDATE CB SET 
		AcquisitionLocationTaxAreaId = AD.AcquisitionLocationTaxAreaId,
		AcquisitionLocationCity = AD.AcquisitionLocationCity,
		AcquisitionLocationMainDivision = AD.AcquisitionLocationMainDivision,
		AcquisitionLocationCountry = AD.AcquisitionLocationCountry
FROM #ContractBasedReceivableDetail CB
LEFT JOIN CTE_AcquisitionLocationDetails AD ON AD.AcquisitionLocationId = CB.AcquisitionLocationId AND AD.ReceivableDetailId=CB.ReceivableDetailId
;


SELECT Min(ReceivableId) ReceivableId, DueDate INTO #CTE_MinContractBasedReceivableDetail FROM #ContractBasedReceivableDetail
WHERE IsRental = 1 AND AssetLocationTaxBasisType = 'UC' GROUP BY DueDate
INSERT  INTO #CTE_MinContractBasedReceivableDetail SELECT Min(ReceivableId) ReceivableId, DueDate FROM #ContractBasedReceivableDetail
WHERE IsRental = 1 AND AssetLocationTaxBasisType = 'UR' AND (ReceivableType = 'CapitalLeaseRental' or ReceivableType = 'OperatingLeaseRental') GROUP BY DueDate
UPDATE #ContractBasedReceivableDetail
SET IsRentalReceivableOnSameDate = CAst(1 AS BIT)
FROM #ContractBasedReceivableDetail CB
JOIN  #CTE_MinContractBasedReceivableDetail MCB ON CB.DueDate = MCB.DueDate
AND CB.IsRental = 1 AND CB.ReceivableId <> MCB.ReceivableId
;
UPDATE
#ContractBasedReceivableDetail
SET
#ContractBasedReceivableDetail.BusCode = GLOrgStructureConfigs.BusinessCode
FROM
#ContractBasedReceivableDetail ContractBasedReceivableDetail
INNER JOIN Contracts
ON Contracts.Id = ContractBasedReceivableDetail.ContractId
INNER JOIN LeaseFinances
ON LeaseFinances.ContractId = Contracts.Id
AND LeaseFinances.IsCurrent = 1
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = ContractBasedReceivableDetail.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = Contracts.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
UPDATE
#ContractBasedReceivableDetail
SET
#ContractBasedReceivableDetail.BusCode = GLOrgStructureConfigs.BusinessCode
FROM
#ContractBasedReceivableDetail ContractBasedReceivableDetail
INNER JOIN Contracts
ON Contracts.Id = ContractBasedReceivableDetail.ContractId
INNER JOIN LoanFinances
ON  LoanFinances.ContractId = Contracts.Id
AND LoanFinances.IsCurrent = 1
INNER JOIN GLOrgStructureConfigs
ON GLOrgStructureConfigs.LegalEntityId = ContractBasedReceivableDetail.LegalEntityId
AND GLOrgStructureConfigs.CostCenterId = LoanFinances.CostCenterId
AND GLOrgStructureConfigs.LineofBusinessId = Contracts.LineofBusinessId
AND GLOrgStructureConfigs.IsActive = 1
;
SELECT DISTINCT * FROM #ContractBasedReceivableDetail ORDER BY ReceivableDetailId
;
SELECT
ALRD.DueDate
,RD.Amount_Amount
,RD.Amount_Currency
,ALRD.LocationId
,ALRD.AssetId
,L.StateId
,ALRD.ReceivableDetailId
,RD.ReceivableId
,R.EntityId
,R.CustomerId
INTO #ReceivableDetail_Temp
FROM #AssetLevelReceivableDetails ALRD
JOIN ReceivableDetails RD ON RD.Id = ALRD.ReceivableDetailId
JOIN #ReceivableIds R ON R.ReceivableId = RD.ReceivableId
JOIN Locations L ON ALRD.LocationId = L.Id
WHERE RD.IsActive = 1
ORDER BY ALRD.DueDate, R.ReceivableId, RD.Id;
SELECT
BRR.RevenueBilledToDate_Amount ,
BRR.AssetId,
BRR.IsActive,
BRR.ContractId,
BRR.StateId
INTO #BilledRentalReceivable_Temp FROM VertexBilledRentalReceivables BRR
JOIN #ReceivableDetail_Temp RD ON RD.AssetId = BRR.AssetId
AND RD.StateId = BRR.StateId AND BRR.IsActive = 1
AND BRR.ContractId = RD.EntityId
SELECT
RD.Amount_Amount RevenueBilledToDate_Amount
,RD.Amount_Currency RevenueBilledToDate_Currency
,RD.StateId
,RD.AssetId
,ISNULL((SELECT ISNULL(SUM(BRR.RevenueBilledToDate_Amount),0.00) FROM #BilledRentalReceivable_Temp BRR
WHERE RD.AssetId = BRR.AssetId AND RD.StateId = BRR.StateId AND BRR.IsActive = 1 AND BRR.ContractId = RD.EntityId),0.00) BilledRentalReceivable_Amount
,RD.Amount_Currency CumulativeAmount_Currency
,RD.ReceivableDetailId
,RD.DueDate
,ROW_NUMBER() OVER (ORDER BY RD.DueDate, RD.ReceivableId, RD.ReceivableDetailId) RowNumber
,RD.EntityId ContractId
,RD.CustomerId
,RD.ReceivableId
INTO #BilledRentalReceivableDetail
FROM #ReceivableDetail_Temp RD
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
,RD.CustomerId
,RD.ReceivableId
FROM #BilledRentalReceivableDetail RD
;
SELECT * INTO #LeaseBasedReceivable
FROM #ContractBasedReceivableDetail
EXCEPT
SELECT * FROM  #ContractBasedReceivableDetail
WHERE IsAssetBased = 1 OR IsLeaseBased = 0;
IF(EXISTS(SELECT * FROM #LeaseBasedReceivable))
BEGIN
INSERT INTO #AssetsInLease
SELECT AL.AssetId, AL.CustomerCost, AL.FixedTermRentalAmount, AL.LeaseAssetId, AL.Id, AL.CustomerId FROM
((SELECT DISTINCT
CLA.AssetId AS AssetId
,CLA.NBV_Amount AS CustomerCost
,CLA.TaxBasisAmount_Amount AS FixedTermRentalAmount
,CLA.Id AS LeaseAssetId
,C.Id
,CLF.CustomerId
FROM Contracts C
INNER JOIN LeaseFinances CLF ON C.Id = CLF.ContractId AND CLF.IsCurrent = 1
INNER JOIN #LeaseBasedReceivable LBR ON LBR.ContractId = CLF.ContractId
INNER JOIN LeaseAssets CLA ON CLF.Id = CLA.LeaseFinanceId AND CLA.IsActive = 1
INNER JOIN Assets A ON CLA.AssetId = A.Id AND (A.FinancialType = 'Real'
OR A.FinancialType = 'Placeholder' OR A.FinancialType = 'NegativeReturn'))
UNION
(SELECT DISTINCT
LALA.AssetId AS AssetId
,LALA.NBV_Amount AS CustomerCost
,LALA.TaxBasisAmount_Amount AS FixedTermRentalAmount
,LALA.Id AS LeaseAssetId
,C.Id
,LF.CustomerId
FROM Contracts C
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId
INNER JOIN LeaseAmendments LA ON LA.CurrentLeaseFinanceId = LF.Id
AND LA.AmendmentType = 'Payoff' AND LA.LeaseAmendmentStatus = 'Approved'
INNER JOIN LeaseAssets LALA ON LA.OriginalLeaseFinanceId = LALA.LeaseFinanceId AND LALA.IsActive = 1
INNER JOIN #LeaseBasedReceivable LBR ON LBR.ContractId = LF.ContractId AND LBR.CustomerId = LF.CustomerId
INNER JOIN Payoffs PO ON LA.OriginalLeaseFinanceId = PO.LeaseFinanceId AND PO.FullPayoff = 1
AND PO.Status = 'Activated'
INNER JOIN Assets PA ON LALA.AssetId = PA.Id AND (PA.FinancialType = 'Real'
OR PA.FinancialType = 'Placeholder' OR PA.FinancialType = 'NegativeReturn')
)) AS AL
;
SELECT
ROW_NUMBER() OVER (PARTITION BY AL.AssetId,LF.ContractId ORDER BY AL.AssetId,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) < 0 THEN AL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) > 0 THEN AL.EffectiveFromDate END  ASC, Al.Id DESC) Row_Num,
AL.EffectiveFromDate 'LocationEffectiveDate',
AL.LocationId 'LocationId',
AL.Id 'AssetLocationId',
LA.AssetId 'AssetId',
LA.CustomerCost_Amount 'CustomerCost',
LA.Id 'LeaseAssetId',
LF.ContractId,
LF.CustomerId,
LBR.ReceivableTypeId,
LBR.ReceivableCodeId
INTO #AllLeaseAssetLocations
FROM
LeaseFinances LF
INNER JOIN Contracts C ON LF.ContractId = C.Id
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
INNER JOIN #LeaseBasedReceivable LBR ON LF.ContractId = LBR.ContractId
INNER JOIN #ContractIdTable CT ON CT.ContractId = LBR.ContractId
LEFT JOIN AssetLocations AL ON A.Id = AL.AssetId AND AL.IsActive = 1
WHERE (A.FinancialType = 'Real' OR A.FinancialType = 'Placeholder'
OR A.FinancialType = 'NegativeReturn') AND LA.IsActive = 1 AND C.TaxAssessmentLevel <> 'Customer'
INSERT INTO #AllLeaseAssetLocations
(
Row_Num,
LocationEffectiveDate,
LocationId,
AssetLocationId,
AssetId,
CustomerCost,
LeaseAssetId,
ContractId,
CustomerId,
ReceivableTypeId,
ReceivableCodeId
)
SELECT
ROW_NUMBER() OVER (PARTITION BY LA.AssetId,LF.ContractId ORDER BY LA.AssetId,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) < 0 THEN AL.EffectiveFromDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, AL.EffectiveFromDate) > 0 THEN AL.EffectiveFromDate END  ASC, Al.Id DESC) Row_Num,
AL.EffectiveFromDate 'LocationEffectiveDate',
AL.LocationId 'LocationId',
AL.Id 'AssetLocationId',
LA.AssetId 'AssetId',
LA.CustomerCost_Amount 'CustomerCost',
LA.Id 'LeaseAssetId',
LF.ContractId,
LF.CustomerId,
LBR.ReceivableTypeId,
LBR.ReceivableCodeId
FROM
LeaseFinances LF
INNER JOIN Contracts C ON LF.ContractId = C.Id
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
INNER JOIN #LeaseBasedReceivable LBR ON LF.ContractId = LBR.ContractId
INNER JOIN #ContractIdTable CT ON CT.ContractId = LBR.ContractId
LEFT JOIN CustomerLocations AL ON LF.CustomerId = AL.CustomerId AND AL.IsActive = 1
WHERE (A.FinancialType = 'Real' OR A.FinancialType = 'Placeholder'
OR A.FinancialType = 'NegativeReturn') AND LA.IsActive = 1 AND C.TaxAssessmentLevel = 'Customer'
;
SELECT * INTO #CTE_LeaseAssetLocationsAsOfDueDate
FROM #AllLeaseAssetLocations
WHERE Row_Num = 1
;
SELECT
ROW_NUMBER() OVER (PARTITION BY AssetLoc.AssetLocationId ORDER BY
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, CT.InvoiceDueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
P.TaxAreaEffectiveDate 'TaxAreaEffectiveDate',
P.TaxAreaId 'TaxAreaId',
AssetLoc.AssetLocationId 'AssetLocationId',
AssetLoc.AssetId 'AssetId',
AssetLoc.LocationEffectiveDate 'LocationEffectiveDate',
AssetLoc.CustomerCost 'CustomerCost',
AssetLoc.LocationId 'LocationId',
AssetLoc.LeaseAssetId 'LeaseAssetId',
AssetLoc.ContractId,
AssetLoc.CustomerId,
AssetLoc.ReceivableTypeId,
AssetLoc.ReceivableCodeId
INTO #CTE_AllTaxAreaIdsForLocation
FROM
#CTE_LeaseAssetLocationsAsOfDueDate AssetLoc
JOIN #ContractIdTable CT ON AssetLoc.ContractId = CT.ContractId
LEFT JOIN LocationTaxAreaHistories p ON P.LocationId = AssetLoc.LocationId
;
SELECT * INTO #CTE_TaxAreaIdAsOfDueDate
FROM #CTE_AllTaxAreaIdsForLocation;
INSERT INTO #LocationDetailsForLeaseAssets
SELECT DISTINCT
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
CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) 'IsVertexSupportedLocation',
CTE.ContractId,
CTE.CustomerId,
ISNULL(L.JurisdictionId,0) 'TaxJurisdictionId'
,DTTFRT.TaxTypeId
,LA.StateTaxTypeId
,LA.CountyTaxTypeId
,LA.CityTaxTypeId
,S.Id StateId
,CTE.ReceivableCodeId
,L.Code LocationCode
FROM
#CTE_TaxAreaIdAsOfDueDate CTE
INNER JOIN Assets A ON CTE.AssetId = A.Id
INNER JOIN AssetTypes AT ON A.TypeId = AT.Id
LEFT JOIN Locations L ON CTE.LocationId = L.Id
LEFT JOIN States S ON L.StateId =S.Id
LEFT JOIN Countries C ON S.CountryId = C.Id
LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
LEFT JOIN LeaseAssets LA ON LA.AssetId = A.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON CTE.ReceivableTypeId = DTTFRT.ReceivableTypeId AND C.Id = DTTFRT.CountryId
END
SELECT DISTINCT
lm.*,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountryTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsStateTaxExempt,0) = 1 OR IsNULL(AssetRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1  OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCityTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
CAST(CASE WHEN IsNULL(TaxExemptRules.IsCountyTaxExempt,0) = 1 OR IsNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1  OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt
INTO #LocationDetailsForLeaseAsset
FROM
#LocationDetailsForLeaseAssets lm
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ON rct.TaxExemptRuleId = TaxExemptRules.Id
LEFT JOIN Assets a ON a.Id = lm.AssetId
LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
LEFT JOIN LeaseFinances lf ON lm.ContractId = lf.ContractId AND lf.IsCurrent = 1
LEFT JOIN TaxExemptRules LeaseRule ON lf.TaxExemptRuleId = LeaseRule.Id
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;
SELECT * FROM #AssetsInLease;
SELECT * FROM #LocationDetailsForLeaseAsset WHERE AssetLocationId IS NOT NULL;
END

GO
