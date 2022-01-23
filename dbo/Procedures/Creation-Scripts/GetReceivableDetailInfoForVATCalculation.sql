SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivableDetailInfoForVATCalculation] (
	@ReceivableDetailInfo [VATReceivableDetailInfo] READONLY,
	@ReceivableEntityTypeValues_CU NVARCHAR(10),
	@LeasePurchaseOptionValues_HirePurchase NVARCHAR(64)
)
AS
BEGIN
	CREATE TABLE #VATLocationDetails
	(
		ReceivableDetailId BIGINT, 
		AssetId BIGINT, 
		TaxLevel NVARCHAR(14), 
		BuyerLocationId BIGINT, 
		SellerLocationId BIGINT, 
		TaxReceivableTypeId BIGINT, 
		TaxAssetTypeId BIGINT,
	 	IsCapitalizedUpfront BIT, 
		IsReceivableCodeTaxExempt BIT
	)

	 CREATE TABLE #VATReceivableDetails
	 (
		ReceivableDetailId BIGINT, 
		AssetId BIGINT, 
		ReceivableDueDate DATE, 
		ReceivableDetailAmount DECIMAL(18, 2),
		Currency NVARCHAR(80),
		InvoiceNumber NVARCHAR(80),
		TaxLevel NVARCHAR(14),
		BuyerLocationId BIGINT,
		SellerLocationId BIGINT, 
		TaxReceivableTypeId BIGINT, 
		TaxAssetTypeId BIGINT, 
		IsCapitalizedUpfront BIT, 
		IsReceivableCodeTaxExempt BIT
	)

	SELECT * INTO #ReceivableDetailInfo FROM @ReceivableDetailInfo

	;WITH CTE_TaxSourceDetails AS
	(
		SELECT
			STA.ReceivableDetailId, 
			STA.AssetId, 
			TSD.TaxLevel, 
			TSD.BuyerLocationId, 
			TSD.SellerLocationId, 
			RC.TaxReceivableTypeId, 
			CASE WHEN RT.IsRental = 1 AND DPT.Name = @LeasePurchaseOptionValues_HirePurchase THEN 
				CAST(1 AS BIT) 
			ELSE 
				CAST(0 AS BIT) 
			END IsCapitalizedUpfront,
			RC.IsTaxExempt IsReceivableCodeTaxExempt,
			ROW_NUMBER() OVER (PARTITION BY ReceivableDetailId, AssetId ORDER BY EffectiveDate DESC) RowNumber
		FROM #ReceivableDetailInfo STA
		INNER JOIN TaxSourceDetails TSD ON STA.ContractId = TSD.SourceId 
			AND STA.EntityType = TSD.SourceTable 
			AND STA.ReceivableDueDate >= TSD.EffectiveDate
		INNER JOIN ReceivableCodes RC ON STA.ReceivableCodeId = RC.Id
		INNER JOIN TaxReceivableTypes TRT ON RC.TaxReceivableTypeId = TRT.Id AND TRT.IsActive = 1
		INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
		INNER JOIN Contracts C ON STA.ContractId = C.Id
		INNER JOIN DealProductTypes DPT ON C.DealProductTypeId = DPT.Id
	)
	INSERT INTO #VATLocationDetails
	(ReceivableDetailId, AssetId, TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, IsCapitalizedUpfront, IsReceivableCodeTaxExempt)
	SELECT
		ReceivableDetailId, 
		AssetId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId,
		IsCapitalizedUpfront, 
		IsReceivableCodeTaxExempt
	FROM CTE_TaxSourceDetails CTE
	WHERE CTE.RowNumber = 1

	;WITH CTE_TaxSourceDetails AS 
	(
		SELECT
			STA.ReceivableDetailId, 
			STA.AssetId, 
			TSD.TaxLevel, 
			TSD.BuyerLocationId, 
			TSD.SellerLocationId, 
			RC.TaxReceivableTypeId, 
			CAST(0 AS BIT) IsCapitalizedUpfront,
			RC.IsTaxExempt IsReceivableCodeTaxExempt,
			ROW_NUMBER() OVER (PARTITION BY ReceivableDetailId, AssetId ORDER BY EffectiveDate DESC) RowNumber
		FROM #ReceivableDetailInfo STA
		INNER JOIN TaxSourceDetails TSD ON STA.SourceId = TSD.SourceId 
			AND STA.SourceTable = TSD.SourceTable AND STA.EntityType = @ReceivableEntityTypeValues_CU
			AND STA.ReceivableDueDate >= TSD.EffectiveDate
		JOIN ReceivableCodes RC ON STA.ReceivableCodeId = RC.Id
	)
	INSERT INTO #VATLocationDetails
	(ReceivableDetailId, AssetId, TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, IsCapitalizedUpfront, IsReceivableCodeTaxExempt)
	SELECT
		ReceivableDetailId, 
		AssetId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId, 
		IsCapitalizedUpfront, 
		IsReceivableCodeTaxExempt
	FROM CTE_TaxSourceDetails CTE
	WHERE CTE.RowNumber = 1

	UPDATE VATRL SET VATRL.TaxAssetTypeId = TATD.TaxAssetTypeId
	FROM #VATLocationDetails VATRL
	INNER JOIN Assets A ON VATRL.AssetId = A.Id
	INNER JOIN TaxAssetTypeDetails TATD ON A.TypeId = TATD.AssetTypeId AND TATD.IsActive = 1

	INSERT INTO #VATReceivableDetails
	(ReceivableDetailId, AssetId, ReceivableDueDate, ReceivableDetailAmount, Currency, InvoiceNumber, TaxLevel, BuyerLocationId, 
	 SellerLocationId, TaxReceivableTypeId, TaxAssetTypeId, IsCapitalizedUpfront, IsReceivableCodeTaxExempt)
	SELECT
		VAT.ReceivableDetailId, 
		VAT.AssetId, 
		VAT.ReceivableDueDate, 
		VAT.ReceivableDetailAmount, 
		VAT.Currency, 
		VAT.InvoiceNumber,
		VATL.TaxLevel, 
		VATL.BuyerLocationId, 
		VATL.SellerLocationId, 
		VATL.TaxReceivableTypeId, 
		VATL.TaxAssetTypeId,
		VATL.IsCapitalizedUpfront, 
		VATL.IsReceivableCodeTaxExempt
	FROM #ReceivableDetailInfo VAT
	JOIN #VATLocationDetails VATL ON VAT.ReceivableDetailId = VATL.ReceivableDetailId	
	 AND VAT.AssetId = VATL.AssetId
	WHERE VAT.AssetId IS NOT NULL

	INSERT INTO #VATReceivableDetails
	(ReceivableDetailId, AssetId, ReceivableDueDate, ReceivableDetailAmount, Currency, InvoiceNumber, TaxLevel, BuyerLocationId, 
	 SellerLocationId, TaxReceivableTypeId, TaxAssetTypeId, IsCapitalizedUpfront, IsReceivableCodeTaxExempt)
	SELECT
		VAT.ReceivableDetailId, 
		VAT.AssetId, 
		VAT.ReceivableDueDate, 
		VAT.ReceivableDetailAmount, 
		VAT.Currency, 
		VAT.InvoiceNumber,
		VATL.TaxLevel, 
		VATL.BuyerLocationId, 
		VATL.SellerLocationId, 
		VATL.TaxReceivableTypeId, 
		VATL.TaxAssetTypeId,
		VATL.IsCapitalizedUpfront, 
		VATL.IsReceivableCodeTaxExempt
	FROM #ReceivableDetailInfo VAT
	JOIN #VATLocationDetails VATL ON VAT.ReceivableDetailId = VATL.ReceivableDetailId
	WHERE VAT.AssetId IS NULL
	
	SELECT
	UniqueDetailId = ROW_NUMBER() OVER (ORDER BY vatReceivableDetail.ReceivableDetailId ASC, vatReceivableDetail.AssetId ASC),
	vatReceivableDetail.ReceivableDetailId,
	DueDate = vatReceivableDetail.ReceivableDueDate,
	ReceivableDetailAmount = vatReceivableDetail.ReceivableDetailAmount,
	Currency = vatReceivableDetail.Currency,
	InvoiceNumber = vatReceivableDetail.InvoiceNumber,
	BuyerLocationId = vatReceivableDetail.BuyerLocationId,
    SellerLocationId = vatReceivableDetail.SellerLocationId,
    TaxAssetTypeId = vatReceivableDetail.TaxAssetTypeId,
    TaxReceivableTypeId = vatReceivableDetail.TaxReceivableTypeId,
    TaxLevel = vatReceivableDetail.TaxLevel,
	IsCapitalizedUpfront = vatReceivableDetail.IsCapitalizedUpfront, 
	IsReceivableCodeTaxExempt = vatReceivableDetail.IsReceivableCodeTaxExempt,
	GroupUniqueId = 0
	FROM #VATReceivableDetails vatReceivableDetail
END

GO
