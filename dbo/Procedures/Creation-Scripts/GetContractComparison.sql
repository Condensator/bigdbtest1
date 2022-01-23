SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContractComparison]
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
SELECT
Target.SequenceNumber
,Target.ContractType
,Target.Status
,Target.SyndicationType
,Target.Currency
,Source.NBVAmount S_NBV
,Target.NBVAmount T_NBV
,CASE WHEN ISNULL(Source.NBVAmount,0) <> ISNULL(Target.NBVAmount,0) THEN 'FALSE' ELSE 'TRUE' END NBV_Matched
,Source.LeasePaymentsAmount S_LeasePaymentsAmount
,Target.LeasePaymentsAmount T_LeasePaymentsAmount
,CASE WHEN ISNULL(Source.LeasePaymentsAmount,0) <> ISNULL(Target.LeasePaymentsAmount,0) THEN 'FALSE' ELSE 'TRUE' END LeasePaymentsAmount_Matched
,Source.LeasePaymentsBalance S_LeasePaymentsBalance
,Target.LeasePaymentsBalance T_LeasePaymentsBalance
,CASE WHEN ISNULL(Source.LeasePaymentsBalance,0) <> ISNULL(Target.LeasePaymentsBalance,0) THEN 'FALSE' ELSE 'TRUE' END LeasePaymentsBalance_Matched
,Source.OverTermRentalAmount S_OverTermRentalAmount
,Target.OverTermRentalAmount T_OverTermRentalAmount
,CASE WHEN ISNULL(Source.OverTermRentalAmount,0) <> ISNULL(Target.OverTermRentalAmount,0) THEN 'FALSE' ELSE 'TRUE' END OverTermRentalAmount_Matched
,Source.OverTermRentalBalance S_OverTermRentalBalance
,Target.OverTermRentalBalance T_OverTermRentalBalance
,CASE WHEN ISNULL(Source.OverTermRentalBalance,0) <> ISNULL(Target.OverTermRentalBalance,0) THEN 'FALSE' ELSE 'TRUE' END OverTermRentalBalance_Matched
,Source.LoanPrincipalAmount S_LoanPrincipalAmount
,Target.LoanPrincipalAmount T_LoanPrincipalAmount
,CASE WHEN ISNULL(Source.LoanPrincipalAmount,0) <> ISNULL(Target.LoanPrincipalAmount,0) THEN 'FALSE' ELSE 'TRUE' END LoanPrincipalAmount_Matched
,Source.LoanPrincipalBalance S_LoanPrincipalBalance
,Target.LoanPrincipalBalance T_LoanPrincipalBalance
,CASE WHEN ISNULL(Source.LoanPrincipalBalance,0) <> ISNULL(Target.LoanPrincipalBalance,0) THEN 'FALSE' ELSE 'TRUE' END LoanPrincipalBalance_Matched
,Source.LoanInterestAmount S_LoanInterestAmount
,Target.LoanInterestAmount T_LoanInterestAmount
,CASE WHEN ISNULL(Source.LoanInterestAmount,0) <> ISNULL(Target.LoanInterestAmount,0) THEN 'FALSE' ELSE 'TRUE' END LoanInterestAmount_Matched
,Source.LoanInterestBalance S_LoanInterestBalance
,Target.LoanInterestBalance T_LoanInterestBalance
,CASE WHEN ISNULL(Source.LoanInterestBalance,0) <> ISNULL(Target.LoanInterestBalance,0) THEN 'FALSE' ELSE 'TRUE' END LoanInterestBalance_Matched
,Source.SecurityDepositAmount S_SecurityDepositAmount
,Target.SecurityDepositAmount T_SecurityDepositAmount
,CASE WHEN ISNULL(Source.SecurityDepositAmount,0) <> ISNULL(Target.SecurityDepositAmount,0) THEN 'FALSE' ELSE 'TRUE' END SecurityDepositAmount_Matched
,Source.SecurityDepositBalance S_SecurityDepositBalance
,Target.SecurityDepositBalance T_SecurityDepositBalance
,CASE WHEN ISNULL(Source.SecurityDepositBalance,0) <> ISNULL(Target.SecurityDepositBalance,0) THEN 'FALSE' ELSE 'TRUE' END SecurityDepositBalance_Matched
,Source.CPIBaseAndOverageAmount S_CPIBaseAndOverageAmount
,Target.CPIBaseAndOverageAmount T_CPIBaseAndOverageAmount
,CASE WHEN ISNULL(Source.CPIBaseAndOverageAmount,0) <> ISNULL(Target.CPIBaseAndOverageAmount,0) THEN 'FALSE' ELSE 'TRUE' END CPIBaseAndOverageAmount_Matched
,Source.CPIBaseAndOverageBalance S_CPIBaseAndOverageBalance
,Target.CPIBaseAndOverageBalance T_CPIBaseAndOverageBalance
,CASE WHEN ISNULL(Source.CPIBaseAndOverageBalance,0) <> ISNULL(Target.CPIBaseAndOverageBalance,0) THEN 'FALSE' ELSE 'TRUE' END CPIBaseAndOverageBalance_Matched
,Source.SundryBalance S_SundryBalance
,Target.SundryBalance T_SundryBalance
,CASE WHEN ISNULL(Source.SundryBalance,0) <> ISNULL(Target.SundryBalance,0) THEN 'FALSE' ELSE 'TRUE' END SundryBalance_Matched
,Source.PropertyTaxBalance S_PropertyTaxBalance
,Target.PropertyTaxBalance T_PropertyTaxBalance
,CASE WHEN ISNULL(Source.PropertyTaxBalance,0) <> ISNULL(Target.PropertyTaxBalance,0) THEN 'FALSE' ELSE 'TRUE' END PropertyTaxBalance_Matched
,Source.LateFeeBalance S_LateFeeBalance
,Target.LateFeeBalance T_LateFeeBalance
,CASE WHEN ISNULL(Source.LateFeeBalance,0) <> ISNULL(Target.LateFeeBalance,0) THEN 'FALSE' ELSE 'TRUE' END LateFeeBalance_Matched
,Source.LeaseIncomeOrLoanInterestAccrued S_LeaseIncomeOrLoanInterestAccrued
,Target.LeaseIncomeOrLoanInterestAccrued T_LeaseIncomeOrLoanInterestAccrued
,CASE WHEN ISNULL(Source.LeaseIncomeOrLoanInterestAccrued,0) <> ISNULL(Target.LeaseIncomeOrLoanInterestAccrued,0) THEN 'FALSE' ELSE 'TRUE' END LeaseIncomeOrLoanInterestAccrued_Matched
,Source.RecognizedLeaseIncomeOrLoanInterestAccrued S_RecognizedLeaseIncomeOrLoanInterestAccrued
,Target.RecognizedLeaseIncomeOrLoanInterestAccrued T_RecognizedLeaseIncomeOrLoanInterestAccrued
,CASE WHEN ISNULL(Source.RecognizedLeaseIncomeOrLoanInterestAccrued,0) <> ISNULL(Target.RecognizedLeaseIncomeOrLoanInterestAccrued,0) THEN 'FALSE' ELSE 'TRUE' END RecognizedLeaseIncomeOrLoanInterestAccrued_Matched
,Source.UnearnedLeaseIncomeOrLoanInterestAccrued S_UnearnedLeaseIncomeOrLoanInterestAccrued
,Target.UnearnedLeaseIncomeOrLoanInterestAccrued T_UnearnedLeaseIncomeOrLoanInterestAccrued
,CASE WHEN ISNULL(Source.UnearnedLeaseIncomeOrLoanInterestAccrued,0) <> ISNULL(Target.UnearnedLeaseIncomeOrLoanInterestAccrued,0) THEN 'FALSE' ELSE 'TRUE' END UnearnedLeaseIncomeOrLoanInterestAccrued_Matched
,Source.LeaseOTPAmount S_LeaseOTPIncome
,Target.LeaseOTPAmount T_LeaseOTPIncome
,CASE WHEN ISNULL(Source.LeaseOTPAmount,0) <> ISNULL(Target.LeaseOTPAmount,0) THEN 'FALSE' ELSE 'TRUE' END LeaseOTPIncome_Matched
,Source.UnearnedLeaseOTPIncome S_UnearnedLeaseOTPIncome
,Target.UnearnedLeaseOTPIncome T_UnearnedLeaseOTPIncome
,CASE WHEN ISNULL(Source.UnearnedLeaseOTPIncome,0) <> ISNULL(Target.UnearnedLeaseOTPIncome,0) THEN 'FALSE' ELSE 'TRUE' END UnearnedLeaseOTPIncome_Matched
,Source.RecognizedLeaseOTPIncome S_RecognizedLeaseOTPIncome
,Target.RecognizedLeaseOTPIncome T_RecognizedLeaseOTPIncome
,CASE WHEN ISNULL(Source.RecognizedLeaseOTPIncome,0) <> ISNULL(Target.RecognizedLeaseOTPIncome,0) THEN 'FALSE' ELSE 'TRUE' END RecognizedLeaseOTPIncome_Matched
,Source.TotalBlendedItemAmount S_TotalBlendedItemAmount
,Target.TotalBlendedItemAmount T_TotalBlendedItemAmount
,CASE WHEN ISNULL(Source.TotalBlendedItemAmount,0) <> ISNULL(Target.TotalBlendedItemAmount,0) THEN 'FALSE' ELSE 'TRUE' END TotalBlendedItemAmount_Matched
,Source.BIIncomeAmount S_BIIncomeAmount
,Target.BIIncomeAmount T_BIIncomeAmount
,CASE WHEN ISNULL(Source.BIIncomeAmount,0) <> ISNULL(Target.BIIncomeAmount,0) THEN 'FALSE' ELSE 'TRUE' END BIIncomeAmount_Matched
,Source.RecognizedBIIncomeAmount S_RecognizedBIIncomeAmount
,Target.RecognizedBIIncomeAmount T_RecognizedBIIncomeAmount
,CASE WHEN ISNULL(Source.RecognizedBIIncomeAmount,0) <> ISNULL(Target.RecognizedBIIncomeAmount,0) THEN 'FALSE' ELSE 'TRUE' END RecognizedBIIncomeAmount_Matched
,Source.UnearnedBIIncomeAmount S_UnearnedBIIncomeAmount
,Target.UnearnedBIIncomeAmount T_UnearnedBIIncomeAmount
,CASE WHEN ISNULL(Source.UnearnedBIIncomeAmount,0) <> ISNULL(Target.UnearnedBIIncomeAmount,0) THEN 'FALSE' ELSE 'TRUE' END UnearnedBIIncomeAmount_Matched
,Source.IsSalesTaxExempt S_SalesTaxExempt
,Target.IsSalesTaxExempt T_SalesTaxExempt
,CASE WHEN ISNULL(Source.IsSalesTaxExempt,0) <> ISNULL(Target.IsSalesTaxExempt,0) THEN 'FALSE' ELSE 'TRUE' END SalesTaxExempt_Matched
,Source.SalesTaxAssessedDate S_SalesTaxAssessedDate
,Target.SalesTaxAssessedDate T_SalesTaxAssessedDate
,CASE WHEN ISNULL(Source.SalesTaxAssessedDate,'1900-01-01') <> ISNULL(Target.SalesTaxAssessedDate,'1900-01-01') THEN 'FALSE' ELSE 'TRUE' END SalesTaxAssessedDate_Matched
,Source.InvoiceGeneratedDate S_InvoiceGeneratedDate
,Target.InvoiceGeneratedDate T_InvoiceGeneratedDate
,CASE WHEN ISNULL(Source.InvoiceGeneratedDate,'1900-01-01') <> ISNULL(Target.InvoiceGeneratedDate,'1900-01-01') THEN 'FALSE' ELSE 'TRUE' END InvoiceGeneratedDate_Matched
,Source.ReceivablesGLPostedDate S_ReceivablesGLPostedDate
,Target.ReceivablesGLPostedDate T_ReceivablesGLPostedDate
,CASE WHEN ISNULL(Source.ReceivablesGLPostedDate,'1900-01-01') <> ISNULL(Target.ReceivablesGLPostedDate,'1900-01-01') THEN 'FALSE' ELSE 'TRUE' END ReceivablesGLPostedDate_Matched
,Source.LateFeesAssessedDate S_LateFeesAssessedDate
,Target.LateFeesAssessedDate T_LateFeesAssessedDate
,CASE WHEN ISNULL(Source.LateFeesAssessedDate,'1900-01-01') <> ISNULL(Target.LateFeesAssessedDate,'1900-01-01') THEN 'FALSE' ELSE 'TRUE' END LateFeesAssessedDate_Matched
,Source.IsNonAccrual S_NonAccrual
,Target.IsNonAccrual T_NonAccrual
,CASE WHEN ISNULL(Source.IsNonAccrual,0) <> ISNULL(Target.IsNonAccrual,0) THEN 'FALSE' ELSE 'TRUE' END NonAccrual_Matched
FROM
#ContractBalancesFromSource Source
INNER JOIN #ContractBalancesFromTarget Target
ON Source.SequenceNumber = Target.SequenceNumber
DROP TABLE #ContractBalancesFromTarget
DROP TABLE #ContractBalancesFromSource

GO
