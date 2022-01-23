SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	

CREATE PROC [dbo].[GetPropertyTaxCombinedTaxRateForAssets]
(
	@propertyTaxRate PropertyTaxRateTableType READONLY,
	@PropertyTaxReceivableType NVARCHAR(50),
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@AssetIds IdList READONLY
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	DECLARE @TaxSourceTypeVertex NVARCHAR(10);
	SET @TaxSourceTypeVertex = 'Vertex';


	CREATE TABLE #AssetLevelReceivableDetails
	(
		EffectiveFromDate		DATE,
		DueDate					DATE,
		LocationId				BIGINT,
		AssetId					BIGINT,
		AssetLocationId			BIGINT,
		LegalEntityId			BIGINT,
		PropertyTaxReportCodeId BIGINT,
		IsExemptAtAsset			BIT,
		TaxExemptRuleId			BIGINT
	)

	CREATE TABLE #ReceivableLocations
	(
		 ID							 INT IDENTITY(1,1)
		,LocationId					 BIGINT
		,MainDivision				 NVARCHAR(30)
		,Country					 NVARCHAR(30)
		,City						 NVARCHAR(30)
		,LocationStatus				 NVARCHAR(30)
		,IsLocationActive			 BIT
		,EffectiveFromDate			 DATE
		,AssetLocationId			 BIGINT
		,IsVertexSupportedLocation	 BIT
		,AssetId				     BIGINT
		,DueDate					 DATE
		,LegalEntityId				 BIGINT
		,PropertyTaxReportCodeId	 BIGINT
		,IsExemptAtAsset			 BIT
		,TaxJurisdictionId			 BIGINT
		,CountyTaxExempt			 BIT
		,CityTaxExempt				 BIT
		,StateTaxExempt				 BIT
		,CountryTaxExempt			 BIT		
	)

	DECLARE @ReceivableTypeId BIGINT;
	SELECT @ReceivableTypeId = (SELECT Id FROM ReceivableTypes WHERE Name = @PropertyTaxReceivableType);

	SELECT * INTO #AssetTemp 
	FROM Assets 
	WHERE Id In (Select * from @AssetIds)
	--Status IN ('Inventory','Leased','Investor','InvestorLeased') AND 
	-- After the disussion, this is removed
	--Excluded Status Donated Scrap WriteOff Sold Error Collateral CollateralOnLoan CollateralPaidOff

	SELECT	LA.AssetId,
			LeaseRule.IsCountyTaxExempt,
			LeaseRule.IsCityTaxExempt,
			LeaseRule.IsStateTaxExempt,
			LeaseRule.IsCountryTaxExempt 
	INTO #LeaseTaxExemptRules
	FROM #AssetTemp A
		INNER JOIN LeaseAssets LA ON A.Id = LA.AssetId AND LA.IsActive = 1 
		INNER JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id AND LF.IsCurrent = 1
		INNER JOIN TaxExemptRules LeaseRule ON LF.TaxExemptRuleId = LeaseRule.Id
	WHERE (A.Status = 'Leased' OR A.Status = 'InvestorLeased')

	SELECT
		AL.EffectiveFromDate AS EffectiveFromDate,
		PT.AsOfDate,
		AL.LocationId AS LocationId,
		AL.AssetId AS AssetId,
		AL.Id AS AssetLocationId,
		L.StateId
	INTO #LeaseAssetLocations
	FROM #AssetTemp A
		INNER JOIN AssetLocations AL ON AL.AssetId = A.Id AND AL.IsActive = 1
		INNER JOIN Locations L ON AL.LocationId = L.Id
		INNER JOIN @propertyTaxRate PT ON PT.StateId = L.StateId
	WHERE L.ApprovalStatus = 'Approved' --OR L.ApprovalStatus = 'ReAssess';
	-- For ReAssess locations, sales tax is not required, default value should be passed as 0.0
	

	SELECT
		MAXAL.AssetId
		,MAX(MAXAL.EffectiveFromDate) AS EffectiveFromDate
		,MAXAL.StateId
		,MAXAL.AsOfDate
	INTO #UniqueLeaseAssetLocations
	FROM  #LeaseAssetLocations MAXAL
		JOIN @propertyTaxRate PT ON PT.StateId = MAXAL.StateId
	WHERE MAXAL.EffectiveFromDate <= PT.AsOfDate
	GROUP BY MAXAL.AssetId,MAXAL.StateId,MAXAL.AsOfDate;
	
	
	INSERT INTO #UniqueLeaseAssetLocations
	SELECT
		MINAL.AssetId
		,MIN(MINAL.EffectiveFromDate) AS EffectiveFromDate
		,MINAL.StateId
		,MINAL.AsOfDate
	FROM #LeaseAssetLocations MINAL
		JOIN @propertyTaxRate PT ON PT.StateId = MINAL.StateId
	WHERE MINAL.EffectiveFromDate > PT.AsOfDate AND MINAL.AssetId NOT IN(SELECT AssetId FROM #UniqueLeaseAssetLocations)
	GROUP BY MINAL.AssetId,MINAL.StateId,MINAL.AsOfDate;
	
	INSERT INTO #AssetLevelReceivableDetails
	(
		EffectiveFromDate,
		DueDate,
		LocationId,
		AssetId,
		AssetLocationId,
		LegalEntityId,
		PropertyTaxReportCodeId,
		IsExemptAtAsset,
		TaxExemptRuleId
	)
	SELECT
		UAL.EffectiveFromDate
		,UAL.AsOfDate
		,AL.LocationId
		,UAL.AssetId
		,AL.AssetLocationId
		,A.LegalEntityId
		,A.PropertyTaxReportCodeId
		,CASE WHEN A.IsTaxExempt IS NULL THEN CAST(0 AS BIT) ELSE A.IsTaxExempt END AS IsExemptAtAsset 
		,A.TaxExemptRuleId
	FROM #UniqueLeaseAssetLocations UAL
	INNER JOIN #LeaseAssetLocations AL ON AL.AssetId = UAL.AssetId AND AL.AsOfDate = UAL.AsOfDate AND AL.EffectiveFromDate = UAL.EffectiveFromDate
	INNER JOIN #AssetTemp A ON A.Id = AL.AssetId


	INSERT INTO #ReceivableLocations
	(
		 LocationId					
		,MainDivision				
		,Country					
		,City						
		,LocationStatus				
		,IsLocationActive			
		,EffectiveFromDate			
		,AssetLocationId			
		,IsVertexSupportedLocation	
		,AssetId					
		,DueDate					
		,LegalEntityId				
		,PropertyTaxReportCodeId	
		,IsExemptAtAsset
		,CountyTaxExempt
		,CityTaxExempt
		,StateTaxExempt
		,CountryTaxExempt
		,TaxJurisdictionId		
	)
	SELECT
		CTE.LocationId AS LocationId
		,S.ShortName AS MainDivision
		,C.ShortName AS Country
		,Loc.City AS City
		,Loc.ApprovalStatus AS LocationStatus
		,Loc.IsActive AS IsLocationActive
		,CTE.EffectiveFromDate AS EffectiveFromDate
		,CTE.AssetLocationId AS AssetLocationId
		,CAST(CASE WHEN C.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) AS IsVertexSupportedLocation
		,CTE.AssetId
		,CTE.DueDate
		,CTE.LegalEntityId
		,CTE.PropertyTaxReportCodeId
		,IsExemptAtAsset
		,CASE WHEN ISNULL(AssetRule.IsCountyTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCountyTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCountyTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS CountyTaxExempt
		,CASE WHEN ISNULL(AssetRule.IsCityTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCityTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCityTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS CityTaxExempt
		,CASE WHEN ISNULL(AssetRule.IsStateTaxExempt,0) = 1 OR ISNULL(LocationRule.IsStateTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsStateTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END AS StateTaxExempt
		,CASE WHEN ISNULL(AssetRule.IsCountryTaxExempt,0) = 1 OR ISNULL(LocationRule.IsCountryTaxExempt,0) = 1 OR ISNULL(LeaseRule.IsCountryTaxExempt,0) = 1 THEN CAST (1 AS BIT) ELSE  CAST (0 AS BIT) END AS CountryTaxExempt
		,JurisdictionId AS TaxJurisdictionId
	FROM #AssetLevelReceivableDetails CTE
		INNER JOIN Locations Loc ON CTE.LocationId = Loc.Id
		INNER JOIN States S ON Loc.StateId = S.Id
		INNER JOIN Countries C ON S.CountryId = C.Id
		LEFT JOIN TaxExemptRules AssetRule ON CTE.TaxExemptRuleId = AssetRule.Id
		LEFT JOIN TaxExemptRules LocationRule ON Loc.TaxExemptRuleId = LocationRule.Id
		LEFT JOIN #LeaseTaxExemptRules LeaseRule ON CTE.AssetId = LeaseRule.AssetId
	WHERE Loc.IsActive=1
	
	;with CTE_TaxAreaIdForLocationAsOfDueDate AS
	(
		SELECT
			ROW_NUMBER() OVER (PARTITION BY Loc.AssetId, MainDivision ORDER BY CASE WHEN DATEDIFF(DAY,Loc.EffectiveFromDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
			CASE WHEN DATEDIFF(DAY, Loc.EffectiveFromDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC, 
			CASE WHEN DATEDIFF(DAY, Loc.EffectiveFromDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END  ASC) Row_Num,
			0 ReceivableDetailId,
			P.TaxAreaEffectiveDate,
			P.TaxAreaId,
			null as TaxJurisdictionId,
			P.LocationId,
			Loc.AssetId,
			Loc.MainDivision,
			Loc.City,
			Loc.Country,
			Loc.DueDate,
			Loc.LegalEntityId,
			Loc.PropertyTaxReportCodeId,
			Loc.LocationStatus,
			IsExemptAtAsset,
			Loc.CountyTaxExempt,
			Loc.CityTaxExempt,
			Loc.StateTaxExempt,
			Loc.CountryTaxExempt,
			IsVertexSupportedLocation
		FROM #ReceivableLocations Loc
			INNER JOIN LocationTaxAreaHistories P ON P.LocationId = Loc.LocationId
		WHERE P.TaxAreaId IS NOT NULL
		UNION
		SELECT
			ROW_NUMBER() OVER (PARTITION BY Loc.AssetId, MainDivision ORDER BY Loc.EffectiveFromDate asc) Row_Num,
			ID as ReceivableDetailId,
			Loc.EffectiveFromDate,
			NULL AS TaxAreaId,
			Loc.TaxJurisdictionId as TaxJurisdictionId,
			Loc.LocationId,
			Loc.AssetId,
			Loc.MainDivision,
			Loc.City,
			Loc.Country,
			Loc.DueDate,
			Loc.LegalEntityId,
			Loc.PropertyTaxReportCodeId,
			Loc.LocationStatus,
			IsExemptAtAsset,
			Loc.CountyTaxExempt,
			Loc.CityTaxExempt,
			Loc.StateTaxExempt,
			Loc.CountryTaxExempt,
			IsVertexSupportedLocation
		FROM #ReceivableLocations Loc
		WHERE Loc.TaxJurisdictionId IS NOT NULL
	)

	SELECT 
		 AssetId
		,TaxAreaId
		,TaxJurisdictionId
		,CAST(1 AS BIT) IsActive
		,MainDivision
		,City
		,Country
		,DueDate
		,'E001' AssetType
		,1000 ExtendedPrice
		,LE.TaxPayer Company
		,LocationId
		,TaxAreaEffectiveDate
		,LocationStatus
		,PTRCC.Code
		,IsExemptAtAsset
		,LOC.CountyTaxExempt
		,LOC.CityTaxExempt
		,LOC.StateTaxExempt
		,LOC.CountryTaxExempt
		,LOC.IsVertexSupportedLocation
		,LOC.ReceivableDetailId
	INTO #PropertyTaxCombinedTaxRate_Temp
	FROM CTE_TaxAreaIdForLocationAsOfDueDate LOC
		JOIN LegalEntities LE ON LOC.LegalEntityId = LE.Id
		LEFT JOIN PropertyTaxReportCodeConfigs PTRCC ON Loc.PropertyTaxReportCodeId = PTRCC.Id
	WHERE Row_Num = 1
	
	--DELETE FROM PropertyTaxCombinedTaxRates
	
	INSERT INTO PropertyTaxCombinedTaxRates (TaxAreaId,IsActive,ExemptionCode,CreatedById,CreatedTime,AssetId,TaxRate)
	SELECT
		 CASE WHEN TaxAreaId IS NOT NULL THEN TaxAreaId ELSE TaxJurisdictionId END
		,IsActive
		,(CASE WHEN (IsExemptAtAsset IS NULL OR IsExemptAtAsset = 0)THEN 'Exempt=N' ELSE 'Exempt=Y' END) IsExemptAtAsset
		,@CreatedById
		,@CreatedTime
		,AssetId
		,0.00
	FROM #PropertyTaxCombinedTaxRate_Temp
	
	SELECT 
		 AssetId
		,TaxAreaId
		,TaxJurisdictionId
		,MainDivision
		,City
		,Country
		,DueDate
		,AssetType
		,CAST(ExtendedPrice AS DECIMAL(9,2)) ExtendedPrice
		,Company
		,LocationId
		,TaxAreaEffectiveDate
		,CASE WHEN ReceivableDetailId IS NULL THEN 0 ELSE ReceivableDetailId END AS ReceivableDetailId
		,0 ReceivableId
		,CAST(0 AS BIT) AS IsRental
		,CAST(NULL AS NVARCHAR) Product
		,0.00 AS FairMarketValue
		,0.00 AS Cost
		,0.00 AS AmountBilledToDate
		,'USD' AS Currency
		,CAST(0 AS BIT) IsAssetBased
		,CAST(0 AS BIT) IsLeaseBased
		,IsExemptAtAsset
		,CountyTaxExempt
		,CityTaxExempt
		,StateTaxExempt
		,CountryTaxExempt
		,'LEASE' AS TransactionType
		,CAST(NULL AS NVARCHAR) CustomerCode
		,0 CustomerId
		,CAST(NULL AS NVARCHAR) ClassCode
		,CAST(1 AS BIT) AS IsLocationActive
		,NULL AS ContractId
		,NULL AS RentAccrualStartDate
		,NULL AS MaturityDate	   
		,CAST(0.00 AS DECIMAL(9,2)) CustomerCost
		,CAST(0 AS BIT) AS IsExemptAtLease
		,CAST(0.00 AS DECIMAL(9,2)) LessorRisk
		,NULL AS AssetLocationId
		,LocationStatus
		,CAST(0 AS BIT) AS IsExemptAtSundry
		,NULL AS ReceivableTaxId
		,IsVertexSupportedLocation
		,'FMV' AS ContractType 
		,CAST(NULL AS NVARCHAR) AS LeaseUniqueId
		,CAST(NULL AS NVARCHAR) AS SundryReceivableCode
		,CAST(NULL AS NVARCHAR) AS LeaseType
		,CAST(0.00 AS DECIMAL(9,2)) AS LeaseTerm
		,CAST(NULL AS NVARCHAR) AS TitleTransferCode
		,CAST(NULL AS DATE) AS LocationEffectiveDate
		,@PropertyTaxReceivableType  AS ReceivableType
		,@ReceivableTypeId as ReceivableTypeId
		,0 LegalEntityId
		,0 Id
		,CAST(0 AS BIT) IsManuallyAssessed
		,CAST(NULL AS NVARCHAR) TransactionCode
		,CAST(NULL AS NVARCHAR) TaxBasisType
		,CAST(NULL AS NVARCHAR) ToState
		,CAST(NULL AS NVARCHAR) FromState
		,CAST(NULL AS NVARCHAR) TaxRemittanceType
		,CAST(NULL AS NVARCHAR) AS SaleLeaseback
		,CAST(0 AS BIT) AS IsElectronicallyDelivered
		,CAST(0.00 AS DECIMAL(9,2)) LienCredit_Amount
		,'USD' LienCredit_Currency
		,CAST(0.00 AS DECIMAL(9,2)) ReciprocityAmount_Amount
		,'USD' ReciprocityAmount_Currency
		,0 GrossVehicleWeight
		,CAST(0 AS BIT) AS IsMultiComponent 
		,CAST(NULL AS NVARCHAR) LocationCode
		,CAST(NULL AS NVARCHAR) AS SalesTaxExemptionLevel
		,CAST(NULL AS NVARCHAR) CommencementDate
		,CAST(0 AS BIT) AS IsInvoiced 
		,CAST(0 AS BIT) AS IsCashPosted 
		,CAST(NULL AS NVARCHAR) SaleLeasebackCode
		,CAST(0 AS BIT) IsExemptAtReceivableCode
		,'_' ContractTypeValue
	FROM #PropertyTaxCombinedTaxRate_Temp
	

	IF OBJECT_ID('tempDB..#PropertyTaxCombinedTaxRate_Temp') IS NOT NULL
	BEGIN
		DROP TABLE #PropertyTaxCombinedTaxRate_Temp
	END
	
	IF OBJECT_ID('tempDB..#UniqueLeaseAssetLocations') IS NOT NULL
	BEGIN
		DROP TABLE #UniqueLeaseAssetLocations
	END
	
	IF OBJECT_ID('tempDB..#LeaseAssetLocations') IS NOT NULL
	BEGIN
		DROP TABLE #LeaseAssetLocations
	END
	
	IF OBJECT_ID('tempDB..#AssetLevelReceivableDetails') IS NOT NULL
	BEGIN
		DROP TABLE #AssetLevelReceivableDetails
	END
	
	IF OBJECT_ID('tempDB..#AssetTemp') IS NOT NULL
	BEGIN
		DROP TABLE #AssetTemp
	END
	
	IF OBJECT_ID('tempDB..#ReceivableLocations') IS NOT NULL
	BEGIN
		DROP TABLE #ReceivableLocations
	END

	IF OBJECT_ID('tempDB..#LeaseTaxExemptRules') IS NOT NULL
	BEGIN
		DROP TABLE #LeaseTaxExemptRules
	END	

END

GO
