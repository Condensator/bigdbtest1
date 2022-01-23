SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetPaymentStreamsForEIPOutBoundInterface]
AS
BEGIN
SET NOCOUNT ON;
WITH CTE_RentalCashForLeveragedLeaseAmorts AS
(
SELECT
ContractId=Contracts.Id,
RentalCashAmount=SUM(RentalCash_Amount)
FROM
Contracts
INNER JOIN LeveragedLeases ON LeveragedLeases.ContractId=Contracts.Id
AND LeveragedLeases.Status='Commenced' AND LeveragedLeases.IsCurrent=1
INNER JOIN LeveragedLeaseAmorts ON LeveragedLeaseAmorts.LeveragedLeaseId=LeveragedLeases.Id AND LeveragedLeaseAmorts.IsActive=1
WHERE LeveragedLeaseAmorts.ResidualIncome_Amount>0
GROUP BY Contracts.Id
),
CTE_ResidualBookedForLeveragedLeaseAmorts AS
(
SELECT
ContractId=Contracts.Id,
IncomeDate=LeveragedLeaseAmorts.IncomeDate,
ResidualBooked=LeveragedLeaseAmorts.ResidualIncome_Amount-LeveragedLeaseAmorts.UnearnedIncome_Amount
FROM
Contracts
INNER JOIN LeveragedLeases ON LeveragedLeases.ContractId=Contracts.Id
AND LeveragedLeases.Status='Commenced' AND LeveragedLeases.IsCurrent=1
INNER JOIN LeveragedLeaseAmorts ON LeveragedLeaseAmorts.LeveragedLeaseId=LeveragedLeases.Id AND LeveragedLeaseAmorts.IsActive=1
WHERE LeveragedLeaseAmorts.ResidualIncome_Amount>0
),
CTE_PaymentRecords AS
(
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='CL',
PaymentDate=CONVERT(NVARCHAR,LeasePaymentSchedules.DueDate,101),
PaymentAmount=LeasePaymentSchedules.Amount_Amount,
IsAdvancePayment=CONVERT(nvarchar,Case
When LeaseFinanceDetails.CommencementDate=LeasePaymentSchedules.DueDate
THEN 1
ELSE 0
END),
InterestAmount=Case
When LeaseFinanceDetails.ClassificationContractType!='Operating'
THEN LeasePaymentSchedules.ReceivableAdjustmentAmount_Amount
ELSE 0.0
END,
LeaseInterest=LeasePaymentSchedules.Interest_Amount
FROM
Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND Contracts.Status='Commenced'
INNER JOIN LeasePaymentSchedules ON LeaseFinances.Id=LeasePaymentSchedules.LeaseFinanceDetailId
AND LeaseFinances.BookingStatus='Commenced' AND LeaseFinances.IsCurrent=1 AND LeasePaymentSchedules.IsActive=1
INNER JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id=LeasePaymentSchedules.LeaseFinanceDetailId AND LeaseFinanceDetails.IsOverTermLease=0
AND LeasePaymentSchedules.Amount_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='CL',
PaymentDate=CONVERT(NVARCHAR,LoanPaymentSchedules.DueDate,101),
PaymentAmount=LoanPaymentSchedules.Amount_Amount,
IsAdvancePayment=CONVERT(nvarchar,Case
When LoanFinances.CommencementDate=LoanPaymentSchedules.DueDate
THEN 1
ELSE 0
END),
InterestAmount=LoanPaymentSchedules.Interest_Amount,
LeaseInterest=LoanPaymentSchedules.Interest_Amount
FROM
Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
AND Contracts.Status='Commenced' AND LoanFinances.IsCurrent=1
INNER JOIN LoanPaymentSchedules ON LoanFinances.Id=LoanPaymentSchedules.LoanFinanceId
AND LoanFinances.Status='Commenced' AND LoanFinances.IsCurrent=1 AND LoanPaymentSchedules.IsActive=1
AND LoanPaymentSchedules.Amount_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='DT',
PaymentDate=CONVERT(NVARCHAR,DeferredTaxes.Date,101),
PaymentAmount=DeferredTaxes.TaxableIncomeTax_Amount,
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
FROM
Contracts
INNER JOIN DeferredTaxes ON DeferredTaxes.ContractId=Contracts.Id AND Contracts.Status='Commenced'
WHERE DeferredTaxes.TaxableIncomeTax_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='DF',
PaymentDate=CONVERT(NVARCHAR,PayableInvoices.DueDate,101),
PaymentAmount=PayableInvoices.InvoiceTotal_Amount,
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
FROM
Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND LeaseFinances.BookingStatus='Commenced'
INNER JOIN LeaseFundings ON LeaseFinances.Id=LeaseFundings.LeaseFinanceId
AND LeaseFinances.BookingStatus='Commenced' AND LeaseFinances.IsCurrent=1 AND LeaseFundings.IsActive=1
INNER JOIN PayableInvoices ON PayableInvoices.Id=LeaseFundings.FundingId AND PayableInvoices.Status='Completed'
INNER JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id=LeaseFinances.Id AND LeaseFinanceDetails.IsOverTermLease=0
WHERE PayableInvoices.InvoiceTotal_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='DF',
PaymentDate=CONVERT(NVARCHAR,PayableInvoices.DueDate,101),
PaymentAmount=PayableInvoices.InvoiceTotal_Amount,
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
FROM
Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
AND LoanFinances.Status='Commenced' AND LoanFinances.IsCurrent=1
INNER JOIN LoanFundings ON LoanFinances.Id=LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1
INNER JOIN PayableInvoices ON PayableInvoices.Id=LoanFundings.FundingId AND PayableInvoices.Status='Completed'
WHERE PayableInvoices.InvoiceTotal_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='LI',
PaymentDate=CONVERT(NVARCHAR,LeveragedLeaseAmorts.IncomeDate,101),
PaymentAmount=LeveragedLeaseAmorts.PreTaxIncome_Amount,
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
FROM
Contracts
INNER JOIN LeveragedLeases ON LeveragedLeases.ContractId=Contracts.Id
AND LeveragedLeases.Status='Commenced' AND LeveragedLeases.IsCurrent=1
INNER JOIN LeveragedLeaseAmorts ON LeveragedLeaseAmorts.LeveragedLeaseId=LeveragedLeases.Id AND LeveragedLeaseAmorts.IsActive=1
WHERE LeveragedLeaseAmorts.PreTaxIncome_Amount>0
UNION ALL
SELECT
LeaseNumber=Contracts.SequenceNumber,
RecordType='LB',
PaymentDate=CONVERT(NVARCHAR,CTE_ResidualBookedForLeveragedLeaseAmorts.IncomeDate,101),
PaymentAmount=ISNULL(IsNULL(CTE_RentalCashForLeveragedLeaseAmorts.RentalCashAmount,0.0)+IsNULL(CTE_ResidualBookedForLeveragedLeaseAmorts.ResidualBooked,0.0),0.0),
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
FROM
Contracts
INNER JOIN LeveragedLeases ON LeveragedLeases.ContractId=Contracts.Id
AND LeveragedLeases.Status='Commenced' AND LeveragedLeases.IsCurrent=1
LEFT JOIN CTE_RentalCashForLeveragedLeaseAmorts ON CTE_RentalCashForLeveragedLeaseAmorts.ContractId=Contracts.Id
LEFT JOIN CTE_ResidualBookedForLeveragedLeaseAmorts ON CTE_ResidualBookedForLeveragedLeaseAmorts.ContractId=Contracts.Id
WHERE (CTE_RentalCashForLeveragedLeaseAmorts.RentalCashAmount+CTE_ResidualBookedForLeveragedLeaseAmorts.ResidualBooked)>0
UNION ALL
Select
LeaseNumber=Contracts.SequenceNumber,
RecordType='VS',
PaymentDate=CONVERT(NVARCHAR,Sundries.ReceivableDueDate,101),
PaymentAmount=Receivables.TotalAmount_Amount,
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
from Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id AND LeaseFinances.IsCurrent=1 AND LeaseFinances.BookingStatus='Commenced'
INNER JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id=LeaseFinances.Id AND LeaseFinanceDetails.IsOverTermLease=0
INNER JOIN Receivables ON Contracts.Id=Receivables.EntityId AND Receivables.EntityType='CT' AND Receivables.IsActive=1
INNER JOIN Sundries ON Receivables.Id=Sundries.ReceivableId AND Sundries.IsActive=1
INNER JOIN BlendedIncomeSchedules ON BlendedIncomeSchedules.LeaseFinanceId=LeaseFinances.Id AND BlendedIncomeSchedules.IsAccounting=1
INNER JOIN BlendedItems ON BlendedItems.Id=BlendedIncomeSchedules.BlendedItemId AND BlendedItems.IsActive=1
INNER JOIN BlendedItemCodes ON BlendedItemCodes.Id=BlendedItems.BlendedItemCodeId AND BlendedItemCodes.IsVendorSubsidy=1
WHERE  Receivables.TotalAmount_Amount>0
UNION ALL
Select
LeaseNumber=Contracts.SequenceNumber,
RecordType='OD',
PaymentDate=CONVERT(NVARCHAR,BookDepreciations.BeginDate,101),
PaymentAmount=ISNULL(BookDepreciations.CostBasis_Amount,0.0),
IsAdvancePayment='0',
InterestAmount=0.0,
LeaseInterest=0.0
from Contracts
INNER JOIN BookDepreciations ON BookDepreciations.ContractId=Contracts.Id
AND BookDepreciations.IsInOTP=0
AND BookDepreciations.IsActive=1
AND Contracts.Status='Commenced'
WHERE  BookDepreciations.CostBasis_Amount>0
)
SELECT
LeaseNumber,
RecordType,
PaymentDate,
PaymentAmount,
IsAdvancePayment,
InterestAmount,
LeaseInterest
FROM
CTE_PaymentRecords
ORDER BY LeaseNumber,RecordType
END

GO
