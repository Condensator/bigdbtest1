SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[LoanProfileReport]
(
@SequenceNumber nvarchar(max) = NULL
)
AS
--Declare @SequenceNumber nvarchar(200)
--set @SequenceNumber = '192-3'
BEGIN
;With CTE_RegularPaymentAmount As
(
Select Amount_Amount [NumberOfToalPayaments] from LoanPaymentSchedules
Inner Join LoanFinances On
LoanFinances.Id = LoanPaymentSchedules.LoanFinanceId
Inner Join Contracts On
Contracts.Id = LoanFinances.ContractId
Where LoanPaymentSchedules.IsActive = 1 And LoanPaymentSchedules.PaymentType = 'FixedTerm'
And LoanPaymentSchedules.PaymentNumber != LoanFinances.NumberOfPayments
And Contracts.SequenceNumber = @SequenceNumber
group by Amount_Amount
)
Select
Contracts.SequenceNumber,
Contracts.Alias,
Parties.PartyNumber 'Customer #',
Parties.PartyName 'Customer Name',
LineofBusinesses.Name 'Line of Businesses',
LegalEntities.Name 'LegalEntities',
LoanFinances.Status 'Loan Status',
Contracts.IsNonAccrual 'Non Accrual',
Contracts.ChargeOffStatus 'ChargeOff Status',
Case when Contracts.SyndicationType = 'FullSale' then Contracts.SyndicationType else ' ' end 'Syndication Type',
case when OriginationSourceTypes.Name = 'Vendor' then OriginationSourceTypes.Name else ' ' end 'Origination Type',
LoanFinances.HoldingStatus 'Holding Status',
LoanFinances.CommencementDate 'Commencement Date',
LoanFinances.MaturityDate 'Maturity Date',
LoanFinances.NumberOfPayments 'No. of Payments',
LoanFinances.Term,
LoanFinances.DayCountConvention 'Day Count Convention',
LoanFinances.PaymentFrequency 'Payment Frequency',
LoanFinances.CompoundingFrequency 'Compounding Frequency',
LoanFinances.InterimDayCountConvention 'Interim Day Count Convention',
LoanFinances.InterimFrequency 'Interim Payment Frequency',
LoanFinances.InterimCompoundingFrequency 'Interim Compounding Frequency',
LoanFinances.LoanAmount_Amount 'Loan Amount',
InterestRateDetails.EffectiveDate 'Effective Date',
FloatRateIndexes.Name 'Float Rate Index',
InterestRateDetails.BaseRate 'Base Rate',
InterestRateDetails.Spread 'Spread',
InterestRateDetails.FloorPercent 'Floor %',
InterestRateDetails.CeilingPercent 'Ceiling %',
InterestRateDetails.CompoundingFrequency 'Interest Rate Compounding Frequency',
Case When (Select Count(*) From CTE_RegularPaymentAmount) = 1 Then (Select NumberOfToalPayaments From CTE_RegularPaymentAmount) Else 0 End [RegularPaymentAmount],
Case When LoanFinances.IsAdvance = 1 Then 'Advance' Else 'Arrear' End 'Advance/Arrear'
From Contracts
Inner Join LoanFinances on
Contracts.Id = LoanFinances.ContractId
And LoanFinances.IsCurrent = 1
Inner join Parties on
LoanFinances.CustomerId = Parties.Id
Inner Join LineofBusinesses on
LineofBusinesses.Id = Contracts.LineofBusinessId
And LineofBusinesses.IsActive = 1
Inner Join LegalEntities on
LoanFinances.LegalEntityId = LegalEntities.Id
Left Join ContractOriginations on
LoanFinances.ContractOriginationId = ContractOriginations.Id
Left Join OriginationSourceTypes on
ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
And OriginationSourceTypes.IsActive = 1
Left Join LoanInterestRates on
LoanFinances.id = LoanInterestRates.LoanFinanceId
Left Join InterestRateDetails on
LoanInterestRates.InterestRateDetailId = InterestRateDetails.Id
And InterestRateDetails.IsActive = 1
Left Join FloatRateIndexes on
InterestRateDetails.FloatRateIndexId = FloatRateIndexes.Id
And FloatRateIndexes.IsActive = 1
Where (Contracts.ContractType = 'Loan' or Contracts.ContractType = 'ProgressLoan')
And LoanFinances.Status != 'Inactive' And (@SequenceNumber IS NOT NULL and Contracts.SequenceNumber = @SequenceNumber)
END
EXEC [LoanProfileReport] @SequenceNumber

GO
