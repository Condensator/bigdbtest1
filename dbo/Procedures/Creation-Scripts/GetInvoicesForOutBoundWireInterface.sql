SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetInvoicesForOutBoundWireInterface] @AggregateFlag BIT
AS
BEGIN
DECLARE @SQL NVARCHAR(Max)
--DECLARE @AggregateFlag BIT
--SET @AggregateFlag = 1
SET @SQL =N'
DECLARE @CurrentDate DateTime
SET @CurrentDate= GetDate()
;WITH CTE_LegalEntityBankDetails
AS
(
SELECT
LegalEntityId
,LegalEntityCurrencyId
From
(
SELECT
LegalEntityId=LegalEntities.Id
,LegalEntityCurrencyId=LegalEntities.CurrencyId
,RowNumber = Row_Number()  over (partition by LegalEntities.Id Order by BankAccounts.Id )
FROM
LegalEntities
INNER JOIN  LegalEntityBankAccounts ON LegalEntities.Id = LegalEntityBankAccounts.LegalEntityId
INNER JOIN BankAccounts  ON LegalEntityBankAccounts.BankAccountId = BankAccounts.Id
AND BankAccounts.IsActive=1
) Test
Where Test.RowNumber = 1
),
CTE_DebitPartyAccountNumber AS
(
SELECT
PaymentVoucherId=PaymentVouchers.Id
,BankAccountId=BankAccounts.Id
FROM PaymentVouchers
INNER JOIN BankAccounts ON PaymentVouchers.PayFromAccountId=BankAccounts.Id
AND BankAccounts.IsActive=1
),
CTE_RemitToDetails AS
(
Select
RemitToId
,BankBranchId = BankBranches.Id 
,Iscorrespondent
,RemitToBankAccountId
, BeneficiaryBankName=BankBranches.BankName
,BankName=BankBranches.BankName
,CurrencyId=BankAccounts.CurrencyId
From
(
Select
RemitToId=RemitToes.Id,
IsCorrespondent=RemitToWireDetails.Iscorrespondent,
RemitToBankAccountId=RemitToWireDetails.BankAccountId,
RowNumber = Row_Number() over (partition by RemitToes.Id Order by RemitToWireDetails.IsBeneficiary desc,RemitToWireDetails.Id desc)
FROM
RemitToes
INNER JOIN RemitToWireDetails ON RemitToes.Id = remitToWireDetails.RemitToId
AND RemitToWireDetails.IsActive=1
AND RemitToes.IsActive=1
) AS Test
INNER JOIN BankAccounts  ON Test.RemitToBankAccountId = BankAccounts.Id AND BankAccounts.IsActive=1
INNER JOIN BankBranches ON BankAccounts.BankBranchId =BankBranches.Id AND BankBranches.IsActive=1
WHERE Test.RowNumber=1
),
CTE_BeneficiaryDetails
AS
(
SELECT
BeneficiaryName
,VendorId
,BeneficiaryAddress
,BeneficiaryCity
,BeneficiaryState
,BeneficiaryZipCode
From
(
SELECT
VendorId=Vendors.Id,
BeneficiaryName=Parties.PartyName,
BeneficiaryAddress=PartyAddresses.AddressLine1,
BeneficiaryCity=PartyAddresses.City,
BeneficiaryState=States.ShortName,
BeneficiaryZipCode=PartyAddresses.PostalCode
FROM
Vendors
INNER JOIN Parties ON Vendors.Id=Parties.Id AND Vendors.Status=''Active''
INNER JOIN PartyAddresses ON Vendors.Id=PartyAddresses.PartyId AND PartyAddresses.IsActive=1 AND PartyAddresses.IsMain=1
INNER JOIN States ON PartyAddresses.StateId=States.Id AND States.IsActive=1
INNER JOIN Countries ON Countries.Id=States.CountryId AND Countries.IsActive=1
) Test
),
CTE_PaymentVouchers AS
(
SELECT
PaymentVoucherId=PaymentVouchers.Id
,TreasuryPayableId=PaymentVoucherDetails.TreasuryPayableId
FROM
PaymentVouchers
INNER JOIN PaymentVoucherDetails ON PaymentVoucherDetails.PaymentVoucherId=PaymentVouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Wire''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
),
CTE_TreasuryPayableDetail AS
(
Select
PaymentVoucherId=PaymentVouchers.Id,
PayeeId=TreasuryPayables.PayeeId,
Sum(PaymentVoucherDetails.Amount_Amount) AS Amount
From PaymentVouchers
INNER JOIN PaymentVoucherDetails ON PaymentVoucherDetails.PaymentVoucherId=PaymentVouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Wire''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
INNER JOIN TreasuryPayables ON TreasuryPayables.Id=PaymentVoucherDetails.TreasuryPayableId
AND TreasuryPayables.Status=''Approved''
GROUP BY PaymentVouchers.Id,TreasuryPayables.PayeeId
),
CTE_PayablesWithDisbursementDetails AS
(
SELECT
TreasuryPayableId=TreasuryPayables.Id
,DisbursementRequestId=DisbursementRequests.Id
,DisbursementMemo=DisbursementRequestPaymentDetails.Memo
,PayableId=Payables.Id
,PayableEntityId=Payables.EntityId
,OriginationType=DisbursementRequests.OriginationType
,PayableSourceTable=Payables.SourceTable
,PayableSourceId=Payables.SourceId
,PayableEntityType=Payables.EntityType
FROM
TreasuryPayables
INNER JOIN TreasuryPayableDetails ON TreasuryPayableDetails.TreasuryPayableId=TreasuryPayables.Id
AND TreasuryPayableDetails.IsActive=1
INNER JOIN DisbursementRequestPayables ON TreasuryPayableDetails.DisbursementRequestPayableId=DisbursementRequestPayables.Id
AND DisbursementRequestPayables.IsActive=1
INNER JOIN DisbursementRequestPayees ON DisbursementRequestPayables.Id=DisbursementRequestPayees.DisbursementRequestPayableId
AND DisbursementRequestPayees.IsActive=1
INNER JOIN DisbursementRequestPaymentDetails ON DisbursementRequestPayees.PayeeId=DisbursementRequestPaymentDetails.Id
AND DisbursementRequestPaymentDetails.IsActive=1
INNER JOIN DisbursementRequests ON DisbursementRequestPaymentDetails.DisbursementRequestId=DisbursementRequests.Id
AND DisbursementRequests.Status=''Completed''
INNER JOIN Payables ON TreasuryPayableDetails.PayableId=Payables.Id
),
CTE_PayablesWithOutDisbursementDetails AS
(
SELECT
TreasuryPayableId=TreasuryPayables.Id
,DisbursementMemo=''''
,PayableId=Payables.Id
,PayableEntityId=Payables.EntityId
,PayableSourceTable=Payables.SourceTable
,PayableSourceId=Payables.SourceId
,PayableEntityType=Payables.EntityType
FROM
TreasuryPayables
INNER JOIN TreasuryPayableDetails ON TreasuryPayableDetails.TreasuryPayableId=TreasuryPayables.Id
AND TreasuryPayableDetails.IsActive=1
INNER JOIN Payables ON TreasuryPayableDetails.PayableId=Payables.Id
),
CTE_PaymentVouchersWithDisbursement AS
(
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
From
(
SELECT
PaymentvoucherId=CTE_PaymentVouchers.PaymentVoucherId
,InvoiceNumber=PayableInvoices.InvoiceNumber
,DisbursementMemo=CTE_PayablesWithDisbursementDetails.DisbursementMemo
,SequenceNumber=Contracts.SequenceNumber
,RowNumber=ROW_NUMBER() over(Partition by CTE_PaymentVouchers.PaymentVoucherId  Order by PayableInvoices.Id desc)
From CTE_PaymentVouchers
INNER JOIN CTE_PayablesWithDisbursementDetails ON CTE_PayablesWithDisbursementDetails.TreasuryPayableId=CTE_PaymentVouchers.TreasuryPayableId
AND CTE_PayablesWithDisbursementDetails.OriginationType IN (''Contract'',''AssetSale'',''StandAlone'',''CashRefund'')
INNER JOIN DisbursementRequestInvoices ON DisbursementRequestInvoices.DisbursementRequestId=CTE_PayablesWithDisbursementDetails.DisbursementRequestId
AND DisbursementRequestInvoices.IsActive=1
INNER JOIN PayableInvoices ON DisbursementRequestInvoices.InvoiceId=PayableInvoices.Id
AND CTE_PayablesWithDisbursementDetails.PayableEntityId=PayableInvoices.Id
AND PayableInvoices.Status=''Completed''
AND CTE_PayablesWithDisbursementDetails.PayableEntityType=''PI''
INNER JOIN Contracts ON Contracts.Id=PayableInvoices.ContractId
UNION ALL
SELECT
PaymentvoucherId=CTE_PaymentVouchers.PaymentVoucherId
,InvoiceNumber=''''
,DisbursementMemo=CTE_PayablesWithDisbursementDetails.DisbursementMemo
,SequenceNumber=''''
,RowNumber=ROW_NUMBER() over(Partition by CTE_PaymentVouchers.PaymentVoucherId Order by PPTInvoices.Id desc)
From CTE_PaymentVouchers
INNER JOIN CTE_PayablesWithDisbursementDetails ON CTE_PayablesWithDisbursementDetails.TreasuryPayableId=CTE_PaymentVouchers.TreasuryPayableId
AND CTE_PayablesWithDisbursementDetails.OriginationType=''PropertyTax'' AND CTE_PayablesWithDisbursementDetails.PayableEntityType=''PPTI''
INNER JOIN PPTInvoices ON PPTInvoices.Id=CTE_PayablesWithDisbursementDetails.PayableEntityId
)AS TEMP Where RowNumber=1
),
CTE_PaymentVouchersWithoutDisbursement AS
(
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
From
(
SELECT
PaymentvoucherId=CTE_PaymentVouchers.PaymentVoucherId
,InvoiceNumber=PayableInvoices.InvoiceNumber
,DisbursementMemo=CTE_PayablesWithOutDisbursementDetails.DisbursementMemo
,SequenceNumber=Contracts.SequenceNumber
,RowNumber=ROW_NUMBER() over(Partition by CTE_PaymentVouchers.PaymentVoucherId  Order by PayableInvoices.Id desc)
From CTE_PaymentVouchers
INNER JOIN CTE_PayablesWithOutDisbursementDetails ON CTE_PayablesWithOutDisbursementDetails.TreasuryPayableId=CTE_PaymentVouchers.TreasuryPayableId
AND CTE_PaymentVouchers.PaymentVoucherId NOT IN (SELECT PaymentVoucherId FROM CTE_PayablesWithDisbursementDetails)
INNER JOIN PayableInvoices ON CTE_PayablesWithOutDisbursementDetails.PayableEntityId=PayableInvoices.Id
AND PayableInvoices.Status=''Completed''
AND CTE_PayablesWithOutDisbursementDetails.PayableEntityType=''PI''
INNER JOIN Contracts ON Contracts.Id=PayableInvoices.ContractId
UNION ALL
SELECT
PaymentvoucherId=CTE_PaymentVouchers.PaymentVoucherId
,InvoiceNumber=''''
,DisbursementMemo=CTE_PayablesWithOutDisbursementDetails.DisbursementMemo
,SequenceNumber=''''
,RowNumber=ROW_NUMBER() over(Partition by CTE_PaymentVouchers.PaymentVoucherId Order by PPTInvoices.Id desc)
From CTE_PaymentVouchers
INNER JOIN CTE_PayablesWithOutDisbursementDetails ON CTE_PayablesWithOutDisbursementDetails.TreasuryPayableId=CTE_PaymentVouchers.TreasuryPayableId
AND CTE_PayablesWithOutDisbursementDetails.PayableEntityType=''PPTI''
AND CTE_PaymentVouchers.PaymentVoucherId NOT IN (SELECT PaymentVoucherId FROM CTE_PayablesWithDisbursementDetails)
INNER JOIN PPTInvoices ON PPTInvoices.Id=CTE_PayablesWithOutDisbursementDetails.PayableEntityId
)AS TEMP Where RowNumber=1
),
CTE_PaymentVouchersWithPayableDetails AS
(
SELECT * FROM CTE_PaymentVouchersWithoutDisbursement
UNION ALL
SELECT * FROM CTE_PaymentVouchersWithDisbursement
),
CTE_SundriesForBatchWire AS
(
SELECT
SundryId=Sundries.Id
,SequenceNumber=CASE
WHEN Sundries.EntityType=''CT''THEN Contracts.SequenceNumber
ELSE ''''
END
FROM Sundries
LEFT JOIN Contracts ON Contracts.Id =Sundries.ContractId
WHERE SundryType=''PayableOnly''
UNION ALL
SELECT
SundryId=Sundries.Id
,SequenceNumber=CASE
WHEN Sundries.EntityType=''CT''THEN Contracts.SequenceNumber
ELSE ''''
END
FROM Sundries
INNER JOIN ReceivableCodes ON Sundries.ReceivableCodeId=ReceivableCodes.Id
AND ReceivableCodes.AccountingTreatment=''CashBased''
LEFT JOIN Contracts ON Contracts.Id =Sundries.ContractId
WHERE SundryType=''PassThrough''
),
CTE_PayablesWithSundries AS
(
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
From
(
SELECT
PaymentvoucherId=CTE_PaymentVouchers.PaymentVoucherId
,InvoiceNumber=''''
,DisbursementMemo=CTE_PayablesWithOutDisbursementDetails.DisbursementMemo
,SequenceNumber=CTE_SundriesForBatchWire.SequenceNumber
,RowNumber=ROW_NUMBER() over(Partition by CTE_PaymentVouchers.PaymentVoucherId Order by Sundries.Id desc)
From CTE_PaymentVouchers
INNER JOIN CTE_PayablesWithOutDisbursementDetails ON CTE_PayablesWithOutDisbursementDetails.TreasuryPayableId=CTE_PaymentVouchers.TreasuryPayableId
AND CTE_PayablesWithOutDisbursementDetails.PayableEntityType=''PPTI''
INNER JOIN Sundries ON Sundries.PayableId=CTE_PayablesWithOutDisbursementDetails.PayableId
OR ( CTE_PayablesWithOutDisbursementDetails.PayableSourceTable=''SundryPayable'' AND CTE_PayablesWithOutDisbursementDetails.PayableSourceId=Sundries.Id )
INNER JOIN CTE_SundriesForBatchWire ON CTE_SundriesForBatchWire.SundryId=Sundries.Id
)AS TEMP Where RowNumber=1
),
CTE_ContractInvoices AS
(
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
FROM
CTE_PaymentVouchersWithDisbursement
UNION ALL
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
FROM
CTE_PaymentVouchersWithoutDisbursement
UNION ALL
Select
PaymentVoucherId
,InvoiceNumber
,SequenceNumber
,DisbursementMemo
FROM
CTE_PayablesWithSundries
),
InitialSelect
AS
(
Select
RemmitanceGroup=PartyRemitToes.RemittanceGroupingOption
,SourceSystemUniqueID=PaymentVouchers.Id
,PartyRemitTo=PaymentVouchers.RemitToId
,PayFromAccountId = PaymentVouchers.PayFromAccountId
,CurrencyCode=PaymentVouchers.Amount_Currency
,VendorId = CTE_TreasuryPayableDetail.PayeeId
,BankBranchId = CTE_RemitToDetails.BankBranchId
,DisbursementAmount=CTE_TreasuryPayableDetail.Amount
,BatchID=PaymentVouchers.Id
,IsAggregateWire = CASE WHEN PartyRemitToes.RemittanceGroupingOption=''Aggregate'' THEN
''1'' ELSE ''0'' END
,DebitPartyName=LegalEntities.Name
,LegalEntityId = LegalEntities.Id
,DebitPartyBankAccountId=CTE_DebitPartyAccountNumber.BankAccountId
,BeneficiaryBankAccountId=CTE_RemitToDetails.RemitToBankAccountId
,BeneficiaryBankType=CAST(CASE WHEN (CTE_RemitToDetails.CurrencyId=CTE_LegalEntityBankDetails.LegalEntityCurrencyId) THEN ''A'' ELSE ''S'' END AS NVARCHAR)
,BeneficiaryBankName=CTE_RemitToDetails.BankName
,BeneficiaryName=CTE_BeneficiaryDetails.BeneficiaryName
,BeneficiaryAddress=CTE_BeneficiaryDetails.BeneficiaryAddress
,BeneficiaryCity=CTE_BeneficiaryDetails.BeneficiaryCity
,BeneficiaryState=CTE_BeneficiaryDetails.BeneficiaryState
,BeneficiaryZipCode=CTE_BeneficiaryDetails.BeneficiaryZipCode
,IntermediaryBankRoutingNumber=CAST( '''' AS NVARCHAR)
,IntermediaryBankName=CAST( '''' AS NVARCHAR)
,DisbursementID=CAST(
CASE
WHEN PartyRemitToes.RemittanceGroupingOption=''Aggregate''
THEN null
ELSE PaymentVouchers.Id
END AS NVARCHAR
)
,DisbursementMemo=CTE_ContractInvoices.DisbursementMemo
,ContractNumber=
CAST(
CASE
WHEN PartyRemitToes.RemittanceGroupingOption=''Aggregate''
THEN null
ELSE CTE_ContractInvoices.SequenceNumber
END AS NVARCHAR
)
,VendorInvoiceNumber=
CAST(
CASE
WHEN PartyRemitToes.RemittanceGroupingOption=''Aggregate''
THEN null
ELSE CTE_ContractInvoices.InvoiceNumber
END AS NVARCHAR
)
,Iscorrespondent=CTE_RemitToDetails.Iscorrespondent
From PaymentVouchers
INNER JOIN CTE_TreasuryPayableDetail ON CTE_TreasuryPayableDetail.PaymentVoucherId=Paymentvouchers.Id
AND PaymentVouchers.BatchId Is NULL
AND PaymentVouchers.ReceiptType=''Wire''
AND PaymentVouchers.Status=''Paid''
AND PaymentVouchers.IsManual=0
AND OriginalVoucherId is null
AND PaymentVouchers.Amount_Amount > 0
LEFT JOIN  PartyRemitToes ON PartyRemitToes.PartyId = CTE_TreasuryPayableDetail.PayeeId
AND PartyRemitToes.RemitToId = PaymentVouchers.RemitToId
LEFT JOIN LegalEntities ON PaymentVouchers.LegalEntityId=LegalEntities.Id
AND LegalEntities.Status=''Active''
LEFT JOIN CTE_LegalEntityBankDetails ON CTE_LegalEntityBankDetails.LegalEntityId=PaymentVouchers.LegalEntityId
LEFT JOIN CTE_BeneficiaryDetails ON CTE_BeneficiaryDetails.VendorId=CTE_TreasuryPayableDetail.PayeeId
LEFT JOIN CTE_RemitToDetails ON CTE_RemitToDetails.RemitToId=PaymentVouchers.RemitToId
LEFT JOIN CTE_ContractInvoices ON CTE_ContractInvoices.PaymentVoucherId=PaymentVouchers.Id
LEFT JOIN CTE_DebitPartyAccountNumber ON CTE_DebitPartyAccountNumber.PaymentVoucherId=PaymentVouchers.Id
)
Select
InitialSelect.*
,SystemMnemonic=''EQF''
,SourceSystemID=''LeaseWave''
,RecordType=''DTL''
,WireSequenceNumber= CONVERT(NVARCHAR,ROW_NUMBER() OVER (order by InitialSelect.SourceSystemUniqueID))
,RequestDate=CONVERT(NVARCHAR,@CurrentDate,101)+'' ''+CONVERT(NVARCHAR,@CurrentDate,108)
,DebitPartyType=(''D'')
From InitialSelect
INNER JOIN Parties ON Parties.Id=InitialSelect.VendorId
INNER JOIN PartyAddresses ON PartyAddresses.PartyId=Parties.Id
AND PartyAddresses.IsMain=1
AND PartyAddresses.IsActive=1
INNER JOIN States ON PartyAddresses.StateId=States.Id
AND States.IsActive=1
INNER JOIN Vendors ON Vendors.Id=Parties.Id
WHERECLAUSE'
if(@AggregateFlag=0)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', 'WHERE InitialSelect.IsAggregateWire = 0');
IF(@AggregateFlag =1)
SET @SQL = REPLACE(@SQL, 'WHERECLAUSE', ' ');
EXEC sp_executesql @SQL
END

GO
