SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetContractBalancesPostMigration]  
(  
@IsLoansApplicable bit  
)  
AS  
SELECT  
Contracts.Id ContractId  
,SUM(Receivables.TotalAmount_Amount) ReceivableAmount  
,SUM(Receivables.TotalBalance_Amount) BalanceAmount  
,ReceivableTypes.Name ReceivableType  
INTO #ContractTotalReceivable  
FROM  
Contracts  
INNER JOIN Receivables  
ON Receivables.EntityId = Contracts.Id  
AND Receivables.EntityType = 'CT'  
AND Receivables.IsActive = 1  
INNER JOIN ReceivableCodes  
ON Receivables.ReceivableCodeId = ReceivableCodes.Id  
INNER JOIN ReceivableTypes  
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id  
GROUP BY  
Contracts.Id  
,ReceivableTypes.Name  
SELECT  
RS.ContractId  
,SUM(RS.LeasePaymentsAmount) LeasePaymentsAmount  
,SUM(RS.LeasePaymentsBalance) LeasePaymentsBalance  
,SUM(RS.OverTermRentalAmount) OverTermRentalAmount  
,SUM(RS.OverTermRentalBalance) OverTermRentalBalance  
,SUM(RS.LoanPrincipalAmount) LoanPrincipalAmount  
,SUM(RS.LoanPrincipalBalance) LoanPrincipalBalance  
,SUM(RS.LoanInterestAmount) LoanInterestAmount  
,SUM(RS.LoanInterestBalance) LoanInterestBalance  
,SUM(RS.SundryAmount) SundryAmount  
,SUM(RS.SundryBalance) SundryBalance  
,SUM(RS.PropertyTaxAmount) PropertyTaxAmount  
,SUM(RS.PropertyTaxBalance) PropertyTaxBalance  
,SUM(RS.SecurityDepositAmount) SecurityDepositAmount  
,SUM(RS.SecurityDepositBalance) SecurityDepositBalance  
,SUM(RS.LateFeeAmount) LateFeeAmount  
,SUM(RS.LateFeeBalance) LateFeeBalance  
,SUM(RS.CPIBaseAndOverageAmount) CPIBaseAndOverageAmount  
,SUM(RS.CPIBaseAndOverageBalance) CPIBaseAndOverageBalance  
INTO #ContractReceivableByCategory  
FROM  
(  
SELECT  
ContractId  
,CASE WHEN ReceivableType IN ('CapitalLeaseRental','OperatingLeaseRental','LeveragedLeaseRental') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [LeasePaymentsAmount]  
,CASE WHEN ReceivableType IN ('CapitalLeaseRental','OperatingLeaseRental','LeveragedLeaseRental') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [LeasePaymentsBalance]  
,CASE WHEN ReceivableType IN ('OverTermRental') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [OverTermRentalAmount]  
,CASE WHEN ReceivableType IN ('OverTermRental') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [OverTermRentalBalance]  
,CASE WHEN ReceivableType IN ('LoanPrincipal') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [LoanPrincipalAmount]  
,CASE WHEN ReceivableType IN ('LoanPrincipal') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [LoanPrincipalBalance]  
,CASE WHEN ReceivableType IN ('LoanInterest') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [LoanInterestAmount]  
,CASE WHEN ReceivableType IN ('LoanInterest') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [LoanInterestBalance]  
,CASE WHEN ReceivableType IN ('Sundry','SundrySeparate') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [SundryAmount]  
,CASE WHEN ReceivableType IN ('Sundry','SundrySeparate') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [SundryBalance]  
,CASE WHEN ReceivableType IN ('PropertyTax','PropertyTaxEscrow') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [PropertyTaxAmount]  
,CASE WHEN ReceivableType IN ('PropertyTax','PropertyTaxEscrow') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [PropertyTaxBalance]  
,CASE WHEN ReceivableType IN ('SecurityDeposit') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [SecurityDepositAmount]  
,CASE WHEN ReceivableType IN ('SecurityDeposit') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [SecurityDepositBalance]  
,CASE WHEN ReceivableType IN ('LateFee') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [LateFeeAmount]  
,CASE WHEN ReceivableType IN ('LateFee') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [LateFeeBalance]  
,CASE WHEN ReceivableType IN ('CPIBaseRental','CPIOverage') THEN SUM(TargetTotalReceivable.ReceivableAmount) ELSE 0 END [CPIBaseAndOverageAmount]  
,CASE WHEN ReceivableType IN ('CPIBaseRental','CPIOverage') THEN SUM(TargetTotalReceivable.BalanceAmount) ELSE 0 END [CPIBaseAndOverageBalance]  
FROM  
#ContractTotalReceivable TargetTotalReceivable  
GROUP BY  
ContractId  
,ReceivableType  
) AS RS  
GROUP BY  
RS.ContractId  
SELECT  
Contracts.Id ContractId  
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'FixedTerm' THEN CASE WHEN lfd.LeaseContractType IN ('Operating') THEN LeaseIncomeSchedules.RentalIncome_Amount WHEN lfd.LeaseContractType IN ('Financing') THEN LeaseIncomeSchedules.FinanceIncome_Amount ELSE LeaseIncomeSchedules.Income_Amount END END) Income_Amount  
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'FixedTerm' AND LeaseIncomeSchedules.IsGLPosted = 0 THEN CASE WHEN lfd.LeaseContractType IN ('Operating') THEN LeaseIncomeSchedules.RentalIncome_Amount WHEN lfd.LeaseContractType IN ('Financing') THEN LeaseIncomeSchedules.FinanceIncome_Amount ELSE LeaseIncomeSchedules.Income_Amount END END) UnearnedIncomeAmount  
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'FixedTerm' AND LeaseIncomeSchedules.IsGLPosted = 1 THEN CASE WHEN lfd.LeaseContractType IN ('Operating') THEN LeaseIncomeSchedules.RentalIncome_Amount WHEN lfd.LeaseContractType IN ('Financing') THEN LeaseIncomeSchedules.FinanceIncome_Amount ELSE LeaseIncomeSchedules.Income_Amount END END) RecognizedIncomeAmount  
,MAX(CASE WHEN LeaseIncomeSchedules.IsGLPosted = 1 AND LeaseIncomeSchedules.IncomeType = 'FixedTerm' THEN LeaseIncomeSchedules.IncomeDate END ) IncomeRecognizedDate  
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'OverTerm' THEN LeaseIncomeSchedules.RentalIncome_Amount END) LeaseOTPIncome 
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'OverTerm' AND LeaseIncomeSchedules.IsGLPosted = 0 THEN LeaseIncomeSchedules.RentalIncome_Amount END) UnearnedLeaseOTPIncome 
,SUM(CASE WHEN LeaseIncomeSchedules.IncomeType = 'OverTerm' AND LeaseIncomeSchedules.IsGLPosted = 1 THEN LeaseIncomeSchedules.RentalIncome_Amount END) RecognizedLeaseOTPIncome 
,MAX(CASE WHEN LeaseIncomeSchedules.IsGLPosted = 1 AND LeaseIncomeSchedules.IncomeType = 'OverTerm' THEN LeaseIncomeSchedules.IncomeDate END ) LeaseOTPIncomeRecognizedDate
INTO #LeaseIncome  
FROM  
Contracts  
INNER JOIN LeaseFinances  
ON Contracts.Id = LeaseFinances.ContractId  
AND LeaseFinances.IsCurrent = 1  
INNER JOIN LeaseIncomeSchedules  
ON LeaseFinances.Id = LeaseIncomeSchedules.LeaseFinanceId
INNER JOIN LeaseFinanceDetails lfd
ON LeaseFinances.Id=lfd.Id
GROUP BY Contracts.Id  
SELECT  
Contracts.Id ContractId  
,SUM(BlendedIncomeSchedules.Income_Amount) Income_Amount  
,SUM(CASE WHEN BlendedIncomeSchedules.PostDate IS NULL THEN BlendedIncomeSchedules.Income_Amount ELSE 0 END) UnearnedIncomeAmount  
,SUM(CASE WHEN BlendedIncomeSchedules.PostDate IS NOT NULL THEN BlendedIncomeSchedules.Income_Amount ELSE 0 END) RecognizedIncomeAmount  
,MAX(CASE WHEN BlendedIncomeSchedules.PostDate IS NOT NULL THEN BlendedIncomeSchedules.IncomeDate ELSE NULL END) IncomeRecognizedDate  
INTO #LeaseBIIncome  
FROM  
Contracts  
INNER JOIN LeaseFinances  
ON Contracts.Id = LeaseFinances.ContractId  
AND LeaseFinances.IsCurrent = 1  
INNER JOIN BlendedIncomeSchedules  
ON LeaseFinances.Id = BlendedIncomeSchedules.LeaseFinanceId  
GROUP BY Contracts.Id  
SELECT  
Contracts.Id ContractId  
,SUM(LoanIncomeSchedules.InterestAccrued_Amount) InterestAccruedAmount  
,SUM(CASE WHEN LoanIncomeSchedules.IsGLPosted = 0 THEN LoanIncomeSchedules.InterestAccrued_Amount ELSE 0 END) UnearnedInterestAccruedAmount  
,SUM(CASE WHEN LoanIncomeSchedules.IsGLPosted = 0 THEN LoanIncomeSchedules.PrincipalRepayment_Amount ELSE 0 END) UnearnedPrincipalAmount  
,SUM(CASE WHEN LoanIncomeSchedules.IsGLPosted = 1 THEN LoanIncomeSchedules.InterestAccrued_Amount ELSE 0 END) RecognizedInterestAccruedAmount  
,SUM(CASE WHEN LoanIncomeSchedules.IsGLPosted = 1 THEN LoanIncomeSchedules.PrincipalRepayment_Amount ELSE 0 END) RecognizedPrincipalAmount  
,MAX(CASE WHEN LoanIncomeSchedules.IsGLPosted = 1 THEN LoanIncomeSchedules.IncomeDate ELSE NULL END) IncomeRecognizedDate  
INTO #LoanIncome  
FROM  
Contracts  
INNER JOIN LoanFinances  
ON Contracts.Id = LoanFinances.ContractId  
AND LoanFinances.IsCurrent = 1  
INNER JOIN LoanIncomeSchedules  
ON LoanFinances.Id = LoanIncomeSchedules.LoanFinanceId  
GROUP BY Contracts.Id  
SELECT  
Contracts.Id ContractId  
,SUM(BlendedIncomeSchedules.Income_Amount) Income_Amount  
,SUM(CASE WHEN BlendedIncomeSchedules.PostDate IS NULL THEN BlendedIncomeSchedules.Income_Amount ELSE 0 END) UnearnedIncomeAmount  
,SUM(CASE WHEN BlendedIncomeSchedules.PostDate IS NOT NULL THEN BlendedIncomeSchedules.Income_Amount ELSE 0 END) RecognizedIncomeAmount  
,MAX(CASE WHEN BlendedIncomeSchedules.PostDate IS NOT NULL THEN BlendedIncomeSchedules.IncomeDate ELSE NULL END) IncomeRecognizedDate  
INTO #LoanBIIncome  
FROM  
Contracts  
INNER JOIN LoanFinances  
ON Contracts.Id = LoanFinances.ContractId  
AND LoanFinances.IsCurrent = 1  
INNER JOIN BlendedIncomeSchedules  
ON LoanFinances.Id = BlendedIncomeSchedules.LeaseFinanceId  
GROUP BY Contracts.Id  
SELECT  
ContractId  
,NBVAmount  
,ResidualBookedAmount  
INTO #ContractInvestment  
FROM  
(  
SELECT  
Contracts.Id ContractId  
,SUM(LeaseAssets.NBV_Amount) NBVAmount  
,SUM(LeaseAssets.BookedResidual_Amount) ResidualBookedAmount  
FROM  
Contracts  
INNER JOIN LeaseFinances  
ON Contracts.Id = LeaseFinances.ContractId  
INNER JOIN LeaseAssets  
ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id  
GROUP BY  
Contracts.Id  
UNION ALL  
SELECT  
Contracts.Id ContractId  
,SUM(CollateralAssets.AcquisitionCost_Amount) NBVAmount  
,0.00 ResidualBookedAmount  
FROM  
Contracts  
INNER JOIN LoanFinances  
ON Contracts.Id = LoanFinances.ContractId  
INNER JOIN CollateralAssets  
ON CollateralAssets.LoanFinanceId = LoanFinances.Id  
GROUP BY  
Contracts.Id  
)AS RS  
SELECT  
ContractId  
,BIAmount  
INTO #ContractBIAmount  
FROM  
(  
SELECT  
Contracts.Id ContractId  
,SUM(BlendedItems.Amount_Amount) BIAmount  
FROM  
Contracts  
INNER JOIN LeaseFinances  
ON Contracts.Id = LeaseFinances.ContractId  
INNER JOIN LeaseBlendedItems  
ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id  
INNER JOIN BlendedItems  
ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId  
GROUP BY  
Contracts.Id  
UNION ALL  
SELECT  
Contracts.Id ContractId  
,SUM(BlendedItems.Amount_Amount) BIAmount  
FROM  
Contracts  
INNER JOIN LoanFinances  
ON Contracts.Id = LoanFinances.ContractId  
INNER JOIN LoanBlendedItems  
ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id  
INNER JOIN BlendedItems  
ON BlendedItems.Id = LoanBlendedItems.BlendedItemId  
GROUP BY  
Contracts.Id  
)AS RS  
SELECT  
Contracts.Id ContractId  
,MAX(CASE WHEN ReceivableDetails.IsTaxAssessed = 1 THEN Receivables.DueDate ELSE NULL END) TaxAssessedDate  
,MAX(CASE WHEN ReceivableDetails.BilledStatus = 'Invoiced' THEN Receivables.DueDate ELSE NULL END) InvoiceGeneratedDate  
,MAX(CASE WHEN Receivables.IsGlPosted = 1 THEN Receivables.DueDate ELSE NULL END) RecivabledGLPostedDate  
INTO #ContractAssessedDates  
FROM  
Contracts  
INNER JOIN Receivables  
ON Receivables.EntityId = Contracts.Id  
AND Receivables.EntityType = 'CT'  
INNER JOIN ReceivableDetails  
ON ReceivableDetails.ReceivableId = Receivables.Id  
GROUP BY Contracts.Id  
SELECT  
Contracts.Id ContractId  
,MAX(ReceivableInvoices.DueDate) LateFeesAssessedTillDate  
INTO #ContractLateFeesAssessedDates  
FROM  
Contracts  
INNER JOIN LateFeeAssessments  
ON Contracts.Id = LateFeeAssessments.ContractId  
INNER JOIN ReceivableInvoices  
ON LateFeeAssessments.ReceivableInvoiceId = ReceivableInvoices.Id  
GROUP BY Contracts.Id  
SELECT  
Contracts.SequenceNumber SequenceNumber  
,Contracts.ContractType  ContractType  
,Contracts.Status  
,LegalEntities.LegalEntityNumber LegalEntityNumber  
,Parties.PartyNumber PartyNumber  
,Currencies.Name Currency  
,Billtoes.Name BillToName  
,DealProductTypes.Name DealTransactionType  
,DealTypes.ProductType DealProductType  
,LineofBusinesses.Name LineOfBusinessName  
,InstrumentTypes.Code InstrumentTypeCode  
,CostCenterConfigs.CostCenter CostCenterName  
,Contracts.SyndicationType SyndicationType  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinances.HoldingStatus ELSE LoanFinances.HoldingStatus END HoldingStatus  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.CommencementDate ELSE LoanFinances.CommencementDate END InceptionDate  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.FrequencyStartDate ELSE FirstPaymentDate END FrequencyStartDate --Todo  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.MaturityDate ELSE LoanFinances.MaturityDate END MaturityDate  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.DueDay ELSE LoanFinances.DueDay END [DueDay]  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN CASE WHEN LeaseFinanceDetails.IsAdvance = 1 THEN 'Yes' ELSE 'No' END ELSE 'No' END [IsAdvance]  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.NumberOfInceptionPayments ELSE 0 END NumberOfInceptionPayments  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.InceptionPayment_Amount ELSE 0 END InceptionPayment  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.NumberOfPayments ELSE LoanFinances.NumberOfPayments END NumberOfPayments  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.PaymentFrequency ELSE LoanFinances.PaymentFrequency END PaymentFrequency  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.TermInMonths ELSE LoanFinances.Term END TermInMonths  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN CASE WHEN LeaseFinanceDetails.IsRegularPaymentStream = 1 THEN 'Yes' ELSE 'No' END ELSE 'Yes' END IsRegularPaymentStream  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.DayCountConvention ELSE LoanFinances.DayCountConvention END DayCountConvention  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.ManagementYield ELSE LoanFinances.ManagementYield END ManagementYield  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.ClassificationYield ELSE 0 END ClassificationYieldOnlyForLease  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.InternalYield ELSE 0 END InternalYieldOnlyForLease  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseFinanceDetails.TotalYield ELSE 0 END TotalYieldOnlyForLease  
,ISNULL(ContractInvestment.NBVAmount,0) NBVAmount  
,ISNULL(ContractInvestment.ResidualBookedAmount,0) [ResidualBookedAmount]  
,ISNULL(ContractReceivableByCategory.LeasePaymentsAmount,0) LeasePaymentsAmount  
,ISNULL(ContractReceivableByCategory.LeasePaymentsBalance,0) LeasePaymentsBalance  
,ISNULL(ContractReceivableByCategory.OverTermRentalAmount,0) OverTermRentalAmount  
,ISNULL(ContractReceivableByCategory.OverTermRentalBalance,0) OverTermRentalBalance  
,ISNULL(ContractReceivableByCategory.LoanPrincipalAmount,0) LoanPrincipalAmount  
,ISNULL(ContractReceivableByCategory.LoanPrincipalBalance,0) LoanPrincipalBalance  
,ISNULL(ContractReceivableByCategory.LoanInterestAmount,0) LoanInterestAmount  
,ISNULL(ContractReceivableByCategory.LoanInterestBalance,0) LoanInterestBalance  
,ISNULL(ContractReceivableByCategory.SecurityDepositAmount,0) SecurityDepositAmount  
,ISNULL(ContractReceivableByCategory.SecurityDepositBalance,0) SecurityDepositBalance  
,ISNULL(ContractReceivableByCategory.SundryBalance,0) SundryBalance  
,ISNULL(ContractReceivableByCategory.PropertyTaxBalance,0) PropertyTaxBalance  
,ISNULL(ContractReceivableByCategory.LateFeeBalance,0) LateFeeBalance  
,ISNULL(ContractReceivableByCategory.CPIBaseAndOverageAmount,0) CPIBaseAndOverageAmount  
,ISNULL(ContractReceivableByCategory.CPIBaseAndOverageBalance,0) CPIBaseAndOverageBalance  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.Income_Amount,0) ELSE ISNULL(LoanIncome.InterestAccruedAmount,0) END LeaseIncomeOrLoanInterestAccrued   
,CASE WHEN Contracts.SyndicationType = 'FullSale' THEN 0 ELSE CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.RecognizedIncomeAmount,0) ELSE ISNULL(LoanIncome.RecognizedInterestAccruedAmount,0) END END RecognizedLeaseIncomeOrLoanInterestAccrued  
,CASE WHEN Contracts.SyndicationType = 'FullSale' THEN 0 ELSE CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.UnearnedIncomeAmount,0) ELSE ISNULL(LoanIncome.UnearnedInterestAccruedAmount,0) END END UnearnedLeaseIncomeOrLoanInterestAccrued  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.LeaseOTPIncome,0) END LeaseOTPIncome 
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.UnearnedLeaseOTPIncome,0) END UnearnedLeaseOTPIncome 
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseIncome.RecognizedLeaseOTPIncome,0) END RecognizedLeaseOTPIncome 
,ISNULL(ContractBIAmount.BIAmount,0) TotalBlendedItemAmount  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseBIIncome.Income_Amount,0) ELSE ISNULL(LoanBIIncome.Income_Amount,0) END BIIncomeAmount  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseBIIncome.UnearnedIncomeAmount,0) ELSE ISNULL(LoanBIIncome.UnearnedIncomeAmount,0) END UnearnedBIIncomeAmount  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN ISNULL(LeaseBIIncome.RecognizedIncomeAmount,0) ELSE ISNULL(LoanBIIncome.RecognizedIncomeAmount,0) END RecognizedBIIncomeAmount  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN CASE WHEN LeaseFinances.IsSalesTaxExempt = 1 THEN 'Yes' ELSE 'No' END ELSE 'No' END  IsSalesTaxExempt  
,ContractAssessedDates.TaxAssessedDate SalesTaxAssessedDate  
,ContractAssessedDates.InvoiceGeneratedDate InvoiceGeneratedDate  
,ContractAssessedDates.RecivabledGLPostedDate ReceivablesGLPostedDate  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseIncome.IncomeRecognizedDate ELSE LoanIncome.IncomeRecognizedDate END IncomeRecognizedDate  
,CASE WHEN LeaseFinances.Id IS NOT NULL THEN LeaseIncome.LeaseOTPIncomeRecognizedDate END LeaseOTPIncomeRecognizedDate
,ContractLateFeesAssessedDates.LateFeesAssessedTillDate LateFeesAssessedDate  
,CASE WHEN Contracts.IsNonAccrual = 1 THEN 'Yes' ELSE 'No' END IsNonAccrual  
FROM  
Contracts  
INNER JOIN BillToes  
ON Contracts.BillToId = BillToes.Id  
INNER JOIN DealProductTypes  
ON Contracts.DealProductTypeId = DealProductTypes.Id  
INNER JOIN DealTypes  
ON Contracts.DealTypeId = DealTypes.Id  
INNER JOIN LineofBusinesses  
ON Contracts.LineofBusinessId = LineofBusinesses.Id  
INNER JOIN CostCenterConfigs  
ON Contracts.CostCenterId = CostCenterConfigs.Id  
INNER JOIN Currencies  
ON Contracts.CurrencyId = Currencies.Id  
LEFT JOIN LanguageConfigs  
ON Contracts.LanguageId = LanguageConfigs.Id  
LEFT JOIN LeaseFinances  
ON Contracts.Id = LeaseFinances.ContractId  
AND LeaseFinances.IsCurrent = 1  
LEFT JOIN LoanFinances  
ON Contracts.Id = LoanFinances.ContractId  
AND LoanFinances.IsCurrent = 1  
LEFT JOIN Parties  
ON CASE WHEN LeaseFinances.CustomerId IS NOT NULL THEN LeaseFinances.CustomerId ELSE LoanFinances.CustomerId END = Parties.Id  
LEFT JOIN LegalEntities  
ON CASE WHEN LeaseFinances.CustomerId IS NOT NULL THEN LeaseFinances.LegalEntityId ELSE LoanFinances.LegalEntityId END = LegalEntities.Id  
LEFT JOIN InstrumentTypes  
ON CASE WHEN LeaseFinances.CustomerId IS NOT NULL THEN LeaseFinances.InstrumentTypeId ELSE LoanFinances.InstrumentTypeId END = InstrumentTypes.Id  
LEFT JOIN LeaseFinanceDetails  
ON LeaseFinances.Id = LeaseFinanceDetails.Id  
LEFT JOIN #ContractReceivableByCategory ContractReceivableByCategory  
ON Contracts.Id = ContractReceivableByCategory.ContractId  
LEFT JOIN #LeaseIncome LeaseIncome  
ON Contracts.Id = LeaseIncome.ContractId  
LEFT JOIN #LoanIncome LoanIncome  
ON Contracts.Id = LoanIncome.ContractId  
LEFT JOIN #LeaseBIIncome LeaseBIIncome  
ON Contracts.Id = LeaseBIIncome.ContractId  
LEFT JOIN #LoanBIIncome LoanBIIncome  
ON Contracts.Id = LoanBIIncome.ContractId  
LEFT JOIN #ContractInvestment ContractInvestment  
ON Contracts.Id = ContractInvestment.ContractId  
LEFT JOIN #ContractBIAmount ContractBIAmount  
ON Contracts.Id = ContractBIAmount.ContractId  
LEFT JOIN #ContractAssessedDates ContractAssessedDates  
ON Contracts.Id = ContractAssessedDates.ContractId  
LEFT JOIN #ContractLateFeesAssessedDates ContractLateFeesAssessedDates  
ON Contracts.Id = ContractLateFeesAssessedDates.ContractId  
ORDER BY Contracts.Id  
DROP TABLE #ContractTotalReceivable  
DROP TABLE #ContractReceivableByCategory  
DROP TABLE #ContractBIAmount  
DROP TABLE #ContractInvestment  
DROP TABLE #ContractLateFeesAssessedDates  
DROP TABLE #ContractAssessedDates  
DROP TABLE #LeaseBIIncome  
DROP TABLE #LeaseIncome  
DROP TABLE #LoanBIIncome  
DROP TABLE #LoanIncome

GO
