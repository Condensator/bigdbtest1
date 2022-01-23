SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertVATReceivableDetails] (
	@JobStepInstanceId	BIGINT,
	@CreatedById		BIGINT,
	@CreatedTime		DATETIMEOFFSET,
	@SalesTaxBatchProcessingStatus_New	NVARCHAR(10),
	@ReceivableTypeValues_LateFee	NVARCHAR(10)
)
AS
BEGIN

	INSERT INTO VATReceivableDetailExtract
	(ReceivableId, ReceivableDetailId, ReceivableDueDate, AssetId, ReceivableDetailAmount, Currency, GLTemplateId, JobStepInstanceId, 
	 TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, TaxAssetTypeId, IsCashBased, BatchStatus, 
     TaxRemittanceType, BuyerLocation, SellerLocation, TaxReceivableType, TaxAssetType, IsCapitalizedUpfront, IsReceivableCodeTaxExempt,
	 BuyerTaxRegistrationId, SellerTaxRegistrationId,IsLateFeeProcessed)
	SELECT
		VAT.ReceivableId, 
		VAT.ReceivableDetailId, 
		VAT.ReceivableDueDate, 
		VAT.AssetId, 
		CASE WHEN VATL.TaxReceivableType =@ReceivableTypeValues_LateFee THEN VATL.BasisAmount ELSE ExtendedPrice END, 
		CASE WHEN VATL.TaxReceivableType =@ReceivableTypeValues_LateFee THEN VATL.BasisAmountCurrency ELSE Currency END,
		GLTemplateId, 
		VAT.JobStepInstanceId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId, 
		TaxAssetTypeId, 
		0,
		@SalesTaxBatchProcessingStatus_New,
		VATL.TaxRemittanceType,
		VATL.BuyerLocation, 
		VATL.SellerLocation, 
		VATL.TaxReceivableType, 
		VATL.TaxAssetType, 
		VATL.IsCapitalizedUpfront, 
		VATL.IsReceivableCodeTaxExempt,
		VATL.BuyerTaxRegistrationId, 
		VATL.SellerTaxRegistrationId,
		0
	FROM SalesTaxReceivableDetailExtract VAT
	JOIN VATReceivableLocationDetailExtract VATL ON VAT.ReceivableDetailId = VATL.ReceivableDetailId
		AND VAT.AssetId = VATL.AssetId AND VAT.JobStepInstanceId = VATL.JobStepInstanceId
	WHERE VAT.JobStepInstanceId = @JobStepInstanceId AND VAT.AssetId IS NOT NULL

	INSERT INTO VATReceivableDetailExtract
	(ReceivableId, ReceivableDetailId, ReceivableDueDate, AssetId, ReceivableDetailAmount, Currency, GLTemplateId, JobStepInstanceId, 
	 TaxLevel, BuyerLocationId, SellerLocationId, TaxReceivableTypeId, TaxAssetTypeId, IsCashBased, BatchStatus, 
     TaxRemittanceType, BuyerLocation, SellerLocation, TaxReceivableType, TaxAssetType, IsCapitalizedUpfront, IsReceivableCodeTaxExempt,
	 BuyerTaxRegistrationId, SellerTaxRegistrationId,IsLateFeeProcessed)
	SELECT
		VAT.ReceivableId, 
		VAT.ReceivableDetailId, 
		VAT.ReceivableDueDate, 
		VAT.AssetId, 
		CASE WHEN VATL.TaxReceivableType =@ReceivableTypeValues_LateFee THEN VATL.BasisAmount ELSE ExtendedPrice END, 
		CASE WHEN VATL.TaxReceivableType =@ReceivableTypeValues_LateFee THEN VATL.BasisAmountCurrency ELSE Currency END,
		GLTemplateId, 
		VAT.JobStepInstanceId, 
		TaxLevel, 
		BuyerLocationId, 
		SellerLocationId, 
		TaxReceivableTypeId, 
		TaxAssetTypeId, 
		0, 
		@SalesTaxBatchProcessingStatus_New,
		VATL.TaxRemittanceType,
		VATL.BuyerLocation, 
		VATL.SellerLocation, 
		VATL.TaxReceivableType, 
		VATL.TaxAssetType, 
		VATL.IsCapitalizedUpfront, 
		VATL.IsReceivableCodeTaxExempt,
		VATL.BuyerTaxRegistrationId, 
		VATL.SellerTaxRegistrationId,
		0
	FROM SalesTaxReceivableDetailExtract VAT
	JOIN VATReceivableLocationDetailExtract VATL ON VAT.ReceivableDetailId = VATL.ReceivableDetailId
		AND VAT.JobStepInstanceId = VATL.JobStepInstanceId
	WHERE VAT.JobStepInstanceId = @JobStepInstanceId AND VAT.AssetId IS NULL

END

GO
