SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetAssetInfo]
(
@ImportedAssets ImportedAssets READONLY,
@AssetFinancialTypeNegativeDeposit NVARCHAR(20),
@PayableInvoiceCompletedStatus NVARCHAR(10),
@ContractId bigint = null,
@SourceModule NVARCHAR(25),
@InvestorStatus NVARCHAR(17),
@InvestorLeasedStatus NVARCHAR(17),
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS 

	SELECT * INTO #ImportedAssets FROM @ImportedAssets;
	ALTER TABLE #ImportedAssets ADD PRIMARY KEY (AssetId)

    BEGIN

	SELECT Id LeaseFinanceId INTO #LF FROM LeaseFinances WHERE ContractId = @ContractId

	SELECT 
		LeaseAssets.AssetId, 
		LeaseFinanceId
	INTO #LeaseAssets
	FROM LeaseAssets
	INNER JOIN #ImportedAssets IA 
		ON LeaseAssets.AssetId = IA.AssetId 
	WHERE LeaseAssets.TerminationDate <> NULL

	CREATE INDEX IX_Asset ON #LeaseAssets (AssetId)

	SELECT 
		#LeaseAssets.AssetId,
		#LeaseAssets.LeaseFinanceId
	INTO #PreviousTaxLeases1
	FROM #LeaseAssets 
	INNER JOIN LeaseFinanceDetails 
		ON #LeaseAssets.LeaseFinanceId=LeaseFinanceDetails.Id 
		AND LeaseFinanceDetails.IsTaxLease=1	
	
	DELETE FROM #PreviousTaxLeases1 WHERE LeaseFinanceId IN (SELECT LeaseFinanceId FROM #LF)

	SELECT DISTINCT AssetId INTO #PreviousTaxLeases FROM #PreviousTaxLeases1

	CREATE CLUSTERED INDEX IX_Asset ON #PreviousTaxLeases (AssetId)

	CREATE TABLE #SyndicatedLeaseAssetsAVH  
	(
		 AssetId BIGINT NOT NULL PRIMARY KEY,
		 IsSchedule BIT NOT NULL,
		 SourceModule NVARCHAR(25) NULL,
	 )

	 INSERT INTO #SyndicatedLeaseAssetsAVH (AssetId,IsSchedule,SourceModule)
     SELECT AVH.AssetId,AVH.IsSchedule,AVH.SourceModule 
	   FROM  #ImportedAssets LeaseAsset 
	   JOIN Assets asset on LeaseAsset.AssetId=asset.Id
	   JOIN AssetValueHistories AVH on asset.Id=AVH.AssetId
	 GROUP BY AVH.SourceModule,asset.Status,AVH.IsSchedule,AVH.AssetId
	 HAVING asset.Status IN (@InvestorStatus,@InvestorLeasedStatus)    
	 AND AVH.SourceModule=@SourceModule 
	 AND AVH.IsSchedule=1;

	;WITH CTE_AssetSerialNumberDetails AS(
	SELECT 
		ASN.AssetId,
		SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
	FROM #ImportedAssets A
	join AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
	GROUP BY ASN.AssetId
	)  
         SELECT Asset.Quantity AS Quantity,
                Asset.Id AS AssetId,
				Asset.CustomerId AS CustomerId,
                Asset.Alias AS Alias,
                Asset.PartNumber AS PartNumber,
                ASN.SerialNumber AS SerialNumber,
                Product.Name AS ProductName,
                Asset.FinancialType AS FinancialType,
                AssetType.Name AS AssetTypeName,
				PricingGroup.Id AS PricingGroupId,
                AssetCategory.Name AS CategoryName,
                AssetType.Id AS TypeId,
                Asset.Status AS Status,
                Asset.Description AS Description,
                NegativeDepositAssetInfo.DepositAssetId AS DepositAssetId,
                NegativeDepositAssetInfo.TakeDownAssetId AS TakeDownAssetId,
                AssetType.ExcludeFrom90PercentTest AS ExcludeFromNinetyPercentTest,
                CASE
                    WHEN TaxDepEntity.Id IS NOT NULL
                    THEN CAST(1 AS     BIT)
                    ELSE CAST(0 AS BIT)
                END AS HasTaxDep,
				TaxDepEntity.Id AS TaxDepEntityId,
				TaxDepEntity.TaxDepTemplateId,
				ISNULL(TaxDepEntity.TaxBasisAmount_Amount,0.0) AS TaxBasisAmount,
				TaxDepEntity.TaxBasisAmount_Currency AS TaxBasisAmountCurrency,
				ISNULL(TaxDepEntity.FXTaxBasisAmount_Amount,0.0) AS FXTaxBasisAmount,
				TaxDepEntity.FXTaxBasisAmount_Currency AS FXTaxBasisAmountCurrency,
				TaxDepEntity.DepreciationBeginDate AS DepreciationBeginDate,
				TaxDepEntity.DepreciationEndDate   AS DepreciationEndDate,
                AssetType.IsSoft AS IsSoftAsset,
                Asset.UsageCondition AS UsageCondition,
                Asset.OwnershipStatus AS OwnershipStatus,
                Asset.InServiceDate AS InServiceDate,
                AssetType.IsEligibleForFPI AS IsEligibleForInsurance,
                COALESCE(Asset.IsTaxExempt, CAST(0 AS BIT)) AS IsTaxExempt,
                COALESCE(Asset.IsSaleLeaseback, CAST(0 AS BIT)) AS IsSalesLeaseBack,
			 COALESCE(Asset.IsLeaseComponent, CAST(0 AS BIT)) AS IsLeaseComponent,
                Asset.SaleLeasebackCodeId AS SaleLeasebackCodeId,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN Location.Code
                    ELSE ''
                END AS LocationCode,
                COALESCE(AssetType.IsCollateralTracking, CAST(0 AS BIT)) AS IsCollateralTracking,
                Asset.PurchaseOrderDate AS PurchaseOrderDate,
                CollateralTracking.Id AS CollateralTrackingNumber,
                PayableInvoiceInfo.PartyName AS VendorName,
                PayableInvoiceInfo.PartyNumber AS VendorNumber,
                CASE
                    WHEN AssetLocation.Id IS NULL
                    THEN CAST(NULL AS     INT)
                    ELSE 1
                END AS C11,
                AssetLocation.TaxBasisType AS TaxBasisType,
                AssetType.CostTypeId AS CostTypeId,
				ISNULL(State.ShortName,'') AS StateShortName,
                CASE
                    WHEN AssetLocation.Id IS NOT NULL
                         AND AssetLocation.IsFLStampTaxExempt = 1
                    THEN CAST(1 AS     BIT)
                    WHEN NOT(AssetLocation.Id IS NOT NULL
                             AND AssetLocation.IsFLStampTaxExempt = 1)
                    THEN CAST(0 AS BIT)
                END AS IsFLStampTaxExempt,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN Location.City
                    ELSE ''
                END AS City,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN CASE
                             WHEN Location.AddressLine1 IS NULL
                             THEN N''
                             ELSE Location.AddressLine1
                         END+CASE
                                 WHEN Location.AddressLine2 IS NULL
                                 THEN N''
                                 ELSE Location.AddressLine2
                             END
                    ELSE ''
                END AS Address,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN Location.PostalCode
                    ELSE ''
                END AS ZipCode,
				ISNULL(Country.ShortName,'') AS CountryShortName,
				Country.Id CountryId,
				ISNULL(Location.AddressLine1+', ', '') 
					+ ISNULL(Location.AddressLine2+', ', '') 
					+ ISNULL(Location.City+', ', '') 
					+ ISNULL(State.ShortName+', ', '')
					+ ISNULL(Location.PostalCode, '') AS AssetLocationEntireAddress,
                Asset.IsEligibleForPropertyTax AS IsEligibleForPropertyTax,
                Asset.AcquisitionDate AS AcquisitionDate,
                Asset.PropertyTaxDate AS PropertyTaxDate,
                Asset.PropertyTaxCost_Amount,
                Asset.PropertyTaxCost_Currency,
                Asset.ModelYear,
                Asset.CustomerPurchaseOrderNumber,
                'n/a' PurchaseOrderNumber,
                ISNULL(Manufacturers.Name,'') AS ManufactureName,
                Asset.ParentAssetId,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN CASE
                             WHEN Location.AddressLine1 IS NULL
                             THEN N''
                             ELSE Location.AddressLine1
                         END
                    ELSE ''
                END AS AddressLine1,
                CASE
                    WHEN Location.Id IS NOT NULL
                         AND AssetLocation.IsActive = 1
                         AND Location.IsActive = 1
                    THEN CASE
                             WHEN Location.AddressLine2 IS NULL
                             THEN N''
                             ELSE Location.AddressLine2
                         END
                    ELSE ''
                END AS AddressLine2,
                ISNULL(Location.Name, '') AS LocationName,
			 Asset.DealerCost_Amount DealerCost_Amount,
			 Asset.DealerCost_Currency DealerCost_Currency,
			 Asset.DMDPercentage DMDPercentage,
			 AssetCatalog.Id AS AssetCatalogId,
			 AssetCatalog.CollateralCode AS CollateralCode,
			 CASE WHEN Asset.ExemptProperty IS NOT NULL Then  Asset.ExemptProperty
			 Else 'None' END AS ExemptProperty,
			 Asset.SpecifiedLeasingProperty AS SpecifiedLeasingProperty,
			 TaxDepEntity.TerminationDate AS TaxDepTerminationDate,
			 ISNULL(AssetGLDetail.HoldingStatus, '_') HoldingStatus, 
			 AssetGLDetail.InstrumentTypeId,
			 AssetGLDetail.LineofBusinessId,
			 CASE
                WHEN PreviousTaxLeases.AssetId IS NOT NULL
					THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
			 END AS WasPartOfTaxedLease,
			 Contracts.Id as PreviousContractId,
			 Asset.Residual_Amount,
			 Asset.Residual_Currency,
			  CASE
                WHEN AssetCatalog.Usefullife IS NOT NULL
					THEN AssetCatalog.Usefullife
                ELSE AssetType.EconomicLifeInMonths
			 END AS UsefulLife,		
			 AssetGLDetail.CostCenterId,
			 Product.Id AS ProductId,
			 Asset.PropertyTaxReportCodeId,
			 Asset.IsSKU AS HasSKU,
			 CASE 
			    WHEN #SyndicatedLeaseAssetsAVH.IsSchedule IS NULL THEN CAST(0 AS BIT) 
				ELSE CAST(#SyndicatedLeaseAssetsAVH.IsSchedule AS BIT) 
			END	IsValueAdjusted,
			PayableInvoiceInfo.VendorId,
			PayableInvoiceInfo.AcquisitionLocationId,
			AssetCatalog.Usefullife AS AssetCatalogUsefulLife,
			Asset.IsTaxParameterChangedForLeasedAsset AS IsTaxParameterChangedForLeasedAsset,
			L.IsAssessSalesTaxAtSKULevel,
			Asset.Salvage_Amount,
			Asset.Salvage_Currency
         FROM dbo.Assets AS Asset
              INNER JOIN dbo.AssetTypes AS AssetType ON Asset.TypeId = AssetType.Id
			  INNER JOIN LegalEntities L ON Asset.LegalEntityId = L.Id
			  INNER JOIN #ImportedAssets IA ON Asset.Id = IA.AssetId
			  LEFT JOIN CTE_AssetSerialNumberDetails ASN ON IA.AssetId = ASN.AssetId
              LEFT JOIN dbo.Products AS Product ON AssetType.ProductId = Product.Id
              LEFT JOIN dbo.AssetCategories AS AssetCategory ON Product.AssetCategoryId = AssetCategory.Id
              LEFT JOIN dbo.Manufacturers ON Asset.ManufacturerId = Manufacturers.Id
			  LEFT JOIN dbo.AssetCatalogs AS AssetCatalog ON Asset.AssetCatalogId = AssetCatalog.Id 
			  LEFT JOIN dbo.AssetGLDetails AS AssetGLDetail ON Asset.Id = AssetGLDetail.Id 
			  LEFT JOIN dbo.PricingGroups AS PricingGroup ON Asset.PricingGroupId = PricingGroup.Id
              LEFT OUTER JOIN
			(
				 SELECT NegativeDepositAsset.NegativeDepositAssetId,
						NegativeDepositAsset.FinancialType,
						NegativeDepositAsset.TakeDownAssetId,
						NegativeDepositAsset.PIDepositAssetId,
						PIDepositAsset.IsActive AS IsActive,
						PIDepositAsset.AssetId AS DepositAssetId
				 FROM
				 (
					 SELECT DISTINCT
							NegativeDepositAsset.Id AS NegativeDepositAssetId,
							NegativeDepositAsset.FinancialType AS FinancialType,
							PITakeDownAsset.AssetId AS TakeDownAssetId,
							PIDepositAsset.DepositAssetId AS PIDepositAssetId
					 FROM dbo.PayableInvoiceDepositTakeDownAssets AS PIDepositTakeDownAsset
						  INNER JOIN dbo.PayableInvoiceAssets AS PINegativeDepositAsset ON PIDepositTakeDownAsset.NegativeDepositAssetId = PINegativeDepositAsset.Id
						  INNER JOIN #ImportedAssets IA ON PINegativeDepositAsset.AssetId = IA.AssetId 
						  INNER JOIN dbo.Assets AS NegativeDepositAsset ON PINegativeDepositAsset.AssetId = NegativeDepositAsset.Id
						  INNER JOIN dbo.PayableInvoiceAssets AS PITakeDownAsset ON PIDepositTakeDownAsset.TakeDownAssetId = PITakeDownAsset.Id
						  INNER JOIN dbo.PayableInvoiceDepositAssets AS PIDepositAsset ON PIDepositTakeDownAsset.PayableInvoiceDepositAssetId = PIDepositAsset.Id
					 WHERE PIDepositTakeDownAsset.IsActive = 1
						   AND PINegativeDepositAsset.IsActive = 1
						   AND PITakeDownAsset.IsActive = 1
						   AND PIDepositAsset.IsActive = 1
				 ) AS NegativeDepositAsset
				INNER JOIN dbo.PayableInvoiceAssets AS PIDepositAsset ON NegativeDepositAsset.PIDepositAssetId = PIDepositAsset.Id
			) AS NegativeDepositAssetInfo ON Asset.Id = NegativeDepositAssetInfo.NegativeDepositAssetId
                       AND NegativeDepositAssetInfo.FinancialType = @AssetFinancialTypeNegativeDeposit
                       AND NegativeDepositAssetInfo.IsActive = 1
            LEFT OUTER JOIN
			(
				 SELECT PayableInvoice.Status AS Status,
						PIAsset.AssetId AS AssetId,
						PIVendor.PartyNumber AS PartyNumber,
						PIVendor.PartyName AS PartyName,
						PIVendor.Id AS VendorId,
						PIAsset.AcquisitionLocationId AS AcquisitionLocationId
				 FROM dbo.PayableInvoices AS PayableInvoice
					  INNER JOIN dbo.PayableInvoiceAssets AS PIAsset ON PayableInvoice.Id = PIAsset.PayableInvoiceId
				      INNER JOIN #ImportedAssets IA ON PIAsset.AssetId = IA.AssetId AND IsPersisted = 1
					  INNER JOIN dbo.Parties AS PIVendor ON PayableInvoice.VendorId = PIVendor.Id
				 WHERE PIAsset.AssetId IS NOT NULL
					   AND PIAsset.IsActive = 1
					   AND PayableInvoice.ParentPayableInvoiceId IS NULL
					   AND PayableInvoice.IsInvalidPayableInvoice <> 1
			) AS PayableInvoiceInfo ON Asset.Id = PayableInvoiceInfo.AssetId
                         AND PayableInvoiceInfo.Status = @PayableInvoiceCompletedStatus
            LEFT OUTER JOIN dbo.CollateralTrackings AS CollateralTracking ON Asset.Id = CollateralTracking.AssetId
						AND CollateralTracking.IsActive = 1
            LEFT OUTER JOIN dbo.TaxDepEntities AS TaxDepEntity ON Asset.Id = TaxDepEntity.AssetId
                        AND TaxDepEntity.AssetId IS NOT NULL
            LEFT OUTER JOIN dbo.AssetLocations AS AssetLocation ON Asset.Id = AssetLocation.AssetId
                         AND 1 = AssetLocation.IsCurrent
            LEFT OUTER JOIN dbo.Locations AS Location ON AssetLocation.LocationId = Location.Id
            LEFT OUTER JOIN dbo.States AS State ON Location.StateId = State.Id
            LEFT OUTER JOIN dbo.Countries AS Country ON State.CountryId = Country.Id
			LEFT OUTER JOIN #PreviousTaxLeases PreviousTaxLeases ON Asset.Id=PreviousTaxLeases.AssetId
			LEFT OUTER JOIN Contracts ON Asset.PreviousSequenceNumber = Contracts.SequenceNumber 
			LEFT OUTER JOIN #SyndicatedLeaseAssetsAVH ON Asset.Id = #SyndicatedLeaseAssetsAVH.AssetId

		DROP TABLE #SyndicatedLeaseAssetsAVH
		DROP TABLE #LF
		DROP TABLE #PreviousTaxLeases
		DROP TABLE #ImportedAssets
		DROP TABLE #PreviousTaxLeases1
		DROP TABLE #LeaseAssets
			   
     END

GO
