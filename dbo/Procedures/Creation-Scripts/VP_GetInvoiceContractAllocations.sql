SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetInvoiceContractAllocations]
(
@InvoiceId BIGINT,
@SequenceNumber NVARCHAR(80)=NULL,
@CurrentVendorId BIGINT
)
AS
SET NOCOUNT ON;
WITH CTE_PayablePaidAmount
AS
(
SELECT
Payable.Id AS InvoiceId
,SUM(DisbursementRequestPayee.PaidAmount_Amount) AS PayablePaidAmount
FROM Payables AS Payable
JOIN PayableCodes PayableCode ON Payable.PayableCodeId =PayableCode.Id
JOIN PayableTypes PayableType ON PayableCode.PayableTypeId=PayableType.Id
JOIN DisbursementRequestPayables DisbursementRequestPayable  ON Payable.Id=DisbursementRequestPayable.PayableId
JOIN DisbursementRequestPayees DisbursementRequestPayee ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId
JOIN DisbursementRequestPaymentDetails DisbursementRequestPaymentDetail ON DisbursementRequestPayee.PayeeId=DisbursementRequestPaymentDetail.Id
JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPaymentDetail.DisbursementRequestId=DisbursementRequest.Id
JOIN TreasuryPayableDetails TreasuryPayableDetail ON TreasuryPayableDetail.DisbursementRequestPayableId= DisbursementRequestPayable.Id
JOIN TreasuryPayables TreasuryPayable  ON  TreasuryPayableDetail.TreasuryPayableId = TreasuryPayable.Id
JOIN PaymentVoucherDetails PaymentVoucherDetail  ON PaymentVoucherDetail.TreasuryPayableId=TreasuryPayable.Id
JOIN PaymentVouchers PaymentVoucher ON PaymentVoucherDetail.PaymentVoucherId=PaymentVoucher.Id
--PPC Take down
LEFT JOIN PayableInvoiceOtherCosts  PayableInvoiceOtherCost ON Payable.SourceId = PayableInvoiceOtherCost.Id
AND Payable.SourceTable='PayableInvoiceOtherCost'
AND PayableInvoiceOtherCost.AllocationMethod = 'ProgressPaymentCredit'
AND PayableInvoiceOtherCost.IsActive = 1
WHERE Payable.EntityType='PI'
AND (Payable.SourceTable='PayableInvoiceAsset' OR Payable.SourceTable='PayableInvoiceOtherCost')
AND Payable.Status!='Inactive'
AND PayableType.IsActive=1
AND PayableCode.IsActive=1
AND DisbursementRequestPaymentDetail.IsActive = 1
AND DisbursementRequestPayee.IsActive = 1
AND DisbursementRequestPayable.IsActive = 1
AND DisbursementRequest.Status = 'Completed'
AND PaymentVoucher.Status='Paid'
AND TreasuryPayable.Status !='Inactive'
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status ='Approved' OR Payable.Status ='PartiallyApproved')
AND PaymentVoucher.OriginalVoucherId IS NULL
AND DisbursementRequestPaymentDetail.PayeeId=@CurrentVendorId
AND  TreasuryPayable.PayeeId=@CurrentVendorId
GROUP BY Payable.Id
),
CTE_CreditApplied
AS
(
SELECT
Payable.Id as InvoiceId
,ISNULL(SUM(DisbursementRequestPayee.ReceivablesApplied_Amount),0.00) AS CreditApplied_Amount
FROM Payables Payable
JOIN DisbursementRequestPayables DisbursementRequestPayable  ON Payable.Id=DisbursementRequestPayable.PayableId
JOIN DisbursementRequestPayees DisbursementRequestPayee ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId
JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPayable.DisbursementRequestId=DisbursementRequest.Id
WHERE (Payable.Status IS NULL OR Payable.Status!='Inactive')
AND (DisbursementRequestPayable.IsActive IS NULL OR DisbursementRequestPayable.IsActive=1)
AND (DisbursementRequestPayee.IsActive IS NULL OR DisbursementRequestPayee.IsActive=1)
AND (DisbursementRequest.Status IS NULL OR DisbursementRequest.Status='Completed')
GROUP BY Payable.Id
),
CTE_InvoicesCompletedStatus
AS
(
SELECT
PIN.Id AS InvoiceId
,PIN.InvoiceNumber
,ISNULL(C.SequenceNumber,'UnAllocated') AS SequenceNumber
,P.Amount_Amount AS InvoiceTotal_Amount
,P.Amount_Currency AS InvoiceTotal_Currency
,P.Balance_Amount AS Balance_Amount
,p.Balance_Currency AS Balance_Currency
,(ISNULL(CTE_PayablePaidAmount.PayablePaidAmount,0.00)) AmountPaid_Amount
,p.Amount_Currency AS AmountPaid_Currency
,(ISNULL(CTE_CreditApplied.CreditApplied_Amount,0.00)) AS CreditApplied_Amount
,P.Amount_Currency AS CreditApplied_Currency
,FS.Content AS InvoiceFileContent
,PIN.PayableInvoiceDocumentInstance_Source AS InvoiceFileSource
,PIN.PayableInvoiceDocumentInstance_Type AS InvoiceFileType
FROM PayableInvoices PIN
JOIN Payables P ON PIN.Id=P.EntityId AND P.EntityType='PI'
LEFT JOIN FileStores FS on FS.Guid = (CASE WHEN PIN.PayableInvoiceDocumentInstance_Content <> 0x AND PIN.PayableInvoiceDocumentInstance_Content is not null THEN dbo.GetContentGuid(PIN.PayableInvoiceDocumentInstance_Content) ELSE NULL END)
LEFT JOIN LoanFundings LFD ON LFD.FundingId = PIN.Id
LEFT JOIN CTE_PayablePaidAmount ON P.Id = CTE_PayablePaidAmount.InvoiceId
LEFT JOIN CTE_CreditApplied ON P.Id = CTE_CreditApplied.InvoiceId
LEFT JOIN PayableInvoiceAssets PIA ON P.SourceId=PIA.Id AND p.SourceTable='PayableInvoiceAsset'
LEFT JOIN PayableInvoiceOtherCosts PIOC ON P.SourceId=PIOC.Id AND P.SourceTable='PayableInvoiceOtherCost'
LEFT JOIN LeaseAssets LA on PIA.AssetId=LA.AssetId
LEFT JOIN LeaseFinances LF ON LA.LeaseFinanceId=LF.Id AND LF.IsCurrent = 1
LEFT JOIN Contracts C ON LF.ContractId=C.Id OR PIN.ContractId=C.Id
LEFT JOIN DocumentInstances DI ON  PIN.Id=DI.Id
LEFT JOIN DocumentAttachments DA ON DI.Id = DA.DocumentInstanceId
WHERE (PIN.Status!='InActive')
AND(PIN.Status='Completed') AND P.Status != 'Inactive'
AND (@InvoiceId IS NULL OR  PIN.Id =@InvoiceId)
AND (PIA.IsActive IS NULL OR PIA.IsActive=1)
AND (PIOC.IsActive IS NULL OR PIOC.IsActive=1)
AND (LA.IsActive IS NULL OR LA.IsActive=1)
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR C.SequenceNumber=@SequenceNumber)
GROUP BY C.SequenceNumber,
PIN.InvoiceNumber
,PIN.Id
,P.Amount_Amount
,p.Amount_Currency
,P.Balance_Amount
,p.Balance_Currency
,(ISNULL(CTE_PayablePaidAmount.PayablePaidAmount,0.00))
,(ISNULL(CTE_CreditApplied.CreditApplied_Amount,0.00))
,FS.Content
,PIN.PayableInvoiceDocumentInstance_Source
,PIN.PayableInvoiceDocumentInstance_Type
,PIN.InvoiceTotal_Amount
,PIN.InvoiceTotal_Currency
),
CTE_InvoiceAssetCostsPendingStatus_Temp
AS
(
SELECT DISTINCT
PIN.Id
,PIN.InvoiceNumber
,ISNULL(C.SequenceNumber,'UnAllocated') AS SequenceNumber
,(select Sum(AcquisitionCost_Amount) from PayableInvoiceAssets
join PayableInvoices on PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id where PayableInvoiceId=@InvoiceId and IsActive=1 and PayableInvoices.Status!='InActive'
AND PayableInvoices.Status!='Completed') as AcquisitionCost_Amount
,PIA.AcquisitionCost_Currency
,(select Sum(Amount_Amount) from PayableInvoiceOtherCosts
join PayableInvoices on PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id where PayableInvoiceId=@InvoiceId and AllocationMethod = 'ProgressPaymentCredit' And IsActive = 1 and PayableInvoices.Status!='InActive'
AND PayableInvoices.Status!='Completed') as Amount_Amount
,FS.Content
,PIN.PayableInvoiceDocumentInstance_Source
,PIN.PayableInvoiceDocumentInstance_Type
,PPCOtherCost.AllocationMethod
FROM PayableInvoices PIN
JOIN PayableInvoiceAssets PIA ON PIN.Id=PIA.PayableInvoiceId
LEFT JOIN LeaseFundings LFD ON LFD.FundingId = PIN.Id
LEFT JOIN FileStores FS on FS.Guid = (CASE WHEN PIN.PayableInvoiceDocumentInstance_Content <> 0x AND PIN.PayableInvoiceDocumentInstance_Content is not null THEN dbo.GetContentGuid(PIN.PayableInvoiceDocumentInstance_Content) ELSE NULL END)
LEFT JOIN LeaseAssets LA on PIA.AssetId=LA.AssetId
LEFT JOIN LeaseFinances LF ON LA.LeaseFinanceId=LF.Id AND LF.IsCurrent = 1
LEFT JOIN Contracts C ON LF.ContractId=C.Id OR PIN.ContractId=C.Id
LEFT JOIN PayableInvoiceOtherCosts PPCOtherCost ON PIN.Id = PPCOtherCost.PayableInvoiceId
AND PPCOtherCost.IsActive = 1 AND PPCOtherCost.AllocationMethod = 'ProgressPaymentCredit'
WHERE (PIN.Status!='InActive')
AND (PIN.Status!='Completed')
AND (@InvoiceId IS NULL OR  PIN.Id =@InvoiceId)
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated'  OR C.SequenceNumber=@SequenceNumber)
AND PIA.IsActive=1
AND (LA.IsActive IS NULL OR LA.IsActive=1)
),
CTE_InvoiceAssetCostsPendingStatus
AS
(
SELECT
Id AS InvoiceId
,InvoiceNumber
,SequenceNumber
,SUM(AcquisitionCost_Amount) AS InvoiceTotal_Amount
,AcquisitionCost_Currency InvoiceTotal_Currency
,SUM(AcquisitionCost_Amount) AS Balance_Amount
,AcquisitionCost_Currency AS Balance_Currency
,SUM(AcquisitionCost_Amount - AcquisitionCost_Amount) AmountPaid_Amount
,AcquisitionCost_Currency AS AmountPaid_Currency
,CASE WHEN AllocationMethod = 'ProgressPaymentCredit' THEN
(ISNULL(SUM(ISNULL(Amount_Amount,0.00)),0.00) * -1)
ELSE 0.00 END AS CreditApplied_Amount
,AcquisitionCost_Currency AS CreditApplied_Currency
,Content AS InvoiceFileContent
,PayableInvoiceDocumentInstance_Source AS InvoiceFileSource
,PayableInvoiceDocumentInstance_Type AS InvoiceFileType
FROM CTE_InvoiceAssetCostsPendingStatus_Temp
GROUP BY
SequenceNumber
,InvoiceNumber
,Id
,AcquisitionCost_Currency
,Content
,PayableInvoiceDocumentInstance_Source
,PayableInvoiceDocumentInstance_Type
,AllocationMethod
),
CTE_InvoiceOtherCostsPendingStatus
AS
(
SELECT
PIN.Id AS InvoiceId
,PIN.InvoiceNumber
,ISNULL(C.SequenceNumber,'UnAllocated') AS SequenceNumber
,SUM(PIOC.Amount_Amount) AS InvoiceTotal_Amount
,PIOC.Amount_Currency InvoiceTotal_Currency
,SUM(PIOC.Amount_Amount) AS Balance_Amount
,PIOC.Amount_Currency AS Balance_Currency
,SUM(PIOC.Amount_Amount-PIOC.Amount_Amount) AmountPaid_Amount
,PIOC.Amount_Currency AS AmountPaid_Currency
,CA.CreditApplied_Amount AS CreditApplied_Amount
,PIOC.Amount_Currency AS CreditApplied_Currency
,FS.Content AS InvoiceFileContent
,PIN.PayableInvoiceDocumentInstance_Source AS InvoiceFileSource
,PIN.PayableInvoiceDocumentInstance_Type AS InvoiceFileType
FROM PayableInvoices PIN
JOIN PayableInvoiceOtherCosts PIOC ON PIN.Id=PIOC.PayableInvoiceId
JOIN Payables P ON PIN.Id=P.EntityId AND P.EntityType='PI'
LEFT JOIN FileStores FS on FS.Guid = (CASE WHEN PIN.PayableInvoiceDocumentInstance_Content <> 0x AND PIN.PayableInvoiceDocumentInstance_Content is not null THEN dbo.GetContentGuid(PIN.PayableInvoiceDocumentInstance_Content) ELSE NULL END)
LEFT JOIN Contracts C ON PIN.ContractId=C.Id
LEFT JOIN CTE_CreditApplied CA ON P.Id = CA.InvoiceId
WHERE  (PIN.Status!='InActive')
AND (PIN.Status!='Completed')
AND (@InvoiceId IS NULL OR  PIN.Id =@InvoiceId) AND PIOC.AllocationMethod <> 'ProgressPaymentCredit'
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR C.SequenceNumber=@SequenceNumber)
AND PIOC.IsActive=1
GROUP BY
C.SequenceNumber
,PIN.InvoiceNumber
,PIN.Id
,PIOC.Amount_Currency
,FS.Content
,PIN.PayableInvoiceDocumentInstance_Source
,PIN.PayableInvoiceDocumentInstance_Type
,CA.CreditApplied_Amount
),
CTE_InvoiceOtherCostDetailssPendingStatus
AS
(
SELECT
PIN.Id AS InvoiceId
,PIN.InvoiceNumber
,ISNULL(C.SequenceNumber,'UnAllocated') AS SequenceNumber
,0.00 AS InvoiceTotal_Amount--SUM(PIOCD.Amount_Amount)
,PIOCD.Amount_Currency InvoiceTotal_Currency
,0.00 AS Balance_Amount--SUM(PIOCD.Amount_Amount)
,PIOCD.Amount_Currency AS Balance_Currency
,0.00 AmountPaid_Amount--SUM(PIOCD.Amount_Amount-PIOCD.Amount_Amount)
,PIOCD.Amount_Currency AS AmountPaid_Currency
,CA.CreditApplied_Amount AS CreditApplied_Amount
,PIOCD.Amount_Currency AS CreditApplied_Currency
,FS.Content AS InvoiceFileContent
,PIN.PayableInvoiceDocumentInstance_Source AS InvoiceFileSource
,PIN.PayableInvoiceDocumentInstance_Type AS InvoiceFileType
FROM PayableInvoices PIN
JOIN PayableInvoiceOtherCosts PIOC ON PIN.Id=PIOC.PayableInvoiceId
JOIN PayableInvoiceOtherCostDetails PIOCD on PIOC.Id= PIOCD.PayableInvoiceOtherCostId
JOIN Payables P ON PIN.Id=P.EntityId AND P.EntityType='PI'
LEFT JOIN FileStores FS on FS.Guid = (CASE WHEN PIN.PayableInvoiceDocumentInstance_Content <> 0x AND PIN.PayableInvoiceDocumentInstance_Content is not null THEN dbo.GetContentGuid(PIN.PayableInvoiceDocumentInstance_Content) ELSE NULL END)
LEFT JOIN Contracts C ON PIN.ContractId=C.Id
LEFT JOIN CTE_CreditApplied CA ON P.Id = CA.InvoiceId
WHERE  (PIN.Status!='InActive')
AND (PIN.Status!='Completed')
AND (@InvoiceId IS NULL OR  PIN.Id =@InvoiceId)
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR C.SequenceNumber=@SequenceNumber)
AND PIOC.IsActive=1
GROUP BY
C.SequenceNumber
,PIN.InvoiceNumber
,PIN.Id
,PIOCD.Amount_Currency
,FS.Content
,PIN.PayableInvoiceDocumentInstance_Source
,PIN.PayableInvoiceDocumentInstance_Type
,CA.CreditApplied_Amount
),
CTE_Result
AS
(
SELECT * FROM CTE_InvoicesCompletedStatus
UNION
SELECT * FROM CTE_InvoiceAssetCostsPendingStatus
UNION
SELECT * FROM CTE_InvoiceOtherCostsPendingStatus
UNION
SELECT * FROM CTE_InvoiceOtherCostDetailssPendingStatus
)
SELECT
ROW_NUMBER() OVER (ORDER BY R.InvoiceId) AS Id
,R.InvoiceId
,R.InvoiceNumber
,R.SequenceNumber
,SUM(R.InvoiceTotal_Amount) AS InvoiceTotal_Amount
,R.InvoiceTotal_Currency
,SUM(R.Balance_Amount) AS Balance_Amount
,R.Balance_Currency
,SUM(R.AmountPaid_Amount) AS AmountPaid_Amount
,R.AmountPaid_Currency
,R.CreditApplied_Amount
,R.CreditApplied_Currency
,R.InvoiceFileContent
,R.InvoiceFileSource
,R.InvoiceFileType
FROM CTE_Result R
GROUP BY
R.SequenceNumber
,R.InvoiceId
,R.InvoiceNumber
,R.InvoiceTotal_Currency
,R.Balance_Currency
,R.AmountPaid_Currency
,R.CreditApplied_Currency
,R.InvoiceFileContent
,R.InvoiceFileSource
,R.InvoiceFileType
,R.CreditApplied_Amount

GO
