SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetRecentFundings]
(
@CurrentVendorId BIGINT
)
AS
BEGIN
SELECT DISTINCT
PaymentVoucher.PaymentDate
,SUM(DisbursementRequestPayable.AmountToPay_Amount) AS PaymentAmount_Amount
,Payable.Amount_Currency AS PaymentAmount_Currency
,Party.PartyName AS PayeeName
,PayableInvoice.InvoiceNumber AS Reference_InvoiceNumber
,PayableInvoice.InvoiceNumber AS Reference_Memo
,PayableInvoice.InvoiceTotal_Amount AS Amount_Amount
,PayableInvoice.InvoiceTotal_Currency AS Amount_Currency
,ISNULL(C.SequenceNumber,'') AS SequenceNumber
,PayableInvoice.Id AS InvoiceId
,PayableInvoice.ContractId
INTO #PayableinvoicePayables
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id=PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id= TreasuryPayableDetail.TreasuryPayableId
JOIN DisbursementRequestPayables DisbursementRequestPayable ON TreasuryPayableDetail.DisbursementRequestPayableId= DisbursementRequestPayable.Id
JOIN DisbursementRequestPayees DisbursementRequestPayee ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId
JOIN DisbursementRequestPaymentDetails DisbursementRequestPaymentDetail ON DisbursementRequestPayee.PayeeId=DisbursementRequestPaymentDetail.Id
JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPaymentDetail.DisbursementRequestId=DisbursementRequest.Id
JOIN Payables Payable ON DisbursementRequestPayable.PayableId=Payable.Id
JOIN PayableInvoices PayableInvoice ON Payable.EntityId=PayableInvoice.Id AND Payable.EntityType='PI'
JOIN Parties Party ON PayableInvoice.VendorId =Party.Id
LEFT JOIN PayableInvoiceAssets PIA ON Payable.SourceId=PIA.Id AND Payable.SourceTable='PayableInvoiceAsset'
LEFT JOIN LeaseAssets LA on PIA.AssetId=LA.AssetId
LEFT JOIN LeaseFinances Lease ON LA.LeaseFinanceId=Lease.Id
LEFT JOIN Contracts C ON PayableInvoice.ContractId = C.Id OR Lease.ContractId=C.Id
WHERE TreasuryPayable.PayeeId=DisbursementRequestPaymentDetail.PayeeId
AND DisbursementRequestPaymentDetail.PayeeId=@CurrentVendorId
AND PayableInvoice.VendorId=@CurrentVendorId
AND DisbursementRequestPaymentDetail.IsActive = 1
AND DisbursementRequestPayee.IsActive = 1
AND DisbursementRequestPayable.IsActive = 1
AND DisbursementRequest.Status = 'Completed'
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND PayableInvoice.Status!='InActive'
AND PaymentVoucher.OriginalVoucherId IS NULL
AND (Lease.IsCurrent IS NULL OR Lease.IsCurrent=1)
GROUP BY PayableInvoice.Id
,PayableInvoice.InvoiceNumber
,PayableInvoice.InvoiceTotal_Amount
,PayableInvoice.InvoiceTotal_Currency
,PayableInvoice.ContractId
,C.SequenceNumber
,Payable.Amount_Currency
,PaymentVoucher.PaymentDate
,Party.PartyName
;
SELECT DISTINCT
PaymentVoucher.PaymentDate
,SUM(Payable.Amount_Amount- Payable.Balance_Amount) AS PaymentAmount_Amount
,Payable.Amount_Currency AS PaymentAmount_Currency
,Party.PartyName AS PayeeName
,''AS Reference_InvoiceNumber
,ISNULL(BlendedItem.Name,Sundry.Memo) AS Reference_Memo
,Sundry.Amount_Amount AS Amount_Amount
,Sundry.Amount_Currency AS Amount_Currency
,C.SequenceNumber
,'' AS InvoiceId
,Sundry.ContractId
INTO #SundryPayables
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id=PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id= TreasuryPayableDetail.TreasuryPayableId
JOIN Payables Payable ON TreasuryPayableDetail.PayableId=Payable.Id
JOIN Sundries Sundry ON Payable.SourceId=Sundry.Id AND Payable.SourceTable='SundryPayable'
JOIN Parties Party ON Sundry.VendorId =Party.Id
LEFT JOIN Contracts C ON Sundry.ContractId = C.Id
LEFT JOIN BlendedItemDetails BlendedItemDetail ON Sundry.Id=BlendedItemDetail.SundryId
LEFT JOIN BlendedItems BlendedItem ON BlendedItemDetail.BlendedItemId=BlendedItem.Id
WHERE TreasuryPayable.PayeeId=Sundry.VendorId
AND Sundry.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (BlendedItemDetail.IsActive IS NULL OR BlendedItemDetail.IsActive=1)
AND (BlendedItem.IsActive IS NULL OR BlendedItem.IsActive=1)
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND PaymentVoucher.OriginalVoucherId IS  NULL
GROUP BY PaymentVoucher.PaymentDate
,Payable.Amount_Currency
,Party.PartyName
,Sundry.Memo
,Sundry.Amount_Amount
,Sundry.Amount_Currency
,C.SequenceNumber
,Sundry.ContractId
,BlendedItem.Name
;
SELECT DISTINCT
PaymentVoucher.PaymentDate
,SUM(Payable.Amount_Amount- Payable.Balance_Amount) AS PaymentAmount_Amount
,Payable.Amount_Currency AS PaymentAmount_Currency
,Party.PartyName AS PayeeName
,''AS Reference_InvoiceNumber
,ISNULL(SR.Memo,'') AS Reference_Memo
,SRPS.Amount_Amount AS Amount_Amount
,SRPS.Amount_Currency AS Amount_Currency
,C.SequenceNumber
,'' AS InvoiceId
,SR.ContractId
INTO #SundryRecurringPayables
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id = PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId = TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id = TreasuryPayableDetail.TreasuryPayableId And TreasuryPayableDetail.IsActive = 1
JOIN Payables Payable on TreasuryPayableDetail.PayableId = Payable.Id
JOIN SundryRecurringPaymentSchedules SRPS on Payable.SourceId = SRPS.Id
JOIN SundryRecurrings SR ON SRPS.SundryRecurringId = SR.Id AND Payable.SourceTable = 'SundryRecurPaySch'
JOIN Parties Party ON SR.VendorId =Party.Id
LEFT JOIN Contracts C ON SR.ContractId = C.Id
WHERE TreasuryPayable.PayeeId=SR.VendorId
AND SR.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND SRPS.IsActive=1
AND SR.IsActive=1
AND PaymentVoucher.OriginalVoucherId IS  NULL
GROUP BY PaymentVoucher.PaymentDate
,Payable.Amount_Currency
,Party.PartyName
,SR.Memo
,SRPS.Amount_Amount
,SRPS.Amount_Currency
,C.SequenceNumber
,SR.ContractId
;
SELECT *  FROM (
SELECT * FROM #PayableinvoicePayables
UNION ALL
SELECT * FROM #SundryPayables
UNION ALL
SELECT * FROM #SundryRecurringPayables
) AS TMP
DROP TABLE #PayableinvoicePayables
DROP TABLE #SundryPayables
DROP TABLE #SundryRecurringPayables
END

GO
