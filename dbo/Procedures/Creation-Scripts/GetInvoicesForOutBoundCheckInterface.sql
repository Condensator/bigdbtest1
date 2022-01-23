SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetInvoicesForOutBoundCheckInterface] @AggregateFlag BIT,@PPTAggregateFlag BIT
AS
BEGIN
SET NOCOUNT ON;
DECLARE @SQL NVARCHAR(Max)
--DECLARE @AggregateFlag BIT
--DECLARE @PPTAggregateFlag BIT
--SET @AggregateFlag = 1
--SET @PPTAggregateFlag = 1
SET @SQL =N'
;WITH CTE_TreasuryPayableDetail AS
(
Select
PaymentVoucherId=PaymentVouchers.Id,
PayeeId=TreasuryPayables.PayeeId,
Sum(PaymentVoucherDetails.Amount_Amount) AS Amount
From PaymentVouchers
INNER JOIN PaymentVoucherDetails
ON PaymentVoucherDetails.PaymentVoucherId=PaymentVouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Check''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
INNER JOIN TreasuryPayables
ON TreasuryPayables.Id=PaymentVoucherDetails.TreasuryPayableId
AND TreasuryPayables.Status IN (''Approved'',''PartiallyApproved'')
INNER JOIN AccountsPayablePaymentVouchers
ON AccountsPayablePaymentVouchers.PaymentVoucherId = PaymentVouchers.Id
INNER JOIN AccountsPayablePayments
ON AccountsPayablePayments.Id = AccountsPayablePaymentVouchers.AccountsPayablePaymentId
AND AccountsPayablePayments.IsIntercompany = 0
GROUP BY
PaymentVouchers.Id,
TreasuryPayables.PayeeId
),
CTE_ContractInvoices
AS(
Select
PaymentvoucherId,
InvoiceNumber,
SequenceNumber,
InterfacingSystem
From
(
Select
PaymentvoucherId=PaymentVouchers.Id,
InvoiceNumber=PayableInvoices.InvoiceNumber,
SequenceNumber=Contracts.SequenceNumber,
InterfacingSystem=convert(nvarchar(40),CASE DisbursementRequests.Type
WHEN NULL THEN '' ''
WHEN ''Origination'' THEN ''ORIG''
WHEN ''PassThru'' THEN ''PASS''
WHEN ''Syndication'' THEN ''SYND''
WHEN ''Refund'' THEN ''CREF''
else ''OTHR''
END),
RowNumber=ROW_NUMBER() over(Partition by PaymentVouchers.Id Order by PayableInvoices.Id desc)
From PaymentVouchers
INNER JOIN PaymentVoucherDetails ON PaymentVoucherDetails.PaymentVoucherId=PaymentVouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Check''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
INNER JOIN TreasuryPayables ON TreasuryPayables.Id=PaymentVoucherDetails.TreasuryPayableId --AND TreasuryPayables.Status=''Approved''
INNER JOIN TreasuryPayableDetails ON TreasuryPayableDetails.TreasuryPayableId=TreasuryPayables.Id AND TreasuryPayableDetails.IsActive=1
LEFT JOIN DisbursementRequestPayables ON TreasuryPayableDetails.DisbursementRequestPayableId=DisbursementRequestPayables.Id
AND DisbursementRequestPayables.IsActive=1
LEFT JOIN DisbursementRequestPayees ON DisbursementRequestPayables.Id=DisbursementRequestPayees.DisbursementRequestPayableId
AND DisbursementRequestPayees.IsActive=1
LEFT JOIN DisbursementRequestPaymentDetails ON DisbursementRequestPayees.PayeeId=DisbursementRequestPaymentDetails.Id AND DisbursementRequestPaymentDetails.IsActive=1
LEFT JOIN DisbursementRequests ON DisbursementRequestPaymentDetails.DisbursementRequestId=DisbursementRequests.Id AND DisbursementRequests.Status=''Completed''
LEFT JOIN DisbursementRequestInvoices ON DisbursementRequestInvoices.DisbursementRequestId=DisbursementRequests.Id AND DisbursementRequestInvoices.IsActive=1
LEFT JOIN Payables ON TreasuryPayableDetails.PayableId=Payables.Id --AND Payables.EntityType=''PI'' AND Payables.Status=''Approved''
LEFT JOIN PayableInvoices ON DisbursementRequestInvoices.InvoiceId=PayableInvoices.Id
AND Payables.EntityId=PayableInvoices.Id
AND PayableInvoices.Status=''Completed''
LEFT JOIN Contracts on Contracts.Id=PayableInvoices.ContractId
--WHERE PaymentVouchers.Id IN (792,793,795,796,797)
)AS TEMP Where RowNumber=1
),
InitialSelect
AS
(
Select
RemmitanceGroup=PartyRemitToes.RemittanceGroupingOption,
PaymentVoucherId = PaymentVouchers.Id
,PartyRemitTo=PaymentVouchers.RemitToId
,PayFromAccountId = PaymentVouchers.PayFromAccountId
,Currency=PaymentVouchers.Amount_Currency
,VendorId =  CTE_TreasuryPayableDetail.PayeeId
,Amount=CTE_TreasuryPayableDetail.Amount
,Requestor=Users.LoginName
,InterfacingSystem=CTE_ContractInvoices.InterfacingSystem,
BatchID=PaymentVouchers.Id,
BatchDetailID=PaymentVouchers.Id,
Invoice=CASE WHEN PartyRemitToes.RemittanceGroupingOption=''Individual'' THEN
CTE_ContractInvoices.InvoiceNumber ELSE '''' END,
LeaseNumber=CASE WHEN PartyRemitToes.RemittanceGroupingOption=''Individual'' THEN
CTE_ContractInvoices.SequenceNumber ELSE '''' END,
CheckStubMemo= ISNULL(PaymentVouchers.Memo, '' ''),
IsIndividualFlag = CASE WHEN PartyRemitToes.RemittanceGroupingOption=''Individual'' THEN
''1'' ELSE ''0'' END,
RemitToId=PaymentVouchers.RemitToId
From PaymentVouchers
INNER JOIN CTE_TreasuryPayableDetail ON CTE_TreasuryPayableDetail.PaymentVoucherId=Paymentvouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Check''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
INNER JOIN PartyRemitToes ON PaymentVouchers.RemitToId = PartyRemitToes.RemitToId
AND CTE_TreasuryPayableDetail.PayeeId = PartyRemitToes.PartyId
LEFT JOIN Users ON Users.Id=PaymentVouchers.UpdatedById
LEFT JOIN CTE_ContractInvoices ON CTE_ContractInvoices.PaymentVoucherId=PaymentVouchers.Id
--WHERE PaymentVouchers.RemitToId=45813 AND PayFromAccountId=2744
)
Select
InitialSelect.RemmitanceGroup,
InitialSelect.PaymentVoucherId,
InitialSelect.PartyRemitTo,
InitialSelect.PayFromAccountId,
InitialSelect.Currency,
InitialSelect.VendorId,
InitialSelect.Amount,
InitialSelect.Requestor,
InitialSelect.InterfacingSystem,
InitialSelect.BatchID,
InitialSelect.BatchDetailID,
InitialSelect.Invoice,
InitialSelect.LeaseNumber,
InitialSelect.CheckStubMemo,
InitialSelect.IsIndividualFlag,
AttentionTo=RemitToPartyContacts.FullName,
PayeeName=Parties.PartyName,
Address1=PartyAddresses.AddressLine1,
Address2=PartyAddresses.AddressLine2,
City=PartyAddresses.City,
State=States.ShortName,
ZipCode=PartyAddresses.PostalCode
,VendorType = Vendors.Type
From InitialSelect
INNER JOIN Parties on Parties.Id=InitialSelect.VendorId
INNER JOIN PartyAddresses on PartyAddresses.PartyId=Parties.Id AND PartyAddresses.IsMain=1 AND PartyAddresses.IsActive=1
INNER JOIN States on PartyAddresses.StateId=States.Id AND States.IsActive=1
INNER JOIN Vendors on Vendors.Id=Parties.Id
--AND Vendors.Status=''Active''
INNER JOIN RemitToes ON InitialSelect.RemitToId=RemitToes.Id AND RemitToes.IsActive=1
LEFT JOIN PartyContacts As RemitToPartyContacts ON RemitToes.PartyContactId=RemitToPartyContacts.Id
AND RemitToPartyContacts.IsActive=1
LEFT JOIN PartyContactTypes ON PartyContactTypes.PartyContactId=RemitToPartyContacts.Id
AND PartyContactTypes.ContactType=''Main''
AND PartyContactTypes.IsActive=1
WHERE InitialSelect.Amount>0
WHERECLAUSE
ORDER BY InitialSelect.BatchID
'
if(@AggregateFlag=0 and @PPTAggregateFlag=0)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', 'AND InitialSelect.IsIndividualFlag = 1 ');
IF(@AggregateFlag =0 and @PPTAggregateFlag=1)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', 'AND (InitialSelect.IsIndividualFlag = 1 AND Vendors.Type NOT IN (''TaxCollector'',''TaxAssessor'')) OR (Vendors.Type IN (''TaxCollector'',''TaxAssessor'') AND InitialSelect.IsIndividualFlag = 0)');
IF(@AggregateFlag =1 and @PPTAggregateFlag=0)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', 'AND (InitialSelect.IsIndividualFlag = 1 AND Vendors.Type IN (''TaxCollector'',''TaxAssessor'')) OR Vendors.Type NOT IN (''TaxCollector'',''TaxAssessor'')');
IF(@AggregateFlag =1 and @PPTAggregateFlag=1)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', ' ');
EXEC sp_executesql @SQL
END

GO
