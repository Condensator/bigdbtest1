SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertContractBasedReceivableDetailsForNonInvoiceSensitive]
(
	@ComputedProcessThroughDate		DATETIME,
	@LegalEntityIds					IDs READONLY,
	@CreatedById					BIGINT,
	@CreatedTime					DATETIMEOFFSET,
	@SundryTableName				NVARCHAR(100),
	@SundryRecurringTableName		NVARCHAR(100),
	@ProgressLoanContractTypeName	NVARCHAR(100),
	@EntityType						NVARCHAR(10),
	@ContractType					NVARCHAR(14) ,
	@ContractId						BIGINT,
	@ExcludeBackgroundProcessingPendingContracts BIT,
	@RecordsExists					TINYINT OUTPUT,
	@JobStepInstanceId				BIGINT
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
	[ContractType] NVarChar(40) NULL,
	[AdjustmentBasisReceivableDetailId] BIGINT NULL,
	[IsOriginalReceivableDetailTaxAssessed] BIT,
	[IsAssessSalesTaxAtSKULevel] BIT NOT NULL,
	[ReceivableTaxType] NVARCHAR(8) NULL,
	[PreCapitalizationRent] Decimal(16,2) NOT NULL
)
INSERT INTO #SalesTaxReceivableDetails
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
	,PaymentScheduleId
	,SourceId
	,SourceTable
	,LegalEntityId
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,IsExemptAtSundry
	,ContractType
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
	,R.EntityId
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
	,CT.ContractType
	,RD.AdjustmentBasisReceivableDetailId
	,NULL AS IsOriginalReceivableDetailTaxAssessed
	,L.IsAssessSalesTaxAtSKULevel
	,R.ReceivableTaxType
	,RD.PreCapitalizationRent_Amount
FROM Receivables R
INNER JOIN Contracts CT ON R.EntityId = CT.Id AND CT.ContractType = @ContractType
	AND R.EntityType = @EntityType  AND R.EntityId = @ContractId
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
INNER JOIN @LegalEntityIds LE ON R.LegalEntityId = LE.Id
INNER JOIN LegalEntities L ON R.LegalEntityId = L.Id
WHERE
R.IsActive =1 AND RD.IsActive =1
AND RD.IsTaxAssessed = 0 AND (R.DueDate <= @ComputedProcessThroughDate) 
AND (@ExcludeBackgroundProcessingPendingContracts = 0 OR CT.BackgroundProcessingPending = 0);

UPDATE #SalesTaxReceivableDetails
SET IsOriginalReceivableDetailTaxAssessed = ORD.IsTaxAssessed
FROM #SalesTaxReceivableDetails STR
INNER JOIN ReceivableDetails ORD ON STR.AdjustmentBasisReceivableDetailId = ORD.Id AND STR.AdjustmentBasisReceivableDetailId IS NOT NULL;

Update #SalesTaxReceivableDetails
SET IsExemptAtSundry = S.IsTaxExempt,
LocationId = CASE WHEN STR.LocationId IS NULL AND ContractType = @ProgressLoanContractTypeName
				  THEN B.LocationId ELSE STR.LocationId END
FROM
#SalesTaxReceivableDetails STR
INNER JOIN
Sundries S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryTableName
LEFT JOIN BillToes B ON B.Id = S.BillToId
WHERE S.BillToId IS NOT NULL OR S.IsAssetBased = 1;

Update #SalesTaxReceivableDetails
SET IsExemptAtSundry = S.IsTaxExempt,
LocationId = CASE WHEN STR.LocationId IS NULL AND ContractType = @ProgressLoanContractTypeName
				  THEN B.LocationId ELSE STR.LocationId END
FROM
#SalesTaxReceivableDetails STR
INNER JOIN
SundryRecurrings S ON S.Id = STR.SourceId AND STR.SourceTable = @SundryRecurringTableName
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
