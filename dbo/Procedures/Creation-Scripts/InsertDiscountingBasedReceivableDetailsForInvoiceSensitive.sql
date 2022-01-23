SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertDiscountingBasedReceivableDetailsForInvoiceSensitive]
(
	@ComputedProcessThroughDate DATETIME,
	@LegalEntityIds				IDs READONLY,
	@CreatedById				BIGINT,
	@CreatedTime				DATETIMEOFFSET,
	@SundryTableName			NVARCHAR(100),
	@SundryRecurringTableName	NVARCHAR(100),
	@DTEntityType				NVARCHAR(100),
	@DiscountingId				BIGINT,
	@RecordsExists				TINYINT OUTPUT,
	@JobStepInstanceId			BIGINT
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
;WITH CTE_CustomersToBeProcessed AS
(
SELECT
DISTINCT
C.Id AS CustomerId
,DATEADD(DD,InvoiceLeaddays,@ComputedProcessThroughDate) DueDate
FROM
Customers C
JOIN
Receivables R ON C.Id = R.CustomerId
WHERE
R.EntityId = @DiscountingId
)
INSERT INTO #SalesTaxReceivableDetails
(ReceivableId
,ReceivableDetailId
,AssetId
,ReceivableDueDate
,Currency
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
,CASE WHEN R.EntityType = @DTEntityType THEN R.EntityId ELSE NULL  END
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
INNER JOIN CTE_CustomersToBeProcessed C ON R.CustomerId = C.CustomerId
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN @LegalEntityIds LE ON R.LegalEntityId = LE.Id
INNER JOIN LegalEntities L ON R.LegalEntityId = L.Id
WHERE
R.IsActive =1 AND RD.IsActive =1 AND RD.IsTaxAssessed = 0 AND (R.DueDate <= C.DueDate)
AND R.EntityId = @DiscountingId AND R.EntityType = @DTEntityType

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

DROP TABLE #SalesTaxReceivableDetails
IF EXISTS(SELECT 1 FROM SalesTaxReceivableDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId)
SET @RecordsExists = 1
ELSE
SET @RecordsExists = 0
END

GO
