SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_GetChargeDetails]
(
@CurrentVendorId BIGINT,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName  NVARCHAR(250)=NULL,
@CreditAppNumber NVARCHAR(80)=NULL,
@SequenceNumber NVARCHAR(80)=NULL,
@ChargeType NVARCHAR(250)=NULL,
@AssetId BIGINT=NULL,
@SerialNumber NVARCHAR(200)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@DueDateFrom DATETIMEOFFSET=NULL,
@DueDateTo DATETIMEOFFSET=NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @CREDITAPPJOINCONDITION NVARCHAR(500)
DECLARE @CREDITAPPWHERECONDITION NVARCHAR(100)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH CTE_DISTINCTPayableAmount
AS
(
SELECT
DISTINCT
PayableInvoice.Id AS PayableInvoiceId
,(Payable.Balance_Amount) AS AmountOutstanding
,(DisbursementRequestPayable.AmountToPay_Amount) - (ISNULL(PayableInvoiceOtherCost.Amount_Amount,0)) AS PaidAmount
FROM PayableInvoices PayableInvoice
JOIN Payables Payable ON  PayableInvoice.Id = Payable.EntityId AND Payable.EntityType=''PI''
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
AND Payable.SourceTable=''PayableInvoiceOtherCost''
AND PayableInvoiceOtherCost.AllocationMethod = ''ProgressPaymentCredit''
AND PayableInvoiceOtherCost.IsActive = 1
WHERE DisbursementRequestPaymentDetail.IsActive = 1
AND DisbursementRequestPayee.IsActive = 1
AND DisbursementRequestPayable.IsActive = 1
AND DisbursementRequest.Status = ''Completed''
AND PaymentVoucher.Status=''Paid''
AND TreasuryPayable.Status !=''Inactive''
AND TreasuryPayableDetail.IsActive=1
AND (Payable.Status =''Approved'' OR Payable.Status =''PartiallyApproved'')
AND PaymentVoucher.OriginalVoucherId IS NULL
),
CTE_PayableAmount AS
(
SELECT
PayableInvoiceId,
SUM(AmountOutstanding) AmountOutstanding,
SUM(PaidAmount) PaidAmount
FROM CTE_DISTINCTPayableAmount
GROUP BY
PayableInvoiceId
)
,CTE_PayableInvoices_Temp
AS
(
SELECT DISTINCT
Payable.Id
,PayableInvoice.Id AS HyperLinkId
,PayableInvoice.InvoiceNumber AS Reference_InvoiceNumber
,PayableInvoice.InvoiceNumber AS Reference_Memo
,PayableInvoice.DueDate
,CASE WHEN PayableInvoice.ContractId <> LeaseFinance.ContractId THEN
CASE WHEN PayableInvoice.ContractId IS NOT NULL THEN
(SELECT Con.SequenceNumber FROM Contracts Con WHERE PayableInvoice.ContractId = Con.Id)
ELSE
(SELECT Con.SequenceNumber FROM Contracts Con WHERE LeaseFinance.ContractId = Con.Id)
END
ELSE
ISNULL(Con.SequenceNumber,'''') END AS SequenceNumber
,PayableType.Name AS ChargeType
,CASE WHEN Payable.SourceTable=''PayableInvoicePPCAsset'' THEN
CASE WHEN PayableInvoiceOtherCostAsset.AssetId IS NOT NULL THEN
PayableInvoiceOtherCostAsset.AssetId
ELSE
PayableInvoiceAsset.AssetId
END
ELSE
Asset.Id
END AS AssetId
,CASE WHEN Payable.SourceTable=''PayableInvoicePPCAsset'' AND  PayableInvoiceOtherCostAsset.AssetId IS NOT NULL THEN
CASE WHEN Count(PASN.Id) > 1 THEN
@AssetMultipleSerialNumberType
ELSE
MAX(PASN.SerialNumber)
END
ELSE
CASE WHEN Count(ASN.Id) > 1 THEN
@AssetMultipleSerialNumberType
ELSE
MAX(PASN.SerialNumber)
END
END AS SerialNumber
,Payable.Amount_Amount AS Charge_Amount
,Payable.Amount_Currency AS Charge_Currency
,Payable.Balance_Amount
,Payable.Balance_Currency
,ISNULL(PaidAmount,0.00) AS AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00) AS CreditApplied_Amount
,Payable.Amount_Currency AS CreditApplied_Currency
FROM PayableInvoices AS PayableInvoice
JOIN Parties AS Party ON PayableInvoice.CustomerId = Party.Id
JOIN Payables Payable ON PayableInvoice.Id = Payable.EntityId AND Payable.EntityType=''PI''
JOIN PayableCodes PayableCode ON Payable.PayableCodeId= PayableCode.Id
JOIN PayableTypes PayableType ON PayableCode.PayableTypeId=PayableType.Id
LEFT JOIN DisbursementRequestPayables DisbursementRequestPayable  ON Payable.Id=DisbursementRequestPayable.PayableId AND DisbursementRequestPayable.IsActive = 1
LEFT JOIN DisbursementRequestPayees DisbursementRequestPayee
ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId AND  DisbursementRequestPayee.IsActive = 1
LEFT JOIN PayableInvoiceAssets PayableInvoiceAsset ON PayableInvoiceAsset.IsActive=1 AND (Payable.SourceId= PayableInvoiceAsset.Id
AND (Payable.SourceTable=''PayableInvoiceAsset'' OR Payable.SourceTable=''PayableInvoicePPCAsset''))
LEFT JOIN PayableInvoiceOtherCostDetails PayableInvoiceOtherCostDetail ON  Payable.SourceId = PayableInvoiceOtherCostDetail.Id
AND (Payable.SourceTable=''PayableInvoicePPCAsset'')
LEFT JOIN PayableInvoiceAssets PayableInvoiceOtherCostAsset ON PayableInvoiceOtherCostDetail.PayableInvoiceAssetId = PayableInvoiceOtherCostAsset.Id
LEFT JOIN Assets PayableInvoiceOtherCostAssetAsset ON PayableInvoiceOtherCostAsset.AssetId = PayableInvoiceOtherCostAssetAsset.Id
LEFT JOIN AssetSerialNumbers PASN ON PayableInvoiceOtherCostAssetAsset.Id = PASN.AssetId AND PASN.IsActive = 1
LEFT JOIN Assets Asset ON PayableInvoiceAsset.AssetId = Asset.Id
LEFT JOIN AssetSerialNumbers ASN ON Asset.Id = ASN.AssetId AND ASN.IsActive = 1
LEFT JOIN LeaseAssets LeaseAsset ON PayableInvoiceAsset.AssetId=LeaseAsset.AssetId  AND LeaseAsset.IsActive=1
LEFT JOIN LeaseFinances LeaseFinance ON LeaseAsset.LeaseFinanceId=LeaseFinance.Id AND LeaseFinance.IsCurrent=1
LEFT JOIN Contracts Con ON PayableInvoice.ContractId = Con.Id OR LeaseFinance.ContractId = Con.Id
LEFT JOIN CTE_PayableAmount ON CTE_PayableAmount.PayableInvoiceId = PayableInvoice.Id
CREDITAPPJOINCONDITION
WHERE PayableInvoice.VendorId = @CurrentVendorId
AND PayableInvoice.Status!=''InActive''
AND Payable.Status!=''Inactive''
AND PayableCode.IsActive=1
AND PayableType.IsActive=1
AND (@ChargeType IS NULL OR PayableType.Name LIKE REPLACE(@ChargeType ,''*'',''%''))
CREDITAPPWHERECONDITION
AND (@InvoiceNumber IS NULL OR PayableInvoice.InvoiceNumber LIKE REPLACE(@InvoiceNumber ,''*'',''%''))
AND (@CustomerNumber IS NULL OR Party.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR Party.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@SequenceNumber IS NULL OR Con.SequenceNumber IS NULL OR Con.SequenceNumber  LIKE REPLACE(@SequenceNumber ,''*'',''%''))
AND ((@DueDateFrom IS NULL OR CAST(@DueDateFrom AS DATE) <= PayableInvoice.DueDate)
AND (@DueDateTo IS NULL OR CAST(@DueDateTo AS DATE) >= PayableInvoice.DueDate))
AND (@AssetId IS NULL OR Asset.Id IS NULL OR Asset.Id=@AssetId)
AND (@SerialNumber IS NULL OR ASN.SerialNumber IS NULL OR ASN.SerialNumber LIKE REPLACE(@SerialNumber ,''*'',''%''))
GROUP BY Payable.Id,PayableInvoice.Id,PayableInvoice.InvoiceNumber,PayableInvoice.DueDate,PayableInvoice.ContractId,LeaseFinance.ContractId,PayableType.Name,Payable.SourceTable,PayableInvoiceOtherCostAsset.AssetId,PayableInvoiceAsset.AssetId,Asset.Id,Payable.Amount_Amount,Payable.Amount_Currency,Payable.Balance_Amount,Payable.Balance_Currency,PaidAmount,DisbursementRequestPayee.ReceivablesApplied_Amount
),
CTE_PayableInvoices AS
(
SELECT DISTINCT
Id
,HyperLinkId
,Reference_InvoiceNumber
,Reference_Memo
,DueDate
,SequenceNumber
,ChargeType
,AssetId
,SerialNumber
,Charge_Amount
,Charge_Currency
,Balance_Amount
,Balance_Currency
,AmountPaid_Amount
,AmountPaid_Currency
,SUM(CreditApplied_Amount) CreditApplied_Amount
,CreditApplied_Currency
FROM CTE_PayableInvoices_Temp
GROUP BY
Id
,HyperLinkId
,Reference_InvoiceNumber
,Reference_Memo
,DueDate
,SequenceNumber
,ChargeType
,AssetId
,SerialNumber
,Charge_Amount
,Charge_Currency
,Balance_Amount
,Balance_Currency
,AmountPaid_Amount
,AmountPaid_Currency
,CreditApplied_Currency
)
,CTE_SundryPaybles
AS
(
SELECT DISTINCT
Payable.Id
,''''AS HyperLinkId
,'''' AS Reference_InvoiceNumber
,ISNULL(BlendedItem.Name,Sundry.Memo) AS Reference_Memo
,Sundry.PayableDueDate AS DueDate
,ISNULL(Con.SequenceNumber,'''') AS SequenceNumber
,PayableType.Name AS ChargeType
,NULL AS AssetId
,''''AS SerialNumber
,Payable.Amount_Amount AS Charge_Amount
,Payable.Amount_Currency AS Charge_Currency
,Payable.Balance_Amount
,Payable.Balance_Currency
,(Payable.Amount_Amount - Payable.Balance_Amount) AS AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,0.00 AS CreditApplied_Amount
,Payable.Amount_Currency AS CreditApplied_Currency
FROM Sundries Sundry
JOIN Parties Party ON Sundry.CustomerId = Party.Id
JOIN Payables Payable ON Sundry.Id= Payable.SourceId
JOIN PayableCodes PayableCode ON Payable.PayableCodeId= PayableCode.Id
JOIN PayableTypes PayableType ON PayableCode.PayableTypeId=PayableType.Id
LEFT JOIN Contracts AS Con ON Sundry.ContractId = Con.Id
LEFT JOIN BlendedItemDetails BlendedItemDetail ON Sundry.Id=BlendedItemDetail.SundryId
LEFT JOIN BlendedItems BlendedItem ON BlendedItemDetail.BlendedItemId=BlendedItem.Id
CREDITAPPJOINCONDITION
WHERE Sundry.VendorId=@CurrentVendorId
AND Sundry.VendorId=Payable.PayeeId
AND Sundry.IsActive=1
AND Payable.Status!=''Inactive''
AND PayableCode.IsActive=1
AND PayableType.IsActive=1
AND Payable.SourceTable=''SundryPayable''
AND (BlendedItemDetail.IsActive IS NULL OR BlendedItemDetail.IsActive=1)
AND (BlendedItem.IsActive IS NULL OR BlendedItem.IsActive=1)
AND (@ChargeType IS NULL OR PayableType.Name LIKE REPLACE(@ChargeType ,''*'',''%''))
CREDITAPPWHERECONDITION
AND (@CustomerNumber IS NULL OR Party.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR Party.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@SequenceNumber IS NULL OR Con.SequenceNumber IS NULL OR Con.SequenceNumber LIKE REPLACE(@SequenceNumber ,''*'',''%''))
AND ((@DueDateFrom IS NULL OR CAST(@DueDateFrom AS DATE)  <= Sundry.PayableDueDate)
AND (@DueDateTo IS NULL OR CAST(@DueDateTo AS DATE) >= Sundry.PayableDueDate))
),
CTE_SundryRecurringPayables
AS
(
SELECT DISTINCT
Payable.Id
,''''AS HyperLinkId
,'''' AS Reference_InvoiceNumber
,SR.Memo AS Reference_Memo
,SRPS.DueDate AS DueDate
,ISNULL(Con.SequenceNumber,'''') AS SequenceNumber
,PayableType.Name AS ChargeType
,NULL AS AssetId
,''''AS SerialNumber
,Payable.Amount_Amount AS Charge_Amount
,Payable.Amount_Currency AS Charge_Currency
,Payable.Balance_Amount
,Payable.Balance_Currency
,(Payable.Amount_Amount - Payable.Balance_Amount) AS AmountPaid_Amount
,Payable.Amount_Currency AS AmountPaid_Currency
,0.00 AS CreditApplied_Amount
,Payable.Amount_Currency AS CreditApplied_Currency
FROM SundryRecurrings SR
JOIN SundryRecurringPaymentSchedules SRPS ON SR.Id= SRPS.SundryRecurringId
JOIN Payables Payable ON SRPS.Id= Payable.SourceId
JOIN PayableCodes PayableCode ON Payable.PayableCodeId= PayableCode.Id
JOIN PayableTypes PayableType ON PayableCode.PayableTypeId=PayableType.Id
JOIN Parties Party ON SR.CustomerId = Party.Id
LEFT JOIN Contracts AS Con ON SR.ContractId = Con.Id
CREDITAPPJOINCONDITION
WHERE Payable.SourceTable = ''SundryRecurPaySch''
AND SR.VendorId= Payable.PayeeId
AND Payable.PayeeId=@CurrentVendorId
AND Payable.Status!=''Inactive''
AND SRPS.IsActive=1
AND SR.IsActive=1
AND (@ChargeType IS NULL OR PayableType.Name LIKE REPLACE(@ChargeType ,''*'',''%''))
CREDITAPPWHERECONDITION
AND (@CustomerNumber IS NULL OR Party.PartyNumber LIKE REPLACE(@CustomerNumber,''*'',''%''))
AND (@CustomerName IS NULL OR Party.PartyName LIKE REPLACE(@CustomerName ,''*'',''%''))
AND (@SequenceNumber IS NULL OR Con.SequenceNumber IS NULL OR Con.SequenceNumber LIKE REPLACE(@SequenceNumber ,''*'',''%''))
AND ((@DueDateFrom IS NULL OR CAST(@DueDateFrom AS DATE)  <= SRPS.DueDate)
AND (@DueDateTo IS NULL OR CAST(@DueDateTo AS DATE) >= SRPS.DueDate ))
)
SELECT * FROM CTE_PayableInvoices
UNION ALL
SELECT * FROM CTE_SundryPaybles
UNION ALL
SELECT * FROM CTE_SundryRecurringPayables
'
IF(@CreditAppNumber IS NOT NULL)
SET @CREDITAPPJOINCONDITION = 'JOIN CreditApprovedStructures CPS ON Con.CreditApprovedStructureId =CPS.Id
JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
JOIN CreditApplications CApp ON Opp.Id= CApp.Id'
ELSE
SET @CREDITAPPJOINCONDITION = ''
IF(@CreditAppNumber IS NOT NULL)
SET @CREDITAPPWHERECONDITION = 'AND (Opp.Number LIKE REPLACE(@CreditAppNumber,''*'',''%''))'
ELSE
SET @CREDITAPPWHERECONDITION=''
SET @Sql =  REPLACE(@Sql,'CREDITAPPJOINCONDITION', @CREDITAPPJOINCONDITION);
SET @Sql =  REPLACE(@Sql,'CREDITAPPWHERECONDITION', @CREDITAPPWHERECONDITION);
;
EXEC sp_executesql @Sql,N'
@CurrentVendorId BIGINT,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName  NVARCHAR(250)=NULL,
@CreditAppNumber NVARCHAR(80)=NULL,
@SequenceNumber NVARCHAR(80)=NULL,
@ChargeType NVARCHAR(250)=NULL,
@AssetId BIGINT=NULL,
@SerialNumber NVARCHAR(200)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@DueDateFrom DATETIMEOFFSET=NULL,
@DueDateTo DATETIMEOFFSET=NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)'
,@CurrentVendorId
,@CustomerNumber
,@CustomerName
,@CreditAppNumber
,@SequenceNumber
,@ChargeType
,@AssetId
,@SerialNumber
,@InvoiceNumber
,@DueDateFrom
,@DueDateTo
,@AssetMultipleSerialNumberType

GO
