SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertCustomerBasedAllReceivableDetailsForNonInvoiceSensitive]
(
	@ComputedProcessThroughDate		DATETIME,
	@LegalEntityIds					IDs READONLY,
	@CreatedById					BIGINT,
	@CreatedTime					DATETIMEOFFSET,
	@SundryTableName				NVARCHAR(100),
	@SundryRecurringTableName		NVARCHAR(100),
	@ProgressLoanContractTypeName	NVARCHAR(100),
	@CTEntityType					NVARCHAR(100),
	@DTEntityType					NVARCHAR(100),
	@ExcludeBackgroundProcessingPendingContracts BIT,
	@RecordsExists					TINYINT OUTPUT,
	@JobStepInstanceId				BIGINT,
	@CustomerIds					CustomerIdCollection READONLY
)
AS
SET NOCOUNT ON;
BEGIN
CREATE TABLE #SalesTaxReceivableDetails
(
[ReceivableId] BigInt  NOT NULL,
[ReceivableDetailId] BigInt  NOT NULL,
[AssetId] BigInt  NULL,
[ReceivableDueDate] Date  NOT NULL,
[ContractId] BigInt  NULL,
[DiscountingId] BigInt  NULL,
[CustomerId] BigInt  NOT NULL,
[EntityType] NVarChar(40)  NOT NULL,
[ExtendedPrice] Decimal(16,2)  NOT NULL,
[Currency] NVarChar(40)  NOT NULL,
[LocationId] BigInt  NULL,
[ReceivableCodeId] BigInt  NOT NULL,
[PaymentScheduleId]  BigInt NULL,
[SourceId]  BigInt NULL,
[SourceTable] NVarChar(400)  NOT NULL,
[LegalEntityId] BigInt NOT NULL,
[TaxPayer]  NVarChar(100) NULL,
[LegalEntityTaxRemittancePreference]  NVarChar(40) NULL,
[IsExemptAtSundry] BIT NOT NULL,
[AdjustmentBasisReceivableDetailId] BIGINT NULL,
[IsOriginalReceivableDetailTaxAssessed] BIT,
[IsAssessSalesTaxAtSKULevel] BIT NOT NULL,
[ReceivableTaxType] NVARCHAR(8) NULL,
[PreCapitalizationRent] DECIMAL(16, 2)
)

SELECT * INTO #CustomerIdList FROM @CustomerIds
SELECT * INTO #LegalEntityIds FROM @LegalEntityIds

CREATE TABLE #BackgroundProcessingPendingContracts (Id BIGINT)
IF (@ExcludeBackgroundProcessingPendingContracts = 1)
BEGIN
INSERT INTO #BackgroundProcessingPendingContracts (Id) SELECT Id FROM Contracts CT WHERE CT.BackgroundProcessingPending = 1
END

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
JOIN #CustomerIdList C  on R.CustomerId = C.CustomerId
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN #LegalEntityIds LE ON R.LegalEntityId = LE.Id
INNER JOIN LegalEntities L ON R.LegalEntityId = L.Id
LEFT JOIN #BackgroundProcessingPendingContracts BPPC ON R.EntityId = BPPC.Id AND R.EntityType = @CTEntityType
WHERE R.IsActive =1 AND RD.IsActive =1 AND RD.IsTaxAssessed = 0 AND BPPC.Id IS NULL 
AND (R.DueDate <= @ComputedProcessThroughDate)

UPDATE #SalesTaxReceivableDetails
SET IsOriginalReceivableDetailTaxAssessed = ORD.IsTaxAssessed
FROM #SalesTaxReceivableDetails STR
INNER JOIN ReceivableDetails ORD ON STR.AdjustmentBasisReceivableDetailId = ORD.Id 
	AND STR.AdjustmentBasisReceivableDetailId IS NOT NULL;

Update #SalesTaxReceivableDetails
SET IsExemptAtSundry = S.IsTaxExempt
FROM #SalesTaxReceivableDetails STR
INNER JOIN Sundries S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryTableName
LEFT JOIN BillToes B ON B.Id = S.BillToId
WHERE S.BillToId IS NOT NULL OR S.IsAssetBased = 1;

Update #SalesTaxReceivableDetails
SET IsExemptAtSundry = S.IsTaxExempt
FROM #SalesTaxReceivableDetails STR
INNER JOIN SundryRecurrings S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryRecurringTableName
LEFT JOIN BillToes B ON B.Id = S.BillToId
WHERE S.BillToId IS NOT NULL OR S.IsAssetBased = 1;

INSERT INTO SalesTaxReceivableDetailExtract
(ReceivableId
,ReceivableDetailId
,AssetId
,ReceivableDueDate
,Currency
,ContractId
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
,DiscountingId
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
,DiscountingId
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
,DiscountingId
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
,DiscountingId
,AdjustmentBasisReceivableDetailId
,IsOriginalReceivableDetailTaxAssessed
,IsAssessSalesTaxAtSKULevel
,SourceId
,SourceTable
,ReceivableTaxType
FROM #SalesTaxReceivableDetails
WHERE PreCapitalizationRent <> 0.00;

DROP TABLE #SalesTaxReceivableDetails;

IF EXISTS(SELECT 1 FROM SalesTaxReceivableDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId)
SET @RecordsExists = 1
ELSE
SET @RecordsExists = 0
END

GO
