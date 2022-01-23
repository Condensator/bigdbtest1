SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ManipulateRecordsForIncomeAmort]
(
@IncomeSchedules LoanIncomeSchedulesForManipulation READONLY,
@PaymentSchedules LoanPaymentSchedulesForManipulation READONLY,
@PaymentScheduleHistories LoanPaymentScheduleHistoriesForManipulation READONLY,
@Receivables ReceivablesForManipulation READONLY,
@Sundries SundriesToPersist READONLY,
@Payables PayablesToPersist READONLY,
@LoanFinance LoanFinanceToUpdate READONLY,
@CaptalizedInterest LoanCaptalizedInterestToPersist READONLY,
@ACHSchedule ACHSchedulesToPersist READONLY,
@BlendedIncomeToInactivate BlendedIncomeScheduleToInactivate READONLY,
@PaymentSchedulesToUpdate LoanPaymentScheduleToUpdate READONLY,
@BlendedItemToUpdate BlendedItemsToUpdateEndDate READONLY,
@PaymentSchedulesToInactivate NVARCHAR(MAX),
@FloatRateIdsToUpdate NVARCHAR(MAX),
@InvalidCapitalizedInterestIds NVARCHAR(MAX),
@ReceivablesTotalBookBalanceToUpdate NVARCHAR(MAX),
@PaymentSheculeGeneratedFlagToUpdate NVARCHAR(MAX),
@PaymentSheculeGeneratedFlagToUpdateInPaydown  NVARCHAR(MAX),
@LoanIncomeSchedulesToUpdate LoanIncomeScheduleToUpdate READONLY,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @updateQuery NVARCHAR(MAX) = '';
CREATE TABLE #PaymentScheduleMapping
(
LoanPaymentScheduleId BIGINT,
Identifier BIGINT,
);
CREATE TABLE #PaymentReceivableMapping
(
ReceivableId BIGINT,
Identifier BIGINT,
);
CREATE TABLE #SyndicationReceivableMapping
(
ReceivableId BIGINT,
Identifier BIGINT,
);
CREATE TABLE #PostMaturityInterestReceivableMapping
(
ReceivableId BIGINT,
Identifier BIGINT,
);
CREATE TABLE #PayableMapping
(
PayableId BIGINT,
Identifier BIGINT,
);
--CREATE TABLE #IncomeScheduleMapping
--(
--	IncomeScheduleId BIGINT,
--	Identifier BIGINT,
--);
--To Update Loan Finance Object with the calculated values
MERGE dbo.LoanFinances AS PersistedLoanFinance
USING @LoanFinance AS LoanFinance
ON (PersistedLoanFinance.Id = LoanFinance.LoanFinanceId)
WHEN MATCHED THEN
UPDATE SET IsPaymentScheduleModified = LoanFinance.IsPaymentScheduleModified
,IsBlendedToBeRecomputed = 0
,FloatRateUpdateRunDate = LoanFinance.FloatRateUpdateRunDate
,MaturityDate = LoanFinance.MaturityDate
,CurrentMaturityDate = LoanFinance.CurrentMaturityDate
,NumberOfPayments = LoanFinance.NumberOfPayments
,Term = LoanFinance.Term
,UpdatedById = @UserId
,UpdatedTime = @Time;
--Clearing Interest Accrual Balance as of commencement Date - 1 day income record for Capitalize interim
MERGE dbo.LoanIncomeSchedules AS PersistedLoanIncomeSchedule
USING @LoanIncomeSchedulesToUpdate AS LoanIncomeSchedule
ON (PersistedLoanIncomeSchedule.Id = LoanIncomeSchedule.IncomeScheduleId)
WHEN MATCHED THEN
UPDATE SET InterestAccrualBalance_Amount = LoanIncomeSchedule.InterestAccrualBalance
,UpdatedById = @UserId
,UpdatedTime = @Time;
--To Persist Loan Income Schedule
MERGE dbo.LoanIncomeSchedules AS PersistedLoanIncome
USING @IncomeSchedules AS Income
ON (PersistedLoanIncome.Id = Income.Id)
WHEN MATCHED THEN
UPDATE SET AdjustmentEntry = Income.AdjustmentEntry
,BeginNetBookValue_Amount = Income.BeginNetBookValue
,BeginNetBookValue_Currency = Income.Currency
,CapitalizedInterest_Amount = Income.CapitalizedInterest
,CapitalizedInterest_Currency = Income.Currency
,CompoundDate = Income.CompoundDate
,CumulativeInterestAppliedToPrincipal_Amount = Income.CumulativeInterestAppliedToPrincipal
,CumulativeInterestAppliedToPrincipal_Currency = Income.Currency
,CumulativeInterestBalance_Amount = Income.CumulativeInterestBalance
,CumulativeInterestBalance_Currency = Income.Currency
,DisbursementId = Income.DisbursementId
,EndNetBookValue_Amount = Income.EndNetBookValue
,EndNetBookValue_Currency = Income.Currency
,FloatRateIndexDetailId = Income.FloatRateIndexDetailId
,IncomeDate = Income.IncomeDate
,InterestAccrualBalance_Amount = Income.InterestAccrualBalance
,InterestAccrualBalance_Currency = Income.Currency
,InterestAccrued_Amount = Income.InterestAccrued
,InterestAccrued_Currency = Income.Currency
,InterestPayment_Amount = Income.InterestPayment
,InterestPayment_Currency = Income.Currency
,InterestRate = Income.InterestRate
,IsAccounting = Income.IsAccounting
,IsGLPosted = Income.IsGLPosted
,IsLessorOwned = Income.IsLessorOwned
,IsNonAccrual = Income.IsNonAccrual
,IsSchedule = Income.IsSchedule
,IsSyndicated = Income.IsSyndicated
,Payment_Amount = Income.Payment
,Payment_Currency = Income.Currency
,PrincipalAdded_Amount = Income.PrincipalAdded
,PrincipalAdded_Currency = Income.Currency
,PrincipalRepayment_Amount = Income.PrincipalRepayment
,PrincipalRepayment_Currency = Income.Currency
,TV5InterestAccrualBalance_Currency = Income.Currency
,TV5InterestAccrualBalance_Amount = Income.TV5InterestAccrualBalance
,UpdatedById = @UserId
,UpdatedTime = @Time
,UnroundedInterestAccrued = Income.UnroundedInterestAccrued
WHEN NOT MATCHED THEN
INSERT (AdjustmentEntry
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,CapitalizedInterest_Amount
,CapitalizedInterest_Currency
,CompoundDate
,CreatedById
,CreatedTime
,CumulativeInterestAppliedToPrincipal_Amount
,CumulativeInterestAppliedToPrincipal_Currency
,CumulativeInterestBalance_Amount
,CumulativeInterestBalance_Currency
,DisbursementId
,EndNetBookValue_Amount
,EndNetBookValue_Currency
,FloatRateIndexDetailId
,IncomeDate
,InterestAccrualBalance_Amount
,InterestAccrualBalance_Currency
,InterestAccrued_Amount
,InterestAccrued_Currency
,InterestPayment_Amount
,InterestPayment_Currency
,InterestRate
,IsAccounting
,IsGLPosted
,IsLessorOwned
,IsNonAccrual
,IsSchedule
,IsSyndicated
,LoanFinanceId
,Payment_Amount
,Payment_Currency
,PrincipalAdded_Amount
,PrincipalAdded_Currency
,PrincipalRepayment_Amount
,PrincipalRepayment_Currency
,UnroundedInterestAccrued
,TV5InterestAccrualBalance_Amount
,TV5InterestAccrualBalance_Currency)
VALUES (Income.AdjustmentEntry
,Income.BeginNetBookValue
,Income.Currency
,Income.CapitalizedInterest
,Income.Currency
,Income.CompoundDate
,@UserId
,@Time
,Income.CumulativeInterestAppliedToPrincipal
,Income.Currency
,Income.CumulativeInterestBalance
,Income.Currency
,Income.DisbursementId
,Income.EndNetBookValue
,Income.Currency
,Income.FloatRateIndexDetailId
,Income.IncomeDate
,Income.InterestAccrualBalance
,Income.Currency
,Income.InterestAccrued
,Income.Currency
,Income.InterestPayment
,Income.Currency
,Income.InterestRate
,Income.IsAccounting
,Income.IsGLPosted
,Income.IsLessorOwned
,Income.IsNonAccrual
,Income.IsSchedule
,Income.IsSyndicated
,Income.LoanFinanceId
,Income.Payment
,Income.Currency
,Income.PrincipalAdded
,Income.Currency
,Income.PrincipalRepayment
,Income.Currency
,Income.UnroundedInterestAccrued
,Income.TV5InterestAccrualBalance
,Income.Currency);
--OUTPUT INSERTED.Id, Income.MaturityReceivableIdentifier INTO #IncomeScheduleMapping;
--To Persist Loan Payment Schedule
MERGE dbo.LoanPaymentSchedules AS PersistedLoanPayment
USING @PaymentSchedules AS Payment
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (PaymentNumber
,DueDate
,StartDate
,EndDate
,AccrualEndDate
,Amount_Amount
,Amount_Currency
,BeginBalance_Amount
,BeginBalance_Currency
,EndBalance_Amount
,EndBalance_Currency
,Principal_Amount
,Principal_Currency
,Interest_Amount
,Interest_Currency
,PaymentStructure
,PaymentType
,Calculate
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LoanFinanceId
,IsFromReceiptPosting
,CustomerId
,IsPostMaturity
,IsSystemGenerated
--,OriginalPaymentStructure
)
VALUES (Payment.PaymentNumber
,Payment.DueDate
,Payment.StartDate
,Payment.EndDate
,Payment.AccrualEndDate
,Payment.Amount
,Payment.Currency
,Payment.BeginBalance
,Payment.Currency
,Payment.EndBalance
,Payment.Currency
,Payment.Principal
,Payment.Currency
,Payment.Interest
,Payment.Currency
,Payment.PaymentStructure
,Payment.PaymentType
,0
,1
,@UserId
,@Time
,null
,null
,Payment.LoanFinanceId
,0
,payment.CustomerId
,payment.IsPostMaturity
,payment.IsSystemGenerated
--,Payment.PaymentStructure
)
OUTPUT INSERTED.Id, Payment.Identifier INTO #PaymentScheduleMapping;
--To Persist Loan Payment Schedule Histories
MERGE dbo.LoanPaymentScheduleHistories AS PersistedLoanPaymentHistories
USING @PaymentScheduleHistories AS PaymentHistories
JOIN #PaymentScheduleMapping PSM ON PaymentHistories.PaymentScheduleIdentifier = PSM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EndDate
,OriginalPaymentAmount_Amount
,OriginalPaymentAmount_Currency
,OriginalPaymentStructure
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,LoanFinanceId
,LoanPaymentScheduleId
)
VALUES (PaymentHistories.EndDate
,PaymentHistories.OriginalPayment
,PaymentHistories.Currency
,PaymentHistories.OriginalPaymentStructure
,1
,@UserId
,@Time
,null
,null
,PaymentHistories.LoanFinanceId
,PSM.LoanPaymentScheduleId
);
--To Persist Receivables
--Already Persisted Payment Schedule
MERGE dbo.Receivables AS PersistedReceivables
USING (SELECT * FROM @Receivables Where PaymentScheduleId != 0 and PaymentScheduleId is not null) AS receivable
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EntityType
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
,AlternateBillingCurrencyId
,ExchangeRate
,TotalAmount_Amount
,TotalAmount_Currency
,TotalBalance_Amount
,TotalBalance_Currency
,TotalEffectiveBalance_Amount
,TotalEffectiveBalance_Currency
,TotalBookBalance_Amount
,TotalBookBalance_Currency)
VALUES( 'CT'
,receivable.EntityId
,receivable.IsDSL
,receivable.DueDate
,1
,receivable.InvoiceComment
,receivable.InvoiceReceivableGroupingOption
,0
,'_'
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
,receivable.AlternateBillingCurrencyId
,receivable.ExchangeRate
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.TotalBookBalance
,receivable.Currency)
OUTPUT INSERTED.Id, receivable.Identifier INTO #PaymentReceivableMapping;
-- Payment Schedule to Persist in this run
MERGE dbo.Receivables AS PersistedReceivables
USING (SELECT * FROM @Receivables WHERE PaymentScheduleId = 0 and PaymentScheduleId is not null) AS receivable
JOIN #PaymentScheduleMapping PSM ON receivable.PaymentScheduleIdentifier = PSM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EntityType
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
,AlternateBillingCurrencyId
,ExchangeRate
,TotalAmount_Amount
,TotalAmount_Currency
,TotalBalance_Amount
,TotalBalance_Currency
,TotalEffectiveBalance_Amount
,TotalEffectiveBalance_Currency
,TotalBookBalance_Amount
,TotalBookBalance_Currency)
VALUES( 'CT'
,receivable.EntityId
,receivable.IsDSL
,receivable.DueDate
,1
,receivable.InvoiceComment
,receivable.InvoiceReceivableGroupingOption
,0
,'_'
,PSM.LoanPaymentScheduleId
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
,receivable.AlternateBillingCurrencyId
,receivable.ExchangeRate
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.TotalBookBalance
,receivable.Currency)
OUTPUT INSERTED.Id, receivable.Identifier INTO #PaymentReceivableMapping;
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
,[LeaseComponentAmount_Amount]
,[LeaseComponentAmount_Currency]
,[NonLeaseComponentAmount_Amount]
,[NonLeaseComponentAmount_Currency]
,[LeaseComponentBalance_Amount]
,[LeaseComponentBalance_Currency]
,[NonLeaseComponentBalance_Amount]
,[NonLeaseComponentBalance_Currency]
,[PreCapitalizationRent_Amount]
,[PreCapitalizationRent_Currency]
)
SELECT	 Re.ReceivableDetailAmount
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency
,Re.ReceivableDetailEffectiveBalance
,Re.Currency
,1
,'NotInvoiced'
,Re.ReceivableDetailIsTaxAssessed
,@UserId
,@Time
,null
,null
,null
,Re.ReceivableDetailBillToId
,Re.AdjustmentBasisReceivableDetailId
,RM.ReceivableId
,0
,Re.ReceivableDetailEffectiveBookBalance
,Re.Currency
,'_'
,Re.ReceivableDetailAmount
,Re.Currency
,0.00
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency
,0.00
,Re.Currency
,0.00
,Re.Currency
FROM @Receivables Re
JOIN #PaymentReceivableMapping RM ON Re.Identifier = RM.Identifier;
-- To Persist Scrape Receivables For Syndicated Contracts
MERGE dbo.Receivables AS PersistedReceivables
USING (SELECT * FROM @Receivables WHERE PaymentScheduleId is null and PaymentScheduleIdentifier is not null) AS receivable
JOIN #PaymentReceivableMapping PRM ON receivable.SourceIdentifier = PRM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EntityType
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
,AlternateBillingCurrencyId
,ExchangeRate
,TotalAmount_Amount
,TotalAmount_Currency
,TotalBalance_Amount
,TotalBalance_Currency
,TotalEffectiveBalance_Amount
,TotalEffectiveBalance_Currency
,TotalBookBalance_Amount
,TotalBookBalance_Currency)
VALUES( 'CT'
,receivable.EntityId
,receivable.IsDSL
,receivable.DueDate
,1
,receivable.InvoiceComment
,receivable.InvoiceReceivableGroupingOption
,0
,'_'
,null
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
,PRM.ReceivableId
,receivable.SourceTable
,receivable.AlternateBillingCurrencyId
,receivable.ExchangeRate
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.TotalBookBalance
,receivable.Currency)
OUTPUT INSERTED.Id, receivable.Identifier INTO #SyndicationReceivableMapping;
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
,[LeaseComponentAmount_Amount]
,[LeaseComponentAmount_Currency]
,[NonLeaseComponentAmount_Amount]
,[NonLeaseComponentAmount_Currency]
,[LeaseComponentBalance_Amount]
,[LeaseComponentBalance_Currency]
,[NonLeaseComponentBalance_Amount]
,[NonLeaseComponentBalance_Currency]
,[PreCapitalizationRent_Amount]
,[PreCapitalizationRent_Currency]
)
SELECT	 Re.ReceivableDetailAmount
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency
,Re.ReceivableDetailEffectiveBalance
,Re.Currency
,1
,'NotInvoiced'
,Re.ReceivableDetailIsTaxAssessed
,@UserId
,@Time
,null
,null
,null
,Re.ReceivableDetailBillToId
,Re.AdjustmentBasisReceivableDetailId
,RM.ReceivableId
,0
,Re.ReceivableDetailEffectiveBookBalance
,Re.Currency
,'_'
,Re.ReceivableDetailAmount
,Re.Currency
,0.00
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency 
,0.00
,Re.Currency
,0.00
,Re.Currency
FROM @Receivables Re
JOIN #SyndicationReceivableMapping RM ON Re.Identifier = RM.Identifier
WHERE Re.PaymentScheduleId is null and PaymentScheduleIdentifier is not null;
--To persist Interest Receivable post maturity for DSL Contract
MERGE dbo.Receivables AS PersistedReceivables
USING (SELECT * FROM @Receivables Where PaymentScheduleId is null and PaymentScheduleIdentifier is null) AS receivable
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EntityType
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
,AlternateBillingCurrencyId
,ExchangeRate
,TotalAmount_Amount
,TotalAmount_Currency
,TotalBalance_Amount
,TotalBalance_Currency
,TotalEffectiveBalance_Amount
,TotalEffectiveBalance_Currency
,TotalBookBalance_Amount
,TotalBookBalance_Currency
, CalculatedDueDate)
VALUES( 'CT'
,receivable.EntityId
,receivable.IsDSL
,receivable.DueDate
,1
,receivable.InvoiceComment
,receivable.InvoiceReceivableGroupingOption
,0
,'_'
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
,receivable.AlternateBillingCurrencyId
,receivable.ExchangeRate
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.ReceivableAmount
,receivable.Currency
,receivable.TotalBookBalance
,receivable.Currency
,receivable.CalculatedDueDate)
OUTPUT INSERTED.Id, receivable.Identifier INTO #PostMaturityInterestReceivableMapping;
INSERT INTO
ReceivableDetails(
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
,[LeaseComponentAmount_Amount]
,[LeaseComponentAmount_Currency]
,[NonLeaseComponentAmount_Amount]
,[NonLeaseComponentAmount_Currency]
,[LeaseComponentBalance_Amount]
,[LeaseComponentBalance_Currency]
,[NonLeaseComponentBalance_Amount]
,[NonLeaseComponentBalance_Currency]
,[PreCapitalizationRent_Amount]
,[PreCapitalizationRent_Currency]
)
SELECT	 Re.ReceivableDetailAmount
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency
,Re.ReceivableDetailEffectiveBalance
,Re.Currency
,1
,'NotInvoiced'
,Re.ReceivableDetailIsTaxAssessed
,@UserId
,@Time
,null
,null
,null
,Re.ReceivableDetailBillToId
,Re.AdjustmentBasisReceivableDetailId
,PMI.ReceivableId
,0
,Re.ReceivableDetailEffectiveBookBalance
,Re.Currency
,'_'
,Re.ReceivableDetailAmount
,Re.Currency
,0.00
,Re.Currency
,Re.ReceivableDetailBalance
,Re.Currency
,0.00
,Re.Currency
,0.00
,Re.Currency
FROM @Receivables Re
JOIN #PostMaturityInterestReceivableMapping PMI ON Re.Identifier = PMI.Identifier
WHERE Re.PaymentScheduleId is null and Re.PaymentScheduleIdentifier is null;
--To Persist Receivable Sundries
MERGE dbo.Sundries AS PersistedSundries
USING (SELECT * FROM @Sundries WHERE SundryType = 'ReceivableOnly') AS sundry
JOIN #SyndicationReceivableMapping SRM ON sundry.Identifier = SRM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (SundryType
,EntityType
,ReceivableDueDate
,InvoiceComment
,PayableDueDate
,Memo
,IsAssetBased
,Amount_Amount
,Amount_Currency
,IsActive
,IsTaxExempt
,IsServiced
,IsCollected
,IsPrivateLabel
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceivableCodeId
,PayableCodeId
,BillToId
,LegalEntityId
,ContractId
,CustomerId
,VendorId
,ReceivableRemitToId
,PayableRemitToId
,LocationId
,ReceivableId
,CurrencyId
,PayableId
,LineofBusinessId
,InstrumentTypeId
,IsOwned
,IsAssignAtAssetLevel
,IsSystemGenerated
,InvoiceAmendmentType
,Type
,TaxPortionOfPayable_Amount
,TaxPortionOfPayable_Currency
,PayableAmount_Amount
,PayableAmount_Currency
,Status
,CostCenterId
,PayableWithholdingTaxRate
,IsVATAssessed
,CountryId
,ProjectedVATAmount_Amount
,ProjectedVATAmount_Currency
)
VALUES(	 sundry.SundryType
,'CT'
,sundry.ReceivableDueDate
,sundry.InvoiceComment
,sundry.PayableDueDate
,sundry.Memo
,0
,sundry.Amount
,sundry.Currency
,1
,0
,1
,1
,0
,@UserId
,@Time
,null
,null
,sundry.ReceivableCodeId
,sundry.PayableCodeId
,sundry.BillToId
,sundry.LegalEntityId
,sundry.ContractId
,sundry.CustomerId
,sundry.VendorId
,sundry.ReceivableRemitToId
,sundry.PayableRemitToId
,sundry.LocationId
,SRM.ReceivableId
,sundry.CurrencyId
,null
,sundry.LineOfBusinessId
,sundry.InstrumentTypeId
,sundry.IsOwned
,0
,1
,'Credit'
,sundry.Type
,0.00
,sundry.Currency
,0.00
,sundry.Currency
,'Approved'
,sundry.CostCenterId
,ISNULL(sundry.PayableWithholdingTaxRate,0.00)
,0
,NULL
,0.0
,sundry.Currency
);
--To Persist Rental Proceed Payable For Syndicated Contract
MERGE dbo.Payables AS PersistedPayables
USING @Payables AS payable
JOIN #PaymentReceivableMapping PRM ON payable.SourceIdentifier = PRM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (EntityType
,EntityId
,Amount_Amount
,Amount_Currency
,Balance_Amount
,Balance_Currency
,DueDate
,Status
,SourceTable
,SourceId
,InternalComment
,IsGLPosted
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,CurrencyId
,PayableCodeId
,LegalEntityId
,PayeeId
,RemitToId
,TaxPortion_Amount
,TaxPortion_Currency
,WithholdingTaxRate
)
VALUES (payable.EntityType
,payable.EntityId
,payable.Amount
,payable.Currency
,payable.Amount
,payable.Currency
,payable.DueDate
,payable.Status
,payable.SourceTable
,PRM.ReceivableId
,payable.InternalComment
,0
,@UserId
,@Time
,null
,null
,payable.CurrencyId
,payable.PayableCodeId
,payable.LegalEntityId
,payable.PayeeId
,payable.RemitToId
,0.00
,payable.Currency
,payable.WithholdingTaxRate
)
OUTPUT INSERTED.Id, payable.Identifier INTO #PayableMapping;
--To Persist Payable Sundries
MERGE dbo.Sundries AS PersistedSundries
USING (SELECT * FROM @Sundries WHERE SundryType = 'PayableOnly') AS sundry
JOIN #PayableMapping PM ON sundry.Identifier = PM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (SundryType
,EntityType
,ReceivableDueDate
,InvoiceComment
,PayableDueDate
,Memo
,IsAssetBased
,Amount_Amount
,Amount_Currency
,IsActive
,IsTaxExempt
,IsServiced
,IsCollected
,IsPrivateLabel
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,ReceivableCodeId
,PayableCodeId
,BillToId
,LegalEntityId
,ContractId
,CustomerId
,VendorId
,ReceivableRemitToId
,PayableRemitToId
,LocationId
,ReceivableId
,CurrencyId
,PayableId
,LineofBusinessId
,InstrumentTypeId
,IsOwned
,IsAssignAtAssetLevel
,IsSystemGenerated
,InvoiceAmendmentType
,Type
,TaxPortionOfPayable_Amount
,TaxPortionOfPayable_Currency
,PayableAmount_Amount
,PayableAmount_Currency
,Status
,CostCenterId
,PayableWithholdingTaxRate
,IsVATAssessed
,CountryId
,ProjectedVATAmount_Amount
,ProjectedVATAmount_Currency
)
VALUES(sundry.SundryType
,'CT'
,sundry.ReceivableDueDate
,sundry.InvoiceComment
,sundry.PayableDueDate
,sundry.Memo
,0
,sundry.Amount
,sundry.Currency
,1
,0
,1
,1
,0
,@UserId
,@Time
,null
,null
,sundry.ReceivableCodeId
,sundry.PayableCodeId
,sundry.BillToId
,sundry.LegalEntityId
,sundry.ContractId
,sundry.CustomerId
,sundry.VendorId
,sundry.ReceivableRemitToId
,sundry.PayableRemitToId
,sundry.LocationId
,null
,sundry.CurrencyId
,PM.PayableId
,sundry.LineOfBusinessId
,sundry.InstrumentTypeId
,sundry.IsOwned
,0
,1
,'Credit'
,sundry.Type
,0.00
,sundry.Currency
,0.00
,sundry.Currency
,'Approved'
,sundry.CostCenterId
,ISNULL(sundry.PayableWithholdingTaxRate,0.00)
,0
,NULL
,0.0
,Sundry.Currency
);
--To Create Loan Captalized Interest from Amort Job
MERGE dbo.LoanCapitalizedInterests AS PersistedCapitalizedInterests
USING @CaptalizedInterest AS captalizedInterest
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT (Source
,Amount_Amount
,Amount_Currency
,CapitalizedDate
,IsActive
,CreatedById
,CreatedTime
,UpdatedById
,UpdatedTime
,PayableInvoiceOtherCostId
,LoanFinanceId
,GLJournalId
)
VALUES (captalizedInterest.Source
,captalizedInterest.Amount
,captalizedInterest.Currency
,captalizedInterest.CapitalizedDate
,1
,@UserId
,@Time
,null
,null
,captalizedInterest.PayableInvoiceOtherCostId
,captalizedInterest.LoanFinanceId
,null
);
--To Create ACH Schedules from Amort Job
MERGE dbo.ACHSchedules AS PersistedACHSchedules
USING @ACHSchedule AS AchSchedule JOIN #PaymentReceivableMapping PM on AchSchedule.Identifier = PM.Identifier
ON (1 = 0)
WHEN NOT MATCHED THEN
INSERT ([ACHPaymentNumber]
,[PaymentType]
,[ACHAmount_Amount]
,[ACHAmount_Currency]
,[SettlementDate]
,[Status]
,[StopPayment]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[ReceivableId]
,[ACHAccountId]
,[ContractBillingId]
,[IsPreACHNotificationCreated]
,[BankAccountPaymentThresholdId])
VALUES
(AchSchedule.ACHPaymentNumber
,AchSchedule.PaymentType
,AchSchedule.Amount
,AchSchedule.Currency
,AchSchedule.SettlementDate
,AchSchedule.Status
,0
,1
,@UserId
,@Time
,null
,null
,PM.ReceivableId
,AchSchedule.ACHAccountId
,AchSchedule.ContractBillingId
,0
,AchSchedule.BankAccountPaymentThresholdId);
--To Inactivate Invalid Loan Payment Schedules
IF (@PaymentSchedulesToInactivate <> '' AND @PaymentSchedulesToInactivate IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update LoanPaymentSchedules SET IsActive = 0, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @PaymentSchedulesToInactivate + ');';
EXEC(@UpdateQuery);
END
----To Update IsProcessed for FloatRate contracts
IF (@FloatRateIdsToUpdate <> '' AND @FloatRateIdsToUpdate IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update ContractFloatRates SET  IsProcessed = 1, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @FloatRateIdsToUpdate + ');';
EXEC(@UpdateQuery);
END
----To Inactivate Invalid Loan Captalized Interest
IF (@InvalidCapitalizedInterestIds <> '' AND @InvalidCapitalizedInterestIds IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update  LoanCapitalizedInterests SET IsActive = 0, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @InvalidCapitalizedInterestIds + ');';
EXEC(@UpdateQuery);
END
--To Update Effective Book Balance in Receivables for Non Accrual
IF (@ReceivablesTotalBookBalanceToUpdate <> '' AND @ReceivablesTotalBookBalanceToUpdate IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update Receivables SET TotalBookBalance_Amount = 0.00, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @ReceivablesTotalBookBalanceToUpdate + ');';
SET @UpdateQuery = @UpdateQuery + 'Update ReceivableDetails SET EffectiveBookBalance_Amount = 0.00, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where ReceivableId in (' + @ReceivablesTotalBookBalanceToUpdate + ');';
EXEC(@UpdateQuery);
END
--To Update Payment Schedule generation flag for validation on Restructure Approval to Regenerate the Payment schedule
IF (@PaymentSheculeGeneratedFlagToUpdate <> '' AND @PaymentSheculeGeneratedFlagToUpdate IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update  LoanFinances SET IsPricingParametersChanged = 1, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @PaymentSheculeGeneratedFlagToUpdate + ');';
EXEC(@UpdateQuery);
EXEC(@UpdateQuery);
END
--To Update Payment Schedule generation flag for validation on Paydown Activation to Regenerate the Payment schedule
IF (@PaymentSheculeGeneratedFlagToUpdateInPaydown <> '' AND @PaymentSheculeGeneratedFlagToUpdateInPaydown IS NOT NULL)
BEGIN
SET @UpdateQuery = 'Update  LoanPaydowns SET IsPaymentScheduleGenerated = 0,IsPaymentModified = 1, UpdatedById = ' + CAST(@UserId As nvarchar(max)) + ', UpdatedTime = ''' + CAST(@Time As nvarchar(max)) + ''' Where Id in (' + @PaymentSheculeGeneratedFlagToUpdateInPaydown + ');';
EXEC(@UpdateQuery);
EXEC(@UpdateQuery);
END
--To Update LoanPaymentSchedule Amount
MERGE dbo.LoanPaymentSchedules AS PaymentSchedulesToUpdate
USING @PaymentSchedulesToUpdate AS PaymentSchedulesIdsToUpdate
ON (PaymentSchedulesToUpdate.Id = PaymentSchedulesIdsToUpdate.PaymentScheduleId)
WHEN MATCHED THEN
UPDATE SET BeginBalance_Amount = PaymentSchedulesIdsToUpdate.BeginBalance
,EndBalance_Amount = PaymentSchedulesIdsToUpdate.EndBalance
,Principal_Amount = PaymentSchedulesIdsToUpdate.Principal
,Interest_Amount = PaymentSchedulesIdsToUpdate.Interest
,Amount_Amount = PaymentSchedulesIdsToUpdate.Amount
,PaymentStructure = PaymentSchedulesIdsToUpdate.PaymentStructure
,UpdatedById = @UserId
,UpdatedTime = @Time;
--To Update Receivable Id in Income Schedules for Income Schedules Beyond maturity Date
--MERGE dbo.LoanIncomeSchedules AS IncomeSchedulesToUpdate
--USING (Select Id , #PostMaturityInterestReceivableMapping.ReceivableId , #IncomeScheduleMapping.IncomeScheduleId From LoanIncomeSchedules
--JOIN #IncomeScheduleMapping ON LoanIncomeSchedules.Id = #IncomeScheduleMapping.IncomeScheduleId
--JOIN #PostMaturityInterestReceivableMapping on #IncomeScheduleMapping.Identifier = #PostMaturityInterestReceivableMapping.Identifier) AS IncomeSchedulesIdsToUpdate
-- ON IncomeSchedulesToUpdate.Id = IncomeSchedulesIdsToUpdate.IncomeScheduleId
--WHEN MATCHED THEN
--	UPDATE SET IncomeSchedulesToUpdate.ReceivableId = IncomeSchedulesIdsToUpdate.ReceivableId;
-- To Inactivate BlendedIncome Schedule for Reaccrual amort job
MERGE dbo.BlendedIncomeSchedules AS PersistedBlendedIncome
USING @BlendedIncomeToInactivate AS BlendedIncomeToUpdate
ON (PersistedBlendedIncome.Id = BlendedIncomeToUpdate.BlendedIncomeScheduleId)
WHEN MATCHED THEN
UPDATE SET IsAccounting = BlendedIncomeToUpdate.IsAccounting
,IsSchedule = 0
,UpdatedById = @UserId
,UpdatedTime = @Time;
-- To Update the Blended Item Current Date when Float Rate Amort Option is Adjust Term
MERGE dbo.BlendedItems AS PersistedBlendedItem
USING @BlendedItemToUpdate AS BlendedItemToUpdate
ON (PersistedBlendedItem.Id = BlendedItemToUpdate.BlendedItemId)
WHEN MATCHED THEN
UPDATE SET CurrentEndDate = BlendedItemToUpdate.CurrentEndDate
,EndDate = BlendedItemToUpdate.EndDate
,UpdatedById = @UserId
,UpdatedTime = @Time;
/* Payables needed to Create DR */
Select PayableId,Identifier From #PayableMapping
DROP TABLE #PaymentScheduleMapping
DROP TABLE #PaymentReceivableMapping
DROP TABLE #SyndicationReceivableMapping
DROP TABLE #PayableMapping
END

GO
