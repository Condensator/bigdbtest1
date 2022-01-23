SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE PROCEDURE [dbo].[GetContractBalancesFromLegacy]
(
	@IsLoansApplicable bit
)
AS
SELECT 
	 Lease.Id LeaseId
	,SUM(LeaseAsset.NBV_Amount) NBVAmount
	,SUM(LeaseAsset.ResidualBookedAmount_Amount) ResidualBookedAmount
INTO #LeaseInvestment
FROM 
	stgLease Lease
	INNER JOIN stgLeaseAsset LeaseAsset
		ON Lease.Id = LeaseAsset.LeaseId
GROUP BY 
   Lease.Id
SELECT 
	 Loan.Id LoanId
	,SUM(LoanCollateralAsset.AcquisitionCost_Amount) NBVAmount
INTO #LoanInvestment
FROM 
	stgLoan Loan 
	INNER JOIN stgLoanCollateralAsset LoanCollateralAsset
		ON Loan.Id = LoanCollateralAsset.LoanId
GROUP BY 
	Loan.Id
SELECT 
	 Lease.SequenceNumber [Sequence Number]
	,'Lease'  ContractType
	,'Commenced' Status
	,Lease.LegalEntityNumber LegalEntityNumber
	,Lease.CustomerPartyNumber PartyNumber
	,Lease.Currency Currency 
	,Lease.BillToName BillToName
	,Lease.DealProductTypeName DealTransactionType
	,Lease.DealTypeName DealProductType
	,Lease.LineOfBusinessName LineOfBusinessName
	,Lease.InstrumentTypeCode InstrumentTypeCode
	,Lease.CostCenterConfigName CostCenterName
	,Lease.SyndicationType SyndicationType
	,Lease.HoldingStatus HoldingStatus
	,LeaseFinanceDetail.CommencementDate InceptionDate
	,LeaseFinanceDetail.FrequencyStartDate --Todo
	,CAST(NULL AS DATE) MaturityDate
	,LeaseFinanceDetail.DueDay DueDay
	,CASE WHEN LeaseFinanceDetail.IsAdvance = 1 THEN 'Yes' ELSE 'No' END  IsAdvance
	,LeaseFinanceDetail.NumberOfCommencementPayments NumberOfInceptionPayments
	,LeaseFinanceDetail.RentAtCommencement_Amount InceptionPayment
	,LeaseFinanceDetail.NumberOfPayments NumberOfPayments
	,LeaseFinanceDetail.PaymentStreamFrequency PaymentFrequency
	,CAST(0.00 AS DECIMAL) TermInMonths
	,CASE WHEN LeaseFinanceDetail.IsRegularPaymentStream = 1 THEN 'Yes' ELSE 'No' END  IsRegularPaymentStream
	,LeaseFinanceDetail.DayCountConvention DayCountConvention
	,CAST(0.00 AS DECIMAL) ManagementYield
	,CAST(0.00 AS DECIMAL) ClassificationYieldOnlyForLease
	,CAST(0.00 AS DECIMAL) InternalYieldOnlyForLease
	,CAST(0.00 AS DECIMAL) TotalYieldOnlyForLease
	,ISNULL(LeaseInvestment.NBVAmount,0) NBVAmount
	,ISNULL(LeaseInvestment.ResidualBookedAmount,0) ResidualBookedAmount
	,LeaseBalanceSummary.LeasePaymentsAmount LeasePaymentsAmount
	,LeaseBalanceSummary.LeasePaymentsBalance LeasePaymentsBalance
	,LeaseBalanceSummary.OverTermRentalAmount OverTermRentalAmount
	,LeaseBalanceSummary.OverTermRentalBalance OverTermRentalBalance
	,CAST(0.00 AS DECIMAL) LoanPrincipalAmount
	,CAST(0.00 AS DECIMAL) LoanPrincipalBalance
	,CAST(0.00 AS DECIMAL) LoanInterestAmount
	,CAST(0.00 AS DECIMAL) LoanInterestBalance
	,LeaseBalanceSummary.SecurityDepositAmount 
	,LeaseBalanceSummary.SecurityDepositBalance 
	,LeaseBalanceSummary.SundryBalance 
	,LeaseBalanceSummary.PropertyTaxBalance 
	,LeaseBalanceSummary.LateFeeBalance 
	,LeaseBalanceSummary.CPIBaseAndOverageAmount 
	,LeaseBalanceSummary.CPIBaseAndOverageBalance 
	,LeaseBalanceSummary.LeaseIncome LeaseIncomeOrLoanInterestAccrued
	,LeaseBalanceSummary.RecognizedLeaseIncome RecognizedLeaseIncomeOrLoanInterestAccrued
	,LeaseBalanceSummary.UnearnedLeaseIncome UnearnedLeaseIncomeOrLoanInterestAccrued
	,LeaseBalanceSummary.LeaseOTPIncome
	,LeaseBalanceSummary.RecognizedLeaseOTPIncome
	,LeaseBalanceSummary.UnearnedLeaseOTPIncome
	,LeaseBalanceSummary.TotalBlendedItemAmount TotalBlendedItemAmount
	,LeaseBalanceSummary.BIIncomeAmount 
	,LeaseBalanceSummary.UnearnedBIIncomeAmount 
	,LeaseBalanceSummary.RecognizedBIIncomeAmount 
	,CASE WHEN Lease.IsSalesTaxExempt = 1 THEN 'Yes' ELSE 'No' END IsSalesTaxExempt
	,LeaseBalanceSummary.SalesTaxAssessedDate 
	,LeaseBalanceSummary.InvoiceGeneratedDate 
	,LeaseBalanceSummary.ReceivablesGLPostedDate 
	,LeaseBalanceSummary.IncomeRecognizedDate 
	,LeaseBalanceSummary.LeaseOTPIncomeRecognizedDate
	,LeaseBalanceSummary.LateFeesAssessedDate 
	,CASE WHEN LeaseBalanceSummary.IsNonAccrual = 1 THEN 'Yes' ELSE 'No' END IsNonAccrual
FROM 
	stgLease Lease
	INNER JOIN stgLeaseFinanceDetail LeaseFinanceDetail
		ON Lease.Id = LeaseFinanceDetail.Id
	LEFT JOIN stgLeaseBalanceSummary LeaseBalanceSummary
		ON Lease.Id = LeaseBalanceSummary.Id
	LEFT JOIN #LeaseInvestment LeaseInvestment
		ON LeaseInvestment.LeaseId = Lease.Id
UNION ALL
SELECT 
	 Loan.SequenceNumber [Sequence Number]
	,'Loan'  [Contract Type]
	,'Commenced'
	,Loan.LegalEntityNumber [Legal Entity Number]
	,Loan.CustomerPartyNumber [Party Number]
	,Loan.CurrencyCode Currency 
	,Loan.BillToName [Bill To Name] 
	,Loan.DealProductTypeName [Deal Transaction Type]
	,Loan.DealTypeName [Deal Product Type]
	,Loan.LineOfBusinessName [Line Of Business Name]
	,Loan.InstrumentTypeCode [Instrument Type Code]
	,Loan.CostCenterName [Cost Center Name]
	,Loan.SyndicationType [Syndication Type]
	,Loan.HoldingStatus [Holding Status]
	,Loan.CommencementDate [Inception Date]
	,Loan.FirstPaymentDate --Todo
	,CAST(NULL AS DATE) MaturityDate
	,Loan.DueDay [Due Day]
	,'No' [Is Advance]
	,0 [Number Of Inception Payments]
	,0 [Inception Payment]
	,Loan.NumberOfPayments [Number Of Payments]
	,Loan.PaymentFrequency [Payment Frequency]
	,0 [Term In Months] 
	,'No' [Is Regular Payment Stream]
	,Loan.DayCountConvention [Day Count Convention]
	,0 [Management Yield]
	,0 [Classification Yield (Only for Lease)]
	,0 [Internal Yield (Only for Lease)]
	,0 [Total Yield(Only for Lease)]
	,ISNULL(LoanInvestment.NBVAmount,0) [NBV Amount]
	,0.0 ResidualBookedAmount
	,0 [Lease Payments Amount]
	,0 [Lease Payments Balance]
	,0 [Over Term Rental Amount]
	,0 [Over Term Rental Balance]
	,LoanBalanceSummary.LoanPrincipalAmount [Loan Principal Amount]
	,LoanBalanceSummary.LoanPrincipalBalance [Loan Principal Balance]
	,LoanBalanceSummary.LoanInterestAmount [Loan Interest Amount]
	,LoanBalanceSummary.LoanInterestBalance [Loan Interest Balance]
	,LoanBalanceSummary.SecurityDepositAmount [Security Deposit Amount]
	,LoanBalanceSummary.SecurityDepositBalance [Security Deposit Balance]
	,LoanBalanceSummary.SundryBalance [Sundry Balance]
	,LoanBalanceSummary.PropertyTaxBalance [Property Tax Balance]
	,LoanBalanceSummary.LateFeeBalance [Late Fee Balance]
	,LoanBalanceSummary.CPIBaseAndOverageAmount [CPI Base And Overage Amount]
	,LoanBalanceSummary.CPIBaseAndOverageBalance [CPI Base And Overage Balance]
	,LoanBalanceSummary.LoanInterestAccrued [Lease Income Or Loan Interest Accrued]
	,LoanBalanceSummary.RecognizedLoanInterestAccrued [Recognized Lease Income Or Loan Interest Accrued]
	,LoanBalanceSummary.UnearnedLoanInterestAccrued [Unearned Lease Income Or Loan Interest Accrued]
	,0 	LeaseOTPIncome
	,0 	RecognizedLeaseOTPIncome
	,0 	UnearnedLeaseOTPIncome
	,LoanBalanceSummary.TotalBlendedItemAmount [Total Blended Item Amount]
	,LoanBalanceSummary.BIIncomeAmount [BI Income Amount]
	,LoanBalanceSummary.UnearnedBIIncomeAmount [Unearned BI Income Amount]
	,LoanBalanceSummary.RecognizedBIIncomeAmount [Recognized BI Income Amount]
	,'No' [Is Sales Tax Exempt]
	,NULL [Sales Tax Assessed Date]
	,LoanBalanceSummary.InvoiceGeneratedDate [Invoice Generated Date]
	,LoanBalanceSummary.ReceivablesGLPostedDate [Receivables GL Posted Date]
	,LoanBalanceSummary.IncomeRecognizedDate [Income Recognized Date]
	,Cast(NULL as Date) LeaseOTPIncomeRecognizedDate
	,LoanBalanceSummary.LateFeesAssessedDate [Late Fees Assessed Date]
	,CASE WHEN LoanBalanceSummary.IsNonAccrual = 1 THEN 'Yes' ELSE 'No' END IsNonAccrual
FROM 
	stgLoan Loan
	LEFT JOIN stgLoanBalanceSummary LoanBalanceSummary
		ON Loan.Id = LoanBalanceSummary.Id
	LEFT JOIN #LoanInvestment LoanInvestment
		ON LoanInvestment.LoanId = Loan.Id
Order by [Sequence Number]
DROP TABLE #LeaseInvestment
DROP TABLE #LoanInvestment

GO
