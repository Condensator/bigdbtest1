SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC  [dbo].[VP_GetContractDetailForSelectedContract]
(
@CurrentVendorId BIGINT,
@ContractId BIGINT=NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_InvoiceContractIds
AS
(
SELECT ISNULL(PIN.ContractId,LF.ContractId) ContractId
FROM PayableInvoices PIN
LEFT JOIN PayableInvoiceAssets PINA ON PIN.Id = PINA.PayableInvoiceId
LEFT JOIN LeaseAssets LA ON PINA.AssetId=LA.AssetId
LEFT JOIN LeaseFinances LF ON LA.LeaseFinanceId=LF.Id
WHERE VendorId = @CurrentVendorId
UNION ALL
SELECT ContractId FROM Sundries
WHERE VendorId = @CurrentVendorId
UNION ALL
SELECT ContractId FROM SundryRecurrings
WHERE VendorId = @CurrentVendorId
),
CTE_Contracts
AS
(
SELECT
C.Id AS ContractId
,C.SequenceNumber
,C.ContractType
,CurrencyCode.ISO AS ContractCurrency
,ISNULL(Opp.Number,'''') AS CreditApplication
FROM CTE_InvoiceContractIds AS PayableInvoice
JOIN Contracts C ON PayableInvoice.ContractId = C.Id
JOIN Currencies Currency ON C.CurrencyId=Currency.Id
JOIN CurrencyCodes CurrencyCode ON Currency.CurrencyCodeId=CurrencyCode.Id
LEFT JOIN CreditApprovedStructures CPS ON C.CreditApprovedStructureId =CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
WHERE (@ContractId IS NULL OR C.Id = @ContractId)
),
CTE_LeaseContractsFirst
AS
(
SELECT DISTINCT
C.ContractId AS Id
,C.ContractId
,C.SequenceNumber
,C.ContractType
,C.ContractCurrency
,C.CreditApplication
,Party.PartyNumber AS CustomerNumber
,Party.PartyName AS CustomerName
,Lease.Id AS LeaseFinanceId
,Lease.BookingStatus AS Status
,Lease.ApprovalStatus  AS ApprovalStatus
,LeaseDetail.TermInMonths  AS Term
,LeaseDetail.PaymentFrequency AS PaymentFrequency
,LeaseDetail.NumberOfPayments AS TotalNumberofPayments
,LeaseDetail.NumberOfInceptionPayments AS NumberofInceptiomPayments
,(LeaseDetail.NumberOfPayments -  LeaseDetail.NumberOfInceptionPayments) AS RemainingNumberofPayments
,LeaseDetail.IsAdvance AS Advance
,(CASE WHEN LeaseDetail.IsRegularPaymentStream =1 THEN ''Regular''
WHEN LeaseDetail.IsRegularPaymentStream =0 THEN ''Irregular'' END) AS PaymentType
,LeaseDetail.CommencementDate AS CommencementDate
,LeaseDetail.MaturityDate AS MaturityDate
,LeaseDetail.FrequencyStartDate AS FirstPaymentDate
,C.ContractCurrency AS TotalCost_Currency
,LeaseDetail.InceptionPayment_Amount AS InceptionPayment_Amount
,LeaseDetail.InceptionPayment_Currency AS InceptionPayment_Currency
,LeaseDetail.DownPayment_Amount
,LeaseDetail.Rent_Amount AS RegularPaymentAmount_Amount
,LeaseDetail.Rent_Currency AS RegularPaymentAmount_Currency
,0 AS DaysPastDue  --Pending
,NULL AS TerminationDate --Pending
FROM CTE_Contracts C
JOIN LeaseFinances Lease ON C.ContractId = Lease.ContractId
JOIN LeaseFinanceDetails LeaseDetail ON Lease.Id = LeaseDetail.Id
JOIN Parties Party ON lease.CustomerId=Party.Id
WHERE Lease.IsCurrent=1
),
CTE_LeaseAssetTotalCost
AS
(
SELECT
Lease.LeaseFinanceId
,SUM(LeaseAsset.NBV_Amount) AS TotalCost_Amount
FROM CTE_LeaseContractsFirst Lease
JOIN LeaseAssets LeaseAsset ON Lease.LeaseFinanceId=LeaseAsset.LeaseFinanceId
WHERE LeaseAsset.IsActive=1
GROUP BY Lease.LeaseFinanceId
),
CTE_LeaseContracts
AS
(
SELECT
Lease.ContractId AS Id
,Lease.ContractId
,Lease.SequenceNumber
,Lease.ContractType
,Lease.ContractCurrency
,Lease.CreditApplication
,Lease.CustomerNumber
,Lease.CustomerName
,Lease.Status
,Lease.ApprovalStatus
,Lease.Term
,Lease.PaymentFrequency
,Lease.TotalNumberofPayments
,Lease.NumberofInceptiomPayments
,Lease.RemainingNumberofPayments
,Lease.Advance
,Lease.PaymentType
,''_'' AS BillingType
,Lease.CommencementDate
,Lease.MaturityDate
,Lease.FirstPaymentDate
,ISNULL(LeaseTotal.TotalCost_Amount,0) AS TotalCost_Amount
,Lease.TotalCost_Currency
,Lease.InceptionPayment_Amount
,Lease.InceptionPayment_Currency
,ISNULL((LeaseTotal.TotalCost_Amount- Lease.DownPayment_Amount),0.00) AS TotalFinancedAmount_Amount
,Lease.TotalCost_Currency AS TotalFinancedAmount_Currency
,Lease.RegularPaymentAmount_Amount
,Lease.RegularPaymentAmount_Currency
,0.00 AS ProgressPaymentCredit_Amount
,Lease.TotalCost_Currency AS ProgressPaymentCredit_Currency
,0.00 AS ProgressLoanBalance_Amount
,Lease.TotalCost_Currency AS ProgressLoanBalance_Currency
,Lease.DaysPastDue
,Lease.TerminationDate
FROM CTE_LeaseContractsFirst Lease
LEFT JOIN CTE_LeaseAssetTotalCost LeaseTotal ON Lease.LeaseFinanceId= LeaseTotal.LeaseFinanceId
),
CTE_LoanContractsFirst
AS
(
SELECT DISTINCT
C.ContractId AS Id
,C.ContractId
,C.SequenceNumber
,C.ContractType
,C.ContractCurrency
,C.CreditApplication
,Party.PartyNumber AS CustomerNumber
,Party.PartyName AS CustomerName
,Loan.Id AS LoanFinanceId
,(CASE WHEN Loan.Status =''Cancelled'' THEN ''Inactive''
WHEN Loan.Status !=''Cancelled'' THEN Loan.Status END) AS Status
,(CASE WHEN Loan.ApprovalStatus =''Rejected'' THEN ''Inactive''
WHEN Loan.ApprovalStatus !=''Rejected'' THEN Loan.ApprovalStatus END) AS ApprovalStatus
,Loan.Term  AS Term
,Loan.PaymentFrequency AS PaymentFrequency
,Loan.NumberOfPayments AS TotalNumberofPayments
,0 AS NumberofInceptiomPayments
,0 AS RemainingNumberofPayments
,NULL AS Advance
,'''' AS PaymentType
,Loan.InterimBillingType AS BillingType
,Loan.CommencementDate AS CommencementDate
,Loan.MaturityDate AS MaturityDate
,Loan.FirstPaymentDate  AS FirstPaymentDate
,Loan.LoanAmount_Amount AS TotalCost_Amount
,Loan.LoanAmount_Currency AS TotalCost_Currency
,0.00 AS InceptionPayment_Amount
,Loan.DownPayment_Currency AS InceptionPayment_Currency
,(Loan.LoanAmount_Amount- Loan.DownPayment_Amount ) AS TotalFinancedAmount_Amount
,Loan.LoanAmount_Currency AS TotalFinancedAmount_Currency
,0 AS DaysPastDue  --Pending
,NULL AS TerminationDate --Pending
FROM CTE_Contracts C
JOIN LoanFinances Loan ON Loan.ContractId = C.ContractId
JOIN Parties Party ON Loan.CustomerId=Party.Id
WHERE Loan.IsCurrent=1
),
CTE_ProgressLoanContracts
AS
(
SELECT
LoanFinance.LoanFinanceId
,SUM((ProgressFunding.Amount_Amount* PayableInvoice.InitialExchangeRate)-(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate)) AS ProgressPaymentCredit_Amount
,SUM(ProgressFunding.CreditBalance_Amount * PayableInvoice.InitialExchangeRate) AS ProgressLoanBalance_Amount
FROM CTE_LoanContractsFirst LoanFinance
JOIN LoanFundings LoanFunding ON LoanFinance.LoanFinanceId=LoanFunding.LoanFinanceId
JOIN PayableInvoices PayableInvoice ON LoanFunding.FundingId=PayableInvoice.Id
JOIN PayableInvoiceOtherCosts ProgressFunding ON PayableInvoice.Id=ProgressFunding.PayableInvoiceId
WHERE LoanFunding.IsActive=1
AND ProgressFunding.IsActive=1
AND ProgressFunding.AllocationMethod=''LoanDisbursement''
AND LoanFunding.IsApproved=1
GROUP BY LoanFinance.LoanFinanceId
),
CTE_LoanContracts
AS
( SELECT
Loan.ContractId AS Id
,Loan.ContractId
,Loan.SequenceNumber
,Loan.ContractType
,Loan.ContractCurrency
,Loan.CreditApplication
,Loan.CustomerNumber
,Loan.CustomerName
,Loan.Status AS Status
,Loan.ApprovalStatus
,Loan.Term  AS Term
,Loan.PaymentFrequency
,Loan.TotalNumberofPayments
,Loan.NumberofInceptiomPayments
,Loan.RemainingNumberofPayments
,Loan.Advance
,Loan.PaymentType
,Loan.BillingType
,Loan.CommencementDate
,Loan.MaturityDate
,Loan.FirstPaymentDate
,Loan.TotalCost_Amount
,Loan.TotalCost_Currency
,Loan.InceptionPayment_Amount
,Loan.InceptionPayment_Currency
,Loan.TotalFinancedAmount_Amount
,Loan.TotalFinancedAmount_Currency
,0.00 AS RegularPaymentAmount_Amount
,Loan.ContractCurrency AS RegularPaymentAmount_Currency
,ISNULL(PPC.ProgressPaymentCredit_Amount,0.00) AS ProgressPaymentCredit_Amount
,Loan.ContractCurrency AS ProgressPaymentCredit_Currency
,ISNULL(PPC.ProgressLoanBalance_Amount,0.00) AS ProgressLoanBalance_Amount
,Loan.ContractCurrency AS ProgressLoanBalance_Currency
,Loan.DaysPastDue  --Pending
,Loan.TerminationDate --Pending
FROM CTE_LoanContractsFirst Loan
LEFT JOIN CTE_ProgressLoanContracts PPC ON Loan.LoanFinanceId=PPC.LoanFinanceId
)
SELECT * FROM CTE_LeaseContracts
UNION SELECT * FROM CTE_LoanContracts'
EXEC sp_executesql @Sql,N'
@CurrentVendorId BIGINT,
@ContractId BIGINT=NULL'
,@CurrentVendorId
,@ContractId

GO
