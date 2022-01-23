SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertVATLocationDetails] 
(
	@JobStepInstanceId				BIGINT,
	@CreatedById					BIGINT,
	@CreatedTime					DATETIMEOFFSET,
	@CurrentBusinessDate			DATE,
	@ReceivableTaxTypeValues_VAT	NVARCHAR(10),
	@ReceivableEntityTypeValues_CU	NVARCHAR(10),
	@LeasePurchaseOptionValues_HirePurchase	NVARCHAR(2)
)
AS
BEGIN
	
	;WITH CTE_TaxSourceDetails AS
	(
		SELECT
			STA.ReceivableId,
			STA.ReceivableDueDate,
			STA.CustomerId,
			STA.LegalEntityId,
			STA.ReceivableDetailId, 
			AssetId, 
			JobStepInstanceId, 
			RC.ReceivableTypeId, 
			TSD.TaxLevel, 
			TSD.BuyerLocationId, 
			TSD.SellerLocationId, 
			RC.TaxReceivableTypeId, 
			REPLACE(C.SalesTaxRemittanceMethod, 'Based','') AS SalesTaxRemittanceMethod,
			TRT.Name TaxReceivableTypeName, 
			CASE WHEN RT.IsRental = 1 AND DPT.LeaseType = @LeasePurchaseOptionValues_HirePurchase THEN 
				CAST(1 AS BIT) 
			ELSE 
				CAST(0 AS BIT) 
			END IsCapitalizedUpfront,
			RC.IsTaxExempt IsReceivableCodeTaxExempt,
			ROW_NUMBER() OVER (PARTITION BY ReceivableDetailId, AssetId ORDER BY EffectiveDate DESC) RowNumber
		FROM SalesTaxReceivableDetailExtract STA
		INNER JOIN TaxSourceDetails TSD ON STA.ContractId = TSD.SourceId 
			AND STA.EntityType = TSD.SourceTable AND STA.ReceivableDueDate >= TSD.EffectiveDate
		INNER JOIN ReceivableCodes RC ON STA.ReceivableCodeId = RC.Id
		INNER JOIN TaxReceivableTypes TRT ON RC.TaxReceivableTypeId = TRT.Id
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
		INNER JOIN Contracts C ON STA.ContractId = C.Id
		INNER JOIN DealProductTypes DPT ON C.DealProductTypeId = DPT.Id
		WHERE STA.JobStepInstanceId = @JobStepInstanceId 
			AND STA.ReceivableTaxType = @ReceivableTaxTypeValues_VAT
	)
	INSERT INTO VATReceivableLocationDetailExtract
	(ReceivableId, ReceivableDueDate, CustomerId, LegalEntityId, ReceivableDetailId, AssetId, JobStepInstanceId, ReceivableTypeId, 
	 TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, TaxRemittanceType, 
	 BuyerLocation, SellerLocation, TaxReceivableType, IsCapitalizedUpfront, IsReceivableCodeTaxExempt,BasisAmount,BasisAmountCurrency)
	SELECT
		ReceivableId,
		ReceivableDueDate,
		CustomerId,
		LegalEntityId,
		ReceivableDetailId, 
		AssetId, 
		JobStepInstanceId, 
		ReceivableTypeId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId,
		SalesTaxRemittanceMethod,
		BuyerLocation.LongName,
		SellerLocation.LongName,
		TaxReceivableTypeName, 
		IsCapitalizedUpfront, 
		IsReceivableCodeTaxExempt,
		0.00 AS BasisAmount,
		'USD' AS BasisAmountCurrency
	FROM CTE_TaxSourceDetails CTE
	INNER JOIN Countries SellerLocation ON CTE.SellerLocationId = SellerLocation.Id
	INNER JOIN Countries BuyerLocation ON CTE.BuyerLocationId = BuyerLocation.Id
	WHERE CTE.RowNumber = 1

	;WITH CTE_TaxSourceDetails AS 
	(
		SELECT
			STA.ReceivableId,
			STA.ReceivableDueDate,
			STA.CustomerId,
			STA.LegalEntityId,
			STA.ReceivableDetailId, 
			AssetId, 
			JobStepInstanceId, 
			RC.ReceivableTypeId, 
			TSD.TaxLevel, 
			TSD.BuyerLocationId, 
			TSD.SellerLocationId, 
			RC.TaxReceivableTypeId, 
			REPLACE(STA.LegalEntityTaxRemittancePreference, 'Based','') AS LegalEntityTaxRemittancePreference,
			TRT.Name TaxReceivableTypeName, 
			CAST(0 AS BIT) IsCapitalizedUpfront,
			RC.IsTaxExempt IsReceivableCodeTaxExempt,
			ROW_NUMBER() OVER (PARTITION BY ReceivableDetailId, AssetId ORDER BY EffectiveDate DESC) RowNumber
		FROM SalesTaxReceivableDetailExtract STA
		INNER JOIN TaxSourceDetails TSD ON STA.SourceId = TSD.SourceId 
			AND STA.SourceTable = TSD.SourceTable AND STA.EntityType = @ReceivableEntityTypeValues_CU
			AND STA.ReceivableDueDate >= TSD.EffectiveDate
		JOIN ReceivableCodes RC ON STA.ReceivableCodeId = RC.Id
		JOIN TaxReceivableTypes TRT ON RC.TaxReceivableTypeId = TRT.Id
		WHERE STA.JobStepInstanceId = @JobStepInstanceId
			AND STA.ReceivableTaxType = @ReceivableTaxTypeValues_VAT
	)

	INSERT INTO VATReceivableLocationDetailExtract
	(ReceivableId, ReceivableDueDate, CustomerId, LegalEntityId, ReceivableDetailId, AssetId, JobStepInstanceId, ReceivableTypeId, 
	 TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, TaxRemittanceType,
	 BuyerLocation, SellerLocation, TaxReceivableType, IsCapitalizedUpfront, IsReceivableCodeTaxExempt,BasisAmount,BasisAmountCurrency)
	SELECT
		ReceivableId,
		ReceivableDueDate,
		CustomerId,
		LegalEntityId,
		ReceivableDetailId, 
		AssetId, 
		JobStepInstanceId, 
		ReceivableTypeId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId,
		LegalEntityTaxRemittancePreference,
		BuyerLocation.LongName,
		SellerLocation.LongName,
		TaxReceivableTypeName, 
		IsCapitalizedUpfront, 
		IsReceivableCodeTaxExempt,
		0.00 AS BasisAmount,
		'USD' AS BasisAmountCurrency
	FROM CTE_TaxSourceDetails CTE
	INNER JOIN Countries SellerLocation ON CTE.SellerLocationId = SellerLocation.Id
	INNER JOIN Countries BuyerLocation ON CTE.BuyerLocationId = BuyerLocation.Id
	WHERE CTE.RowNumber = 1

	UPDATE VATRL
		SET VATRL.TaxAssetTypeId = TATD.TaxAssetTypeId,
			VATRL.TaxAssetType = TAT.Name
	FROM VATReceivableLocationDetailExtract VATRL
	INNER JOIN Assets A ON VATRL.AssetId = A.Id
	INNER JOIN TaxAssetTypeDetails TATD ON A.TypeId = TATD.AssetTypeId AND TATD.IsActive = 1
	INNER JOIN TaxAssetTypes TAT ON TATD.TaxAssetTypeId = TAT.Id AND TAT.IsActive = 1
	;

	DECLARE @ReceivableCustomerList AS ReceivableCustomerCollection
	DECLARE @ReceivableLEList AS ReceivableLECollection

	INSERT INTO @ReceivableCustomerList 
	(ReceivableId, DueDate, CustomerId, LocationId, TaxLevel)
	SELECT 
		ReceivableId, ReceivableDueDate, CustomerId, BuyerLocationId, TaxLevel 
	FROM VATReceivableLocationDetailExtract
	WHERE JobStepInstanceId = @JobStepInstanceId
	;

	INSERT INTO @ReceivableLEList 
	(ReceivableId, DueDate, LegalEntityId, LocationId, TaxLevel)
	SELECT 
		ReceivableId, ReceivableDueDate, LegalEntityId, SellerLocationId, TaxLevel 
	FROM VATReceivableLocationDetailExtract
	WHERE JobStepInstanceId = @JobStepInstanceId
	;

	UPDATE VAT
		SET BuyerTaxRegistrationId = BuyerTax.TaxRegId
	FROM VATReceivableLocationDetailExtract VAT
	JOIN (SELECT * FROM dbo.GetCustomerTaxRegistrationNumber(@ReceivableCustomerList, @CurrentBusinessDate)) BuyerTax
	ON VAT.CustomerId = BuyerTax.CustomerId AND VAT.BuyerLocationId = BuyerTax.LocationId 
	AND VAT.ReceivableDueDate = BuyerTax.DueDate AND VAT.JobStepInstanceId = @JobStepInstanceId
	;

	UPDATE VAT
		SET SellerTaxRegistrationId = SellerTax.TaxRegId
	FROM VATReceivableLocationDetailExtract VAT
	JOIN (SELECT * FROM dbo.GetLegalEntityTaxRegistrationNumber(@ReceivableLEList, @CurrentBusinessDate)) SellerTax
	ON VAT.LegalEntityId = SellerTax.LegalEntityId AND VAT.SellerLocationId = SellerTax.LocationId 
	AND VAT.ReceivableDueDate = SellerTax.DueDate AND VAT.JobStepInstanceId = @JobStepInstanceId
	;

END

GO
