SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetCollectionWorkListContractDetails]
(
@ContractId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #ContractDetails
(
ContractId BIGINT PRIMARY KEY,
IsReportableDelinquency Bit
)
CREATE TABLE #CollectionWorkListContractDetails
(
ContractId BIGINT INDEX CollectionWorkListContractDetails_IX_ContractId NONCLUSTERED,
TotalOutstandingBalance_Amount decimal(18,2),
TotalReportableBalance_Amount  decimal(18,2),
OpenBalance decimal(18,2),
PastDueAmount decimal(18,2),
UninvoicedTotalBalance decimal(18,2),
RNIDate DateTime,
RNIAmount decimal(18,2),
RNIIncomeDate DATETIME INDEX CollectionWorkListContractDetails_RNIIncomeDate_IX NONCLUSTERED
)
CREATE TABLE #ContractReceivableDetails
(
ContractId BIGINT INDEX ContractReceivableDetails_ContractId_IX NONCLUSTERED,
Receivables_DueDate DATETIME,
Receivables_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableDetails_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableTaxDetails_EffectiveBalance_Amount DECIMAL(18,2),
ContractType NVARCHAR(15),
ReceivableInvoices_DueDate DATETIME,
BilledStatus NVARCHAR(15),
LeasePaymentType NVARCHAR(30),
LoanPaymentType NVARCHAR(30),
ReceivableInvoiceDetails_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableInvoiceDetails_EffectiveTaxBalance_Amount DECIMAL(18,2),
UpdatedTime DATETIME,
RNIAmount DECIMAL(18,2),
RNIIncomeDate DATETIME INDEX ContractReceivableDetails_RNIIncomeDate_IX NONCLUSTERED
)
INSERT INTO #ContractDetails
(
ContractId,
IsReportableDelinquency
)
SELECT
contracts.Id,
contracts.IsReportableDelinquency
FROM
Contracts
WHERE
contracts.Id=@ContractId
INSERT INTO #ContractReceivableDetails
(
ContractId,
Receivables_DueDate,
Receivables_EffectiveBalance_Amount,
ReceivableDetails_EffectiveBalance_Amount,
ReceivableTaxDetails_EffectiveBalance_Amount,
ContractType,
ReceivableInvoices_DueDate,
BilledStatus,
LeasePaymentType,
LoanPaymentType,
ReceivableInvoiceDetails_EffectiveBalance_Amount,
ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,
UpdatedTime,
RNIAmount,
RNIIncomeDate
)
SELECT
Contracts.Id AS ContractId,
Receivables.DueDate AS Receivables_DueDate,
ISNULL(Receivables.TotalEffectiveBalance_Amount,0) AS Receivables_EffectiveBalance_Amount,
ISNULL(ReceivableDetails.EffectiveBalance_Amount,0) AS ReceivableDetails_EffectiveBalance_Amount,
ISNULL(ReceivableTaxDetails.EffectiveBalance_Amount,0) AS ReceivableTaxDetails_EffectiveBalance_Amount,
Contracts.ContractType AS ContractType,
ReceivableInvoices.DueDate AS ReceivableInvoices_DueDate,
ReceivableDetails.BilledStatus AS BilledStatus,
LeasePaymentSchedules.PaymentType AS LeasePaymentType,
LoanPaymentSchedules.PaymentType AS LoanPaymentType,
ISNULL(ReceivableInvoiceDetails.EffectiveBalance_Amount,0) AS ReceivableInvoiceDetails_EffectiveBalance_Amount,
ISNULL(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount,0) ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,
ISNULL(RemainingNetInvestments.UpdatedTime,RemainingNetInvestments.CreatedTime) UpdatedTime,
ISNULL(RemainingNetInvestments.RNIAmount_Amount,0) RNIAmount,
RemainingNetInvestments.IncomeDate
FROM
#ContractDetails
INNER JOIN Contracts
ON #ContractDetails.ContractId = Contracts.Id
INNER JOIN Receivables
ON Contracts.Id = Receivables.EntityId
INNER JOIN ReceivableDetails
ON Receivables.Id = ReceivableDetails.ReceivableId
LEFT JOIN RemainingNetInvestments
ON Contracts.Id=RemainingNetInvestments.ContractId
AND RemainingNetInvestments.IsActive=1
LEFT JOIN LeasePaymentSchedules
ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
AND LeasePaymentSchedules.IsActive=1
LEFT JOIN LoanPaymentSchedules
ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
AND LoanPaymentSchedules.IsActive=1
LEFT JOIN ReceivableTaxDetails
ON ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId
AND ReceivableTaxDetails.IsActive=1
LEFT JOIN ReceivableInvoiceDetails
ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
AND ReceivableInvoiceDetails.IsActive=1
LEFT JOIN ReceivableInvoices
ON ReceivableInvoiceDetails.ReceivableInvoiceId=ReceivableInvoices.Id
WHERE
Receivables.EntityType = 'CT'
AND Receivables.EntityId = #ContractDetails.ContractId
AND Receivables.IsActive = 1
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance,
RNIDate,
RNIAmount,
RNIIncomeDate
)
SELECT TOP 1
#ContractDetails.ContractId,
CASE
WHEN SUM(ISNULL(#ContractReceivableDetails.ReceivableDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount,0)) <> 0
THEN SUM(#ContractReceivableDetails.Receivables_EffectiveBalance_Amount + #ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount )
ELSE 0
END TotalOutstandingBalance_Amount,
0.0,
0.0,
0.0,
0.0,
MAX(UpdatedTime) AS RNIDate,
MAX(ISNULL(RNIAmount,0))	AS RNIAmount,
(RNIIncomeDate)
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
WHERE
Receivables_DueDate < GETDATE()
AND (#ContractReceivableDetails.ContractType='Lease' AND LeasePaymentType IN ('InterimInterest','InterimRent','FixedTerm' )
OR ((#ContractReceivableDetails.ContractType='Loan'OR #ContractReceivableDetails.ContractType='ProgressLoan')AND LoanPaymentType IN ('Interim','FixedTerm' )))
GROUP BY
#ContractDetails.ContractId
,#ContractReceivableDetails.RNIIncomeDate
--HAVING
--	RNIIncomeDate=MAX(RNIIncomeDate)
ORDER BY
#ContractReceivableDetails.RNIIncomeDate DESC
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance,
RNIDate,
RNIAmount,
RNIIncomeDate
)
SELECT TOP 1
#ContractDetails.ContractId ContractId,
0.0,
CASE
WHEN SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0)) <> 0
THEN SUM(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount)
ELSE 0
END TotalOutstandingBalance_Amount,
0.0,
0.0,
0.0,
MAX(UpdatedTime) AS RNIDate,
MAX(ISNULL(RNIAmount,0))	AS RNIAmount,
RNIIncomeDate
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
WHERE
#ContractDetails.IsReportableDelinquency=1
AND Receivables_DueDate < GETDATE()
AND BilledStatus='Invoiced'
AND (ContractType='Lease' AND LeasePaymentType IN ('InterimInterest','InterimRent','FixedTerm','OTP' )
OR ((#ContractReceivableDetails.ContractType='Loan'OR #ContractReceivableDetails.ContractType='ProgressLoan')AND LoanPaymentType IN ('Interim','FixedTerm' )))
GROUP BY
#ContractDetails.ContractId,
#ContractReceivableDetails.RNIIncomeDate
--HAVING
--	RNIIncomeDate=MAX(RNIIncomeDate)
ORDER BY
#ContractReceivableDetails.RNIIncomeDate DESC
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance,
RNIDate,
RNIAmount,
RNIIncomeDate
)
SELECT TOP 1
#ContractDetails.ContractId ContractId,
0.0,
0.0,
CASE
WHEN SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0)+ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,0)) <> 0
THEN SUM(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount+#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount)
ELSE 0
END TotalOutstandingBalance_Amount,
0.0,
0.0,
MAX(UpdatedTime) AS RNIDate,
MAX(ISNULL(RNIAmount,0))	AS RNIAmount,
RNIIncomeDate
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
WHERE BilledStatus='Invoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId,
#ContractReceivableDetails.RNIIncomeDate
--HAVING
--	RNIIncomeDate=MAX(RNIIncomeDate)
ORDER BY
#ContractReceivableDetails.RNIIncomeDate DESC
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance,
RNIDate,
RNIAmount,
RNIIncomeDate
)
SELECT TOP 1
#ContractDetails.ContractId ContractId,
0.0,
0.0,
0.0,
CASE
WHEN SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,0)) <> 0
THEN SUM(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount + #ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount)
ELSE 0
END TotalOutstandingBalance_Amount,
0.0,
MAX(UpdatedTime) AS RNIDate,
MAX(ISNULL(RNIAmount,0))	AS RNIAmount,
RNIIncomeDate
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
WHERE
ReceivableInvoices_DueDate < GETDATE()
AND BilledStatus='Invoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId,
#ContractReceivableDetails.RNIIncomeDate
--HAVING
--	RNIIncomeDate=MAX(RNIIncomeDate)
ORDER BY
#ContractReceivableDetails.RNIIncomeDate DESC
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance,
RNIDate,
RNIAmount,
RNIIncomeDate
)
SELECT TOP 1
#ContractDetails.ContractId ContractId,
0.0,
0.0,
0.0,
0.0,
CASE
WHEN SUM(ISNULL(#ContractReceivableDetails.ReceivableDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount,0)) <> 0
THEN SUM(#ContractReceivableDetails.ReceivableDetails_EffectiveBalance_Amount + #ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount)
ELSE 0
END TotalOutstandingBalance_Amount,
MAX(UpdatedTime) AS RNIDate,
MAX(ISNULL(RNIAmount,0))	AS RNIAmount,
RNIIncomeDate
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
WHERE
BilledStatus='NotInvoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId,
#ContractReceivableDetails.RNIIncomeDate
--HAVING
--	RNIIncomeDate=MAX(RNIIncomeDate)
ORDER BY
#ContractReceivableDetails.RNIIncomeDate DESC
SELECT
#CollectionWorkListContractDetails.ContractId,
SUM(TotalOutstandingBalance_Amount) AS TotalOutstandingBalance_Amount,
SUM(TotalReportableBalance_Amount) AS TotalReportableBalance_Amount,
SUM(OpenBalance) AS OpenBalance,
SUM(PastDueAmount) AS PastDueAmount,
SUM(UninvoicedTotalBalance) AS UninvoicedTotalBalance,
MAX(RNIDate) AS RNIDate,
MAX(RNIAmount) AS RNIAmount
FROM
#CollectionWorkListContractDetails
GROUP BY
#CollectionWorkListContractDetails.ContractId
DROP TABLE #ContractDetails
DROP TABLE #CollectionWorkListContractDetails
DROP TABLE #ContractReceivableDetails
END

GO
