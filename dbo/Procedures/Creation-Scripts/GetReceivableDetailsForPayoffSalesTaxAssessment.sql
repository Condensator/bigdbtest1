SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceivableDetailsForPayoffSalesTaxAssessment]
(
@PayoffId BIGINT,
@IsRepossessionPayoff BIT,
@PayoffReceivableSourceTable NVARCHAR(20),
@SundryReceivableTypeName NVARCHAR(20) = NULL,
@PropertyTaxReceivableTypeName NVARCHAR(20) = NULL,
@CanGenerateInvoiceRequestFile BIT,
@IsVATApplicable BIT,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
DECLARE @TaxSourceTypeVertex NVARCHAR(10)
SET @TaxSourceTypeVertex = 'Vertex'
--DECLARE @PayoffId BIGINT
--DECLARE @IsRepossessionPayoff BIT
--DECLARE @PayoffReceivableSourceTable NVARCHAR(20)
--DECLARE @SundryReceivableTypeName NVARCHAR(20) = NULL  
--DECLARE @PropertyTaxReceivableTypeName NVARCHAR(20) = NULL  
--DECLARE @CanGenerateInvoiceRequestFile BIT
DECLARE @BuyoutReceivableCodeId BIGINT;
DECLARE @Currency NVARCHAR(3);  

--SET @PayoffId = 32 
--SET @IsRepossessionPayoff = 0
--SET @PayoffReceivableSourceTable = 'LeasePayoff'
--SET @SundryReceivableTypeName  = 'Sundry' 
--SET @PropertyTaxReceivableTypeName = 'PropertyTax'
--SET @CanGenerateInvoiceRequestFile =  0
SET @BuyoutReceivableCodeId = (SELECT BuyoutReceivableCodeId FROM Payoffs WHERE Id = @PayoffId);
SET @Currency = (SELECT BuyoutAmount_Currency FROM Payoffs WHERE Id = @PayoffId);


SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #AllAssetLocations
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

(SELECT
	ReceivableId = R.Id,
	DueDate = R.DueDate,
	LocationId = R.LocationId,
	ContractId = R.EntityId,
	LegalEntityId = R.LegalEntityId,
	ReceivableCodeId = R.ReceivableCodeId,
	IsLeaseBased = 1,
	C.TaxAssessmentLevel,
	RT.IsRental,
	RT.Name [ReceivableTypeName],
	LE.TaxPayer,
	LE.IsAssessSalesTaxAtSKULevel,
	RC.Name [ReceivableCode],
	RC.IsTaxExempt IsExemptAtReceivableCode,
	RT.Id [ReceivableTypeId],
	R.CustomerId
INTO #ReceivablesInfo
FROM PayoffSundries PFS
INNER JOIN Sundries S ON PFS.SundryId = S.Id
INNER JOIN Receivables R ON S.ReceivableId = R.Id
INNER JOIN Contracts C ON R.EntityId = C.Id
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE PFS.PayoffId = @PayoffId
AND S.IsTaxExempt = 0
AND R.IsActive = 1 AND 1 = CASE 
								WHEN @IsVATApplicable = 1 THEN 1 
								WHEN R.LocationId IS NOT NULL THEN 1 
								ELSE 0 END
AND (PFS.IsActive = 1 AND S.IsActive = 1))
UNION
(SELECT
	ReceivableId = R.Id,
	DueDate = R.DueDate,
	LocationId = R.LocationId,
	ContractId = R.EntityId,
	LegalEntityId = R.LegalEntityId,
	ReceivableCodeId = R.ReceivableCodeId,
	IsLeaseBased = 0,
	C.TaxAssessmentLevel,
	RT.IsRental,
	RT.Name [ReceivableTypeName],
	LE.TaxPayer,
	LE.IsAssessSalesTaxAtSKULevel,
	RC.Name [ReceivableCode],
	RC.IsTaxExempt IsExemptAtReceivableCode,
	RT.Id [ReceivableTypeId],
	R.CustomerId
FROM Payoffs PF
INNER JOIN Receivables R ON PF.Id = R.SourceId AND R.SourceTable = @PayoffReceivableSourceTable
INNER JOIN Contracts C ON R.EntityId = C.Id
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
WHERE PF.Id = @PayoffId AND R.IsActive = 1 
AND R.ReceivableCodeId IN (PF.PayoffReceivableCodeId, PF.BuyoutReceivableCodeId, PF.PropertyTaxEscrowReceivableCodeId))

DECLARE @TaxAssessmentLevel NVARCHAR(20)
SELECT @TaxAssessmentLevel = TaxAssessmentLevel FROM #ReceivablesInfo

SELECT
	RDs.ReceivableId ReceivableId,
	MAX(GLT.Id) GLTemplateId
INTO #SalesTaxGLTemplateDetail
FROM #ReceivablesInfo RDs
INNER JOIN LegalEntities LE ON LE.Id = RDs.LegalEntityId AND LE.Status = 'Active'
INNER JOIN GLConfigurations GLC ON GLC.Id = LE.GLConfigurationId
INNER JOIN GLTemplates GLT ON GLC.Id = GLT.GLConfigurationId AND GLT.IsActive = 1
INNER JOIN GLTransactionTypes GTT ON GLT.GLTransactionTypeId = GTT.Id AND GTT.IsActive = 1 AND GTT.Name = 'SalesTax'
GROUP BY
RDs.ReceivableId;

SELECT
	PF.Id [PayoffId],
	Con.Id [ContractId],
	Con.SequenceNumber,
	Con.ContractType,
	Con.SalesTaxRemittanceMethod [ContractSalesTaxRemittanceMethod],
	Con.TaxAssessmentLevel [ContractTaxAssessmentLevel],
	LF.IsSalesTaxExempt AS IsExemptAtLease,
	LF.TaxExemptRuleId [LeaseTaxExemptRuleId],
	LFD.CommencementDate,
	LFD.MaturityDate,
	LFD.BookedResidual_Amount - LFD.CustomerGuaranteedResidual_Amount - LFD.ThirdPartyGuaranteedResidual_Amount AS LessorRisk,
	C.Id [CustomerId],
	P.PartyNumber,
	P.VATRegistrationNumber,
	CC.Class [ClassCode],
	DPT.LeaseType,	
	IncorporationCountry.ShortName [IncorporationCountryShortName],
	CAST(CASE WHEN con.SyndicationType = 'None' THEN 0 ELSE 1 END AS BIT) AS IsSyndicated
INTO #PayoffContractLevelInfo
FROM Payoffs PF
INNER JOIN LeaseFinances LF ON PF.LeaseFinanceId = LF.Id
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
INNER JOIN Contracts Con ON LF.ContractId = Con.Id
LEFT JOIN DealProductTypes DPT ON Con.DealProductTypeId = DPT.Id
LEFT JOIN Customers C ON PF.BillToCustomerId = C.Id
LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id 
LEFT JOIN Parties P ON C.Id = P.Id
LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
WHERE PF.Id = @PayoffId

SELECT
	PA.PayoffId,
	PA.DropOffLocationId,
	PA.UtilitySaleAtAuction,
	A.Id AssetId,
	SLBC.Code [SaleLeaseBackCode],
	A.IsParent,
	A.GrossVehicleWeight,
	A.IsElectronicallyDelivered,	
	A.IsTaxExempt,
	A.TypeId [AssetTypeId],	
	ACC.ClassCode,
	A.IsSKU,
	A.TitleTransferCodeId,
	STEL.Name [SalesTaxExemptionLevel],
	A.UsageCondition,
	A.TaxExemptRuleId [AssetTaxExemptRuleId],	
	A.AssetUsageId,
	LA.SalesTaxRemittanceResponsibility,
	LA.AcquisitionLocationId [LeaseAssetAcquisitionLocationId],
	LA.StateTaxTypeId,
	LA.CountyTaxTypeId,
	LA.CityTaxTypeId
INTO #PayoffAssetLevelInfo
FROM PayoffAssets PA
INNER JOIN LeaseAssets LA ON PA.LeaseAssetId = LA.Id
INNER JOIN Assets A ON LA.AssetId = A.Id
LEFT JOIN SaleLeasebackCodeConfigs SLBC ON A.SaleLeasebackCodeId = SLBC.Id
LEFT JOIN SalesTaxExemptionLevelConfigs STEL ON A.SalesTaxExemptionLevelId = STEL.Id
LEFT JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN AssetClassCodes ACC ON ATS.AssetClassCodeId = ACC.Id
WHERE PA.PayoffId = @PayoffId AND PA.IsActive = 1

IF @TaxAssessmentLevel = 'Customer'
BEGIN
INSERT INTO #AllAssetLocations
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
	Row_Num = CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId THEN 1
	ELSE ROW_NUMBER() OVER (PARTITION BY RD.AssetId, RD.Id ORDER BY RD.AssetId,
	CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) = 0 THEN 0 ELSE 1 END,
	CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) < 0 THEN CL.EffectiveFromDate END DESC,
	CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, CL.EffectiveFromDate) > 0 THEN CL.EffectiveFromDate END  ASC,CL.Id DESC) END,
	EffectiveFromDate =  CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId THEN RecInfo.DueDate
	ELSE CL.EffectiveFromDate END,
	DueDate = RecInfo.DueDate,
	LocationId = CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId AND PA.DropOffLocationId IS NOT NULL THEN PA.DropOffLocationId
	ELSE
	CL.LocationId
	END,
	AssetId = PA.AssetId,
	ReceivableDetailId = RD.Id,
	AssetLocationId = CL.Id ,
	SaleLeasebackCode = PA.SaleLeaseBackCode,
	IsElectronicallyDelivered = PA.IsElectronicallyDelivered,
	ReciprocityAmount_Amount = 0,
	ReciprocityAmount_Currency = @Currency,
	LienCredit_Amount = 0,
	LienCredit_Currency = @Currency,
	GrossVehicleWeight = ISNULL(PA.GrossVehicleWeight,0),
	IsMultiComponent = ISNULL(PA.IsParent,CONVERT(BIT,0)),
	RecInfo.TaxAssessmentLevel,
	ISNULL(CCL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT)),
	CCL.TaxBasisType
FROM #ReceivablesInfo RecInfo
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND (RD.IsTaxAssessed = 0 OR @CanGenerateInvoiceRequestFile = 1)
INNER JOIN #PayoffAssetLevelInfo PA ON RD.AssetId = PA.AssetId
LEFT JOIN CustomerLocations CL ON CL.CustomerId = RecInfo.CustomerId
	AND CL.IsActive = 1
	AND (@IsRepossessionPayoff = 0 OR (RecInfo.ReceivableCodeId <> @BuyoutReceivableCodeId) OR PA.DropOffLocationId IS NULL)
LEFT JOIN ContractCustomerLocations CCL ON CL.Id = CCL.CustomerLocationId AND RecInfo.ContractId = CCL.ContractId AND CCL.UpfrontTaxAssessedInLegacySystem = 1
WHERE RecInfo.IsLeaseBased = 0
END
ELSE
BEGIN
INSERT INTO #AllAssetLocations
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
	Row_Num = CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId 
				   THEN 1
				   ELSE ROW_NUMBER() OVER (PARTITION BY AL.AssetId, RD.Id ORDER BY AL.AssetId,
			  CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) = 0 
				   THEN 0 
				   ELSE 1 END,	
			  CASE WHEN DATEDIFF(DAY, RecInfo.DueDate, AL.EffectiveFromDate ) < 0 
				   THEN AL.EffectiveFromDate END DESC,
			  CASE WHEN DATEDIFF(DAY, RecInfo.DueDate,  AL.EffectiveFromDate ) > 0 
				   THEN AL.EffectiveFromDate END ASC,AL.Id DESC) END,
	EffectiveFromDate = CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId 
							 THEN RecInfo.DueDate
							 ELSE AL.EffectiveFromDate END,
	DueDate = RecInfo.DueDate,
	LocationId = CASE WHEN @IsRepossessionPayoff = 1 AND RecInfo.ReceivableCodeId = @BuyoutReceivableCodeId AND PA.DropOffLocationId IS NOT NULL 
					  THEN PA.DropOffLocationId
				      ELSE AL.LocationId END,
	AssetId = PA.AssetId,
	ReceivableDetailId = RD.Id,
	AssetLocationId = AL.Id ,
	SaleLeasebackCode = PA.SaleLeasebackCode,
	IsElectronicallyDelivered = PA.IsElectronicallyDelivered,
	ReciprocityAmount_Amount = ISNULL(AL.ReciprocityAmount_Amount, 0),
	ReciprocityAmount_Currency = ISNULL(AL.ReciprocityAmount_Currency, @Currency),
	LienCredit_Amount = ISNULL(AL.LienCredit_Amount, 0),
	LienCredit_Currency = ISNULL(AL.LienCredit_Currency, @Currency),
	GrossVehicleWeight = ISNULL(PA.GrossVehicleWeight,0),
	IsMultiComponent = ISNULL(PA.IsParent,CONVERT(BIT,0)),
	RecInfo.TaxAssessmentLevel,
	ISNULL(AL.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT)),
	AL.TaxBasisType
FROM #ReceivablesInfo RecInfo
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId AND (RD.IsTaxAssessed = 0 OR @CanGenerateInvoiceRequestFile = 1)
INNER JOIN #PayoffAssetLevelInfo PA ON RD.AssetId = PA.AssetId
INNER JOIN AssetLocations AL ON PA.AssetId = AL.AssetId 
	AND AL.IsActive = 1
	AND (@IsRepossessionPayoff = 0 OR PA.DropOffLocationId IS NULL OR RecInfo.ReceivableCodeId <> @BuyoutReceivableCodeId)
WHERE RecInfo.IsLeaseBased = 0
END

;WITH CTE_AssetLocationsNearestToPayoffDate
AS
(
SELECT  
	LAL.EffectiveFromDate,
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
FROM #AllAssetLocations AS LAL
WHERE LAL.Row_Num = 1
),
CTE_LocationInfoNearestToPayoffDate
AS
(
SELECT  
	 TE.LocationId AS LocationId
	,LocInfo.StateShortName AS MainDivision
	,LocInfo.CountryShortName AS Country
	,LocInfo.City AS City
	,LocInfo.ApprovalStatus AS LocationStatus
	,LocInfo.IsActive AS IsLocationActive
	,TE.EffectiveFromDate AS EffectiveFromDate
	,TE.ReceivableDetailId AS ReceivableDetailId
	,TE.AssetLocationId AS AssetLocationId
	,LocInfo.IsVertexSupported 
    ,TE.SaleLeasebackCode
	,TE.IsElectronicallyDelivered
	,TE.ReciprocityAmount_Currency
	,TE.ReciprocityAmount_Amount
	,TE.LienCredit_Amount
	,TE.LienCredit_Currency 
	,TE.GrossVehicleWeight
	,TE.IsMultiComponent
	,LocInfo.UpfrontTaxMode
	,TE.DueDate
	,TE.UpfrontTaxAssessedInLegacySystem
	,LocInfo.CountryId
	,LocInfo.StateId
	,LocInfo.StateShortName
	,LocInfo.Code
	,LocInfo.JurisdictionId
	,TE.TaxBasisType
FROM CTE_AssetLocationsNearestToPayoffDate TE
INNER JOIN 
( 
	SELECT 
		Loc.Code, Loc.JurisdictionId, Loc.UpfrontTaxMode, 
		States.Id [StateId], States.ShortName [StateShortName], Loc.Id [LocationId], Countries.ShortName [CountryShortName],
		Countries.Id [CountryId], Loc.IsActive,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupported
		, Loc.City, Loc.ApprovalStatus
	FROM Locations Loc 
	INNER JOIN States states ON Loc.StateId = states.Id
	INNER JOIN Countries countries ON states.CountryId = countries.Id
	WHERE Loc.Id IN (SELECT DISTINCT LocationId FROM CTE_AssetLocationsNearestToPayoffDate)
) AS LocInfo ON TE.LocationId = LocInfo.LocationId
),
CTE_AllTaxAreaInfo
AS
(
SELECT 	
	ROW_NUMBER() OVER (PARTITION BY Loc.ReceivableDetailId ORDER BY 
		CASE WHEN DATEDIFF(DAY,Loc.DueDate, LocTaxAreaHistory.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
		CASE WHEN DATEDIFF(DAY, Loc.DueDate, LocTaxAreaHistory.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC, 
		CASE WHEN DATEDIFF(DAY, Loc.DueDate, LocTaxAreaHistory.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
	LocTaxAreaHistory.TaxAreaEffectiveDate,
	LocTaxAreaHistory.TaxAreaId,
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
	,Loc.CountryId
	,Loc.StateId
	,Loc.StateShortName
	,Loc.Code
	,Loc.JurisdictionId
	,LOC.TaxBasisType
FROM CTE_LocationInfoNearestToPayoffDate Loc
LEFT JOIN 
	(
		SELECT LocationId, TaxAreaEffectiveDate, TaxAreaId FROM LocationTaxAreaHistories
		WHERE LocationId IN (SELECT DISTINCT LocationId FROM CTE_AssetLocationsNearestToPayoffDate)
	) AS LocTaxAreaHistory ON Loc.LocationId = LocTaxAreaHistory.LocationId
)
SELECT * 
INTO #LocationTaxAreaInfoNearestToPayoffDate
FROM CTE_AllTaxAreaInfo
WHERE Row_Num = 1

;WITH CTE_DistinctLocationPriorToPayoffDate
AS
(
	SELECT DISTINCT LocationId,ReceivableDetailId FROM #AllAssetLocations WHERE Row_Num = 2
)
SELECT #AllAssetLocations.ReceivableDetailId, FromState.ShortName [StateShortName] 
INTO #LocationTaxAreaInfoPriorToPayoffDate
FROM CTE_DistinctLocationPriorToPayoffDate FromLoc
INNER JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
INNER JOIN States FromState ON FromLocation.StateId = FromState.Id
INNER JOIN #AllAssetLocations ON FromLocation.Id = #AllAssetLocations.LocationId AND #AllAssetLocations.ReceivableDetailId=FromLoc.ReceivableDetailId

;WITH CTE_RecDetailInfo
AS
(
	SELECT RD.Id [ReceivableDetailId], RD.AssetId [AssetId], RecInfo.DueDate, RecInfo.IsRental, RecInfo.ReceivableId,
	RD.Amount_Amount [Amount], RecInfo.ReceivableTypeName, RecInfo.TaxPayer, RecInfo.ReceivableTypeId, RecInfo.ReceivableCodeId,
	RecInfo.LegalEntityId, RecInfo.IsAssessSalesTaxAtSKULevel, RecInfo.IsExemptAtReceivableCode, RecInfo.ReceivableCode
	FROM #ReceivablesInfo RecInfo
	INNER JOIN ReceivableDetails RD ON RecInfo.ReceivableId = RD.ReceivableId	
	WHERE RecInfo.IsLeaseBased = 0 AND (RD.IsTaxAssessed = 0 OR @CanGenerateInvoiceRequestFile = 1)
)
SELECT 
	RD.ReceivableDetailId
	,RD.ReceivableId AS ReceivableId
	,RD.DueDate AS DueDate
	,RD.IsRental AS IsRental
	,PA.ClassCode AS Product
	,0.00 AS FairMarketValue
	,0.00 AS Cost
	,0.00 AS AmountBilledToDate
	,RD.Amount AS ExtendedPrice
	,@Currency AS Currency
	,CONVERT(BIT,1) AS IsAssetBased
	,CONVERT(BIT,0) AS IsLeaseBased
	,CASE WHEN CONVERT(BIT,1) IN (PA.IsTaxExempt,PA.UtilitySaleAtAuction) THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS IsExemptAtAsset
	,CASE WHEN RD.ReceivableTypeName = 'BuyOut' THEN 'SALE' ELSE 'LEASE' END AS TransactionType
	,RD.TaxPayer AS Company
	,Contract.PartyNumber AS CustomerCode
	,Contract.CustomerId  AS CustomerId
	,Contract.ClassCode AS ClassCode
	,Loc.Code AS LocationCode
	,Loc.LocationId AS LocationId
	,Loc.MainDivision AS MainDivision
	,Loc.Country AS Country
	,Loc.City AS City
	,Loc.TaxAreaId AS TaxAreaId
	,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	,Loc.IsLocationActive
	,Contract.ContractId
	,CAST(NULL as Date) AS RentAccrualStartDate 
	,0.00 AS CustomerCost
	,Contract.IsExemptAtLease AS IsExemptAtLease
	,Contract.LessorRisk AS LessorRisk
	,Loc.AssetLocationId AS AssetLocationId
	,Loc.LocationStatus AS LocationStatus
	,CONVERT(BIT,0) AS IsExemptAtSundry
	--,RecT.Id AS ReceivableTaxId
	,Loc.IsVertexSupported AS IsVertexSupportedLocation
	,CASE WHEN RD.IsRental = 1 THEN 'FMV' ELSE '' END AS ContractType
	,Contract.SequenceNumber AS LeaseUniqueId
	,CASE WHEN (RD.IsRental = 1) THEN '' ELSE RD.ReceivableCode END AS SundryReceivableCode
	,PA.ClassCode AS AssetType
	,Contract.LeaseType AS LeaseType
	,ISNULL(CAST((DATEDIFF(day,Contract.CommencementDate,Contract.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00) AS LeaseTerm
	,CAST(NULL AS NVARCHAR(40)) AS TitleTransferCode 
	,Loc.EffectiveFromDate AS LocationEffectiveDate
	,RD.ReceivableTypeName AS ReceivableType
	,RD.LegalEntityId 'LegalEntityId'
	,0 'Id'
	,CAST(0 AS BIT) 'IsManuallyAssessed'
	,'_' 'TransactionCode'
	,Loc.TaxBasisType
	,Loc.IsMultiComponent AS IsMultiComponent
	,STGL.GLTemplateId GlTemplateId
	,RD.IsExemptAtReceivableCode IsExemptAtReceivableCode	
	,Contract.ContractType ContractTypeValue
	,ISNULL(Loc.JurisdictionId,CAST(0 AS BIGINT)) AS TaxJurisdictionId
	,RD.ReceivableTypeId AS ReceivableTypeId
	,RD.ReceivableCodeId ReceivableCodeId
	,CAST('' AS NVARCHAR(40)) AS BusCode
	--User Defined Flex Fields
	,'' SaleLeasebackCode
	,ISNULL(Loc.IsElectronicallyDelivered,CONVERT(BIT,0)) AS IsElectronicallyDelivered
	,REPLACE(Contract.ContractSalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
    ,Loc.StateShortName ToState
	,FromLoc.StateShortName FromState
	,Loc.GrossVehicleWeight GrossVehicleWeight
	,ISNULL(Loc.LienCredit_Amount,0.00) LienCredit_Amount
	,ISNULL(Loc.LienCredit_Currency,'USD') LienCredit_Currency
	,ISNULL(Loc.ReciprocityAmount_Amount, 0.00) ReciprocityAmount_Amount
	,ISNULL(Loc.ReciprocityAmount_Currency, 'USD') ReciprocityAmount_Currency
	,RD.AssetId AS AssetId
	,Contract.IsSyndicated
	,CAST(NULL AS NVARCHAR) AS EngineType
	,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
	,PA.SalesTaxExemptionLevel
	,Contract.ContractTaxAssessmentLevel AS TaxAssessmentLevel
	,DTTFRT.TaxTypeId
	,PA.StateTaxTypeId
	,PA.CountyTaxTypeId
	,PA.CityTaxTypeId
	,Loc.StateId --NULL AS StateId--,ToState.Id StateId
	,ISNULL(Loc.UpfrontTaxMode,'_') UpfrontTaxMode
	,ISNULL(Contract.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	,ISNULL(Contract.IncorporationCountryShortName, NULL) AS ISOCountryCode
	,Contract.CommencementDate AS CommencementDate
	,Contract.MaturityDate MaturityDate
	,CAST(null as BIGINT) as AssetSKUId
	,CAST(null as BIGINT) as ReceivableSKUId
	,CASE WHEN (RD.ReceivableTypeName = 'PropertyTaxEscrow' OR RD.IsAssessSalesTaxAtSKULevel = 0) THEN 0 ELSE CONVERT(BIT,PA.IsSKU) END AS 'HasSKU' 
	,Loc.UpfrontTaxAssessedInLegacySystem
	INTO #AssetBasedReceivablesInfos
FROM
#PayoffAssetLevelInfo PA
INNER JOIN #PayoffContractLevelInfo Contract ON Pa.PayoffId = Contract.PayoffId
INNER JOIN CTE_RecDetailInfo RD ON PA.AssetId = RD.AssetId
LEFT JOIN #LocationTaxAreaInfoNearestToPayoffDate Loc ON RD.ReceivableDetailId = Loc.ReceivableDetailId
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RD.ReceivableTypeId = DTTFRT.ReceivableTypeId AND Loc.CountryId = DTTFRT.CountryId
LEFT JOIN #LocationTaxAreaInfoPriorToPayoffDate FromLoc ON RD.ReceivableDetailId = FromLoc.ReceivableDetailId
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RD.ReceivableId = STGL.ReceivableId

SELECT 
	DISTINCT
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
		AU.Usage [AssetUsage],
		CASE WHEN STRH.EffectiveTillDate IS NOT NULL AND STRH.EffectiveTillDate >= lm.DueDate THEN STRH.SalesTaxRemittanceResponsibility ELSE PA.SalesTaxRemittanceResponsibility END AS SalesTaxRemittanceResponsibility,
		PA.LeaseAssetAcquisitionLocationId [AcquisitionLocationId],
		ISNULL(PA.UsageCondition,'_') AS AssetUsageCondition
INTO #AssetBasedReceivablesInfo
FROM #AssetBasedReceivablesInfos lm
INNER JOIN #PayoffAssetLevelInfo PA ON lm.AssetId = PA.AssetId
INNER JOIN #PayoffContractLevelInfo Contract ON lm.ContractId = Contract.ContractId
LEFT JOIN AssetUsages AU ON AU.Id = PA.AssetUsageId
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN TaxExemptRules AssetRule ON PA.AssetTaxExemptRuleId = AssetRule.Id 
LEFT JOIN ContractSalesTaxRemittanceResponsibilityHistories STRH ON STRH.AssetId = PA.AssetId AND STRH.ContractId = Contract.ContractId
LEFT JOIN TaxExemptRules LeaseRule ON LeaseRule.Id = Contract.LeaseTaxExemptRuleId
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;

;WITH cte_SKUReceivables
AS
(
SELECT 
	  ReceivableDetailId
FROM #AssetBasedReceivablesInfo
WHERE HasSKU = 1
GROUP BY ReceivableDetailId
)
SELECT
	ReceivableSKUs.ReceivableDetailId,
	ReceivableSKUs.AssetSKUId,
	ReceivableSKUs.Id [ReceivableSKUId],
	ReceivableSKUs.Amount_Amount [Amount]
INTO #ReceivableSKUs
FROM cte_SKUReceivables
INNER JOIN ReceivableSKUs ON cte_SKUReceivables.ReceivableDetailId = ReceivableSKUs.ReceivableDetailId

;WITH cte_SKUAssets
AS
(
SELECT
	AssetId
FROM #AssetBasedReceivablesInfo
WHERE HasSKU = 1
GROUP BY AssetId
)
SELECT ASKU.Id [AssetSKUId] , ASKU.IsSalesTaxExempt , ACC.ClassCode
INTO #AssetSKUs
FROM cte_SKUAssets
INNER JOIN AssetSKUs ASKU on cte_SKUAssets.AssetId = ASKU.AssetId
INNER JOIN AssetTypes AT ON ASKU.TypeId=AT.Id
INNER JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id;

SELECT
	A.ReceivableDetailId AS ReceivableDetailId
	,A.ReceivableId AS ReceivableId
	,A.DueDate AS DueDate
	,A.IsRental AS IsRental
	,#AssetSKUs.ClassCode AS Product
	,0.00 AS FairMarketValue
	,0.00 AS Cost
	,0.00 AS AmountBilledToDate
	,#ReceivableSKUs.Amount AS ExtendedPrice
	,A.Currency AS Currency
	,CONVERT(BIT,1) AS IsAssetBased
	,CONVERT(BIT,0) AS IsLeaseBased
	,#AssetSKUs.IsSalesTaxExempt AS IsExemptAtAsset
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
	,0.00 AS CustomerCost --LASKU.CustomerCost_Amount  AS CustomerCost
	,A.IsExemptAtLease AS IsExemptAtLease
	,A.LessorRisk AS LessorRisk
	,A.AssetLocationId AS AssetLocationId
	,A.LocationStatus AS LocationStatus
	,A.IsExemptAtSundry AS IsExemptAtSundry
	--,A.ReceivableTaxId AS ReceivableTaxId
	,A.IsVertexSupportedLocation AS IsVertexSupportedLocation
	,A.ContractType AS ContractType
	,A.LeaseUniqueId AS LeaseUniqueId
	,A.SundryReceivableCode AS SundryReceivableCode
	,#AssetSKUs.ClassCode AS AssetType
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
	,A.BusCode AS BusCode

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
	,A.MaturityDate AS MaturityDate	
	,#ReceivableSKUs.AssetSKUId as AssetSKUId
	,#ReceivableSKUs.ReceivableSKUId as ReceivableSKUId
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
	,A.AssetUsage
	,A.SalesTaxRemittanceResponsibility
	,A.AcquisitionLocationId
	,A.AssetUsageCondition AS AssetUsageCondition
INTO #SKUBasedReceivablesInfo 
FROM #AssetBasedReceivablesInfo A
INNER JOIN #ReceivableSKUs ON A.ReceivableDetailId = #ReceivableSKUs.ReceivableDetailId
INNER JOIN #AssetSKUs ON #ReceivableSKUs.AssetSKUId = #AssetSKUs.AssetSKUId;	

SELECT  
	R.LocationId AS LocationId
	,R.DueDate
	,R.ReceivableId
	,states.ShortName AS MainDivision
	,countries.ShortName AS Country
	,Loc.City AS City
	,Loc.ApprovalStatus AS LocationStatus
	,Loc.IsActive AS IsLocationActive
	,CAST(CASE WHEN countries.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT)  AS IsVertexSupported
	,Loc.UpfrontTaxMode
INTO #TE_ReceivableLocations_Lease
FROM 
#ReceivablesInfo R 
INNER JOIN Locations Loc ON R.LocationId = Loc.Id
INNER JOIN States states ON Loc.StateId = states.Id
INNER JOIN Countries countries ON states.CountryId = countries.Id
WHERE R.IsLeaseBased = 1 And R.LocationId IS NOT NULL

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
INTO #TE_AllTaxAreaIdsForLocation_Lease
FROM #TE_ReceivableLocations_Lease Loc
LEFT JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId

SELECT * 
INTO #TE_TaxAreaIdForLocationAsOfDueDate_Lease
FROM #TE_AllTaxAreaIdsForLocation_Lease
WHERE Row_Num = 1

SELECT * 
INTO #TE_FromTaxAreaIdForLocationAsOfDueDate_Lease
FROM #TE_AllTaxAreaIdsForLocation_Lease
WHERE Row_Num = 2

SELECT
	RD.Id AS ReceivableDetailId
	,RD.ReceivableId AS ReceivableId
	,RecInfo.DueDate AS DueDate
	,RecInfo.IsRental AS IsRental
	,RecInfo.ReceivableTypeName AS Product
	,0.00 AS FairMarketValue
	,0.00 AS Cost
	,0.00 AS AmountBilledToDate
	,RD.Amount_Amount AS ExtendedPrice
	,RD.Amount_Currency AS Currency
	,CONVERT(BIT,0) AS IsAssetBased
	,CONVERT(BIT,1) AS IsLeaseBased
	,CONVERT(BIT,0) AS IsExemptAtAsset
	,'LEASE' AS TransactionType
	,RecInfo.TaxPayer AS Company
	,Contract.PartyNumber AS CustomerCode
	,Contract.CustomerId
	,Contract.ClassCode
	,ToLocation.Code AS LocationCode
	,Loc.LocationId AS LocationId
	,Loc.MainDivision AS MainDivision
	,Loc.Country AS Country
	,Loc.City AS City
	,Loc.TaxAreaId AS TaxAreaId
	,Loc.TaxAreaEffectiveDate AS TaxAreaEffectiveDate
	,Loc.IsLocationActive
	,RecInfo.ContractId AS ContractId
	,CAST(NULL AS DATE) AS RentAccrualStartDate
	,0.0 AS CustomerCost
	,Contract.IsExemptAtLease
	,Contract.LessorRisk
	,CAST(NULL AS BIGINT) AS AssetLocationId
	,Loc.LocationStatus AS LocationStatus
	,ISNULL(S.IsTaxExempt,CONVERT(BIT,0)) AS IsExemptAtSundry
	--,RecT.Id AS ReceivableTaxId
	,Loc.IsVertexSupported AS IsVertexSupportedLocation
	,CASE WHEN RecInfo.IsRental = 1 THEN 'FMV' ELSE '' END AS ContractType
	,Contract.SequenceNumber AS LeaseUniqueId
	,CASE WHEN (RecInfo.IsRental = 1) THEN '' ELSE RecInfo.ReceivableCode END AS SundryReceivableCode
	,'' AS AssetType
	,Contract.LeaseType AS LeaseType
	,ISNULL(CAST((DATEDIFF(day,Contract.CommencementDate,Contract.MaturityDate) + 1) AS DECIMAL(10,2)), 0.00) AS LeaseTerm
	,CAST(NULL AS NVARCHAR(5)) AS TitleTransferCode
	,CAST(NULL AS DATE) AS LocationEffectiveDate
	,RecInfo.ReceivableTypeName AS ReceivableType
	,RecInfo.LegalEntityId
	,0 'Id'
	,CAST(0 AS BIT) 'IsManuallyAssessed'
	,'_' 'TransactionCode'
	,'_' 'TaxBasisType'
	,CAST(0 AS BIT) AS IsMultiComponent
	,STGL.GLTemplateId GlTemplateId
	,RecInfo.IsExemptAtReceivableCode
	,Contract.ContractType ContractTypeValue
	,ISNULL(ToLocation.JurisdictionId,CAST(0 AS BIGINT)) AS TaxJurisdictionId
	,RecInfo.ReceivableTypeId
	,RecInfo.ReceivableCodeId
	,CAST('' AS NVARCHAR(40)) AS BusCode
	--User Defined Flex Fields
	,'' AS SaleLeasebackCode
	,CAST(0 AS BIT) AS IsElectronicallyDelivered
	,REPLACE(Contract.ContractSalesTaxRemittanceMethod, 'Based','') TaxRemittanceType
	,ToState.ShortName ToState
	,FromState.ShortName FromState
	,0 GrossVehicleWeight
	,0.00 LienCredit_Amount
	,'USD' LienCredit_Currency
	,0.00 ReciprocityAmount_Amount
	,'USD' ReciprocityAmount_Currency
	,CAST(NULL AS BIGINT) AS AssetId
	,Contract.IsSyndicated
	,CAST(NULL AS NVARCHAR) AS EngineType
	,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
	,'' SalesTaxExemptionLevel
	,Contract.ContractTaxAssessmentLevel AS TaxAssessmentLevel
	,DTTFRT.TaxTypeId
	,CAST(NULL AS BIGINT) StateTaxTypeId
	,CAST(NULL AS BIGINT) CountyTaxTypeId
	,CAST(NULL AS BIGINT) CityTaxTypeId
	,ToState.Id StateId
	,ISNULL(Loc.UpfrontTaxMode,'_') UpfrontTaxMode
	,ISNULL(Contract.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	,ISNULL(Contract.IncorporationCountryShortName, NULL) AS ISOCountryCode
	,Contract.CommencementDate AS CommencementDate
	,Contract.MaturityDate AS MaturityDate
	,CAST(NULL AS BIGINT) as AssetSKUId
	,CAST(NULL AS BIGINT) as ReceivableSKUId
	,CONVERT(BIT,0) 'HasSKU'
	,CAST(0 AS BIT) UpfrontTaxAssessedInLegacySystem
INTO #TE_LeaseBasedReceivablesInfos
FROM #ReceivablesInfo RecInfo
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = RecInfo.ReceivableId 
	AND (RD.IsTaxAssessed = 0 OR  @CanGenerateInvoiceRequestFile = 1)
INNER JOIN Sundries S ON RecInfo.ReceivableId = S.ReceivableId
INNER JOIN #PayoffContractLevelInfo Contract ON RecInfo.ContractId = Contract.ContractId
LEFT JOIN #TE_TaxAreaIdForLocationAsOfDueDate_Lease Loc ON RecInfo.ReceivableId = Loc.ReceivableId
LEFT JOIN Locations ToLocation ON Loc.LocationId = ToLocation.Id
LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RecInfo.ReceivableTypeId = DTTFRT.ReceivableTypeId AND ToState.CountryId = DTTFRT.CountryId
LEFT JOIN #TE_FromTaxAreaIdForLocationAsOfDueDate_Lease FromLoc ON RD.Id = FromLoc.ReceivableId
LEFT JOIN Locations FromLocation ON FromLoc.LocationId = FromLocation.Id
LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
LEFT JOIN #SalesTaxGLTemplateDetail STGL ON RecInfo.ReceivableId = STGL.ReceivableId
WHERE RecInfo.IsLeaseBased = 1;

SELECT 
	DISTINCT
	lm.*,
	CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountryTaxExempt,0) = 1 OR IsNULL(LocationRule.IsCountryTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountryTaxExempt,
	CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsStateTaxExempt,0) = 1 OR IsNULL(LocationRule.IsStateTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)StateTaxExempt,
	CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCityTaxExempt,0) = 1 OR IsNULL(LocationRule.IsCityTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CityTaxExempt,
	CAST(CASE WHEN IsNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LeaseRule.IsCountyTaxExempt,0) = 1 OR IsNULL(LocationRule.IsCountyTaxExempt,0) = 1 THEN 1 ELSE 0 END AS BIT)CountyTaxExempt,
	CASE WHEN LeaseRule.IsCountryTaxExempt = 1 THEN 'ContractTaxExemptRule' 
		WHEN LocationRule.IsCountryTaxExempt = 1 THEN 'LocationTaxExemptRule'
		WHEN ReceivableCodeRule.IsCountryTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
		ELSE '' END AS CountryTaxExemptRule,
	CASE WHEN LeaseRule.IsStateTaxExempt = 1 THEN 'ContractTaxExemptRule' 
		WHEN LocationRule.IsStateTaxExempt = 1 THEN 'LocationTaxExemptRule'
		WHEN ReceivableCodeRule.IsStateTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
		ELSE '' END AS StateTaxExemptRule,
	CASE WHEN LeaseRule.IsCityTaxExempt = 1 THEN 'ContractTaxExemptRule' 
		WHEN LocationRule.IsCityTaxExempt = 1 THEN 'LocationTaxExemptRule'
		WHEN ReceivableCodeRule.IsCityTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
		ELSE '' END AS CityTaxExemptRule,
	CASE WHEN LeaseRule.IsCountyTaxExempt = 1 THEN 'ContractTaxExemptRule' 
		WHEN LocationRule.IsCountyTaxExempt = 1 THEN 'LocationTaxExemptRule'
		WHEN ReceivableCodeRule.IsCountyTaxExempt = 1 THEN 'ReceivableCodeTaxExemptRule'
		ELSE '' END AS CountyTaxExemptRule,
		CAST(NULL AS NVARCHAR(1)) [Usage],
		CAST(NULL AS NVARCHAR(1)) AS SalesTaxRemittanceResponsibility,
		CAST(NULL AS BIGINT) AS AcquisitionLocationId,
		CAST(NULL AS NVARCHAR(1)) AS AssetUsageCondition
INTO #LeaseBasedReceivablesInfo
FROM #TE_LeaseBasedReceivablesInfos lm
INNER JOIN #PayoffContractLevelInfo Contract ON lm.ContractId = Contract.ContractId
LEFT JOIN ReceivableCodeTaxExemptRules rct ON lm.ReceivableCodeId = rct.ReceivableCodeId AND lm.StateId = rct.StateId AND rct.IsActive = 1
LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
LEFT JOIN TaxExemptRules LeaseRule ON LeaseRule.Id = Contract.LeaseTaxExemptRuleId 
LEFT JOIN Locations l ON lm.LocationId = l.Id
LEFT JOIN TaxExemptRules LocationRule ON l.TaxExemptRuleId = LocationRule.Id;


UPDATE 
	#AssetBasedReceivablesInfo
SET  
	#AssetBasedReceivablesInfo.BusCode = GLOrgStructureConfigs.BusinessCode
FROM 
#AssetBasedReceivablesInfo AssetBasedReceivablesInfo
INNER JOIN Contracts
	ON Contracts.Id = AssetBasedReceivablesInfo.ContractId
INNER JOIN LeaseFinances
	ON  LeaseFinances.ContractId = Contracts.Id
	AND LeaseFinances.IsCurrent = 1 
INNER JOIN GLOrgStructureConfigs
	ON GLOrgStructureConfigs.LegalEntityId = AssetBasedReceivablesInfo.LegalEntityId
	AND GLOrgStructureConfigs.CurrencyId = Contracts.CurrencyId
	AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
	AND GLOrgStructureConfigs.LineofBusinessId = LeaseFinances.LineofBusinessId;

UPDATE 
	#LeaseBasedReceivablesInfo
SET  
	#LeaseBasedReceivablesInfo.BusCode = GLOrgStructureConfigs.BusinessCode
FROM 
#LeaseBasedReceivablesInfo TE_LeaseBasedReceivablesInfo
INNER JOIN Contracts
	ON Contracts.Id = TE_LeaseBasedReceivablesInfo.ContractId
INNER JOIN LeaseFinances
	ON  LeaseFinances.ContractId = Contracts.Id
	AND LeaseFinances.IsCurrent = 1 
INNER JOIN GLOrgStructureConfigs
	ON GLOrgStructureConfigs.LegalEntityId = TE_LeaseBasedReceivablesInfo.LegalEntityId
	AND GLOrgStructureConfigs.CurrencyId = Contracts.CurrencyId
	AND GLOrgStructureConfigs.CostCenterId = LeaseFinances.CostCenterId
	AND GLOrgStructureConfigs.LineofBusinessId = LeaseFinances.LineofBusinessId;


SELECT * INTO #ReceivableDetailsForPayoff 
FROM 
(
SELECT * FROM #AssetBasedReceivablesInfo A WHERE A.HasSKU=0 
UNION
SELECT * FROM #SKUBasedReceivablesInfo
UNION
SELECT * FROM #LeaseBasedReceivablesInfo
) AS ReceivableDetailsForPayoff


;WITH CTE_DistinctAquisitionLocations
AS
(
	SELECT 
		AcquisitionLocationId
	FROM #ReceivableDetailsForPayoff
	GROUP BY AcquisitionLocationId
),
 CTE_AcquisitionLocationDetails
AS
(
	SELECT 
		L.Id AS AcquisitionLocationId,
		L.TaxAreaId AS AcquisitionLocationTaxAreaId,
		L.City AS AcquisitionLocationCity,
		S.ShortName AS AcquisitionLocationMainDivision,
		C.ShortName AS AcquisitionLocationCountry
	FROM CTE_DistinctAquisitionLocations RD
	JOIN Locations L ON RD.AcquisitionLocationId = L.Id
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

SELECT 
	DISTINCT RD.*,
	AD.AcquisitionLocationTaxAreaId,
	AD.AcquisitionLocationCity,
	AD.AcquisitionLocationMainDivision,
	AD.AcquisitionLocationCountry,
	ROW_NUMBER() OVER (ORDER BY RD.Id) as LineItemNumber,
	ASN.SerialNumber AS AssetSerialOrVIN,
	CAST(1 AS BIT) AS IsRetrieveSalesTax
FROM #ReceivableDetailsForPayoff RD
LEFT JOIN CTE_AcquisitionLocationDetails AD ON AD.AcquisitionLocationId = RD.AcquisitionLocationId
LEFT JOIN CTE_AssetSerialNumberDetails ASN on RD.AssetId = ASN.AssetId

DROP TABLE #AssetBasedReceivablesInfos
DROP TABLE #SalesTaxGLTemplateDetail
DROP TABLE #TE_LeaseBasedReceivablesInfos
DROP TABLE #AllAssetLocations
DROP TABLE #AssetBasedReceivablesInfo
DROP TABLE #ReceivablesInfo
DROP TABLE #SKUBasedReceivablesInfo
DROP TABLE #TE_ReceivableLocations_Lease
DROP TABLE #TE_AllTaxAreaIdsForLocation_Lease
DROP TABLE #LocationTaxAreaInfoPriorToPayoffDate
DROP TABLE #LocationTaxAreaInfoNearestToPayoffDate
DROP TABLE #TE_TaxAreaIdForLocationAsOfDueDate_Lease
DROP TABLE #TE_FromTaxAreaIdForLocationAsOfDueDate_Lease
DROP TABLE #LeaseBasedReceivablesInfo
DROP TABLE #ReceivableDetailsForPayoff
DROP TABLE #PayoffAssetLevelInfo
DROP TABLE #PayoffContractLevelInfo
DROP TABLE #ReceivableSKUs
DROP TABLE #AssetSKUs

END

GO
