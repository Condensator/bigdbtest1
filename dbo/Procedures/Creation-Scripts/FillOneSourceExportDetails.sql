SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[FillOneSourceExportDetails]
(
	@JobStepInstanceId BIGINT,			
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@EntityType NVARCHAR(20),
	@TaxBook NVARCHAR(20),
    @applicableAssets PropertyTaxExportOneSourceAssets READONLY
)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #tempTable1
	(
		AssetId BIGINT,
		FederalTaxDep Decimal(16,2) NULL
	)

	SELECT TaxDepEntities.Id as TaxDepEntityId, TaxDepEntities.AssetId
	INTO #EligibleTaxDepEntities
	FROM TaxDepEntities JOIN TaxDepTemplates ON TaxDepTemplates.Id = TaxDepEntities.TaxDepTemplateId 
		JOIN TaxDepTemplateDetails ON TaxDepTemplateDetails.TaxDepTemplateId = TaxDepTemplates.Id
		JOIN @applicableAssets applicableAsset ON TaxDepEntities.AssetId=applicableAsset.AssetId AND applicableAsset.IsIncluded = 1
	WHERE TaxDepEntities.EntityType=@EntityType and TaxDepTemplateDetails.TaxBook=@TaxBook

	IF EXISTS (SELECT TOP 1 * FROM #EligibleTaxDepEntities)
	BEGIN
		INSERT INTO #tempTable1
		SELECT #EligibleTaxDepEntities.AssetId AssetId, SUM(TaxDepAmortizationDetail.DepreciationAmount_Amount) FederalTaxDep
		FROM TaxDepAmortizationDetails TaxDepAmortizationDetail
			JOIN TaxDepAmortizations ON TaxDepAmortizationDetail.TaxDepAmortizationId = TaxDepAmortizations.Id
			JOIN #EligibleTaxDepEntities ON TaxDepAmortizations.TaxDepEntityId = #EligibleTaxDepEntities.TaxDepEntityId
		GROUP BY #EligibleTaxDepEntities.AssetId
	END



	-- LeaseAssets is kept seperately to avoid duplicates and its not being used
	SELECT applicableAsset.AssetId,applicableAsset.ContractId,applicableAsset.AssetLocationId,--leaseAsset.IsActive,
		 leaseFinance.Id LeaseFinanceId ,leaseFinance.BookingStatus,contract.SequenceNumber
		,leaseFinanceDetail.LeaseContractType 
	INTO #temptable3
	FROM @applicableAssets applicableAsset 
	--INNER JOIN LeaseAssets leaseAsset ON leaseAsset.AssetId =applicableAsset.AssetId
	INNER JOIN LeaseFinances leaseFinance ON applicableAsset.ContractId = leaseFinance.ContractId								
									AND leaseFinance.IsCurrent = 1 -- This needs to be verified
	INNER JOIN LeaseFinanceDetails leaseFinanceDetail ON leaseFinance.Id = leaseFinanceDetail.Id
	INNER JOIN Contracts Contract ON leaseFinance.ContractId = Contract.Id	


	--SELECT * INTO #tempTable2 FROM OneSourceExportDetailExtracts WHERE 1=2
	SELECT 	ExtractData.LegalEntityId LegalEntityId,
			LeaseAssetDetail.SequenceNumber LeaseNumber,
			asset.Id AssetNumber,
			category.Name ItemType,
			asset.Description AssetDescription,
			asset.AcquisitionDate AcquisitionDate,
			asset.PropertyTaxCost_Amount AssetCost,
			assetLocation.AddressLine1 AssetAddressLine1,
			assetLocation.AddressLine2 AssetAddressLine2,
			assetLocation.AddressLine3 AssetAddressLine3,
			assetLocation.City AssetCity,
			state.LongName AssetState,
			assetLocation.PostalCode AssetZipCode,
			assetLocation.Division AssetCountyName,
			assetType.Name EquipmentCode,
			LeaseAssetDetail.LeaseContractType LeaseType,
			ExtractData.SerialNumber AssetSerialNumber,
			asset.Quantity Quantity,
			case when assetLevelFederalTaxDep.AssetId is not null then assetLevelFederalTaxDep.FederalTaxDep else null end FederalTaxDep,
			manufacturer.Name Manufacturer,
			asset.ModelYear ModelYear,
			party.PartyName AgreementCustomerName,
			partyAddress.AddressLine1 CustomerAddressLine1,
			partyAddress.AddressLine2 CustomerAddressLine2,
			partyAddress.AddressLine3 CustomerAddressLine3,
			partyAddress.City CustomerCity,	
			partyState.LongName CustomerState,
			partyAddress.PostalCode CustomerZipCode,
			asset.IsEligibleForPropertyTax TaxExempt,
			@JobStepInstanceId JobStepInstanceId,
			@CreatedById CreatedById,
			@CreatedTime CreatedTime,
			applicableAsset.IsIncluded IsIncluded,
			applicableAsset.RejectReason RejectReason,
			applicableAsset.FileName FileName,
			applicableAsset.AsOfDate
			,applicableAsset.IsDisposedAssetReported
			,applicableAsset.PreviousLeaseNumber
	INTO #finalResults
	FROM Assets asset 
			INNER JOIN @applicableAssets applicableAsset ON asset.Id=applicableAsset.AssetId
			INNER JOIN PropertyTaxExportJobExtracts ExtractData 
						ON applicableAsset.AssetId = ExtractData.AssetID
						AND ((applicableAsset.ContractId IS NULL AND ExtractData.ContractId IS NULL) OR (applicableAsset.ContractId = ExtractData.ContractId))
						AND applicableAsset.AssetLocationId = ExtractData.AssetLocationId	
						AND ExtractData.JobStepInstanceId = @JobStepInstanceId
			INNER JOIN AssetTypes assetType ON asset.TypeId = assetType.Id
			LEFT JOIN AssetCategories category ON asset.AssetCategoryId = category.Id
			LEFT JOIN Manufacturers manufacturer ON asset.ManufacturerId = manufacturer.Id
			LEFT JOIN AssetLocations assetCurrentLocation ON asset.Id=assetCurrentLocation.AssetId 
							AND applicableAsset.AssetLocationId = assetCurrentLocation.Id 							
			LEFT JOIN Locations assetLocation ON assetCurrentLocation.LocationId = assetLocation.Id
			LEFT JOIN States state ON assetLocation.StateId = state.Id
			LEFT JOIN #temptable3 LeaseAssetDetail ON LeaseAssetDetail.AssetId = applicableAsset.AssetId
						AND LeaseAssetDetail.AssetLocationId = applicableAsset.AssetLocationId						
						AND ((applicableAsset.ContractId IS NULL AND LeaseAssetDetail.ContractId IS NULL) OR (applicableAsset.ContractId = LeaseAssetDetail.ContractId))
			LEFT JOIN Parties party ON asset.CustomerId = party.Id
			LEFT JOIN PartyAddresses partyAddress ON party.Id=partyAddress.PartyId and partyAddress.IsMain=1
			LEFT JOIN States partyState ON partyAddress.StateId = partyState.Id
			LEFT JOIN #tempTable1 assetLevelFederalTaxDep ON asset.Id = assetLevelFederalTaxDep.AssetId



 
	INSERT INTO OneSourceExportDetailExtracts
	(
			LegalEntityId,
			LeaseNumber,
			AssetNumber,
			ItemType,
			AssetDescription,
			AcquisitionDate,
			AssetCost,
			AssetAddressLine1,
			AssetAddressLine2,
			AssetAddressLine3,
			AssetCity,
			AssetState,
			AssetZipCode,
			AssetCountyName,
			EquipmentCode,
			LeaseType,
			AssetSerialNumber,
			Quantity,
			FederalTaxDep,
			Manufacturer,
			ModelYear,
			AgreementCustomerName,
			CustomerAddressLine1,
			CustomerAddressLine2,
			CustomerAddressLine3,
			CustomerCity,
			CustomerState,
			CustomerZipCode,
			TaxExempt,
			JobStepInstanceId,
			CreatedById,
			CreatedTime,
			IsIncluded,
			RejectReason,
			FileName,
			AsOfDate,
			IsDisposedAssetReported,
			PreviousLeaseNumber
	)
	SELECT 
			LegalEntityId,
			LeaseNumber,
			AssetNumber,
			ItemType,
			AssetDescription,
			AcquisitionDate,
			AssetCost,
			AssetAddressLine1,
			AssetAddressLine2,
			AssetAddressLine3,
			AssetCity,
			AssetState,
			AssetZipCode,
			AssetCountyName,
			EquipmentCode,
			LeaseType,
			AssetSerialNumber,
			Quantity,
			FederalTaxDep,
			Manufacturer,
			ModelYear,
			AgreementCustomerName,
			CustomerAddressLine1,
			CustomerAddressLine2,
			CustomerAddressLine3,
			CustomerCity,	
			CustomerState,
			CustomerZipCode,
			TaxExempt,
			JobStepInstanceId,
			CreatedById,
			CreatedTime,
			IsIncluded,
			RejectReason,
			FileName,
			AsOfDate
			,IsDisposedAssetReported
			,PreviousLeaseNumber
		FROM #finalResults


	SELECT
			LegalEntityId,
			LeaseNumber,
			AssetNumber,
			ItemType,
			AssetDescription,
			AcquisitionDate,
			AssetCost,
			AssetAddressLine1,
			AssetAddressLine2,
			AssetAddressLine3,
			AssetCity,
			AssetState,
			AssetZipCode,
			AssetCountyName,
			EquipmentCode,
			LeaseType,
			AssetSerialNumber,
			Quantity,
			FederalTaxDep,
			Manufacturer,
			ModelYear,
			AgreementCustomerName,
			CustomerAddressLine1,
			CustomerAddressLine2,
			CustomerAddressLine3,
			CustomerCity,
			CustomerState,
			CustomerZipCode,
			TaxExempt,
			JobStepInstanceId,
			CreatedById,
			CreatedTime,
			IsIncluded,
			RejectReason,
			FileName,
			PreviousLeaseNumber
	FROM #finalResults WHERE IsIncluded=1
 
 
 	IF OBJECT_ID('tempDB..#tempTable1') IS NOT NULL
		DROP TABLE #tempTable1
	IF OBJECT_ID('tempDB..#tempTable2') IS NOT NULL
		DROP TABLE #tempTable2
	IF OBJECT_ID('tempDB..#temptable3') IS NOT NULL
		DROP TABLE #temptable3
	IF OBJECT_ID('tempDB..#EligibleTaxDepEntities') IS NOT NULL
		DROP TABLE #EligibleTaxDepEntities
	IF OBJECT_ID('tempDB..#finalResults') IS NOT NULL
		DROP TABLE #finalResults
		
		
END

GO
