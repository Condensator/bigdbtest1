SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[FillPTMSExportDetails]
(
		@JobStepInstanceId BIGINT,			
		@CreatedById BIGINT,
		@CreatedTime DATETIMEOFFSET,
		@assetDetails PropertyTaxExportPTMSAssets READONLY
)

AS
BEGIN
SET NOCOUNT ON;
    CREATE TABLE #CombinedSalesTaxRate
	(
	AssetId BIGINT,
	AssetLocationId BIGINT,
	TaxRate DECIMAL(10,6),
	ExemptionCode NVARCHAR(100)
	)
	DECLARE @decimalNumer DECIMAL(10,2)=0.00, @result DECIMAL(10,2); 



	SELECT ApplicableAssetDetail.AssetId,ApplicableAssetDetail.AssetLocationId,
			contract.SequenceNumber, leaseFinanceDetail.CommencementDate,leaseFinanceDetail.MaturityDate,
			leaseAsset.Rent_Amount,
			dealproducttype.Name ProductType,
			ApplicableAssetDetail.ContractId,			
			leaseFinance.Id LeaseFinanceId,
			leaseFinance.CustomerId,
			leaseFinance.LineofBusinessId,
			leaseFinance.CostCenterId,
			leaseFinance.InstrumentTypeId,
			contract.CurrencyId,
			contract.DealProductTypeId,
			contract.BillToId ,
			--payoffasset.IsActive PayOffAssetIsActive,
			--payoffasset.LeaseAssetId PayOffLeaseAssetId,
			leaseFinance.BookingStatus			
	INTO #LeaseAssetDetails
	FROM @assetDetails ApplicableAssetDetail
		JOIN LeaseFinances leaseFinance ON ApplicableAssetDetail.ContractId = leaseFinance.ContractId					
													AND leaseFinance.IsCurrent=1 
		JOIN LeaseAssets LeaseAsset ON LeaseAsset.AssetId = ApplicableAssetDetail.AssetId 
											AND	LeaseAsset.LeaseFinanceId = leaseFinance.Id
		JOIN LeaseFinanceDetails leaseFinanceDetail ON leaseFinance.Id=leaseFinanceDetail.Id
		JOIN Contracts contract ON leaseFinance.ContractId = contract.Id
		JOIN DealProductTypes dealproducttype ON contract.DealProductTypeId=dealproducttype.Id
		--LEFT JOIN PayoffAssets payoffasset ON payoffasset.IsActive=1 AND LeaseAsset.Id=payoffasset.LeaseAssetId
	--WHERE LeaseAsset.IsActive = 1


	INSERT INTO #CombinedSalesTaxRate
	SELECT assetDetails.AssetId,assetDetails.AssetLocationId
			,PropertyTaxCombinedTaxRates.TaxRate
			,PropertyTaxCombinedTaxRates.ExemptionCode
	FROM @assetDetails assetDetails
		JOIN AssetLocations assetLocation ON assetDetails.AssetLocationId = assetLocation.Id 
								AND assetLocation.IsActive = 1 AND assetDetails.assetId = assetLocation.AssetId 
		JOIN Locations location ON assetLocation.LocationId=location.Id	
		JOIN LocationTaxAreaHistories ON LocationTaxAreaHistories.LocationId =Location.Id
		JOIN PropertyTaxCombinedTaxRates ON PropertyTaxCombinedTaxRates.TaxAreaId = LocationTaxAreaHistories.TaxAreaId 
								AND PropertyTaxCombinedTaxRates.AssetId = assetDetails.AssetId
	WHERE assetDetails.IsIncluded = 1

	INSERT INTO #CombinedSalesTaxRate
	SELECT assetDetails.AssetId,assetDetails.AssetLocationId
			,PropertyTaxCombinedTaxRates.TaxRate
			,PropertyTaxCombinedTaxRates.ExemptionCode
	FROM @assetDetails assetDetails
		JOIN AssetLocations assetLocation ON assetDetails.AssetLocationId = assetLocation.Id 
								AND assetLocation.IsActive = 1 AND assetDetails.assetId = assetLocation.AssetId 
		JOIN Locations location ON assetLocation.LocationId=location.Id	
		JOIN PropertyTaxCombinedTaxRates ON PropertyTaxCombinedTaxRates.TaxAreaId =  JurisdictionId
								AND PropertyTaxCombinedTaxRates.AssetId = assetDetails.AssetId
	WHERE assetDetails.IsIncluded = 1
	-- Due to the existing issue in SalesTax Non-Vertex Locations, duplication of records are happening in CombinedSalesTaxRate table
		--AND propertyTaxCombinedTaxRate.TaxRate > 0;

	
	SELECT MAX(PayOffId) PayOffId, AssetId
	INTO  #payOffDetails --#tempTable2 
	FROM (
		SELECT 
			ValidAssets.AssetId,
			(
				SELECT TOP(1) t.PayoffId 
				FROM 
					(
						SELECT 
							pa.PayoffId, 
							DATEDIFF (day, po.[PayoffEffectiveDate], SysDateTime()) DateDif,
							po.Status FROM PayoffAssets pa 
						join Payoffs po ON pa.PayoffId = po.Id 
						WHERE pa.IsActive=1 AND pa.LeaseAssetId =LeaseAsset.Id -- payoffasset.LeaseAssetId	
						AND po.PayoffEffectiveDate <= ValidAssets.AsOfDate				
					) t
				where t.Status='Activated' AND t.DateDif>=0 ORDER BY t.DateDif
			) PayOffId 
		FROM @assetDetails ValidAssets
		JOIN LeaseAssets LeaseAsset ON LeaseAsset.AssetId = ValidAssets.AssetId	
		--JOIN PayoffAssets payoffasset ON payoffasset.IsActive=1 AND LeaseAsset.Id=payoffasset.LeaseAssetId
	) PA
    GROUP BY PA.AssetId


	SELECT 
			asset.TypeId,
			ApplicableAssetDetail.FileName,
			asset.Id assetId,
			asset.Description,
			asset.InServiceDate,
			asset.PropertyTaxCost_Amount,
			asset.PropertyTaxCost_Currency,
			--asset.PropertyTaxReportCodeId,
			ExtractData.SerialNumber,
			asset.Quantity,
			asset.UsageCondition,
			(SELECT Usage FROM AssetUsages WHERE id=asset.AssetUsageId) ManufacturerIndicator,
			legalEntity.GLSegmentValue LEGLSegmentValue,
			LeaseAssetDetail.SequenceNumber LeaseNumber,
			LeaseAssetDetail.CommencementDate LeaseCommencementDate,
			LeaseAssetDetail.MaturityDate LeaseEndDate,
			LeaseAssetDetail.Rent_Amount AssetPaymentAmount,
			ExtractData.AssetStatus,
			(SELECT top 1 ClassCode FROM AssetClassCodes WHERE id= assetType.AssetClassCodeId) AssetClassCode,
			legalentity.Id LegalEntityId,
			asset.Alias AssetAlias,
			LeaseAssetDetail.ProductType,
			assetCatalog.CollateralCode CollateralCode,
			(SELECT sum(cost_amount) from
			(SELECT Cost_Amount, ROW_NUMBER() OVER(PARTITION BY isleasecomponent ORDER BY incomedate DESC,Id DESC) rowNumber FROM AssetValueHistories WHERE AssetId=asset.Id)  
			assetValueHistory WHERE rowNumber=1) OECCost,
			asset.ModelYear Model,
			product.Name ProductCode,
			asset.SubStatus DispositionCode,
			LeaseAssetDetail.ContractId,
			LeaseAssetDetail.LeaseFinanceId,
			LeaseAssetDetail.CustomerId,
			LeaseAssetDetail.LineofBusinessId,
			LeaseAssetDetail.CostCenterId,
			LeaseAssetDetail.InstrumentTypeId,
			LeaseAssetDetail.CurrencyId,
			LeaseAssetDetail.DealProductTypeId,
			asset.AssetCatalogId,
			asset.ProductId,
			--LeaseAssetDetail.PayOffAssetIsActive IsActive,
			--LeaseAssetDetail.PayOffLeaseAssetId poaLeaseAssetId,
			LeaseAssetDetail.BillToId 
			,ApplicableAssetDetail.IsIncluded
			,ApplicableAssetDetail.RejectReason
			,ApplicableAssetDetail.LienDate
			,ApplicableAssetDetail.AssetLocationId
			,ApplicableAssetDetail.AsOfDate
			,ApplicableAssetDetail.ExclusionCode
			,ApplicableAssetDetail.IsDisposedAssetReported
			,ApplicableAssetDetail.IsTransferAsset
			,ApplicableAssetDetail.PreviousLeaseNumber
			,ExtractData.PropertyTaxReportCode
			,(CASE WHEN ExtractData.AssetStatus IN ('Donated','WriteOff','Scrap','Sold') THEN 1 ELSE 0 END) IsDisposedAsset
			,(CASE WHEN ExtractData.AssetStatus IN ('Donated','WriteOff','Scrap','Sold')
				   THEN 
						(CASE WHEN ExtractData.SourceModule = 'AssetSale' OR 
								 EXISTS (Select TOP 1 Id from AssetHistories AH WHERE AH.AssetId = ExtractData.AssetID AND AH.SourceModule = 'AssetSale')
							  THEN 1
							  ELSE 0
						END)
					ELSE 0
			 END) IsDisposedThroughAssetSale
			 ,payOffDetails.PayOffId
	INTO #tempTable1
	FROM Assets asset 		
		INNER JOIN @assetDetails ApplicableAssetDetail ON asset.Id = ApplicableAssetDetail.AssetId
		INNER JOIN PropertyTaxExportJobExtracts ExtractData 
								ON ApplicableAssetDetail.AssetId = ExtractData.AssetID
								AND ((ApplicableAssetDetail.ContractId IS NULL AND ExtractData.ContractId IS NULL) OR (ApplicableAssetDetail.ContractId = ExtractData.ContractId))
								AND ApplicableAssetDetail.AssetLocationId = ExtractData.AssetLocationId		
								AND ExtractData.JobStepInstanceId = @JobStepInstanceId						
		INNER JOIN LegalEntities legalEntity ON asset.LegalEntityId= legalEntity.Id		
		INNER JOIN AssetTypes assetType ON asset.TypeId=assetType.Id
		LEFT JOIN #LeaseAssetDetails LeaseAssetDetail ON ApplicableAssetDetail.AssetId = LeaseAssetDetail.AssetId
				AND ApplicableAssetDetail.AssetLocationId = LeaseAssetDetail.AssetLocationId
				AND ((ApplicableAssetDetail.ContractId IS NULL AND LeaseAssetDetail.ContractId IS NULL) OR ApplicableAssetDetail.ContractId = LeaseAssetDetail.ContractId)		
		LEFT JOIN AssetCatalogs assetCatalog ON asset.AssetCatalogId=assetCatalog.Id
		LEFT JOIN Products product ON asset.ProductId = product.Id	
		LEFT JOIN #payOffDetails payOffDetails ON payOffDetails.AssetId = ApplicableAssetDetail.AssetId 
						AND payOffDetails.PayOffId IS NOT NULL -- This is required to avoid duplicates		

SELECT DISTINCT 
	LineofBusinessId,
	LegalEntityId,
	CostCenterId,
	CurrencyId
INTO #UniqueGLOrgStructureConfigInputs
FROM #tempTable1

SELECT 
	glOrgStructure.BusinessCode,
	glOrgStructure.LineofBusinessId,
	glOrgStructure.LegalEntityId,
	glOrgStructure.CostCenterId,
	glOrgStructure.CurrencyId,
	CounterGlOrgStructureCombination= ROW_NUMBER() OVER(PARTITION BY glOrgStructure.LineofBusinessId, glOrgStructure.LegalEntityId, glOrgStructure.CostCenterId, glOrgStructure.CurrencyId ORDER BY glOrgStructure.Id)
	INTO #UniqueGLOrgStructureConfigValue
	FROM GLOrgStructureConfigs glOrgStructure 
	JOIN #UniqueGLOrgStructureConfigInputs t2 
	ON glOrgStructure.IsActive=1 AND t2.LineofBusinessId=glOrgStructure.LineofBusinessId AND t2.LegalEntityId= glOrgStructure.LegalEntityId AND t2.CostCenterId=glOrgStructure.CostCenterId AND t2.CurrencyId=glOrgStructure.CurrencyId
	

	SELECT 
			t2.assetId AssetNumber,
			t2.FileName,
			t2.Description DESCription,
			t2.InServiceDate AssetInServiceDate,
			t2.PropertyTaxCost_Amount,
			t2.PropertyTaxCost_Currency,
			t2.PropertyTaxReportCode,
			t2.SerialNumber SerialNumber,
			t2.Quantity,
			t2.UsageCondition AssetUsageCondition,
			t2.ManufacturerIndicator,
			t2.LEGLSegmentValue,
			t2.LeaseNumber,
			t2.LeaseCommencementDate,
			t2.LeaseEndDate,
			t2.AssetPaymentAmount,
			t2.AssetStatus,
			t2.AssetClassCode,
			t2.LegalEntityId,
			t2.AssetAlias,
			t2.ProductType,
			t2.CollateralCode,
			t2.OECCost,
			t2.Model,
			t2.ProductCode,
			t2.DispositionCode,
			t2.ContractId,
			t2.LeaseFinanceId,
			t2.CustomerId,
			t2.LineofBusinessId,
			t2.CostCenterId,
			t2.InstrumentTypeId,
			t2.CurrencyId,
			t2.DealProductTypeId,
			t2.AssetCatalogId,
			t2.ProductId,
			--t2.IsActive,
			--t2.poaLeaseAssetId,
			t2.BillToId,
			instrumentType.Code InstrumentType,
			location.AddressLine1 AddressLine1,
			location.AddressLine2 AddressLine2,
			location.AddressLine3 AddressLine3,
			location.City CityName,
			location.Division CountyName,
			(SELECT ShortName FROM States WHERE Id=location.StateId) StateCode,
			location.PostalCode ZipCode,
			party.PartyName LesseeName,
			party.PartyNumber LesseeNumber,
			(SELECT top 1 PhoneNumber1 FROM PartyContacts WHERE PartyId=party.Id) LesseeContactNumber,
			billTo.CustomerBillToName BillToName,
			partyAddress.AddressLine1 BillToAddressLine1,
			partyAddress.AddressLine2 BillToAddressLine2,
			partyAddress.City BillToCityName,
			(SELECT top 1 ShortName FROM States WHERE id=partyAddress.StateId) BillToState,
			partyAddress.PostalCode BillToZip,
			AsOfDate,
			CASE WHEN AsOfDate IS NOT NULL AND IsDisposedAsset = 1 THEN AsOfDate ELSE NULL END DisposedDate,
			CASE WHEN AsOfDate IS NOT NULL AND AssetStatus='Inventory' THEN AsOfDate ELSE NULL END InventoryDate,			
			location.StateId StateId,
			CASE WHEN taxRateDetail.AssetId IS NOT NULL THEN CAST(ROUND(taxRateDetail.TaxRate,2,0) AS DECIMAL(8,2)) ELSE @decimalNumer END CombinedSalesTaxRate,
			taxRateDetail.ExemptionCode SalesTaxExemptionCode,
			location.Code AddressCodeForAsset,
			glOrgStructure.BusinessCode BusinessCode	
			,CASE WHEN IsDisposedAsset = 1 AND IsDisposedThroughAssetSale = 0 THEN payoff.PayoffAssetSubStatus ELSE NULL END DisposalNote,
			businessTypesSICsCodes.name SICCode,
			assetLocation.EffectiveFromDate LocationEffectiveFromDate,
			assetLocation.Id AssetLocationId
			,t2.IsIncluded
			,t2.RejectReason
			,t2.LienDate			
			,ExclusionCode
			,IsDisposedAssetReported
			,IsTransferAsset
			,PreviousLeaseNumber
	INTO #tempTable4
	FROM #tempTable1 t2 
		LEFT JOIN Payoffs payoff ON t2.PayOffId=payoff.Id
		LEFT JOIN #UniqueGLOrgStructureConfigValue glOrgStructure ON glOrgStructure.CounterGlOrgStructureCombination=1 AND t2.LineofBusinessId=glOrgStructure.LineofBusinessId AND t2.LegalEntityId= glOrgStructure.LegalEntityId AND t2.CostCenterId=glOrgStructure.CostCenterId AND t2.CurrencyId=glOrgStructure.CurrencyId
		LEFT JOIN BillToes billTo ON t2.BillToId=billTo.Id
		LEFT JOIN InstrumentTypes instrumentType ON t2.InstrumentTypeId=instrumentType.Id
		LEFT JOIN AssetLocations assetLocation ON t2.AssetLocationId = assetLocation.Id and assetLocation.IsActive=1 AND t2.assetId=assetLocation.AssetId 
		LEFT JOIN Locations location ON assetLocation.LocationId=location.Id		
		LEFT JOIN Parties party ON t2.CustomerId=party.Id
		LEFT JOIN Customers customer ON party.Id=customer.Id		
		LEFT JOIN BusinessTypesSICsCodes businessTypesSICsCodes ON businessTypesSICsCodes.Id=customer.BusinessTypesSICsCodeId
		LEFT JOIN PartyAddresses partyAddress ON billTo.BillingAddressId=partyAddress.Id
		LEFT JOIN #CombinedSalesTaxRate  taxRateDetail ON t2.assetId = taxRateDetail.AssetId AND taxRateDetail.AssetLocationId = t2.AssetLocationId						


	-- This check need to be verified, this looks like a redundant check since we already added LeaseFinance.IsCurrent = 1
	--WITH result AS
	--(
	--	SELECT AssetNumber,LeaseFinanceId, ROW_NUMBER() OVER(PARTITION BY AssetNumber ORDER BY AssetNumber,LeaseFinanceId DESC) rowNumber 
	--	FROM #tempTable4
	--)

	--SELECT AssetNumber,LeaseFinanceId 
	--INTO #tempTable5 
	--FROM result 
	--WHERE rowNumber=1;

	--select * into #tempTable6 from PtmsExportDetailExtracts where 1=2

	INSERT INTO PtmsExportDetailExtracts
	(
		[AssetNumber], 
		[FileName],
		[LEGLSegmentValue],
		[InstrumentType],
		[AddressLine1],
		[AddressLine2],
		[AddressLine3],
		[CityName],
		[CountyName],  
		[StateCode],
		[ZipCode],
		[Description],  
		[AssetInServiceDate],
		[PropertyTaxCost_Amount] ,
		[PropertyTaxCost_Currency],
		PropertyTaxReportCode,
		[DisposedDate],
		[CombinedSalesTaxRate],
		[SalesTaxExemptionCode],
		[LeaseNumber],  
		[LesseeName],
		[BillToName],
		[LesseeNumber],
		[LeaseCommencementDate],
		[LeaseEndDate],
		[AssetPaymentAmount],
		[BillToAddress1],
		[BillToAddress2],
		[BillToCityName],
		[BillToState],  
		[BillToZip],
		[LesseeContactNumber],
		[SerialNumber],
		[Quantity],
		[ManufacturerIndicator],
		[ExclusionCode],
		[IsDisposedAssetReported],
		[LegalEntityId],
		[PropertyTaxCostInString],
		[StateId],
		[InventoryDate],
		[ProductType],  
		[CollateralCode],
		[Model],
		[AddressCodeForAsset],
		[BusinessCode], 
		[ProductCode], 
		[DisposalNote], 
		[DispositionCode],
		[SICCode],
		[AssetAlias] ,
		[OECCostInString],
		[LocationEffectiveFromDate],
		[AssetStatus], 
		[AssetUsageCondition],
		[AssetLocationId],
		[JobStepInstanceId],  
		[CreatedById],
		[CreatedTime],
		[IsIncluded],
		[RejectReason],
		[LienDate],
		[AsOfDate],
		[IsTransferAsset],
		PreviousLeaseNumber,
		AssetClassCode
	)
	SELECT 
			t4.AssetNumber AssetNumber,
			t4.FileName,
			t4.LEGLSegmentValue LEGLSegmentValue,
			t4.InstrumentType InstrumentType,
			t4.AddressLine1 AddressLine1,
			t4.AddressLine2 AddressLine2,
			t4.AddressLine3 AddressLine3,
			t4.CityName CityName,
			t4.CountyName CountyName,
			t4.StateCode StateCode,
			t4.ZipCode ZipCode,
			t4.Description DESCription,
			t4.AssetInServiceDate AssetInServiceDate,
			t4.PropertyTaxCost_Amount,
			t4.PropertyTaxCost_Currency,
			t4.PropertyTaxReportCode,
			t4.DisposedDate,			
			t4.CombinedSalesTaxRate,
			t4.SalesTaxExemptionCode SalesTaxExemptionCode,
			t4.LeaseNumber LeaseNumber,
			t4.LesseeName LesseeName,
			t4.BillToName BillToName,
			t4.LesseeNumber LesseeNumber,
			t4.LeaseCommencementDate LeaseCommencementDate,
			t4.LeaseEndDate LeaseEndDate,
			t4.AssetPaymentAmount AssetPaymentAmount,
			t4.BillToAddressLine1 BillToAddress1,
			t4.BillToAddressLine2 BillToAddress2,
			t4.BillToCityName BillToCityName,
			t4.BillToState BillToState,
			t4.BillToZip BillToZip,
			t4.LesseeContactNumber LesseeContactNumber,
			t4.SerialNumber SerialNumber,
			t4.Quantity Quantity,
			t4.ManufacturerIndicator ManufacturerIndicator,
			t4.ExclusionCode,
			t4.IsDisposedAssetReported,
			t4.LegalEntityId LegalEntityId,
			t4.PropertyTaxCost_Amount,
			t4.StateId StateId,
			t4.InventoryDate,
			t4.ProductType ProductType,
			t4.CollateralCode CollateralCode,
			t4.Model Model,
			t4.AddressCodeForAsset AddressCodeForAsset,
			t4.BusinessCode BusinessCode,
			t4.ProductCode ProductCode,
			t4.DisposalNote,
			t4.DispositionCode DispositionCode,
			t4.SICCode SICCode,
			t4.AssetAlias AssetAlias,
			t4.OECCost,
			t4.LocationEffectiveFromDate LocationEffectiveFromDate,
			t4.AssetStatus AssetStatus,
			t4.AssetUsageCondition AssetUsageCondition,
			t4.AssetLocationId AssetLocationId,
			@JobStepInstanceId,
			@CreatedById,
			@CreatedTime
			,t4.IsIncluded
			,t4.RejectReason
			,t4.LienDate
			,t4.AsOfDate
			,t4.IsTransferAsset
			,t4.PreviousLeaseNumber
			,t4.AssetClassCode
	FROM #tempTable4 t4
		--LEFT JOIN #tempTable5 t5 ON t4.LeaseFinanceId=t5.LeaseFinanceId AND t4.AssetNumber=t5.AssetNumber

	SELECT		
			[AssetNumber], 
			[FileName],
			[LEGLSegmentValue],
			[InstrumentType],
			[AddressLine1],
			[AddressLine2],
			[AddressLine3],
			[CityName],
			[CountyName],  
			[StateCode],
			[ZipCode],
			[Description],  
			[AssetInServiceDate],
			[PropertyTaxCost_Amount] ,
			[PropertyTaxCost_Currency],
			PropertyTaxReportCode,
			[DisposedDate],
			CONVERT(varchar, CombinedSalesTaxRate) CombinedSalesTaxRate,
			[SalesTaxExemptionCode],
			[LeaseNumber],  
			[LesseeName],
			[BillToName],
			[LesseeNumber],
			[LeaseCommencementDate],
			[LeaseEndDate],
			CONVERT(varchar, AssetPaymentAmount) AssetPaymentAmount,
			BillToAddressLine1 [BillToAddress1],
			BillToAddressLine2 [BillToAddress2],
			[BillToCityName],
			[BillToState],  
			[BillToZip],
			[LesseeContactNumber],
			[SerialNumber],
			[Quantity],
			[ManufacturerIndicator],
			[ExclusionCode],
			IsDisposedAssetReported,
			[LegalEntityId],
			CONVERT(varchar,PropertyTaxCost_Amount) [PropertyTaxCostInString],
			[StateId],
			[InventoryDate],
			[ProductType],  
			[CollateralCode],
			[Model],
			[AddressCodeForAsset],
			[BusinessCode], 
			[ProductCode], 
			[DisposalNote], 
			[DispositionCode],
			[SICCode],
			[AssetAlias],
			CONVERT(varchar, OECCost) [OECCostInString],			
			[LocationEffectiveFromDate],
			[AssetStatus], 
			[AssetUsageCondition],
			[AssetLocationId],
			@JobStepInstanceId JobStepInstanceId,  
			@CreatedById CreatedById,
			@CreatedTime CreatedTime,
			[IsIncluded],
			[RejectReason],
			[LienDate],
			[AsOfDate],
			[PreviousLeaseNumber]
			,AssetClassCode
	FROM #tempTable4 WHERE IsIncluded=1



	IF OBJECT_ID('tempDB..#tempTable1') IS NOT NULL
		DROP TABLE #tempTable1
	IF OBJECT_ID('tempDB..#payOffDetails') IS NOT NULL
		DROP TABLE #payOffDetails				
	IF OBJECT_ID('tempDB..#CombinedSalesTaxRate') IS NOT NULL
		DROP TABLE #CombinedSalesTaxRate
	IF OBJECT_ID('tempDB..#tempTable4') IS NOT NULL
		DROP TABLE #tempTable4	
	IF OBJECT_ID('tempDB..#tempTable5') IS NOT NULL
		DROP TABLE #tempTable5
	IF OBJECT_ID('tempDB..#tempTable6') IS NOT NULL
		DROP TABLE #tempTable6
	IF OBJECT_ID('tempDB..#LeaseAssetDetails') IS NOT NULL
		DROP TABLE #LeaseAssetDetails		
	IF OBJECT_ID('tempDB..#UniqueGLOrgStructureConfigInputs') IS NOT NULL
	DROP TABLE #UniqueGLOrgStructureConfigInputs
	IF OBJECT_ID('tempDB..#UniqueGLOrgStructureConfigValue') IS NOT NULL
	DROP TABLE #UniqueGLOrgStructureConfigValue
END

GO
