SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CreateContractAmendmentForGLTransfer]
(	
	@GLTransferId BIGINT
	,@Alias NVARCHAR(100)
	,@AmendmentDate DATETIME
	,@Comment NVARCHAR(200)
	,@AmendmentAtInception BIT
	,@CreatedById BIGINT
	,@CreatedTime DATETIMEOFFSET
	,@CreateCPURestructure BIT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN

CREATE TABLE #AmendmentTemp
(
ContractType NVARCHAR(14) NOT NULL,
ReceivableAmendmentType NVARCHAR(20) NULL, 
CurrentFinanceId BIGINT NOT NULL,
OldFinanceId BIGINT NULL,
CurrencyCode NVARCHAR(3) NOT NULL,
SalesTaxRemittanceMethod NVARCHAR(20) NULL
);

CREATE TABLE #ContractTemp
(
ContractId BIGINT,
ContractType NVARCHAR(14) NOT NULL,
ReceivableAmendmentType NVARCHAR(20) NULL, 
CurrencyCode NVARCHAR(3) NOT NULL,
SalesTaxRemittanceMethod NVARCHAR(20) NULL
);

SELECT Contracts.Id ContractId,Contracts.ContractType,Contracts.ReceivableAmendmentType,TaxPaidtoVendor_Currency AS CurrencyCode, Contracts.SalesTaxRemittanceMethod
INTO #ContractInfo
FROM GLTransferDealDetails
JOIN Contracts ON GLTransferDealDetails.ContractId = Contracts.Id AND GLTransferDealDetails.IsActive=1
WHERE GLTransferDealDetails.GLTransferId = @GLTransferId
AND Contracts.ContractType <> 'LeveragedLease'


WHILE((SELECT COUNT(*) FROM #ContractInfo) >= 1)
BEGIN

INSERT INTO #ContractTemp
SELECT TOP 500 * FROM #ContractInfo

IF EXISTS(SELECT * FROM #ContractTemp WHERE ContractType = 'Lease')
BEGIN
	INSERT INTO #AmendmentTemp
	SELECT #ContractTemp.ContractType,#ContractTemp.ReceivableAmendmentType,FinanceInfo.CurrentFinanceId, FinanceInfo.OldLeaseFinanceId, #ContractTemp.CurrencyCode, #ContractTemp.SalesTaxRemittanceMethod 
	FROM #ContractTemp
	JOIN (SELECT #ContractTemp.ContractId,LeaseFinances.Id AS CurrentFinanceId,MAX(OldLeaseFinance.Id) OldLeaseFinanceId 
		FROM #ContractTemp
		JOIN LeaseFinances ON #ContractTemp.ContractId = LeaseFinances.ContractId AND LeaseFinances.IsCurrent=1
		JOIN LeaseFinances AS OldLeaseFinance ON #ContractTemp.ContractId = OldLeaseFinance.ContractId AND OldLeaseFinance.IsCurrent=0 and OldLeaseFinance.ApprovalStatus = 'Approved' and OldLeaseFinance.BookingStatus = 'Commenced'
		GROUP BY #ContractTemp.ContractId,LeaseFinances.Id) 
	AS FinanceInfo ON #ContractTemp.ContractId = FinanceInfo.ContractId
	WHERE ContractType = 'Lease'

	INSERT INTO LeaseAmendments(Name,LeaseAmendmentStatus,ReceivableAmendmentType,AmendmentDate,AmendmentType,Description
								,AmendmentAtInception,CreatedById,CreatedTime,CurrentLeaseFinanceId,LeasePaymentScheduleId
								,IsTDR,IsLienFilingException,IsLienFilingRequired,TDRReason,PreRestructureLeaseNBV_Amount
								,PreRestructureLeaseNBV_Currency,PostRestructureLeaseNBV_Amount,PostRestructureLeaseNBV_Currency
								,PreRestructureResidualBooked_Amount,PreRestructureResidualBooked_Currency,PostRestructureResidualBooked_Amount
								,PostRestructureResidualBooked_Currency,PreRestructureFAS91Balance_Amount,PreRestructureFAS91Balance_Currency
								,PostRestructureFAS91Balance_Amount,PostRestructureFAS91Balance_Currency,NetWritedowns_Amount,NetWritedowns_Currency
								,AccountingDate,PostDate,ImpairmentAmount_Amount,ImpairmentAmount_Currency,IsLeaseLevelImpairment,GLTemplateId
								,AccumulatedImpairmentAmount_Amount,AccumulatedImpairmentAmount_Currency,PreRestructureUnguaranteedResidual_Amount
								,PreRestructureUnguaranteedResidual_Currency,PostRestructureUnguaranteedResidual_Amount,PostRestructureUnguaranteedResidual_Currency
								,PreRestructureClassificationYield,PreRestructureLessorYield,OriginalLeaseFinanceId
								,TaxPaidtoVendor_Amount,TaxPaidtoVendor_Currency,GSTTaxPaidtoVendor_Amount,GSTTaxPaidtoVendor_Currency
								,HSTTaxPaidtoVendor_Amount,HSTTaxPaidtoVendor_Currency,QSTorPSTTaxPaidtoVendor_Amount,QSTorPSTTaxPaidtoVendor_Currency
								,PreRestructureLessorYieldLeaseAsset,PreRestructureLessorYieldFinanceAsset,PreRestructureClassificationYield5A,PreRestructureClassificationYield5B,FloatRateRestructure,SalesTaxRemittanceMethod,CreateCPURestructure)
	SELECT
			@Alias,'Approved',ReceivableAmendmentType,@AmendmentDate,'GLTransfer',@Comment
			,@AmendmentAtInception,@CreatedById,@CreatedTime,CurrentFinanceId,null,CAST (0 AS BIT),CAST (0 AS BIT),CAST (0 AS BIT),'_', 0.0, 
			CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode, 
			0.0, CurrencyCode, NULL, NULL, 0.0, CurrencyCode, CAST(0 AS BIT), NULL, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, 
			CurrencyCode,0.0,0.0,OldFinanceId, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode, 0.0, CurrencyCode,0,0,0,0,0,SalesTaxRemittanceMethod,@CreateCPURestructure
	FROM #AmendmentTemp WHERE ContractType = 'Lease'
END

IF EXISTS(SELECT * FROM #ContractTemp WHERE ContractType = 'Loan')
BEGIN
	INSERT INTO #AmendmentTemp
	SELECT #ContractTemp.ContractType,#ContractTemp.ReceivableAmendmentType,LoanFinances.Id AS CurrentFinanceId, NULL, #ContractTemp.CurrencyCode, NULL
	FROM #ContractTemp
	JOIN LoanFinances ON #ContractTemp.ContractId = LoanFinances.ContractId AND LoanFinances.IsCurrent=1
	WHERE ContractType = 'Loan'

	INSERT INTO LoanAmendments(QuoteName,QuoteStatus,AmendmentType,AmendmentDate,Comment,AmendmentAtInception
								,ReceivableAmendmentType,CreatedById,CreatedTime,LoanFinanceId,LoanPaymentScheduleId
								,IsLienFilingRequired,IsLienFilingException,TDRReason,IsTDR,IsRestructureDateConfirmed,PreRestructureDateLoanNBV_Amount
								,PreRestructureDateLoanNBV_Currency,PostRestructureDateLoanNBV_Amount,PostRestructureDateLoanNBV_Currency,PreRestructureFAS91Balance_Amount
								,PreRestructureFAS91Balance_Currency,PostRestructureFAS91Balance_Amount,PostRestructureFAS91Balance_Currency,NetWritedown_Amount
								,NetWritedown_Currency,IsModified)
	SELECT
		@Alias,'Approved','GLTransfer',@AmendmentDate,@Comment,@AmendmentAtInception,ReceivableAmendmentType
			,@CreatedById,@CreatedTime,CurrentFinanceId,null,CAST (0 AS BIT),CAST (0 AS BIT),'_',CAST (0 AS BIT),CAST (0 AS BIT),0.0
			,CurrencyCode,0.0,CurrencyCode,0.0
			,CurrencyCode,0.0,CurrencyCode,0.0
			,CurrencyCode,0
	FROM #AmendmentTemp WHERE ContractType = 'Loan'
END

	DELETE FROM #AmendmentTemp
	DELETE FROM #ContractInfo WHERE ContractId IN(SELECT ContractId FROM #ContractTemp)
	DELETE FROM #ContractTemp		
END

DROP TABLE #AmendmentTemp
DROP TABLE #ContractInfo
DROP TABLE #ContractTemp

END

GO
