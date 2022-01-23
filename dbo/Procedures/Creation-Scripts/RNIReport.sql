SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RNIReport]  
(  
 @SequenceNumber Nvarchar(80) = NULL,  
 @CustomerNumber Nvarchar(max) = NULL,  
 @IncomeDate  Date,  
 @OffBooks BIT = 0,  
 @CurrentPortfolioId BIGINT = NULL,  
 @AccessibleLegalEntities NVARCHAR(MAX) = NULL  
)  
As  
BEGIN  
SET NOCOUNT ON  
--DECLARE @SequenceNumber Nvarchar(80)  
--DECLARE @CustomerNumber Nvarchar(max)   
--DECLARE @IncomeDate  Date  
--DECLARE @OffBooks BIT   
  
--SET @SequenceNumber =''  
--SET @CustomerNumber=''  
--SET @IncomeDate='2017-04-29'   
--SET @OffBooks=0   
--DECLARE @CurrentPortfolioId BIGINT = 1  
  
-----EXEC RNIReport_Updated null,null,'2020-01-31',0,1,'1,2,3,4,5,6'  
  
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')  
  
CREATE TABLE #CommonDetails  
(  
  ContractId BIGINT PRIMARY KEY  
 ,CustomerNumber NVARCHAR(40)  
 ,CustomerName NVARCHAR(250)  
 ,SequenceNumber NVARCHAR(40)  
 ,LineOfBusiness NVARCHAR(40)  
 ,LegalId BIGINT  
 ,LegalEntity NVARCHAR(20)  
 ,CommencementDate DATE  
 ,MaturityDate DATE  
 ,SyndicationType NVARCHAR(16)  
)  
  
  
/* Lease details */  
INSERT INTO #CommonDetails  
SELECT  
 Contracts.Id 'ContractId',  
 LEP.PartyNumber 'CustomerNumber',  
 LEP.PartyName 'CustomerName',  
 Contracts.SequenceNumber,  
 LOB.Name 'LineOfBusiness',  
 LELE.Id 'LegalId',  
 LELE.LegalEntityNumber 'LegalEntity',  
 LFD.CommencementDate  'CommencementDate',  
 LFD.MaturityDate  'MaturityDate',  
 Contracts.SyndicationType  
FROM   
 Contracts  
 INNER JOIN LineofBusinesses LOB ON Contracts.LineofBusinessId =  LOB.Id  
 INNER JOIN LeaseFinances LEF ON Contracts.Id = LEF.ContractId AND LEF.IsCurrent = 1  
 INNER JOIN LeaseFinanceDetails LFD ON LEF.Id = LFD.Id  
 INNER JOIN LegalEntities LELE ON LEF.LegalEntityId =  LELE.Id  
 INNER JOIN Parties LEP ON LEF.CustomerId = LEP.Id  
 INNER JOIN #AccessibleLegalEntityIds ON #AccessibleLegalEntityIds.ID=LELE.Id  
WHERE   
 (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)  
 AND (@CustomerNumber IS NULL OR LEP.PartyNumber = @CustomerNumber);  
  
/* Loan details */  
  
INSERT INTO #CommonDetails  
SELECT  
 Contracts.Id 'ContractId',  
 LOP.PartyNumber 'CustomerNumber',  
 LOP.PartyName 'CustomerName',  
 Contracts.SequenceNumber,  
 LOB.Name 'LineOfBusiness',  
 LOLE.Id  'LegalId',  
 LOLE.LegalEntityNumber  'LegalEntity',  
 LOF.CommencementDate  'CommencementDate',  
 LOF.MaturityDate 'MaturityDate',  
 Contracts.SyndicationType  
FROM   
 Contracts  
 INNER JOIN LineofBusinesses LOB ON Contracts.LineofBusinessId =  LOB.Id  
 INNER JOIN LoanFinances LOF ON Contracts.Id = LOF.ContractId  AND  LOF.IsCurrent = 1   
 INNER JOIN LegalEntities LOLE ON LOF.LegalEntityId =  LOLE.Id  
 INNER JOIN Parties LOP ON  LOF.CustomerId = LOP.Id  
 INNER JOIN #AccessibleLegalEntityIds ON #AccessibleLegalEntityIds.ID= LOLE.Id  
WHERE   
 (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)  
 AND(@CustomerNumber IS NULL OR LOP.PartyNumber = @CustomerNumber);  
  
/* Leveraged Lease details */  
INSERT INTO #CommonDetails  
SELECT  
 Contracts.Id 'ContractId',  
 LLP.PartyNumber 'CustomerNumber',  
 LLP.PartyName 'CustomerName',  
 Contracts.SequenceNumber,  
 LOB.Name 'LineOfBusiness',  
 LL.Id 'LegalId',  
 LLLE.LegalEntityNumber 'LegalEntity',  
 LL.CommencementDate  'CommencementDate',  
 LL.MaturityDate  'MaturityDate',  
 Contracts.SyndicationType  
FROM   
 Contracts  
 INNER JOIN LineofBusinesses LOB ON Contracts.LineofBusinessId =  LOB.Id  
 INNER JOIN LeveragedLeases LL ON Contracts.Id = LL.ContractId AND LL.IsCurrent = 1  
 INNER JOIN LegalEntities LLLE ON LL.LegalEntityId =  LLLE.Id  
 INNER JOIN Parties LLP ON LL.CustomerId = LLP.Id  
 INNER JOIN #AccessibleLegalEntityIds ON #AccessibleLegalEntityIds.ID= LLLE.Id  
WHERE   
 (@SequenceNumber IS NULL OR Contracts.SequenceNumber =@SequenceNumber)   
 AND (@CustomerNumber IS NULL OR LLP.PartyNumber = @CustomerNumber);  
  
SELECT CD.ContractId,  
 (CASE WHEN Count(CHSH.Id) > 0 THEN 'Yes' ELSE 'No' END) 'HFSHistory'  
INTO #HoldingStatusHistories  
FROM ContractHoldingStatusHistories CHSH  
JOIN #CommonDetails CD ON CHSH.ContractId = CD.ContractId  
WHERE CHSH.IsActive = 1  
GROUP BY CD.ContractId  
;  
  
SELECT CD.ContractId,  
 LPS.StartDate 'SyndicationDate'  
INTO #SyndicationDetails  
FROM #CommonDetails CD  
JOIN LeaseFinances LF ON CD.ContractId = LF.ContractId  
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id  
JOIN LeasePaymentSchedules LPS ON LFD.Id = LPS.LeaseFinanceDetailId   
JOIN ReceivableForTransfers RFT ON CD.ContractId = RFT.ContractId AND LPS.Id = RFT.LeasePaymentId  
AND RFT.ApprovalStatus = 'Approved'   
;  
  
INSERT INTO #SyndicationDetails  
SELECT CD.ContractId,  
  LPS.StartDate 'SyndicationDate'  
FROM #CommonDetails CD  
JOIN LoanFinances LF ON CD.ContractId = LF.ContractId  
JOIN LoanPaymentSchedules LPS ON LF.Id = LPS.LoanFinanceId   
JOIN ReceivableForTransfers RFT ON CD.ContractId = RFT.ContractId AND LPS.Id = RFT.LoanPaymentId  
AND RFT.ApprovalStatus = 'Approved'   
;  
  
IF @OffBooks = 0  
BEGIN  
 SELECT  
  CD.CustomerNumber 'CustomerNumber',  
  CD.CustomerName 'CustomerName',  
  CD.SequenceNumber,  
  RNI.ContractType,  
  CD.LineOfBusiness 'LineOfBusiness',  
  CD.LegalEntity 'LegalEntity',  
  IT.Code 'InstrumentType',  
  IncomeDate,  
  RNIAmount_Amount 'RNIAmount',  
  (CASE WHEN IsOTP = 0 THEN 'No' ELSE 'Yes' END) IsOTP,  
  (CASE WHEN IsInNonAccrual = 0 THEN 'No' ELSE 'Yes' END) IsInNonAccrual,  
  RNI.NonAccrualDate,  
  RNIAmount_Currency 'Currency',  
  RNI.Status,  
  RNI.HoldingStatus,  
  HSH.HFSHistory,  
  RNI.RetainedPercentage,      
  (CASE WHEN IsPaymentStreamSold = 0 THEN 'No' ELSE 'Yes' END) 'IsPaymentStreamSold',    
  (PrincipalBalance + PrincipalBalanceAdjustment) 'PrincipalBalance',  
  DelayedFundingPayables 'DelayedFundingPayables',  
  LoanPrincipleOSAR 'LoanPrincipalOSAR',  
  LoanInterestOSAR 'LoanInterestOSAR',  
  InterimInterestOSAR 'InterimInterestOSAR',  
  (CASE WHEN RNI.ContractType = 'Lease' AND RNI.SubType != 'Operating' THEN 0.00 ELSE IncomeAccrualBalance END) 'IncomeAccrualBalance' ,  
  FinanceIncomeAccrualBalance'FinanceIncomeAccrualBalance',  
  SuspendedIncomeAccrualBalance 'SuspendedIncomeAccrualBalance',  
  SuspendedFinanceIncomeAccrualBalance 'SuspendedFinanceIncomeAccrualBalance',  
  ProgressFundings 'ProgressFundings',  
  ProgressPaymentCredits 'ProgressPaymentCredits',  
  TotalFinancedAmount 'TotalFinancedAmount',  
  UnappliedCash 'UnappliedCash',  
  GrossWritedowns 'GrossWritedowns',  
  FinanceGrossWritedowns 'FinanceGrossWritedowns',  
  NetWritedowns 'NetWritedowns',    
  FinanceNetWritedowns 'FinanceNetWritedowns',  
  IDCBalance 'IDCBalance',  
  SuspendedIDCBalance 'SuspendedIDCBalance',  
  SuspendedFAS91ExpenseBalance 'SuspendedFAS91ExpenseBalance',  
  SuspendedFAS91IncomeBalance 'SuspendedFAS91IncomeBalance',  
  FAS91ExpenseBalance 'FAS91ExpenseBalance',  
  FAS91IncomeBalance 'FAS91IncomeBalance',  
  OperatingLeaseAssetGrossCost 'OperatingLeaseAssetGrossCost',  
  AccumulatedDepreciation 'AccumulatedDepreciation',  
  OperatingLeaseRentOSAR 'OperatingLeaseRentOSAR',  
  InterimRentOSAR 'InterimRentOSAR',  
  DeferredOperatingIncome 'DeferredOperatingIncome',  
  DeferredExtensionIncome'DeferredExtensionIncome',  
  CapitalLeaseContractReceivable 'CapitalLeaseContractReceivable',  
  FinancingContractReceivable 'FinancingContractReceivable',  
  UnguaranteedResidual 'UnguaranteedResidual',  
  CustomerGuaranteedResidual 'CustomerGuaranteedResidual',  
  ThirdPartyGauranteedResidual 'ThirdPartyGauranteedResidual',  
  CapitalLeaseRentOSAR 'CapitalLeaseRentOSAR',  
  FinancingRentOSAR 'FinancingRentOSAR',  
  OverTermRentOSAR 'OverTermRentOSAR',  
  FinanceUnguaranteedResidual'FinanceUnguaranteedResidual',  
  FinanceCustomerGuaranteedResidual'FinanceCustomerGuaranteedResidual',  
  FinanceThirdPartyGauranteedResidual'FinanceThirdPartyGauranteedResidual',  
  (CASE WHEN RNI.ContractType = 'Lease' AND RNI.SubType != 'Operating' THEN IncomeAccrualBalance ELSE UnearnedRentalIncome END) 'UnearnedRentalIncome',  
  OTPResidualRecapture 'OTPResidualRecapture',  
  PrepaidReceivables 'PrepaidReceivables',   
  PrepaidInterest 'PrepaidInterest',  
  AccumulatedNBVImpairment 'AccumulatedNBVImpairment',  
  FloatRateAdjustmentOSAR 'FloatRateAdjustmentOSAR',  
  FloatRateIncomeBalance 'FloatRateIncomeBalance',  
  SuspendedFloatRateIncomeBalance 'SuspendedFloatRateIncomeBalance',  
  HeldForSaleValuationAllowance 'HeldForSaleValuationAllowance',  
  HeldForSaleBalance 'HeldForSaleBalance',  
  SalesTaxOSAR 'SalesTaxOSAR',  
  SecurityDeposit 'SecurityDeposit',  
  SecurityDepositOSAR 'SecurityDepositOSAR',  
  VendorSubsidyOSAR 'VendorSubsidyOSAR',  
  DelayedVendorSubsidy 'DelayedVendorSubsidy',  
  DeferredSellingProfit 'DeferredSellingProfit',  
  SuspendedDeferredSellingProfit 'SuspendedDeferredSellingProfit'  
 FROM RemainingNetInvestments RNI  
 JOIN #CommonDetails CD ON RNI.ContractId = CD.ContractId AND IncomeDate = @IncomeDate AND RNI.IsActive = 1  
 LEFT JOIN InstrumentTypes IT ON RNI.InstrumentTypeId = IT.Id  
 LEFT JOIN #HoldingStatusHistories HSH ON RNI.ContractId = HSH.ContractId  
 LEFT JOIN #SyndicationDetails SD ON RNI.ContractId = SD.ContractId  
 WHERE  (RNI.Status IN ('Terminated','Commenced','FullyPaidOff') OR (RNI.ContractType = 'ProgressLoan' AND RNI.Status ='Uncommenced'))  
 AND (RNI.InstrumentTypeId IS NULL OR (RNI.InstrumentTypeId IS NOT NULL AND IT.Code != 'L35' AND IT.Code != 'L36'))  
 AND (CD.SyndicationType != 'FullSale' OR (CD.SyndicationType = 'FullSale' AND SD.SyndicationDate != CD.CommencementDate))  
 ;  
END  
ELSE  
BEGIN  
 SELECT  
  CD.CustomerNumber 'CustomerNumber',  
  CD.CustomerName 'CustomerName',  
  CD.SequenceNumber,  
  RNI.ContractType,  
  CD.LineOfBusiness 'LineOfBusiness',  
  CD.LegalEntity 'LegalEntity',  
  IT.Code 'InstrumentType',  
  IncomeDate,  
  ServicedRNIAmount 'ServicedRNIAmount',  
  (CASE WHEN IsOTP = 0 THEN 'No' ELSE 'Yes' END) IsOTP,  
  (CASE WHEN IsInNonAccrual = 0 THEN 'No' ELSE 'Yes' END) IsInNonAccrual,  
  RNI.NonAccrualDate,  
  RNIAmount_Currency 'Currency',  
  RNI.Status,  
  RNI.HoldingStatus,  
  HSH.HFSHistory,  
  RNI.RetainedPercentage,      
  (CASE WHEN IsPaymentStreamSold = 0 THEN 'No' ELSE 'Yes' END) 'IsPaymentStreamSold',  
  (PrincipalBalanceFunderPortion + (PrincipalBalanceAdjustment * (CASE WHEN RNI.RetainedPercentage != 0 THEN (1 - (RNI.RetainedPercentage / 100)) ELSE 0 END)))'PrincipalBalance',  
  (CASE WHEN RNI.ContractType = 'Lease' AND RNI.SubType != 'Operating' THEN 0.00 ELSE IncomeAccrualBalanceFunderPortion END) 'IncomeAccrualBalance' ,  
  (CASE WHEN RNI.ContractType = 'Lease' AND RNI.SubType != 'Operating' THEN IncomeAccrualBalanceFunderPortion ELSE UnearnedRentalIncome END) 'UnearnedRentalIncome',  
  SyndicatedPrepaidReceivables 'SyndicatedPrepaidReceivables',  
  SyndicatedFixedTermReceivablesOSAR 'SyndicatedFixedTermReceivablesOSAR',  
  SyndicatedInterimReceivablesOSAR 'SyndicatedInterimReceivablesOSAR',  
  SyndicatedSalesTaxOSAR 'SyndicatedSalesTaxOSAR',  
  SyndicatedCapitalLeaseContractReceivable 'SyndicatedCapitalLeaseContractReceivable',  
  SyndicatedFinancingContractReceivable 'SyndicatedFinancingContractReceivable',  
  FinanceSyndicatedFixedTermReceivablesOSAR 'FinanceSyndicatedFixedTermReceivablesOSAR'  
 FROM RemainingNetInvestments RNI  
 JOIN #CommonDetails CD ON RNI.ContractId = CD.ContractId AND IncomeDate = @IncomeDate AND RNI.IsActive = 1  
 LEFT JOIN InstrumentTypes IT ON RNI.InstrumentTypeId = IT.Id  
 LEFT JOIN #HoldingStatusHistories HSH ON RNI.ContractId = HSH.ContractId  
 WHERE   
  (RNI.IsPaymentStreamSold = 1 OR RNI.RetainedPercentage != 100)  
 AND (RNI.Status IN ('Terminated','Commenced','FullyPaidOff') OR (RNI.ContractType = 'ProgressLoan' AND RNI.Status ='Uncommenced'))  
 ;  
END  
  
DROP TABLE #CommonDetails;  
DROP TABLE #HoldingStatusHistories;  
DROP TABLE #SyndicationDetails;  
DROP TABLE #AccessibleLegalEntityIds  

END

GO
