SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetLegalEntitySummary]
(
@IsLoansApplicable bit
)
AS
CREATE TABLE #ContractBalancesFromSource
(
SequenceNumber Nvarchar(100)
,ContractType Nvarchar(30)
,Status Nvarchar(30)
,LegalEntityNumber Nvarchar(100)
,PartyNumber Nvarchar(100)
,Currency  Nvarchar(10)
,BillToName Nvarchar(100)
,DealTransactionType Nvarchar(100)
,DealProductType Nvarchar(100)
,LineOfBusinessName Nvarchar(100)
,InstrumentTypeCode Nvarchar(100)
,CostCenterName Nvarchar(100)
,SyndicationType Nvarchar(20)
,HoldingStatus Nvarchar(20)
,InceptionDate Date
,FrequencyStartDate Date
,MaturityDate Date
,DueDay int
,IsAdvance nvarchar(10)
,NumberOfInceptionPayments int
,InceptionPayment decimal(18,2)
,NumberOfPayments int
,PaymentFrequency nvarchar(20)
,TermInMonths decimal
,IsRegularPaymentStream nvarchar(10)
,DayCountConvention nvarchar(20)
,ManagementYield decimal(10,8)
,ClassificationYieldOnlyForLease decimal(10,8)
,InternalYieldOnlyForLease decimal(10,8)
,TotalYieldOnlyForLease decimal(10,8)
,NBVAmount decimal(18,2)
,ResidualBookedAmount decimal(18,2)
,LeasePaymentsAmount decimal(18,2)
,LeasePaymentsBalance decimal(18,2)
,OverTermRentalAmount decimal(18,2)
,OverTermRentalBalance decimal(18,2)
,LoanPrincipalAmount decimal(18,2)
,LoanPrincipalBalance decimal(18,2)
,LoanInterestAmount decimal(18,2)
,LoanInterestBalance decimal(18,2)
,SecurityDepositAmount decimal(18,2)
,SecurityDepositBalance decimal(18,2)
,SundryBalance  decimal(18,2)
,PropertyTaxBalance decimal(18,2)
,LateFeeBalance  decimal(18,2)
,CPIBaseAndOverageAmount decimal(18,2)
,CPIBaseAndOverageBalance decimal(18,2)
,LeaseIncomeOrLoanInterestAccrued decimal(18,2)
,RecognizedLeaseIncomeOrLoanInterestAccrued decimal(18,2)
,UnearnedLeaseIncomeOrLoanInterestAccrued decimal(18,2)
,LeaseOTPAmount decimal(18,2)
,UnearnedLeaseOTPIncome decimal(18,2)
,RecognizedLeaseOTPIncome decimal(18,2)
,TotalBlendedItemAmount decimal(18,2)
,BIIncomeAmount decimal(18,2)
,UnearnedBIIncomeAmount decimal(18,2)
,RecognizedBIIncomeAmount decimal(18,2)
,IsSalesTaxExempt  nvarchar(10)
,SalesTaxAssessedDate  Date
,InvoiceGeneratedDate Date
,ReceivablesGLPostedDate Date
,IncomeRecognizedDate Date
,LeaseOTPIncomeRecognizedDate Date
,LateFeesAssessedDate Date
,IsNonAccrual nvarchar(10)
)
INSERT INTO #ContractBalancesFromSource
exec dbo.GetContractBalancesFromLegacy @isLoansApplicable=0
CREATE TABLE #ContractBalancesFromTarget
(
SequenceNumber Nvarchar(100)
,ContractType Nvarchar(30)
,Status Nvarchar(30)
,LegalEntityNumber Nvarchar(100)
,PartyNumber Nvarchar(100)
,Currency  Nvarchar(10)
,BillToName Nvarchar(100)
,DealTransactionType Nvarchar(100)
,DealProductType Nvarchar(100)
,LineOfBusinessName Nvarchar(100)
,InstrumentTypeCode Nvarchar(100)
,CostCenterName Nvarchar(100)
,SyndicationType Nvarchar(20)
,HoldingStatus Nvarchar(20)
,InceptionDate Date
,FrequencyStartDate Date
,MaturityDate Date
,DueDay int
,IsAdvance  nvarchar(10)
,NumberOfInceptionPayments int
,InceptionPayment decimal(18,2)
,NumberOfPayments int
,PaymentFrequency nvarchar(20)
,TermInMonths decimal
,IsRegularPaymentStream nvarchar(10)
,DayCountConvention nvarchar(20)
,ManagementYield decimal(10,8)
,ClassificationYieldOnlyForLease decimal(10,8)
,InternalYieldOnlyForLease decimal(10,8)
,TotalYieldOnlyForLease decimal(10,8)
,NBVAmount decimal(18,2)
,ResidualBookedAmount decimal(18,2)
,LeasePaymentsAmount decimal(18,2)
,LeasePaymentsBalance decimal(18,2)
,OverTermRentalAmount decimal(18,2)
,OverTermRentalBalance decimal(18,2)
,LoanPrincipalAmount decimal(18,2)
,LoanPrincipalBalance decimal(18,2)
,LoanInterestAmount decimal(18,2)
,LoanInterestBalance decimal(18,2)
,SecurityDepositAmount decimal(18,2)
,SecurityDepositBalance decimal(18,2)
,SundryBalance  decimal(18,2)
,PropertyTaxBalance decimal(18,2)
,LateFeeBalance  decimal(18,2)
,CPIBaseAndOverageAmount decimal(18,2)
,CPIBaseAndOverageBalance decimal(18,2)
,LeaseIncomeOrLoanInterestAccrued decimal(18,2)
,RecognizedLeaseIncomeOrLoanInterestAccrued decimal(18,2)
,UnearnedLeaseIncomeOrLoanInterestAccrued decimal(18,2)
,LeaseOTPAmount decimal(18,2)
,UnearnedLeaseOTPIncome decimal(18,2)
,RecognizedLeaseOTPIncome decimal(18,2)
,TotalBlendedItemAmount decimal(18,2)
,BIIncomeAmount decimal(18,2)
,UnearnedBIIncomeAmount decimal(18,2)
,RecognizedBIIncomeAmount decimal(18,2)
,IsSalesTaxExempt   nvarchar(10)
,SalesTaxAssessedDate  Date
,InvoiceGeneratedDate Date
,ReceivablesGLPostedDate Date
,IncomeRecognizedDate Date
,LeaseOTPIncomeRecognizedDate Date
,LateFeesAssessedDate Date
,IsNonAccrual  nvarchar(10)
)
INSERT INTO #ContractBalancesFromTarget
exec dbo.GetContractBalancesPostMigration @isLoansApplicable=0
CREATE TABLE #LegalEntitySummary
(
LegalEntityNumber Nvarchar(100)
,Total Nvarchar(200)
,Source Decimal(18, 2)
,Target Decimal(18, 2)
,Difference Decimal(18, 2)
,OrderBy Int
)
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'NBV Amount'
,SUM(ISNULL(Source.NBVAmount,0))
,SUM(ISNULL(Target.NBVAmount,0))
,SUM(ISNULL(Source.NBVAmount,0)) - SUM(ISNULL(Target.NBVAmount,0))
,1
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Lease Payments Amount'
,SUM(ISNULL(Source.LeasePaymentsAmount,0))
,SUM(ISNULL(Target.LeasePaymentsAmount,0))
,SUM(ISNULL(Source.LeasePaymentsAmount,0)) - SUM(ISNULL(Target.LeasePaymentsAmount,0))
,2
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Lease Payments Balance'
,SUM(ISNULL(Source.LeasePaymentsBalance,0))
,SUM(ISNULL(Target.LeasePaymentsBalance,0))
,SUM(ISNULL(Source.LeasePaymentsBalance,0)) - SUM(ISNULL(Target.LeasePaymentsBalance,0))
,3
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'OverTerm Rental Amount'
,SUM(ISNULL(Source.OverTermRentalAmount,0))
,SUM(ISNULL(Target.OverTermRentalAmount,0))
,SUM(ISNULL(Source.OverTermRentalAmount,0)) - SUM(ISNULL(Target.OverTermRentalAmount,0))
,4
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'OverTerm Rental Balance'
,SUM(ISNULL(Source.OverTermRentalBalance,0))
,SUM(ISNULL(Target.OverTermRentalBalance,0))
,SUM(ISNULL(Source.OverTermRentalBalance,0)) - SUM(ISNULL(Target.OverTermRentalBalance,0))
,5
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Loan Principal Amount'
,SUM(ISNULL(Source.LoanPrincipalAmount,0))
,SUM(ISNULL(Target.LoanPrincipalAmount,0))
,SUM(ISNULL(Source.LoanPrincipalAmount,0)) - SUM(ISNULL(Target.LoanPrincipalAmount,0))
,6
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Loan Principal Balance'
,SUM(ISNULL(Source.LoanPrincipalBalance,0))
,SUM(ISNULL(Target.LoanPrincipalBalance,0))
,SUM(ISNULL(Source.LoanPrincipalBalance,0)) - SUM(ISNULL(Target.LoanPrincipalBalance,0))
,7
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Loan Interest Amount'
,SUM(ISNULL(Source.LoanInterestAmount,0))
,SUM(ISNULL(Target.LoanInterestAmount,0))
,SUM(ISNULL(Source.LoanInterestAmount,0)) - SUM(ISNULL(Target.LoanInterestAmount,0))
,8
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Loan Interest Balance'
,SUM(ISNULL(Source.LoanInterestBalance,0))
,SUM(ISNULL(Target.LoanInterestBalance,0))
,SUM(ISNULL(Source.LoanInterestBalance,0)) - SUM(ISNULL(Target.LoanInterestBalance,0))
,9
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Security Deposit Amount'
,SUM(ISNULL(Source.SecurityDepositAmount,0))
,SUM(ISNULL(Target.SecurityDepositAmount,0))
,SUM(ISNULL(Source.SecurityDepositAmount,0)) - SUM(ISNULL(Target.SecurityDepositAmount,0))
,10
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Security Deposit Balance'
,SUM(ISNULL(Source.SecurityDepositBalance,0))
,SUM(ISNULL(Target.SecurityDepositBalance,0))
,SUM(ISNULL(Source.SecurityDepositBalance,0)) - SUM(ISNULL(Target.SecurityDepositBalance,0))
,11
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'CPI Base And Overage Amount'
,SUM(ISNULL(Source.CPIBaseAndOverageAmount,0))
,SUM(ISNULL(Target.CPIBaseAndOverageAmount,0))
,SUM(ISNULL(Source.CPIBaseAndOverageAmount,0)) - SUM(ISNULL(Target.CPIBaseAndOverageAmount,0))
,12
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'CPI Base And Overage Balance'
,SUM(ISNULL(Source.CPIBaseAndOverageBalance,0))
,SUM(ISNULL(Target.CPIBaseAndOverageBalance,0))
,SUM(ISNULL(Source.CPIBaseAndOverageBalance,0)) - SUM(ISNULL(Target.CPIBaseAndOverageBalance,0))
,13
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Sundry Balance'
,SUM(ISNULL(Source.SundryBalance,0))
,SUM(ISNULL(Target.SundryBalance,0))
,SUM(ISNULL(Source.SundryBalance,0)) - SUM(ISNULL(Target.SundryBalance,0))
,14
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'PropertyTax Balance'
,SUM(ISNULL(Source.PropertyTaxBalance,0))
,SUM(ISNULL(Target.PropertyTaxBalance,0))
,SUM(ISNULL(Source.PropertyTaxBalance,0)) - SUM(ISNULL(Target.PropertyTaxBalance,0))
,15
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'LateFee Balance'
,SUM(ISNULL(Source.LateFeeBalance,0))
,SUM(ISNULL(Target.LateFeeBalance,0))
,SUM(ISNULL(Source.LateFeeBalance,0)) - SUM(ISNULL(Target.LateFeeBalance,0))
,16
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Lease Income Or Loan Interest Accrued'
,SUM(ISNULL(Source.LeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Target.LeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Source.LeaseIncomeOrLoanInterestAccrued,0)) - SUM(ISNULL(Target.LeaseIncomeOrLoanInterestAccrued,0))
,17
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Recognized Lease Income Or Loan Interest Accrued'
,SUM(ISNULL(Source.RecognizedLeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Target.RecognizedLeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Source.RecognizedLeaseIncomeOrLoanInterestAccrued,0)) - SUM(ISNULL(Target.RecognizedLeaseIncomeOrLoanInterestAccrued,0))
,18
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Unearned Lease Income Or Loan Interest Accrued'
,SUM(ISNULL(Source.UnearnedLeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Target.UnearnedLeaseIncomeOrLoanInterestAccrued,0))
,SUM(ISNULL(Source.UnearnedLeaseIncomeOrLoanInterestAccrued,0)) - SUM(ISNULL(Target.UnearnedLeaseIncomeOrLoanInterestAccrued,0))
,19
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Lease OTP Income Amount'
,SUM(ISNULL(Source.LeaseOTPAmount,0))
,SUM(ISNULL(Target.LeaseOTPAmount,0))
,SUM(ISNULL(Source.LeaseOTPAmount,0)) - SUM(ISNULL(Target.LeaseOTPAmount,0))
,19
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Unearned Lease OTP Income Amount'
,SUM(ISNULL(Source.UnearnedLeaseOTPIncome,0))
,SUM(ISNULL(Target.UnearnedLeaseOTPIncome,0))
,SUM(ISNULL(Source.UnearnedLeaseOTPIncome,0)) - SUM(ISNULL(Target.UnearnedLeaseOTPIncome,0))
,19
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber

INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Recognized Lease OTP Income Amount'
,SUM(ISNULL(Source.RecognizedLeaseOTPIncome,0))
,SUM(ISNULL(Target.RecognizedLeaseOTPIncome,0))
,SUM(ISNULL(Source.RecognizedLeaseOTPIncome,0)) - SUM(ISNULL(Target.RecognizedLeaseOTPIncome,0))
,19
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Total Blended Item Amount'
,SUM(ISNULL(Source.TotalBlendedItemAmount,0))
,SUM(ISNULL(Target.TotalBlendedItemAmount,0))
,SUM(ISNULL(Source.TotalBlendedItemAmount,0)) - SUM(ISNULL(Target.TotalBlendedItemAmount,0))
,20
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'BI Income Amount'
,SUM(ISNULL(Source.BIIncomeAmount,0))
,SUM(ISNULL(Target.BIIncomeAmount,0))
,SUM(ISNULL(Source.BIIncomeAmount,0)) - SUM(ISNULL(Target.BIIncomeAmount,0))
,21
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Recognized BI Income Amount'
,SUM(ISNULL(Source.RecognizedBIIncomeAmount,0))
,SUM(ISNULL(Target.RecognizedBIIncomeAmount,0))
,SUM(ISNULL(Source.RecognizedBIIncomeAmount,0)) - SUM(ISNULL(Target.RecognizedBIIncomeAmount,0))
,22
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
INSERT INTO #LegalEntitySummary
SELECT
Target.LegalEntityNumber
,'Unearned BI Income Amount'
,SUM(ISNULL(Source.UnearnedBIIncomeAmount,0))
,SUM(ISNULL(Target.UnearnedBIIncomeAmount,0))
,SUM(ISNULL(Source.UnearnedBIIncomeAmount,0)) - SUM(ISNULL(Target.UnearnedBIIncomeAmount,0))
,23
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
GROUP BY
Target.LegalEntityNumber
SELECT
LegalEntityNumber
,Total
,Source
,Target
,Difference
FROM #LegalEntitySummary
ORDER BY LegalEntityNumber, OrderBy
DROP TABLE #ContractBalancesFromTarget
DROP TABLE #ContractBalancesFromSource
DROP TABLE #LegalEntitySummary

GO
