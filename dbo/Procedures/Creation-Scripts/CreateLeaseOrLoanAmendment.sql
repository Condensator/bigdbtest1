SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateLeaseOrLoanAmendment]
(	
	@ContractType NVARCHAR(50)
	,@FinanceId BIGINT
	,@PaymentId BIGINT = NULL
	,@ReceivableAmendmentType NVARCHAR(50)
	,@AmendmentDate DATETIMEOFFSET
	,@Comment NVARCHAR(200)
	,@AmendmentAtInception BIT
	,@SalesTaxRemittanceMethod NVARCHAR(50)
	,@CreatedId BIGINT
	,@CurrencyCode NVARCHAR(3)
	,@CreatedTime DATETIMEOFFSET
	,@CreateCPURestructure BIT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN
IF(@ContractType = 'Lease')
	BEGIN
		INSERT INTO LeaseAmendments(Name,LeaseAmendmentStatus,ReceivableAmendmentType,AmendmentDate,AmendmentType,Description
								   ,AmendmentAtInception,CreatedById,CreatedTime,CurrentLeaseFinanceId,LeasePaymentScheduleId
								   ,IsTDR,IsLienFilingException,IsLienFilingRequired,TDRReason,PreRestructureLeaseNBV_Amount,PreRestructureLeaseNBV_Currency,PostRestructureLeaseNBV_Amount,PostRestructureLeaseNBV_Currency
								   ,PreRestructureResidualBooked_Amount,PreRestructureResidualBooked_Currency,PostRestructureResidualBooked_Amount
								   ,PostRestructureResidualBooked_Currency,PreRestructureFAS91Balance_Amount,PreRestructureFAS91Balance_Currency
								   ,PostRestructureFAS91Balance_Amount,PostRestructureFAS91Balance_Currency,NetWritedowns_Amount,NetWritedowns_Currency
								   ,AccountingDate,PostDate,ImpairmentAmount_Amount,ImpairmentAmount_Currency,IsLeaseLevelImpairment,GLTemplateId
								   ,AccumulatedImpairmentAmount_Amount,AccumulatedImpairmentAmount_Currency,PreRestructureUnguaranteedResidual_Amount
								   ,PreRestructureUnguaranteedResidual_Currency,PostRestructureUnguaranteedResidual_Amount,PostRestructureUnguaranteedResidual_Currency
								   ,PreRestructureClassificationYield,PreRestructureLessorYield,TaxPaidtoVendor_Amount,TaxPaidtoVendor_Currency,GSTTaxPaidtoVendor_Amount
								   ,GSTTaxPaidtoVendor_Currency,HSTTaxPaidtoVendor_Amount,HSTTaxPaidtoVendor_Currency,QSTorPSTTaxPaidtoVendor_Amount,QSTorPSTTaxPaidtoVendor_Currency
								   ,PreRestructureLessorYieldLeaseAsset,PreRestructureLessorYieldFinanceAsset,PreRestructureClassificationYield5A,PreRestructureClassificationYield5B,FloatRateRestructure,SalesTaxRemittanceMethod,CreateCPURestructure)
		VALUES
			 ('Syndication','Approved',@ReceivableAmendmentType,@AmendmentDate,'Syndication',@Comment
			  ,@AmendmentAtInception,@CreatedId,@CreatedTime,@FinanceId,@PaymentId,CAST (0 AS BIT),CAST (0 AS BIT),CAST (0 AS BIT),'_', 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode, NULL, NULL, 0.0, @CurrencyCode, CAST(0 AS BIT), NULL, 0.0, @CurrencyCode, 0.0, @CurrencyCode, 0.0, @CurrencyCode,0.0,0.0,0.00,@CurrencyCode,0.00,@CurrencyCode,0.00,@CurrencyCode,0.00,@CurrencyCode
			  ,0.00,0.00,0.00,0.00,0,@SalesTaxRemittanceMethod,@CreateCPURestructure)
	END
ELSE IF(@ContractType = 'Loan')
	BEGIN
		INSERT INTO LoanAmendments(QuoteName,QuoteStatus,AmendmentType,AmendmentDate,Comment,AmendmentAtInception
								  ,ReceivableAmendmentType,CreatedById,CreatedTime,LoanFinanceId,LoanPaymentScheduleId
								  ,IsLienFilingRequired,IsLienFilingException,TDRReason,IsTDR,IsRestructureDateConfirmed,PreRestructureDateLoanNBV_Amount
								  ,PreRestructureDateLoanNBV_Currency,PostRestructureDateLoanNBV_Amount,PostRestructureDateLoanNBV_Currency,PreRestructureFAS91Balance_Amount
								  ,PreRestructureFAS91Balance_Currency,PostRestructureFAS91Balance_Amount,PostRestructureFAS91Balance_Currency,NetWritedown_Amount
								  ,NetWritedown_Currency,IsModified)
		VALUES
			('Syndication','Approved','Syndication',@AmendmentDate,@Comment,@AmendmentAtInception,@ReceivableAmendmentType
			 ,@CreatedId,@CreatedTime,@FinanceId,@PaymentId,CAST (0 AS BIT),CAST (0 AS BIT),'_',CAST (0 AS BIT),CAST (0 AS BIT),0.0
			 ,@CurrencyCode,0.0,@CurrencyCode,0.0
			 ,@CurrencyCode,0.0,@CurrencyCode,0.0
			 ,@CurrencyCode,0)
	END
END 

GO
