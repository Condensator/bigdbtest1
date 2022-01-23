SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[VP_GetPaymentVoucherDetails]
(
@CurrentVendorId BIGINT,
@VoucherId BIGINT=NULL,
@ProgramVendor NVARCHAR(250)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@InvoiceFromDueDate DATETIMEOFFSET=NULL,
@InvoiceToDueDate DATETIMEOFFSET=NULL,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName  NVARCHAR(250)=NULL,
@PayableType NVARCHAR(20)=NULL,
@PaidDateFrom DATETIMEOFFSET=NULL,
@PaidDateTo DATETIMEOFFSET=NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_CustomerDetails
AS
(
SELECT
PInv.[Id]
FROM [dbo].[PayableInvoices] AS PInv
JOIN [dbo].[Vendors] AS V ON PInv.VendorId = V.Id
JOIN [dbo].[Parties] AS PVen ON V.Id = PVen.Id
JOIN [dbo].[Customers] AS C ON PInv.CustomerId = C.Id
JOIN [dbo].[Parties] AS P ON C.ID = P.Id
WHERE PInv.Status!=''InActive''
AND (PInv.VendorId = @CurrentVendorId)
AND (@ProgramVendor IS NULL OR PVen.PartyName LIKE REPLACE(@ProgramVendor,''*'',''%''))
AND (@InvoiceNumber IS NULL OR PInv.InvoiceNumber LIKE REPLACE(@InvoiceNumber ,''*'',''%''))
AND (@CustomerNumber IS NULL OR P.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR P.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND ((@InvoiceFromDueDate IS NULL OR CAST(@InvoiceFromDueDate AS DATE)  <= PInv.DueDate)
AND (@InvoiceToDueDate IS NULL OR CAST(@InvoiceToDueDate AS DATE) >= PInv.DueDate))
),
CTE_PayableInvoicePayables
AS
(
SELECT DISTINCT
PaymentVoucher.Id
,PaymentVoucher.Id PaymentVoucherId
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate AS PaidDate
,PaymentVoucher.ReceiptType
,ISNULL(PaymentVoucher.CheckNumber,ISNULL(PaymentVoucher.FederalReferenceNumber,'''')) AS CheckNumber
,PaymentVoucher.FederalReferenceNumber AS ReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id=PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id= TreasuryPayableDetail.TreasuryPayableId
JOIN DisbursementRequestPayables DisbursementRequestPayable ON TreasuryPayableDetail.DisbursementRequestPayableId= DisbursementRequestPayable.Id
JOIN DisbursementRequestPayees DisbursementRequestPayee ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId
JOIN DisbursementRequestPaymentDetails DisbursementRequestPaymentDetail ON DisbursementRequestPayee.PayeeId=DisbursementRequestPaymentDetail.Id
JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPaymentDetail.DisbursementRequestId=DisbursementRequest.Id
JOIN Payables Payable ON DisbursementRequestPayable.PayableId=Payable.Id
JOIN CTE_CustomerDetails PayableInvoice ON Payable.EntityId=PayableInvoice.Id AND Payable.EntityType=''PI''
WHERE TreasuryPayable.PayeeId=DisbursementRequestPaymentDetail.PayeeId
AND DisbursementRequestPaymentDetail.PayeeId=@CurrentVendorId
AND DisbursementRequestPaymentDetail.IsActive = 1
AND DisbursementRequestPayee.IsActive = 1
AND DisbursementRequestPayable.IsActive = 1
AND DisbursementRequest.Status = ''Completed''
AND PaymentVoucher.Status=''Paid''
AND TreasuryPayable.Status !=''Inactive''
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status =''Approved'' OR Payable.Status =''PartiallyApproved'')
AND PaymentVoucher.OriginalVoucherId IS NULL
AND (@VoucherId IS NULL OR PaymentVoucher.Id = @VoucherId)
AND ((@PaidDateFrom IS NULL OR CAST(@PaidDateFrom AS DATE)  <= PaymentVoucher.PaymentDate)
AND (@PaidDateTo IS NULL OR CAST(@PaidDateTo AS DATE) >= PaymentVoucher.PaymentDate))
AND (@PayableType IS NULL OR PaymentVoucher.ReceiptType LIKE REPLACE(@PayableType,''*'',''%''))
GROUP BY PaymentVoucher.Id
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate
,PaymentVoucher.ReceiptType
,PaymentVoucher.CheckNumber
,PaymentVoucher.FederalReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
),
CTE_SundryPayables
AS
(
SELECT DISTINCT
PaymentVoucher.Id
,PaymentVoucher.Id PaymentVoucherId
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate AS PaidDate
,PaymentVoucher.ReceiptType
,ISNULL(PaymentVoucher.CheckNumber,ISNULL(PaymentVoucher.FederalReferenceNumber,'''')) AS CheckNumber
,PaymentVoucher.FederalReferenceNumber AS ReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id=PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id= TreasuryPayableDetail.TreasuryPayableId
JOIN Payables Payable ON TreasuryPayableDetail.PayableId=Payable.Id
JOIN Sundries Sundry ON Payable.SourceId=Sundry.Id AND Payable.SourceTable=''SundryPayable''
JOIN Parties Party ON Sundry.VendorId =Party.Id
JOIN Parties PartyCustomer ON Sundry.CustomerId=PartyCustomer.Id
WHERE TreasuryPayable.PayeeId=Sundry.VendorId
AND Sundry.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status=''Paid''
AND TreasuryPayable.Status !=''Inactive''
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status =''Approved'' OR Payable.Status =''PartiallyApproved'')
AND PaymentVoucher.OriginalVoucherId IS  NULL
AND (@VoucherId IS NULL OR PaymentVoucher.Id = @VoucherId)
AND ((@PaidDateFrom IS NULL OR CAST(@PaidDateFrom AS DATE)  <= PaymentVoucher.PaymentDate)
AND (@PaidDateTo IS NULL OR CAST(@PaidDateTo AS DATE) >= PaymentVoucher.PaymentDate))
AND (@PayableType IS NULL OR PaymentVoucher.ReceiptType LIKE REPLACE(@PayableType,''*'',''%''))
AND (@CustomerNumber IS NULL OR PartyCustomer.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR PartyCustomer.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ProgramVendor IS NULL OR Party.PartyName LIKE REPLACE(@ProgramVendor,''*'',''%''))
AND (@InvoiceNumber IS NULL  OR Sundry.Memo LIKE REPLACE(@InvoiceNumber ,''*'',''%''))
AND ((@InvoiceFromDueDate IS NULL OR CAST(@InvoiceFromDueDate AS DATE)  <= Sundry.PayableDueDate)
AND (@InvoiceToDueDate IS NULL OR CAST(@InvoiceToDueDate AS DATE) >= Sundry.PayableDueDate))
GROUP BY PaymentVoucher.Id
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate
,PaymentVoucher.ReceiptType
,PaymentVoucher.CheckNumber
,PaymentVoucher.FederalReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
),
CTE_SundryRecurringPayables
AS
(
SELECT DISTINCT
PaymentVoucher.Id
,PaymentVoucher.Id PaymentVoucherId
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate AS PaidDate
,PaymentVoucher.ReceiptType
,ISNULL(PaymentVoucher.CheckNumber,ISNULL(PaymentVoucher.FederalReferenceNumber,'''')) AS CheckNumber
,PaymentVoucher.FederalReferenceNumber AS ReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
FROM PaymentVouchers PaymentVoucher
JOIN PaymentVoucherDetails PaymentVoucherDetail ON PaymentVoucher.Id = PaymentVoucherDetail.PaymentVoucherId
JOIN TreasuryPayables TreasuryPayable ON PaymentVoucherDetail.TreasuryPayableId = TreasuryPayable.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayable.Id = TreasuryPayableDetail.TreasuryPayableId
JOIN Payables Payable on TreasuryPayableDetail.PayableId = Payable.Id
JOIN SundryRecurringPaymentSchedules SRPS ON Payable.SourceId = SRPS.Id
JOIN SundryRecurrings SR ON SRPS.SundryRecurringId = SR.Id AND Payable.SourceTable = ''SundryRecurPaySch''
JOIN Parties Party ON SR.VendorId =Party.Id
JOIN Parties PartyCustomer ON SR.CustomerId=PartyCustomer.Id
LEFT JOIN Contracts C ON SR.ContractId = C.Id
WHERE TreasuryPayable.PayeeId=SR.VendorId
AND SR.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND PaymentVoucher.Status=''Paid''
AND TreasuryPayable.Status !=''Inactive''
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status =''Approved'' OR Payable.Status =''PartiallyApproved'')
AND SRPS.IsActive=1
AND SR.IsActive=1
AND PaymentVoucher.OriginalVoucherId IS  NULL
AND (@VoucherId IS NULL OR PaymentVoucher.Id = @VoucherId)
AND ((@PaidDateFrom IS NULL OR CAST(@PaidDateFrom AS DATE)  <= PaymentVoucher.PaymentDate)
AND (@PaidDateTo IS NULL OR CAST(@PaidDateTo AS DATE) >= PaymentVoucher.PaymentDate))
AND (@PayableType IS NULL OR PaymentVoucher.ReceiptType LIKE REPLACE(@PayableType,''*'',''%''))
AND (@CustomerNumber IS NULL OR PartyCustomer.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR PartyCustomer.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@ProgramVendor IS NULL OR Party.PartyName LIKE REPLACE(@ProgramVendor,''*'',''%''))
AND (@InvoiceNumber IS NULL  OR SR.Memo LIKE REPLACE(@InvoiceNumber ,''*'',''%''))
AND ((@InvoiceFromDueDate IS NULL OR CAST(@InvoiceFromDueDate AS DATE)  <= SRPS.DueDate)
AND (@InvoiceToDueDate IS NULL OR CAST(@InvoiceToDueDate AS DATE) >= SRPS.DueDate))
GROUP BY PaymentVoucher.Id
,PaymentVoucher.VoucherNumber
,PaymentVoucher.PaymentDate
,PaymentVoucher.ReceiptType
,PaymentVoucher.CheckNumber
,PaymentVoucher.FederalReferenceNumber
,PaymentVoucher.Amount_Amount
,PaymentVoucher.Amount_Currency
,PaymentVoucher.CheckDate
),
CTE_Result
AS
(
SELECT * FROM CTE_PayableinvoicePayables
UNION ALL
SELECT * FROM CTE_SundryPayables
UNION ALL
SELECT * FROM CTE_SundryRecurringPayables
)
SELECT DISTINCT * FROM CTE_Result
'
EXEC sp_executesql @Sql,N'
@CurrentVendorId BIGINT,
@VoucherId BIGINT=NULL,
@ProgramVendor NVARCHAR(250)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@InvoiceFromDueDate DATETIMEOFFSET=NULL,
@InvoiceToDueDate DATETIMEOFFSET=NULL,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName NVARCHAR(250)=NULL,
@PayableType NVARCHAR(20)=NULL,
@PaidDateFrom DATETIMEOFFSET=NULL,
@PaidDateTo DATETIMEOFFSET=NULL'
,@CurrentVendorId
,@VoucherId
,@ProgramVendor
,@InvoiceNumber
,@InvoiceFromDueDate
,@InvoiceToDueDate
,@CustomerNumber
,@CustomerName
,@PayableType
,@PaidDateFrom
,@PaidDateTo

GO
