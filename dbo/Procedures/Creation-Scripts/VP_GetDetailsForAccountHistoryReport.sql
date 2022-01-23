SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetDetailsForAccountHistoryReport]
(
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber NVARCHAR(40)=NULL
,@ToSequenceNumber NVARCHAR(40)=NULL
,@CustomerNumber NVARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40) = NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @SequenceNumber_Condition NVARCHAR(1000)
DECLARE @LeaseCommencementDate_Condition NVARCHAR(1000)
DECLARE @LeaseMaturityDate_Condition NVARCHAR(1000)
DECLARE @LoanCommencementDate_Condition NVARCHAR(1000)
DECLARE @LoanMaturityDate_Condition NVARCHAR(1000)
DECLARE @ORIGINATIONWHERECONDITION NVARCHAR(1000)
DECLARE @PROGRAMWHERECONDITION NVARCHAR(40)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_AssumptionDetails AS
(
SELECT
ContractId,
MIN(Id) Id
FROM Assumptions WHERE Status = ''Approved''
Group BY
ContractId
)
,CTE_Contracts
AS
(
SELECT DISTINCT Contracts.Id AS ContractId
,Contracts.SequenceNumber
,Contracts.ContractType
,Contracts.CurrencyId
,CASE WHEN CreditApplications.VendorId IS NULL THEN OriginationSource.PartyName ELSE Vendor.PartyName END AS ProgramVendor
FROM Contracts
JOIN CreditApprovedStructures  ON Contracts.CreditApprovedStructureId =CreditApprovedStructures.Id
JOIN CreditProfiles  ON CreditApprovedStructures.CreditProfileId = CreditProfiles.Id
JOIN Opportunities ON CreditProfiles.OpportunityId = Opportunities.Id
JOIN CreditApplications ON CreditApplications.Id = Opportunities.Id
JOIN Parties OriginationSource ON OriginationSource.Id = Opportunities.OriginationSourceId
LEFT JOIN Parties Vendor ON Vendor.Id = CreditApplications.VendorId
LEFT JOIN ContractThirdPartyRelationships ContractTP ON Contracts.Id= ContractTP.ContractId
LEFT JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id
WHERE
(
ORIGINATIONWHERECONDITION
SequenceNumber_Condition
)
OR
(
CustomerTP.ThirdPartyId = CASE WHEN @IsProgramVendor = ''1'' THEN (SELECT Id from Parties where PartyNumber = @ProgramVendorNumber)
ELSE (SELECT Id from Parties where PartyNumber = @DealerOrDistributorNumber )
END
AND CustomerTP.IsActive = 1 AND ContractTP.IsActive = 1 AND CustomerTP.RelationshipType = ''VendorRecourse''
)
)
,
CTE_TaxDetail (ReceivableDetailId, ReceivableTaxAmount, ReceivableTaxBalance) AS (
SELECT
ReceivableDetailId = ReceivableDetails.Id,
ReceivableTaxAmount = SUM(ReceivableTaxDetails.Amount_Amount),
ReceivableTaxBalance = SUM(ReceivableTaxDetails.Balance_Amount)
FROM  CTE_Contracts
JOIN Receivables ON Receivables.EntityId = CTE_Contracts.ContractId AND Receivables.EntityType = ''CT''AND Receivables.IsActive = 1
JOIN ReceivableDetails ON ReceivableDetails.ReceivableId = Receivables.Id AND ReceivableDetails.IsActive = 1
JOIN ReceivableTaxDetails ON ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1
GROUP BY ReceivableDetails.Id
)
,
CTE_Invoices
AS
(
SELECT  ReceivableInvoices.Id,
ReceivableInvoices.Number InvoiceNumber,
CTE_Contracts.ContractId ContractId,
CTE_Contracts.ContractType ContractType,
ReceivableInvoices.DueDate DueDate,
Receivables.CustomerId,
SUM(ReceivableInvoiceDetails.InvoiceAmount_Amount) AmountDue,
SUM(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) TaxAmount,
ReceivableDetails.IsTaxAssessed TaxAssessed,
SUM(ReceivableDetails.Amount_Amount) - SUM(ReceivableDetails.Balance_Amount) AmountPaid,
SUM(ISNULL(TaxDetail.ReceivableTaxAmount, 0.00)) - SUM(ISNULL(TaxDetail.ReceivableTaxBalance, 0.00)) TaxPaid,
SUM(ReceivableInvoiceDetails.Balance_Amount) Balance,
SUM(ReceivableInvoiceDetails.TaxBalance_Amount) TaxBalance,
CTE_Contracts.SequenceNumber,
CTE_Contracts.CurrencyId,
CTE_Contracts.ProgramVendor
FROM ReceivableInvoices
INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
INNER JOIN ReceivableDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
INNER JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN CTE_Contracts ON Receivables.EntityId = CTE_Contracts.ContractId AND Receivables.EntityType = ''CT''
LEFT JOIN CTE_TaxDetail AS TaxDetail ON ReceivableDetails.Id = TaxDetail.ReceivableDetailId
WHERE ReceivableInvoices.IsActive = 1
GROUP BY ReceivableInvoices.Id,
ReceivableInvoices.Number,
CTE_Contracts.ContractId,
CTE_Contracts.SequenceNumber,
CTE_Contracts.CurrencyId,
CTE_Contracts.ProgramVendor,
ReceivableInvoices.DueDate,
Receivables.CustomerId,
CTE_Contracts.ContractType,
ReceivableDetails.IsTaxAssessed
),
CTE_PaymentDetails
AS
(
SELECT CTE_Invoices.Id,
MAX(CASE WHEN Receipts.ReceivedDate IS NOT NULL THEN Receipts.ReceivedDate
WHEN Receipts.PostDate IS NOT NULL THEN Receipts.PostDate
WHEN DSLReceipt.ReceivedDate IS NOT NULL THEN DSLReceipt.ReceivedDate
WHEN DSLReceipt.PostDate IS NOT NULL THEN DSLReceipt.PostDate
ELSE NULL END) PaymentDate
FROM CTE_Invoices
INNER JOIN ReceivableInvoiceDetails
ON CTE_Invoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
LEFT JOIN ReceiptApplicationReceivableDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
AND ReceiptApplicationReceivableDetails.IsActive = 1
LEFT JOIN ReceiptApplications
ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
LEFT JOIN Receipts
ON ReceiptApplications.ReceiptId = Receipts.Id AND (Receipts.Status =''Posted'' OR Receipts.Status =''Completed'')
LEFT JOIN DSLReceiptHistories DSLRH
ON ReceivableInvoiceDetails.ReceivableDetailId = DSLRH.ReceivableDetailId AND DSLRH.IsActive = 1
LEFT JOIN Receipts DSLReceipt
ON DSLRH.ReceiptId = DSLReceipt.Id AND (DSLReceipt.Status =''Posted'' OR DSLReceipt.Status =''Completed'')
GROUP BY CTE_Invoices.Id
),
CTE_InvoiceDetails
AS
(
SELECT
InvoiceNumber,
ContractId,
ContractType,
DueDate,
CustomerId,
CTE_PaymentDetails.PaymentDate,
AmountDue,
TaxAmount,
TaxAssessed,
AmountPaid,
TaxPaid,
Balance,
TaxBalance,
SequenceNumber,
CurrencyId,
ProgramVendor
FROM CTE_Invoices
INNER JOIN CTE_PaymentDetails ON CTE_Invoices.Id = CTE_PaymentDetails.Id
),
CTE_LeaseContracts
AS
(
SELECT DISTINCT
CTE_InvoiceDetails.ContractId  AS Id
,CTE_InvoiceDetails.SequenceNumber
,LeaseFinanceDetails.CommencementDate AS CommencementDate
,CASE WHEN (LeaseFinanceDetails.PaymentFrequency IS NULL OR LeaseFinanceDetails.PaymentFrequency = ''_'') THEN
CASE WHEN LeaseFinanceDetails.InterimInterestBillingType = ''Periodic'' THEN
LeaseFinanceDetails.InterimPaymentFrequency
ELSE ''_'' END
ELSE LeaseFinanceDetails.PaymentFrequency END AS PaymentFrequency
,LeaseFinanceDetails.TermInMonths  AS Term
,LeaseFinanceDetails.MaturityDate AS MaturityDate
,Currencies.Name ContractCurrency
,CTE_InvoiceDetails.InvoiceNumber
,CTE_InvoiceDetails.PaymentDate
,CTE_InvoiceDetails.DueDate
,CTE_InvoiceDetails.AmountDue
,CTE_InvoiceDetails.TaxAmount
,CTE_InvoiceDetails.TaxAssessed
,CTE_InvoiceDetails.AmountPaid
,CTE_InvoiceDetails.TaxPaid
,CTE_InvoiceDetails.Balance
,CTE_InvoiceDetails.TaxBalance
,CTE_InvoiceDetails.ContractType
,CTE_InvoiceDetails.ProgramVendor
,CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyNumber ELSE CAST(NULL AS NVARCHAR) END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN Parties.PartyName ELSE CAST(NULL AS NVARCHAR) END AS CustomerName
,Programs.Name AS ProgramName
FROM CTE_InvoiceDetails
JOIN LeaseFinances  ON CTE_InvoiceDetails.ContractId = LeaseFinances.ContractId
LEFT JOIN ContractOriginations ON LeaseFinances.ContractOriginationId=ContractOriginations.Id
LEFT JOIN Programs ON ContractOriginations.ProgramId=Programs.Id
JOIN Parties ON LeaseFinances.CustomerId = Parties.Id
JOIN LeaseFinanceDetails  ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Currencies ON CTE_InvoiceDetails.CurrencyId = Currencies.Id
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = CTE_InvoiceDetails.ContractId
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
WHERE (@CustomerNumber IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyNumber ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyName ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerName ,''*'',''%''))
AND LeaseFinances.IsCurrent = 1
LeaseCommencementDate_Condition
LeaseMaturityDate_Condition
PROGRAMWHERECONDITION
),
CTE_LoanContracts
AS
(
SELECT DISTINCT
CTE_InvoiceDetails.ContractId  AS Id
,CTE_InvoiceDetails.SequenceNumber
,LoanFinances.CommencementDate AS CommencementDate
,CASE WHEN (LoanFinances.PaymentFrequency IS NULL OR LoanFinances.PaymentFrequency = ''_'') THEN
CASE WHEN LoanFinances.InterimBillingType = ''Periodic'' THEN LoanFinances.InterimFrequency ELSE ''_'' END
ELSE LoanFinances.PaymentFrequency END AS PaymentFrequency
,LoanFinances.Term  AS Term
,LoanFinances.MaturityDate AS MaturityDate
,Currencies.Name ContractCurrency
,CTE_InvoiceDetails.InvoiceNumber
,CTE_InvoiceDetails.PaymentDate
,CTE_InvoiceDetails.DueDate
,CTE_InvoiceDetails.AmountDue
,CTE_InvoiceDetails.TaxAmount
,CTE_InvoiceDetails.TaxAssessed
,CTE_InvoiceDetails.AmountPaid
,CTE_InvoiceDetails.TaxPaid
,CTE_InvoiceDetails.Balance
,CTE_InvoiceDetails.TaxBalance
,CTE_InvoiceDetails.ContractType
,CTE_InvoiceDetails.ProgramVendor
,CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyNumber ELSE CAST(NULL AS NVARCHAR) END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN Parties.PartyName ELSE CAST(NULL AS NVARCHAR) END AS CustomerName
,Programs.Name AS ProgramName
FROM CTE_InvoiceDetails
JOIN LoanFinances ON CTE_InvoiceDetails.ContractId = LoanFinances.ContractId
LEFT JOIN ContractOriginations ON LoanFinances.ContractOriginationId=ContractOriginations.Id
LEFT JOIN Programs ON ContractOriginations.ProgramId=Programs.Id
JOIN Parties  ON LoanFinances.CustomerId=Parties.Id
JOIN Currencies ON CTE_InvoiceDetails.CurrencyId = Currencies.Id
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = CTE_InvoiceDetails.ContractId
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
WHERE (@CustomerNumber IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyNumber ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName  IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN Parties.PartyName ELSE AP.PartyNumber END) LIKE REPLACE(@CustomerName ,''*'',''%''))
AND LoanFinances.IsCurrent = 1
LoanCommencementDate_Condition
LoanMaturityDate_Condition
PROGRAMWHERECONDITION
),
CTE_ContractDetails
AS
(
SELECT * FROM CTE_LeaseContracts
UNION SELECT * FROM CTE_LoanContracts
)
SELECT * FROM CTE_ContractDetails
'
IF (@FromSequenceNumber IS NOT NULL AND @ToSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '' AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND Contracts.SequenceNumber BETWEEN @FromSequenceNumber AND @ToSequenceNumber '
ELSE IF(@FromSequenceNumber IS NOT NULL AND @FromSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND Contracts.SequenceNumber = @FromSequenceNumber '
ELSE IF(@ToSequenceNumber IS NOT NULL AND @ToSequenceNumber <> '')
SET @SequenceNumber_Condition =  'AND Contracts.SequenceNumber = @ToSequenceNumber '
ELSE
SET @SequenceNumber_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL AND @CommencementDateFrom <> '' AND @CommencementDateTo <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseFinanceDetails.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LeaseCommencementDate_Condition =  'AND LeaseFinanceDetails.CommencementDate = CAST(@CommencementDateFrom AS DATE)'
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LeaseCommencementDate_Condition =  'AND LeaseFinanceDetails.CommencementDate <= @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  'AND LeaseFinanceDetails.CommencementDate = @CommencementDateTo '
ELSE
SET @LeaseCommencementDate_Condition =  ''
IF (@CommencementDateFrom IS NOT NULL AND @CommencementDateTo IS NOT NULL)
SET @LoanCommencementDate_Condition =  'AND LoanFinances.CommencementDate BETWEEN CAST(@CommencementDateFrom AS DATE) AND CAST(@CommencementDateTo AS DATE)'
ELSE IF(@CommencementDateFrom IS NOT NULL AND @CommencementDateFrom <> '')
SET @LoanCommencementDate_Condition =  'AND LoanFinances.CommencementDate = CAST(@CommencementDateFrom AS DATE) '
ELSE IF(@CommencementDateTo IS NOT NULL AND @CommencementDateTo <> '')
IF(@IsCommencementUpToDate = '1')
SET @LoanCommencementDate_Condition =  'AND LoanFinances.CommencementDate <= @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  'AND LoanFinances.CommencementDate = @CommencementDateTo '
ELSE
SET @LoanCommencementDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LeaseMaturityDate_Condition =  'AND LeaseFinanceDetails.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LeaseMaturityDate_Condition =  'AND LeaseFinanceDetails.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LeaseMaturityDate_Condition =  'AND LeaseFinanceDetails.MaturityDate <= @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  'AND LeaseFinanceDetails.MaturityDate = @MaturityDateTo '
ELSE
SET @LeaseMaturityDate_Condition =  ''
IF (@MaturityDateFrom IS NOT NULL AND @MaturityDateTo IS NOT NULL)
SET @LoanMaturityDate_Condition =  'AND LoanFinances.MaturityDate BETWEEN CAST(@MaturityDateFrom AS DATE) AND CAST(@MaturityDateTo AS DATE) '
ELSE IF(@MaturityDateFrom IS NOT NULL AND @MaturityDateFrom <> '')
SET @LoanMaturityDate_Condition =  'AND LoanFinances.MaturityDate = CAST(@MaturityDateFrom AS DATE)'
ELSE IF(@MaturityDateTo IS NOT NULL AND @MaturityDateTo <> '')
IF(@IsMaturityUpToDate = '1')
SET @LoanMaturityDate_Condition =  'AND LoanFinances.MaturityDate <= @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  'AND LoanFinances.MaturityDate = @MaturityDateTo '
ELSE
SET @LoanMaturityDate_Condition =  ''
IF (@ProgramName IS NOT NULL AND @ProgramName <> '')
SET @PROGRAMWHERECONDITION =  'AND Programs.Name =''@ProgramName'''
ELSE
SET @PROGRAMWHERECONDITION =  ''
IF(@IsProgramVendor = '0')
SET @ORIGINATIONWHERECONDITION = '(@DealerOrDistributorNumber IS NULL OR @DealerOrDistributorNumber =''''
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''  OR
Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'','')))))'
ELSE
IF(@IsDealerFilterAppliedExternally = '0')
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR (OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
))'
ELSE
SET @ORIGINATIONWHERECONDITION = '
(OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributorNumber,'',''))
AND Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR ((@DealerOrDistributorNumber IS NULL OR @DealerOrDistributorNumber ='''')
AND (@ProgramVendorNumber IS NULL OR @ProgramVendorNumber =''''
OR OriginationSource.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))
OR  Vendor.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendorNumber,'',''))))
)'
SET @Sql =  REPLACE(@Sql, 'SequenceNumber_Condition', @SequenceNumber_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseCommencementDate_Condition', @LeaseCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LeaseMaturityDate_Condition', @LeaseMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanCommencementDate_Condition', @LoanCommencementDate_Condition);
SET @Sql =  REPLACE(@Sql, 'LoanMaturityDate_Condition', @LoanMaturityDate_Condition);
SET @Sql =  REPLACE(@Sql, 'ORIGINATIONWHERECONDITION', @ORIGINATIONWHERECONDITION);
SET @Sql =  REPLACE(@Sql, 'PROGRAMWHERECONDITION', @PROGRAMWHERECONDITION);
--select @Sql
EXEC sp_executesql @Sql,N'
@CommencementDateFrom DATE=NULL
,@CommencementDateTo DATE=NULL
,@MaturityDateFrom DATE=NULL
,@MaturityDateTo DATE=NULL
,@FromSequenceNumber VARCHAR(40)=NULL
,@ToSequenceNumber VARCHAR(40)=NULL
,@CustomerNumber VARCHAR(500)=NULL
,@CustomerName NVARCHAR(500)=NULL
,@ProgramVendorNumber NVARCHAR(1000)=NULL
,@DealerOrDistributorNumber VARCHAR(1000)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL
,@IsCommencementUpToDate NVARCHAR(1)=NULL
,@IsMaturityUpToDate NVARCHAR(1)=NULL
,@IsDealerFilterAppliedExternally NVARCHAR(1) = NULL
,@ProgramName NVARCHAR(40)=NULL'
,@CommencementDateFrom
,@CommencementDateTo
,@MaturityDateFrom
,@MaturityDateTo
,@FromSequenceNumber
,@ToSequenceNumber
,@CustomerNumber
,@CustomerName
,@ProgramVendorNumber
,@DealerOrDistributorNumber
,@IsProgramVendor
,@IsCommencementUpToDate
,@IsMaturityUpToDate
,@IsDealerFilterAppliedExternally
,@ProgramName

GO
