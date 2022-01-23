SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertSalesTaxReceivableDetails]  
(   
    @ReceivableIds SalesTaxReceivableIds null Readonly,
    @ReceivableDetailIds SalesTaxReceivableDetailIds null Readonly,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@SundryTableName NVARCHAR(100),
	@SundryRecurringTableName NVARCHAR(100),
	@RecordsCount BIGINT OUTPUT,
	@JobStepInstanceId BIGINT,
	@CTEntityType NVARCHAR(100),
    @DTEntityType NVARCHAR(100),
	@FetchTaxAssessedRecordsForVAT BIT,
	@IsReAssess BIT,
	@hasReceivable BIT output
)  
AS   
SET NOCOUNT ON;  
  
BEGIN  

SET @hasReceivable = 0;
CREATE TABLE #SalesTaxReceivableDetails
(
	[ReceivableId]							BIGINT NOT NULL,
	[ReceivableDetailId]					BIGINT NOT NULL,
	[AssetId]								BIGINT NULL,
	[ReceivableDueDate]						DATE NOT NULL,
	[ContractId]							BIGINT NULL,
	[DiscountingId]							BIGINT NULL,
	[CustomerId]							BIGINT NOT NULL,
	[EntityType]							NVARCHAR(40) NOT NULL,
	[ExtendedPrice]							DECIMAL(16,2) NOT NULL,
	[Currency]								NVARCHAR(40) NOT NULL,
	[LocationId]							BIGINT NULL,
	[ReceivableCodeId]						BIGINT NOT NULL,
	[PaymentScheduleId]						BIGINT NULL,
	[SourceId]								BIGINT NULL,
	[SourceTable]							NVARCHAR(400) NOT NULL,
	[LegalEntityId]							BIGINT NOT NULL,
    [TaxPayer]								NVARCHAR(100) NULL,
	[LegalEntityTaxRemittancePreference]	NVARCHAR(40) NULL,  
	[IsExemptAtSundry]						BIT NOT NULL,
	[AdjustmentBasisReceivableDetailId]		BIGINT NULL,
	[IsOriginalReceivableDetailTaxAssessed] BIT,
	[IsAssessSalesTaxAtSKULevel]			BIT NOT NULL,
	[ReceivableTaxType]						NVARCHAR(8) NULL,
	[PreCapitalizationRent]					DECIMAL(16,2) NOT NULL,
)

INSERT INTO #SalesTaxReceivableDetails 
	(ReceivableId 
	,ReceivableDetailId 
	,AssetId 
	,ReceivableDueDate
	,Currency
	,ContractId
	,DiscountingId
	,CustomerId
	,EntityType
	,ExtendedPrice
	,LocationId
	,ReceivableCodeId
	,PaymentScheduleId
	,SourceId
	,SourceTable
	,LegalEntityId
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,IsExemptAtSundry
	,AdjustmentBasisReceivableDetailId
	,IsOriginalReceivableDetailTaxAssessed
	,IsAssessSalesTaxAtSKULevel
	,ReceivableTaxType
	,PreCapitalizationRent)
SELECT
	 R.Id
	,RD.Id
	,RD.AssetId
	,R.DueDate
	,RD.Amount_Currency
	,CASE WHEN R.EntityType = @CTEntityType THEN R.EntityId ELSE NULL END
	,CASE WHEN R.EntityType = @DTEntityType THEN R.EntityId ELSE NULL END
	,R.CustomerId
	,R.EntityType
	,RD.Amount_Amount
	,R.LocationId
	,R.ReceivableCodeId
	,R.PaymentScheduleId
	,R.SourceId
	,R.SourceTable
	,R.LegalEntityId
	,L.TaxPayer
	,REPLACE(L.TaxRemittancePreference, 'Based','')
	,0
	,RD.AdjustmentBasisReceivableDetailId
	,NULL AS IsOriginalReceivableDetailTaxAssessed
	,L.IsAssessSalesTaxAtSKULevel
	,R.ReceivableTaxType
	,RD.PreCapitalizationRent_Amount
FROM 
	Receivables R  
	INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
	INNER JOIN LegalEntities L ON R.LegalEntityId = L.Id
	LEFT JOIN @ReceivableIds RIC ON R.Id= RIC.ReceivableId
	LEFT JOIN @ReceivableDetailIds RDIC ON RD.Id = RDIC.ReceivableDetailId   
WHERE (RIC.ReceivableId IS NOT NULL OR RDIC.ReceivableDetailId IS NOT NULL)
	AND ((@FetchTaxAssessedRecordsForVAT = 1 AND R.ReceivableTaxType = 'VAT') OR (RD.IsTaxAssessed = 0 OR (@IsReAssess = 1 AND RD.IsTaxAssessed = 1)))
	AND R.IsActive =1 AND RD.IsActive =1 
	
UPDATE #SalesTaxReceivableDetails
SET IsOriginalReceivableDetailTaxAssessed = ORD.IsTaxAssessed
FROM #SalesTaxReceivableDetails STR
INNER JOIN ReceivableDetails ORD ON STR.AdjustmentBasisReceivableDetailId = ORD.Id AND STR.AdjustmentBasisReceivableDetailId IS NOT NULL;
	
Update #SalesTaxReceivableDetails 
	SET IsExemptAtSundry = S.IsTaxExempt
FROM 
	#SalesTaxReceivableDetails STR
INNER JOIN 
	Sundries S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryTableName;

Update #SalesTaxReceivableDetails 
	SET IsExemptAtSundry = S.IsTaxExempt
FROM 
	#SalesTaxReceivableDetails STR
INNER JOIN 
	SundryRecurrings S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryRecurringTableName;


INSERT INTO SalesTaxReceivableDetailExtract 
	(ReceivableId
	,ReceivableDetailId
	,AssetId
	,ReceivableDueDate
	,Currency
	,ContractId
	,DiscountingId
	,CustomerId
	,EntityType
	,ExtendedPrice
	,LocationId
	,ReceivableCodeId
	,AmountBilledToDate
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId	
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,IsVertexSupported
	,JobStepInstanceId
	,AdjustmentBasisReceivableDetailId
	,IsOriginalReceivableDetailTaxAssessed
	,IsAssessSalesTaxAtSKULevel
	,SourceId
	,SourceTable
	,ReceivableTaxType)  
SELECT 
	ReceivableId
	,ReceivableDetailId
	,AssetId
	,ReceivableDueDate
	,Currency
	,ContractId
	,DiscountingId
	,CustomerId
	,EntityType
	,ExtendedPrice
	,LocationId
	,ReceivableCodeId
	,0.00
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,0
	,@JobStepInstanceId
	,AdjustmentBasisReceivableDetailId
	,IsOriginalReceivableDetailTaxAssessed
	,IsAssessSalesTaxAtSKULevel
	,SourceId
	,SourceTable
	,ReceivableTaxType
FROM #SalesTaxReceivableDetails
WHERE PreCapitalizationRent = 0.00;

INSERT INTO SalesTaxReceivableDetailExtract 
	(ReceivableId
	,ReceivableDetailId
	,AssetId
	,ReceivableDueDate
	,Currency
	,ContractId
	,DiscountingId
	,CustomerId
	,EntityType
	,ExtendedPrice
	,LocationId
	,ReceivableCodeId
	,AmountBilledToDate
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId	
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,IsVertexSupported
	,JobStepInstanceId
	,AdjustmentBasisReceivableDetailId
	,IsOriginalReceivableDetailTaxAssessed
	,IsAssessSalesTaxAtSKULevel
	,SourceId
	,SourceTable
	,ReceivableTaxType)  
SELECT 
	ReceivableId
	,ReceivableDetailId
	,AssetId
	,ReceivableDueDate
	,Currency
	,ContractId
	,DiscountingId
	,CustomerId
	,EntityType
	,PreCapitalizationRent
	,LocationId
	,ReceivableCodeId
	,0.00
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,0
	,@JobStepInstanceId
	,AdjustmentBasisReceivableDetailId
	,IsOriginalReceivableDetailTaxAssessed
	,IsAssessSalesTaxAtSKULevel
	,SourceId
	,SourceTable
	,ReceivableTaxType
FROM #SalesTaxReceivableDetails
WHERE PreCapitalizationRent <> 0.00;

IF exists(SELECT 1 FROM #SalesTaxReceivableDetails)
BEGIN
SET @hasReceivable = 1
END

DROP TABLE #SalesTaxReceivableDetails;

END

GO
