SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetPayableTypesForSelectedInvoice]
(
@InvoiceId BIGINT
,@SequenceNumber NVARCHAR(80)=NULL,
@CurrentVendorId BIGINT
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_PayablePaidAmount
AS
(
SELECT
Payable.Id
--,(Payable.Amount_Amount - Payable.Balance_Amount)- (ISNULL(PayableInvoiceOtherCost.Amount_Amount,0)) AS PayablePaidAmount
-- ,SUM(ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00)) AS CreditApplied_Amount
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
GROUP BY  Payable.Id
),
CTE_CreditApplied
AS
(
SELECT
Payable.Id as  PayableId
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
CTE_Payables
AS
(
SELECT
Payable.SourceId
,PayableType.Name AS PayableType
,Payable.Amount_Amount AS PayableTypeAmount_Amount
,Payable.Amount_Currency AS  PayableTypeAmount_Currency
,Payable.Balance_Amount AS PayableTypeBalance_Amount
,Payable.Balance_Currency  AS PayableTypeBalance_Currency
,Payable.SourceTable
,Payable.Amount_Currency AS CreditApplied_Currency
,Payable.EntityId
,ISNULL(CTE_PayablePaidAmount.PayablePaidAmount,0.00) AS AmountPaid_Amount
,ISNULL(CTE_CreditApplied.CreditApplied_Amount,0.00) AS CreditApplied_Amount
FROM Payables AS Payable
JOIN PayableCodes PayableCode ON Payable.PayableCodeId =PayableCode.Id
JOIN PayableTypes PayableType ON PayableCode.PayableTypeId=PayableType.Id
LEFT JOIN CTE_PayablePaidAmount ON Payable.Id = CTE_PayablePaidAmount.Id
LEFT JOIN CTE_CreditApplied ON Payable.Id = PayableId
WHERE Payable.EntityType='PI'
AND (Payable.SourceTable='PayableInvoiceAsset' OR Payable.SourceTable='PayableInvoiceOtherCost')
AND Payable.Status!='Inactive'
AND PayableType.IsActive=1
AND PayableCode.IsActive=1
AND Payable.EntityId=@InvoiceId
GROUP BY
Payable.Id
,Payable.SourceId
,PayableType.Name
,Payable.Amount_Amount
,Payable.Amount_Currency
,Payable.Balance_Amount
,Payable.Balance_Currency
,Payable.SourceTable
,Payable.Amount_Currency
,Payable.EntityId
,CTE_PayablePaidAmount.PayablePaidAmount
,CTE_CreditApplied.CreditApplied_Amount
),
CTE_PayableInvoiceAssets
AS
(
SELECT
Payable.PayableType
,Asset.Description
,Payable.PayableTypeAmount_Amount
,Payable.PayableTypeAmount_Currency
,Payable.PayableTypeBalance_Amount
,Payable.PayableTypeBalance_Currency
,Payable.CreditApplied_Amount
,Payable.CreditApplied_Currency
,Payable.AmountPaid_Amount
FROM CTE_Payables Payable
JOIN PayableInvoices PayableInvoice ON Payable.EntityId = PayableInvoice.Id
JOIN PayableInvoiceAssets InvoiceAsset ON Payable.SourceId=InvoiceAsset.Id
JOIN Assets Asset ON InvoiceAsset.AssetId = Asset.Id
LEFT JOIN LeaseAssets LeaseAsset ON Asset.Id= LeaseAsset.AssetId
LEFT JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId= LeaseFinance.Id
LEFT JOIN Contracts C ON LeaseFinance.ContractId= C.Id OR PayableInvoice.ContractId = C.ID
WHERE InvoiceAsset.IsActive=1
AND SourceTable='PayableInvoiceAsset'
AND( LeaseFinance.IsCurrent IS NULL OR LeaseFinance.IsCurrent=1)
AND (@SequenceNumber IS NULL OR (C.SequenceNumber IS NULL AND @SequenceNumber='UnAllocated') OR C.SequenceNumber=@SequenceNumber)
),
CTE_PayableInvoiceOtherCosts
AS
(
SELECT
Payable.PayableType
,OtherCost.Description AS Description
,Payable.PayableTypeAmount_Amount
,Payable.PayableTypeAmount_Currency
,Payable.PayableTypeBalance_Amount
,Payable.PayableTypeBalance_Currency
,Payable.CreditApplied_Amount
,Payable.CreditApplied_Currency
,Payable.AmountPaid_Amount
FROM CTE_Payables Payable
JOIN PayableInvoiceOtherCosts OtherCost ON Payable.SourceId=OtherCost.Id
JOIN PayableInvoices PayableInvoice ON OtherCost.PayableInvoiceId= PayableInvoice.Id
LEFT JOIN Contracts Contract  ON PayableInvoice.ContractId= Contract.Id
WHERE OtherCost.IsActive=1
AND SourceTable='PayableInvoiceOtherCost'
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR Contract.SequenceNumber=@SequenceNumber)
),
CTE_PayableInvoiceOtherCostForPendingPayabeinvoice
AS
(
SELECT
AllocationMethod  as PayableType
,Description AS Description
,Amount_Amount as PayableTypeAmount_Amount
,Amount_Currency as PayableTypeAmount_Currency
,Amount_Amount AS PayableTypeBalance_Amount
,Amount_Currency  AS PayableTypeBalance_Currency
,0.00 AS CreditApplied_Amount
,Amount_Currency AS CreditApplied_Currency
,0.00 AS AmountPaid_Amount
FROM PayableInvoiceOtherCosts
JOIN PayableInvoices ON PayableInvoices.Id = PayableInvoiceOtherCosts.PayableInvoiceId
LEFT JOIN Contracts Contract  ON PayableInvoices.ContractId= Contract.Id
WHERE PayableInvoiceId = @InvoiceId
AND PayableInvoiceOtherCosts.IsActive=1
AND PayableInvoices.Status!='Completed'
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR Contract.SequenceNumber=@SequenceNumber)
),
CTE_PayableInvoiceAssetsForPendingPayabeinvoice
AS
(
SELECT
PT.Name as PayableType
,Asset.Description
,PIA.AcquisitionCost_Amount as PayableTypeAmount_Amount
,PIA.AcquisitionCost_Currency as PayableTypeAmount_Currency
,PIA.AcquisitionCost_Amount as PayableTypeBalance_Amount
,PIA.AcquisitionCost_Currency as PayableTypeBalance_Currency
,0.00 AS CreditApplied_Amount
,PIA.AcquisitionCost_Currency AS CreditApplied_Currency
,0.00 AS AmountPaid_Amount
FROM PayableInvoices PIN
JOIN PayableCodes PC on PIN.AssetCostPayableCodeId=PC.Id
JOIN PayableTypes PT on PC.PayableTypeId=PT.Id
JOIN PayableInvoiceAssets PIA on PIN.Id=PIA.PayableInvoiceId
JOIN Assets Asset ON PIA.AssetId = Asset.Id
LEFT JOIN LeaseAssets LeaseAsset ON Asset.Id= LeaseAsset.AssetId
LEFT JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId= LeaseFinance.Id
LEFT JOIN Contracts C ON LeaseFinance.ContractId= C.Id OR PIN.ContractId = C.Id
WHERE PIN.Id= @InvoiceId
AND PIN.Status!='Completed'
AND PIA.IsActive=1
AND PC.IsActive=1
AND PT.IsActive=1
AND( LeaseFinance.IsCurrent IS NULL OR LeaseFinance.IsCurrent=1)
AND (@SequenceNumber IS NULL OR @SequenceNumber='UnAllocated' OR C.SequenceNumber=@SequenceNumber)
)
SELECT * FROM CTE_PayableInvoiceAssets
UNION ALL
SELECT * FROM CTE_PayableInvoiceOtherCosts
UNION ALL
SELECT * FROM CTE_PayableInvoiceOtherCostForPendingPayabeinvoice
UNION ALL
SELECT * FROM CTE_PayableInvoiceAssetsForPendingPayabeinvoice

GO
