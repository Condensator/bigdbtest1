SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetTransactionsForEIPOutBoundInterfaces]
AS
BEGIN
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;
;WITH CTE_Contracts
AS
(
Select
ContractID = Contracts.Id
,AcquisitionId = LeaseFinance.AcquisitionId
,CustomerNumber= Parties.PartyNumber
,ContractNumber = Contracts.SequenceNumber
,InstrumentTypeCode = InstrumentTypes.Code
,CustomerName = Parties.PartyName
,HoldingStatus = LeaseFinance.HoldingStatus
,private_label_flag = CONVERT(NVARCHAR,ISNULL(ServicingDetails.IsPrivateLabel,0))
FROM Contracts
INNER JOIN LeaseFinances LeaseFinance ON Contracts.Id = LeaseFinance.ContractId AND LeaseFinance.IsCurrent = 1
INNER JOIN Parties ON LeaseFinance.CustomerId = Parties.Id
INNER JOIN InstrumentTypes ON LeaseFinance.InstrumentTypeId = InstrumentTypes.Id AND InstrumentTypes.IsActive=1
LEFT JOIN ContractOriginations ON LeaseFinance.ContractOriginationId = ContractOriginations.Id
LEFT JOIN ContractOriginationServicingDetails ON ContractOriginations.Id = ContractOriginationServicingDetails.ContractOriginationId
LEFT JOIN ServicingDetails ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id AND ServicingDetails.IsActive = 1
UNION ALL
Select
ContractID = Contracts.Id
,AcquisitionId= LoanFinance.AcquisitionId
,CustomerNumber= Parties.PartyNumber
,ContractNumber = Contracts.SequenceNumber
,InstrumentTypeCode = InstrumentTypes.Code
,CustomerName = Parties.PartyName
,HoldingStatus = LoanFinance.HoldingStatus
,private_label_flag = CONVERT(NVARCHAR,ISNULL(ServicingDetails.IsPrivateLabel,0))
FROM Contracts
INNER JOIN LoanFinances LoanFinance ON Contracts.Id = LoanFinance.ContractId ANd LoanFinance.IsCurrent = 1
INNER JOIN Parties ON LoanFinance.CustomerId = Parties.Id
INNER JOIN InstrumentTypes ON LoanFinance.InstrumentTypeId = InstrumentTypes.Id AND InstrumentTypes.IsActive=1
LEFT JOIN ContractOriginations ON LoanFinance.ContractOriginationId = ContractOriginations.Id
LEFT JOIN ContractOriginationServicingDetails ON ContractOriginations.Id = ContractOriginationServicingDetails.ContractOriginationId
LEFT JOIN ServicingDetails ON ContractOriginationServicingDetails.ServicingDetailId = ServicingDetails.Id AND ServicingDetails.IsActive = 1
)
,CTE_ContractsWithGLJournalDetails
AS
(
Select
CTE_Contracts.AcquisitionId
,CustomerNumber
,ContractNumber
,InstrumentTypeCode
,CustomerName
,HoldingStatus
,private_label_flag
,GLJournalDetailId = GLJournalDetails.Id
FROM CTE_Contracts
INNER JOIN GLJournalDetails ON GLJournalDetails.EntityId = CTE_Contracts.ContractID AND GLJournalDetails.EntityType = 'Contract' AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
)
,CTE_Disbursements
AS
(
Select
DisbursementRequestId = DisbursementRequests.Id
,InvoiceNumber = Max(PayableInvoices.InvoiceNumber)
,InvoiceDueDate = CONVERT(NVARCHAR,PayableInvoices.InvoiceDate,101)
,VendorNumber = Parties.PartyNumber
,VendorName = Parties.PartyName
from DisbursementRequests
INNER JOIN DisbursementRequestPayables DRP ON DisbursementRequests.Id = DRP.DisbursementRequestId AND DRP.IsActive=1
INNER JOIN Payables P ON DRP.PayableId = P.Id
INNER JOIN PayableInvoices ON P.EntityId = PayableInvoices.Id AND P.EntityType = 'PI'
INNER JOIN Parties ON PayableInvoices.VendorId = Parties.Id
group by DisbursementRequests.Id,PayableInvoices.InvoiceDate, Parties.PartyNumber, Parties.PartyName
)
,CTE_DisbursementsWithGLJournalDetails
AS
(
Select
InvoiceNumber
,InvoiceDueDate
,VendorNumber
,VendorName
,GLJournalDetailId = GLJournalDetails.Id
From CTE_Disbursements
INNER JOIN GLJournalDetails ON GLJournalDetails.EntityId = CTE_Disbursements.DisbursementRequestId AND GLJournalDetails.EntityType = 'DisbursementRequest' AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
)
,CTE_AccountsPayables
AS
(
Select
AccountsPayablePaymentId = AccountsPayablePayments.Id
,InvoiceNumber = Max(PayableInvoices.InvoiceNumber)
,InvoiceDueDate = CONVERT(NVARCHAR,PayableInvoices.InvoiceDate,101)
,VendorNumber = Parties.PartyNumber
,VendorName = Parties.PartyName
,CheckNumber = Max(PaymentVouchers.CheckNumber)
From AccountsPayablePayments
INNER JOIN AccountsPayablePaymentVouchers ON AccountsPayablePayments.Id = AccountsPayablePaymentVouchers.AccountsPayablePaymentId AND AccountsPayablePaymentVouchers.IsActive=1
INNER JOIN PaymentVouchers ON AccountsPayablePaymentVouchers.PaymentVoucherId = PaymentVouchers.Id
INNER JOIN PaymentVoucherDetails ON PaymentVouchers.Id = PaymentVoucherDetails.PaymentVoucherId
INNER JOIN TreasuryPayables ON PaymentVoucherDetails.TreasuryPayableId = TreasuryPayables.Id
INNER JOIN TreasuryPayableDetails ON TreasuryPayables.Id = TreasuryPayableDetails.TreasuryPayableId AND TreasuryPayableDetails.IsActive=1
INNER JOIN Payables P ON TreasuryPayableDetails.PayableId = P.Id
INNER JOIN PayableInvoices ON P.EntityId = PayableInvoices.Id AND P.EntityType = 'PI'
INNER JOIN Parties ON PayableInvoices.VendorId = Parties.Id
Group By AccountsPayablePayments.Id,PayableInvoices.InvoiceDate,Parties.PartyNumber,Parties.PartyName
)
,CTE_AccountsPayablesWithGLJournalDetails
AS
(
Select
InvoiceNumber
,InvoiceDueDate
,VendorNumber
,VendorName
,CheckNumber
,GLJournalDetailId = GLJournalDetails.Id
From CTE_AccountsPayables
INNER JOIN GLJournalDetails ON GLJournalDetails.EntityId = CTE_AccountsPayables.AccountsPayablePaymentId
AND GLJournalDetails.EntityType = 'AccountsPayablePayment' AND GLJournalDetails.IsActive=1
AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
)
,CTE_AssetsWithGLJournalDetails
AS
(
Select
AssetNumber = CASE WHEN COUNT(ASN.Id) = 1 THEN  MAX(ASN.SerialNumber) ELSE null END 
,GLJournalDetailId = GLJournalDetails.ID
From Assets
INNER JOIN GLJournalDetails ON Assets.Id = GLJournalDetails.EntityId AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
LEFT JOIN AssetSerialNumbers ASN ON Assets.Id = ASN.AssetId
Where EntityType IN('Asset','AssetSale','AssetValueAdjustment')
GROUP BY GLJournalDetails.ID
)
,CTE_CustomersWithGLJournalDetails
AS
(
Select
CustomerNumber = Parties.PartyNumber
,CustomerName = Parties.PartyName
,GLJournalDetailId = GLJournalDetails.ID
From Parties
INNER JOIN GLJournalDetails ON Parties.Id = GLJournalDetails.EntityId AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN GLJournals ON GLJournalDetails.GLJournalId = GLJournals.Id
Where EntityType IN('Customer')
)
,CTE_ReceivablesWithGLJournalDetails
AS
(
Select
ReceivableCode = ReceivableCodes.Name
,GLJournalDetailId = GLJournalDetails.ID
From ReceivableGLJournals
INNER JOIN GLJournals ON ReceivableGLJournals.GLJournalId = GLJournals.Id
INNER JOIN GLJournalDetails ON GLJournals.id = GLJournalDetails.GLJournalId AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN Receivables ON ReceivableGLJournals.ReceivableId = Receivables.Id AND Receivables.IsActive=1
INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id AND ReceivableCodes.IsActive=1
)
SELECT
ExportJobId=GLJournalDetails.ExportJobId
,TransactionUniqueIdentifier = GLJournaldetails.GLJournalId
,SystemMnemonic = 'EQF'
,AcquisitionID = CTE_ContractsWithGLJournalDetails.AcquisitionId
,GLCompanyNumber = LegalEntities.GLSegmentValue
,GLCostCenter = ''
,GLAccountNumber = GLJournalDetails.GLAccountNumber
,GLTemplateName = GLTemplates.Name
,GLTransactionType = GLTransactionTypes.Name
,CreditOrDebit = CONVERT(NVARCHAR,GLJournalDetails.IsDebit)
,TransactionAmount = GLJournaldetails.Amount_Amount
,DebitAmount = CASE WHEN GLJournalDetails.IsDebit = 1 THEN GLJournaldetails.Amount_Amount
ELSE 0.0 END
,CreditAmount = CASE WHEN GLJournalDetails.IsDebit = 0 THEN GLJournaldetails.Amount_Amount
ELSE 0.0 END
,CurrencyCode = GLJournaldetails.Amount_Currency
,PostingDate = CONVERT(NVARCHAR,GLJournals.CreatedTime,101)
,EffectiveDate = CONVERT(NVARCHAR,GLJournals.PostDate,101)
,TransactionGroupID = GLJournalDetails.GLJournalId
,PostedBy = GLJournals.CreatedById
,GLAccountDescription = GLAccounts.Description
,AffiliateCode = Case When LEN(GLJournalDetails.GLAccountNumber)-LEN(REPLACE(GLJournalDetails.GLAccountNumber, '-', ''))=4
then Reverse(SUBSTRING(Reverse(GLJournalDetails.GLAccountNumber), 1,CHARINDEX('-', Reverse(GLJournalDetails.GLAccountNumber))-1))
ELSE '' END
,GLBookCode = GLUserBooks.SystemDefinedBook
,CustomerNumber = CASE WHEN GLJournalDetails.EntityType = 'Contract' THEN
CTE_ContractsWithGLJournalDetails.CustomerNumber
WHEN GLJournalDetails.EntityType = 'Customer' THEN
CTE_CustomersWithGLJournalDetails.CustomerNumber
ELSE '' END
,ContractNumber = CTE_ContractsWithGLJournalDetails.ContractNumber
,AssetNumber = CTE_AssetsWithGLJournalDetails.AssetNumber
,CIFAccountNumber = ' '
,CheckNumber = CTE_AccountsPayablesWithGLJournalDetails.CheckNumber
,TransactionComments = GLJournalDetails.Description
,CashFlag = CASE WHEN GLEntryItems.Name = 'Cash' THEN '1' ELSE '0' END
,AdditionalReferenceInformation = dbo.GetParsedString(GLTransactionTypes.Id,1,4,'0') +  dbo.GetParsedString(GLEntryItems.Id,1,6,'0')
,InstrumentTypeCode = CTE_ContractsWithGLJournalDetails.InstrumentTypeCode
,ProcessingStatus = 'N'
,GLAccountType = CASE WHEN SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '1' THEN
'Asset'
WHEN SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '2' THEN
'Liability'
WHEN (SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '3' OR SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '5')  THEN
'Revenue'
WHEN (SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '4' OR SUBSTRING(GLJournalDetails.GLAccountNumber,1,1) = '6') THEN
'Expense'
ELSE '' END
,CustomerName = CASE WHEN GLJournalDetails.EntityType = 'Contract' THEN
CTE_ContractsWithGLJournalDetails.CustomerName
WHEN GLJournalDetails.EntityType = 'Customer' THEN
CTE_CustomersWithGLJournalDetails.CustomerName
ELSE '' END
,HoldingStatus = CTE_ContractsWithGLJournalDetails.HoldingStatus
,InvoiceNumber = CASE WHEN GLJournalDetails.EntityType = 'DisbursementRequest' THEN
CTE_DisbursementsWithGLJournalDetails.InvoiceNumber
WHEN GLJournalDetails.EntityType = 'AccountsPayablePayment' THEN
CTE_AccountsPayablesWithGLJournalDetails.InvoiceNumber
ELSE '' END
,InvoiceDueDate = CASE WHEN GLJournalDetails.EntityType = 'DisbursementRequest' THEN
CTE_DisbursementsWithGLJournalDetails.InvoiceDueDate
WHEN GLJournalDetails.EntityType = 'AccountsPayablePayment' THEN
CTE_AccountsPayablesWithGLJournalDetails.InvoiceDueDate
ELSE '' END
,VendorNumber = CASE WHEN GLJournalDetails.EntityType = 'DisbursementRequest' THEN
CTE_DisbursementsWithGLJournalDetails.VendorNumber
WHEN GLJournalDetails.EntityType = 'AccountsPayablePayment' THEN
CTE_AccountsPayablesWithGLJournalDetails.VendorNumber
ELSE '' END
,VendorName = CASE WHEN GLJournalDetails.EntityType = 'DisbursementRequest' THEN
CTE_DisbursementsWithGLJournalDetails.VendorName
WHEN GLJournalDetails.EntityType = 'AccountsPayablePayment' THEN
CTE_AccountsPayablesWithGLJournalDetails.VendorName
ELSE '' END
,ReceivableCode = CTE_ReceivablesWithGLJournalDetails.ReceivableCode
,private_label_flag = CTE_ContractsWithGLJournalDetails.private_label_flag
INTO #TransactionRecords
FROM GLJournals
INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalID AND GLJournalDetails.IsActive=1 AND GLJournalDetails.ExportJobId Is NULL
INNER JOIN LegalEntities ON GLJournals.LegalEntityID = LegalEntities.Id
LEFT JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id AND GLTemplateDetails.IsActive=1
LEFT JOIN GLTemplates ON GLTemplateDetails.GLTemplateId = GLTemplates.Id AND GLTemplates.IsActive=1
LEFT JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
LEFT JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id AND GLAccounts.IsActive=1
LEFT JOIN GLConfigurations ON GLTemplates.GLConfigurationId = GLConfigurations.Id
LEFT JOIN GLUserBooks ON GLUserBooks.GLConfigurationId = GLConfigurations.Id AND GLUserBooks.IsActive = 1 AND GLUserBooks.IsActive=1
LEFT JOIN CTE_ContractsWithGLJournalDetails ON GLJournalDetails.Id = CTE_ContractsWithGLJournalDetails.GLJournalDetailId
LEFT JOIN CTE_CustomersWithGLJournalDetails ON GLJournalDetails.Id = CTE_CustomersWithGLJournalDetails.GLJournalDetailId
LEFT JOIN CTE_DisbursementsWithGLJournalDetails ON GLJournalDetails.Id = CTE_DisbursementsWithGLJournalDetails.GLJournalDetailId
LEFT JOIN CTE_AccountsPayablesWithGLJournalDetails ON GLJournalDetails.Id = CTE_AccountsPayablesWithGLJournalDetails.GLJournalDetailId
LEFT JOIN CTE_AssetsWithGLJournalDetails ON GLJournalDetails.Id = CTE_AssetsWithGLJournalDetails.GLJournalDetailId
LEFT JOIN CTE_ReceivablesWithGLJournalDetails ON GLJournalDetails.Id = CTE_ReceivablesWithGLJournalDetails.GLJournalDetailId
SELECT
TransactionUniqueIdentifier
,SystemMnemonic
,AcquisitionID
,GLCompanyNumber
,GLCostCenter
,GLAccountNumber
,GLTemplateName
,GLTransactionType
,CreditOrDebit
,TransactionAmount
,DebitAmount
,CreditAmount
,CurrencyCode
,PostingDate
,EffectiveDate
,TransactionGroupID
,PostedBy
,GLAccountDescription
,AffiliateCode
,GLBookCode
,CustomerNumber
,ContractNumber
,AssetNumber
,CIFAccountNumber
,CheckNumber
,TransactionComments
,CashFlag
,AdditionalReferenceInformation
,InstrumentTypeCode
,ProcessingStatus
,GLAccountType
,CustomerName
,HoldingStatus
,InvoiceNumber
,InvoiceDueDate
,VendorNumber
,VendorName
,ReceivableCode
,private_label_flag
FROM #TransactionRecords
DROP TABLE #TransactionRecords
END

GO
