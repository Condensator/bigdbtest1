SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VP_GetVoucherInvoices]
(
@VoucherId BIGINT,
@CurrentVendorId BIGINT
)
AS
BEGIN
WITH CTE_PayableinvoicePayables
AS
(
SELECT DISTINCT
PayableInvoice.Id AS InvoiceId
,PayableInvoice.InvoiceNumber AS Reference_InvoiceNumber
,PayableInvoice.DueDate
,SUM(Payable.Amount_Amount) AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,Party.PartyName AS CustomerName
,PayableInvoice.InvoiceNumber AS Reference_Memo
,PayableInvoice.VendorId
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
JOIN Parties Party ON PayableInvoice.CustomerId =Party.Id
WHERE PaymentVoucher.Id=@VoucherId
AND TreasuryPayable.PayeeId=DisbursementRequestPaymentDetail.PayeeId
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
GROUP BY PayableInvoice.Id
,PayableInvoice.InvoiceNumber
,PayableInvoice.DueDate
,Payable.Amount_Currency
,Party.PartyName
,PayableInvoice.VendorId
),
CTE_SundryPayables
AS
(
SELECT DISTINCT
'' AS InvoiceId
,''AS Reference_InvoiceNumber
,Sundry.PayableDueDate AS DueDate
,SUM(Payable.Amount_Amount- Payable.Balance_Amount) AS AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,Party.PartyName AS CustomerName
,ISNULL(BlendedItem.Name,Sundry.Memo) AS Reference_Memo
, Sundry.VendorId
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id=PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id= TreasuryPayableDetail.TreasuryPayableId
JOIN Payables Payable ON TreasuryPayableDetail.PayableId=Payable.Id
JOIN Sundries Sundry ON Payable.SourceId=Sundry.Id AND Payable.SourceTable='SundryPayable'
JOIN Parties Party ON Sundry.CustomerId =Party.Id
LEFT JOIN BlendedItemDetails BlendedItemDetail ON Sundry.Id=BlendedItemDetail.SundryId
LEFT JOIN BlendedItems BlendedItem ON BlendedItemDetail.BlendedItemId=BlendedItem.Id
WHERE PaymentVoucher.Id=@VoucherId
AND TreasuryPayable.PayeeId=Sundry.VendorId
AND Sundry.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND PaymentVoucher.OriginalVoucherId IS  NULL
AND (BlendedItemDetail.IsActive IS NULL OR BlendedItemDetail.IsActive=1)
AND (BlendedItem.IsActive IS NULL OR BlendedItem.IsActive=1)
GROUP BY Sundry.PayableDueDate
,Payable.Amount_Currency
,Party.PartyName
,Sundry.Memo
,Sundry.VendorId
,BlendedItem.Name
),
CTE_SundryRecurringPayables
AS
(
SELECT DISTINCT
'' AS InvoiceId
,''AS Reference_InvoiceNumber
,SRPS.DueDate AS DueDate
,SUM(Payable.Amount_Amount- Payable.Balance_Amount) AS AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,Party.PartyName AS CustomerName
,SR.Memo AS Reference_Memo
,SR.VendorId
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id = PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId = TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id = TreasuryPayableDetail.TreasuryPayableId And TreasuryPayableDetail.IsActive = 1
JOIN Payables Payable on TreasuryPayableDetail.PayableId = Payable.Id
JOIN SundryRecurringPaymentSchedules SRPS on Payable.SourceId = SRPS.Id
JOIN SundryRecurrings SR ON SRPS.SundryRecurringId = SR.Id AND Payable.SourceTable = 'SundryRecurPaySch'
JOIN Parties Party ON SR.VendorId =Party.Id
LEFT JOIN Contracts C ON SR.ContractId = C.Id
WHERE  PaymentVoucher.Id=@VoucherId
AND TreasuryPayable.PayeeId=SR.VendorId
AND SR.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND SRPS.IsActive=1
AND SR.IsActive=1
AND PaymentVoucher.OriginalVoucherId IS  NULL
GROUP BY SRPS.DueDate
,Payable.Amount_Currency
,Party.PartyName
,SR.Memo
,SR.VendorId
)
SELECT * FROM CTE_PayableinvoicePayables
UNION ALL
SELECT * FROM CTE_SundryPayables
UNION ALL
SELECT * FROM CTE_SundryRecurringPayables
END

GO
