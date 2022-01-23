SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertPayoffOutStandingReceivableDetailsForQuotationRequest]  
(  
    @ReceivableIds OutStandingReceivableIds ReadOnly,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@SundryTableName NVARCHAR(100),
	@SundryRecurringTableName NVARCHAR(100),
	@RecordsCount BIGINT OUTPUT,
	@JobStepInstanceId BIGINT
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
	[ReceivableTaxType] NVARCHAR(8) NULL
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
	,ReceivableTaxType)
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
	,R.ReceivableTaxType
FROM 
	Receivables R  
INNER JOIN 
	@ReceivableIds RID ON R.Id = RID.Id
INNER JOIN 
	ReceivableDetails RD ON R.Id = RD.ReceivableId  
INNER JOIN 
    LegalEntities L ON R.LegalEntityId = L.Id
WHERE 
	R.IsActive =1 AND RD.IsActive =1 

	
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


INSERT INTO SalesTaxReceivableDetail_Extract 
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
	,CreatedById
	,CreatedTime
	,AmountBilledToDate
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId	
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,IsVertexSupported
	,JobStepInstanceId
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
	,@CreatedById
	,@CreatedTime
	,0.00
	,IsExemptAtSundry
	,PaymentScheduleId
	,LegalEntityId
	,TaxPayer
	,LegalEntityTaxRemittancePreference
	,0
	,@JobStepInstanceId
	,SourceId
	,SourceTable
	,ReceivableTaxType
FROM #SalesTaxReceivableDetails;

DROP TABLE #SalesTaxReceivableDetails;

SET @RecordsCount = (SELECT COUNT(*) FROM SalesTaxReceivableDetail_Extract
					 WHERE JobStepInstanceId = @JobStepInstanceId);

IF @RecordsCount IS NULL
	SET @RecordsCount = 0
END

GO
