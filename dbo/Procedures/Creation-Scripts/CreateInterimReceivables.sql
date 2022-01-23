SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateInterimReceivables]
(
@Receivables ReceivablesForInterim READONLY,
@UserId BIGINT,
@Time DATETIMEOFFSET,
@IsSalesTaxRequiredForLoan BIT
)
AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #ReceivableTemp
(
ReceivableId BIGINT,
PaymentScheduleId BIGINT
)

INSERT INTO dbo.Receivables (EntityType
	,EntityId		
	,IsDSL
	,DueDate
	,IsActive
	,InvoiceComment
	,InvoiceReceivableGroupingOption
	,IsGLPosted
	,IncomeType
	,PaymentScheduleId
	,IsCollected
	,IsServiced
	,CreatedById
	,CreatedTime
	,UpdatedById
	,UpdatedTime
	,ReceivableCodeId
	,CustomerId
	,FunderId
	,RemitToId
	,TaxRemitToId
	,LocationId
	,LegalEntityId
	,IsDummy
	,IsPrivateLabel
	,SourceId
	,SourceTable
	,TotalAmount_Amount
	,TotalAmount_Currency
	,TotalBalance_Amount
	,TotalBalance_Currency
	,TotalEffectiveBalance_Amount
	,TotalEffectiveBalance_Currency
	,TotalBookBalance_Amount
	,TotalBookBalance_Currency
	,ExchangeRate
	,AlternateBillingCurrencyId
	,CalculatedDueDate
	,CreationSourceTable
	,CreationSourceId)
	OUTPUT INSERTED.Id, INSERTED.PaymentScheduleId INTO #ReceivableTemp
	Select 'CT'
			,receivable.EntityId 
			,receivable.IsDSL 			   
			,receivable.DueDate
			,1
			,receivable.InvoiceComment 
			,receivable.InvoiceReceivableGroupingOption 
			,0
			,'InterimInterest'
			,receivable.PaymentScheduleId
			,receivable.IsCollected 
			,receivable.IsServiced 
			,@UserId
			,@Time
			,null
			,null
			,receivable.ReceivableCodeId 
			,receivable.CustomerId 
			,receivable.FunderId 
			,receivable.RemitToId 
			,receivable.RemitToId 
			,receivable.LocationId 
			,receivable.LegalEntityId 
			,receivable.IsDummy 
			,receivable.IsPrivateLabel 
			,receivable.SourceId 
			,receivable.SourceTable 
			,receivable.ReceivableAmount
			,receivable.Currency
			,receivable.ReceivableAmount
			,receivable.Currency
			,receivable.ReceivableAmount
			,receivable.Currency
			,receivable.TotalBookBalance
			,receivable.Currency
			,receivable.ExchangeRate
			,1
			,null
			,'_'
			,null
			FROM @Receivables receivable WHERE PaymentScheduleId is not null		
			
			

--To Persist ReceivableDetails

	INSERT INTO ReceivableDetails(
		Amount_Amount
		,Amount_Currency
		,Balance_Amount
		,Balance_Currency
		,EffectiveBalance_Amount
		,EffectiveBalance_Currency
		,IsActive
		,BilledStatus
		,IsTaxAssessed
		,CreatedById
		,CreatedTime
		,UpdatedById
		,UpdatedTime
		,AssetId
		,BillToId
		,AdjustmentBasisReceivableDetailId
		,ReceivableId
		,StopInvoicing
		,EffectiveBookBalance_Amount
		,EffectiveBookBalance_Currency
		,AssetComponentType
		,LeaseComponentAmount_Amount
		,NonLeaseComponentAmount_Amount
		,LeaseComponentBalance_Amount
		,NonLeaseComponentBalance_Amount
		,LeaseComponentAmount_Currency
		,NonLeaseComponentAmount_Currency
		,LeaseComponentBalance_Currency
		,NonLeaseComponentBalance_Currency
		,PreCapitalizationRent_Amount
		,PreCapitalizationRent_Currency
		)
		SELECT	 Re.ReceivableDetailAmount
				,Re.Currency
				,Re.ReceivableDetailBalance
				,Re.Currency
				,Re.ReceivableDetailEffectiveBalance
				,Re.Currency 
				,1
				,'NotInvoiced'
				,@IsSalesTaxRequiredForLoan
				,@UserId
				,@Time
				,null
				,null
				,null
				,Re.ReceivableDetailBillToId
				,null
				,RM.ReceivableId
				,0
				,Re.ReceivableDetailEffectiveBookBalance
				,Re.Currency
				,'_'
				,Re.ReceivableDetailAmount
				,0.00
				,Re.ReceivableDetailBalance
				,0.00
				,Re.Currency
				,Re.Currency
				,Re.Currency
				,Re.Currency
				,0.00
				,Re.Currency
				FROM @Receivables Re
				JOIN #ReceivableTemp RM ON Re.PaymentScheduleId = RM.PaymentScheduleId;

Drop table #ReceivableTemp

SET NOCOUNT OFF	
END

GO
