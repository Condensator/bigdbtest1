SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateCollectionWorkListContractDetails]
(
@CustomerIds CustomerDetail READONLY,
@UpdatedUserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #CustomerDetails
(
CustomerId BIGINT PRIMARY KEY
)
CREATE TABLE #ContractDetails
(
ContractId BIGINT,
CustomerId BIGINT,
IsReportableDelinquency Bit
)
CREATE TABLE #CollectionWorkListContractDetails
(
ContractId BIGINT INDEX CollectionWorkListContractDetails_IX_ContractId NONCLUSTERED,
CustomerId BIGINT,
TotalOutstandingBalance_Amount decimal(18,2),
TotalReportableBalance_Amount  decimal(18,2),
OpenBalance decimal(18,2),
PastDueAmount decimal(18,2),
UninvoicedTotalBalance decimal(18,2)
)
CREATE TABLE #CollectionWorkListFinalDetails
(
ContractId BIGINT INDEX CollectionWorkListFinalDetails_IX_ContractId NONCLUSTERED,
CustomerId BIGINT,
TotalOutstandingBalance_Amount decimal(18,2),
TotalReportableBalance_Amount  decimal(18,2),
OpenBalance decimal(18,2),
PastDueAmount decimal(18,2),
UninvoicedTotalBalance decimal(18,2),
RowNumber BIGINT
)
CREATE TABLE #ContractReceivableDetails
(
ContractId BIGINT INDEX ContractReceivableDetails_IX_ContractId NONCLUSTERED,
CustomerId BIGINT,
Receivables_DueDate DATETIME,
Receivables_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableDetails_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableTaxDetails_EffectiveBalance_Amount DECIMAL(18,2),
ContractType NVARCHAR(25),
ReceivableInvoices_DueDate DATETIME,
BilledStatus NVARCHAR(25),
LeasePaymentType NVARCHAR(30),
LoanPaymentType NVARCHAR(30),
ReceivableInvoiceDetails_EffectiveBalance_Amount DECIMAL(18,2),
ReceivableInvoiceDetails_EffectiveTaxBalance_Amount DECIMAL(18,2),
UpdatedTime DATETIME
)
INSERT INTO #CustomerDetails
(
CustomerId
)
SELECT
CustomerId
FROM @CustomerIds;
INSERT INTO #ContractDetails
(
ContractId,
CustomerId,
IsReportableDelinquency
)
SELECT
contracts.Id,
LeaseFinances.CustomerId,
Contracts.IsReportableDelinquency
FROM
#CustomerDetails
INNER JOIN  LeaseFinances
ON LeaseFinances.CustomerId = #CustomerDetails.CustomerId
AND LeaseFinances.IsCurrent = 1
INNER JOIN Contracts
ON Contracts.Id = LeaseFinances.ContractId
INNER JOIN CollectionWorkListContractDetails
ON Contracts.Id = CollectionWorkListContractDetails.ContractId
INNER JOIN CollectionWorkLists
ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
AND LeaseFinances.CustomerId = CollectionWorkLists.CustomerId
WHERE
contracts.Status NOT IN ('Cancelled','Terminated''Inactive')
AND CollectionWorkLists.Status='Open'
GROUP BY
contracts.Id,
LeaseFinances.CustomerId,
IsReportableDelinquency
UNION ALL
SELECT
contracts.Id,
LoanFinances.CustomerId,
Contracts.IsReportableDelinquency
FROM
#CustomerDetails
INNER JOIN  LoanFinances
ON LoanFinances.CustomerId = #CustomerDetails.CustomerId
AND LoanFinances.IsCurrent = 1
INNER JOIN Contracts
ON Contracts.Id = LoanFinances.ContractId
INNER JOIN CollectionWorkListContractDetails
ON Contracts.Id = CollectionWorkListContractDetails.ContractId
INNER JOIN CollectionWorkLists
ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
AND LoanFinances.CustomerId = CollectionWorkLists.CustomerId
WHERE
contracts.Status NOT IN ('Cancelled','Terminated''Inactive')
AND CollectionWorkLists.Status ='Open'
GROUP BY
contracts.Id,
LoanFinances.CustomerId,
IsReportableDelinquency
UNION ALL
SELECT
Contracts.Id,
#CustomerDetails.CustomerId,
Contracts.IsReportableDelinquency
FROM
#CustomerDetails
INNER JOIN Assumptions
ON Assumptions.OriginalCustomerId = #CustomerDetails.CustomerId
AND Assumptions.Status = 'Approved'
INNER JOIN Contracts
ON Contracts.Id = Assumptions.ContractId
AND Contracts.Status Not In('Cancelled','Inactive','Terminated')
GROUP BY
Contracts.Id,
#CustomerDetails.CustomerId,
Contracts.IsReportableDelinquency
INSERT INTO #ContractReceivableDetails
(
ContractId,
CustomerId,
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
ReceivableInvoiceDetails_EffectiveTaxBalance_Amount
)
SELECT
Contracts.Id AS ContractId,
#ContractDetails.CustomerId,
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
ISNULL(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount,0) ReceivableInvoiceDetails_EffectiveTaxBalance_Amount
FROM
#ContractDetails
INNER JOIN Contracts
ON #ContractDetails.ContractId = Contracts.Id
INNER JOIN Receivables
ON #ContractDetails.ContractId = Receivables.EntityId
AND #ContractDetails.CustomerId = Receivables.CustomerId
INNER JOIN ReceivableDetails
ON Receivables.Id = ReceivableDetails.ReceivableId
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
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#ContractDetails.ContractId,
#ContractDetails.CustomerId,
SUM(ISNULL(#ContractReceivableDetails.ReceivableDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount,0)),
0.0,
0.0,
0.0,
0.0
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
AND #ContractReceivableDetails.CustomerId = #ContractDetails.CustomerId
WHERE
Receivables_DueDate < GETDATE()
AND (#ContractReceivableDetails.ContractType='Lease' AND LeasePaymentType IN ('InterimInterest','InterimRent','FixedTerm' )
OR ((#ContractReceivableDetails.ContractType='Loan'OR #ContractReceivableDetails.ContractType='ProgressLoan')AND LoanPaymentType IN ('Interim','FixedTerm' )))
GROUP BY
#ContractDetails.ContractId
,#ContractDetails.CustomerId
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#ContractDetails.ContractId ContractId,
#ContractDetails.CustomerId,
0.0,
SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0)),
0.0,
0.0,
0.0
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
AND #ContractReceivableDetails.CustomerId = #ContractDetails.CustomerId
WHERE
#ContractDetails.IsReportableDelinquency=1
AND Receivables_DueDate < GETDATE()
AND BilledStatus='Invoiced'
AND (ContractType='Lease' AND LeasePaymentType IN ('InterimInterest','InterimRent','FixedTerm','OTP' )
OR ((#ContractReceivableDetails.ContractType='Loan'OR #ContractReceivableDetails.ContractType='ProgressLoan')AND LoanPaymentType IN ('Interim','FixedTerm' )))
GROUP BY
#ContractDetails.ContractId
,#ContractDetails.CustomerId
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#ContractDetails.ContractId ContractId,
#ContractDetails.CustomerId,
0.0,
0.0,
SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0)+ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,0)),
0.0,
0.0
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
AND #ContractReceivableDetails.CustomerId = #ContractDetails.CustomerId
WHERE BilledStatus='Invoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId
,#ContractDetails.CustomerId
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#ContractDetails.ContractId ContractId,
#ContractDetails.CustomerId,
0.0,
0.0,
0.0,
SUM(ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableInvoiceDetails_EffectiveTaxBalance_Amount,0)),
0.0
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
AND #ContractReceivableDetails.CustomerId = #ContractDetails.CustomerId
WHERE
ReceivableInvoices_DueDate < GETDATE()
AND BilledStatus='Invoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId
,#ContractDetails.CustomerId
INSERT INTO #CollectionWorkListContractDetails
(
ContractId,
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#ContractDetails.ContractId ContractId,
#ContractDetails.CustomerId,
0.0,
0.0,
0.0,
0.0,
SUM(ISNULL(#ContractReceivableDetails.ReceivableDetails_EffectiveBalance_Amount,0) + ISNULL(#ContractReceivableDetails.ReceivableTaxDetails_EffectiveBalance_Amount,0))
FROM
#ContractReceivableDetails
INNER JOIN #ContractDetails
ON  #ContractReceivableDetails.ContractId=#ContractDetails.ContractId
AND #ContractReceivableDetails.CustomerId = #ContractDetails.CustomerId
WHERE
BilledStatus='NotInvoiced'
AND (ContractType='Lease'
OR(ContractType='Loan'OR ContractType='ProgressLoan'))
GROUP BY
#ContractDetails.ContractId
,#ContractDetails.CustomerId
INSERT INTO #CollectionWorkListFinalDetails
(
ContractId,
CustomerId,
TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount,
OpenBalance,
PastDueAmount,
UninvoicedTotalBalance
)
SELECT
#CollectionWorkListContractDetails.ContractId,
#CollectionWorkListContractDetails.CustomerId,
SUM(TotalOutstandingBalance_Amount),
SUM(TotalReportableBalance_Amount),
SUM(OpenBalance),
SUM(PastDueAmount),
SUM(UninvoicedTotalBalance)
FROM
#CollectionWorkListContractDetails
GROUP BY
#CollectionWorkListContractDetails.ContractId
,#CollectionWorkListContractDetails.CustomerId
ORDER BY
#CollectionWorkListContractDetails.ContractId
UPDATE
CollectionWorkListContractDetails
SET
TotalOutstandingBalance_Amount = #CollectionWorkListFinalDetails.TotalOutstandingBalance_Amount,
TotalReportableBalance_Amount = #CollectionWorkListFinalDetails.TotalReportableBalance_Amount,
PastDueAmount_Amount = #CollectionWorkListFinalDetails.PastDueAmount,
OpenBalanceInvoiced_Amount = #CollectionWorkListFinalDetails.OpenBalance,
UninvoicedTotalBalance_Amount = #CollectionWorkListFinalDetails.UninvoicedTotalBalance,
UpdatedById=@UpdatedUserId,
UpdatedTime=@UpdatedTime
FROM
#CollectionWorkListFinalDetails
INNER JOIN CollectionWorkListContractDetails
ON #CollectionWorkListFinalDetails.ContractId=CollectionWorkListContractDetails.ContractId
INNER JOIN CollectionWorkLists
ON  CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
AND #CollectionWorkListFinalDetails.CustomerId = CollectionWorkLists.CustomerId
WHERE
CollectionWorkLists.Status='Open'
UPDATE
CollectionWorkListContractDetails
SET
TotalOutstandingBalance_Amount = 0.0,
TotalReportableBalance_Amount = 0.0,
PastDueAmount_Amount = 0.0,
OpenBalanceInvoiced_Amount = 0.0,
UninvoicedTotalBalance_Amount = 0.0,
UpdatedById=@UpdatedUserId,
UpdatedTime=@UpdatedTime
FROM
#ContractDetails
INNER JOIN CollectionWorkLists
ON  #ContractDetails.CustomerId = CollectionWorkLists.CustomerId
INNER JOIN CollectionWorkListContractDetails
ON  CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
AND #ContractDetails.ContractId = CollectionWorkListContractDetails.ContractId
WHERE CollectionWorkLists.Status='Open'
AND #ContractDetails.ContractId NOT IN (Select ContractId FROM #CollectionWorkListFinalDetails)
UPDATE
CollectionWorkLists
SET
UpdatedById=@UpdatedUserId,
UpdatedTime=@UpdatedTime
FROM
#CollectionWorkListFinalDetails
INNER JOIN CollectionWorkListContractDetails
ON #CollectionWorkListFinalDetails.ContractId=CollectionWorkListContractDetails.ContractId
INNER JOIN CollectionWorkLists
ON CollectionWorkListContractDetails.CollectionWorkListId = CollectionWorkLists.Id
AND #CollectionWorkListFinalDetails.CustomerId = CollectionWorkLists.CustomerId
WHERE CollectionWorkLists.Status='Open'
DROP TABLE #CustomerDetails
DROP TABLE #ContractDetails
DROP TABLE #CollectionWorkListContractDetails
DROP TABLE #ContractReceivableDetails
DROP TABLE #CollectionWorkListFinalDetails
END

GO
