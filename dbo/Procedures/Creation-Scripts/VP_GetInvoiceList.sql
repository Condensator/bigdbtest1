SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetInvoiceList]
(
@CurrentVendorId BIGINT,
@InvoiceId BIGINT=NULL,
@ProgramVendor NVARCHAR(250)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@InvoiceFromDueDate DATETIMEOFFSET=NULL,
@InvoiceToDueDate DATETIMEOFFSET=NULL,
@PaidDateFrom DATETIMEOFFSET=NULL,
@PaidDateTo DATETIMEOFFSET=NULL,
@InvoiceStatus NVARCHAR(250)=NULL,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName  NVARCHAR(250)=NULL,
@CreditAppNumber NVARCHAR(80)=NULL,
@SequenceNumber NVARCHAR(80)=NULL,
@PaymentStatus NVARCHAR(250)=NULL
)
AS
DECLARE @Sql NVARCHAR(MAX)
DECLARE @CREDITAPPJOINCONDITION NVARCHAR(500)
DECLARE @CREDITAPPWHERECONDITION NVARCHAR(100)
DECLARE @PAIDDATEJOINCONDITION NVARCHAR(100)
SET @Sql =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
;WITH CTE_AssumptionDetails AS
(
SELECT
ContractId,
MIN(Id) Id
FROM Assumptions WHERE Status = ''Approved''
Group BY
ContractId
),
CTE_CustomerDetails AS
(
SELECT
PInv.[Id] AS InvoiceId
,PVen.PartyName AS ProgramVendor
,PInv.InvoiceNumber AS InvoiceNumber
,PInv.DueDate AS InvoiceDueDate
,PInv.Status AS InvoiceStatus
,CASE WHEN AP.PartyNumber IS NULL THEN P.PartyNumber ELSE AP.PartyNumber END AS CustomerNumber
,CASE WHEN AP.PartyName IS NULL THEN P.PartyName ELSE AP.PartyName END AS CustomerName
,Con.SequenceNumber AS SequenceNumber
,Con.Id As ContractId
,PInv.InvoiceTotal_Amount AS InvoiceTotal_Amount
,PInv.InvoiceTotal_Currency AS InvoiceTotal_Currency
,PInv.Balance_Amount AS Balance_Amount
,PInv.Balance_Currency AS Balance_Currency
,CASE WHEN PInv.PayableInvoiceDocumentInstance_Content IS NOT NULL AND PInv.PayableInvoiceDocumentInstance_Content <> 0x THEN
(SELECT TOP(1) FS.Content FROM FileStores FS WHERE FS.Guid = dbo.GetContentGuid( PInv.PayableInvoiceDocumentInstance_Content) ORDER BY Id DESC)
ELSE NULL END AS InvoiceFileContent
,CASE WHEN PInv.PayableInvoiceDocumentInstance_Content IS NOT NULL AND PInv.PayableInvoiceDocumentInstance_Content <> 0x THEN
(SELECT TOP(1) FS.StorageSystem FROM FileStores FS WHERE FS.Guid = dbo.GetContentGuid( PInv.PayableInvoiceDocumentInstance_Content) ORDER BY Id DESC)
ELSE NULL END AS StorageSystem
,CASE WHEN PInv.PayableInvoiceDocumentInstance_Content IS NOT NULL AND PInv.PayableInvoiceDocumentInstance_Content <> 0x THEN
(SELECT TOP(1) FS.ExtStoreReference FROM FileStores FS WHERE FS.Guid = dbo.GetContentGuid( PInv.PayableInvoiceDocumentInstance_Content) ORDER BY Id DESC)
ELSE NULL END AS InvoiceFilePath
,PInv.PayableInvoiceDocumentInstance_Source AS InvoiceFileSource
,PInv.PayableInvoiceDocumentInstance_Type AS InvoiceFileType
FROM [dbo].[PayableInvoices] AS PInv
JOIN [dbo].[Vendors] AS V ON PInv.VendorId = V.Id
JOIN [dbo].[Parties] AS PVen ON V.Id = PVen.Id
JOIN [dbo].[Customers] AS C ON PInv.CustomerId = C.Id
JOIN [dbo].[Parties] AS P ON C.ID = P.Id
LEFT JOIN  [dbo].[Contracts] AS Con ON PInv.ContractId = Con.Id
LEFT JOIN LeaseFinances Lease ON Con.Id = Lease.ContractId AND Lease.IsCurrent = 1
LEFT JOIN LoanFinances Loan ON Con.Id = Loan.ContractId AND Loan.IsCurrent = 1
LEFT JOIN CTE_AssumptionDetails CAD ON CAD.ContractId = Con.Id
LEFT JOIN Assumptions A ON CAD.Id = A.Id
LEFT JOIN Parties AP ON AP.Id = A.OriginalCustomerId
LEFT JOIN LeaseFundings LeaseFunding ON PInv.Id = LeaseFunding.FundingId
LEFT JOIN LeaseFinances LeaseFinanceFunding ON LeaseFunding.LeaseFinanceId = LeaseFinanceFunding.Id
LEFT JOIN LoanFundings LoanFunding ON PInv.Id = LoanFunding.FundingId
LEFT JOIN LoanFinances LoanFinanceFunding ON LoanFunding.LoanFinanceId = LoanFinanceFunding.Id
CREDITAPPJOINCONDITION
WHERE (PInv.VendorId = @CurrentVendorId)
AND (@InvoiceId IS NULL OR PInv.Id = @InvoiceId)
AND PInv.Status!=''InActive''
AND PInv.ParentPayableInvoiceId IS NULL
AND PInv.IsInvalidPayableInvoice=0
CREDITAPPWHERECONDITION
AND (@ProgramVendor IS NULL OR PVen.PartyName LIKE REPLACE(REPLACE(@ProgramVendor,''_'',''[_]''),''*'',''%''))
AND (@InvoiceNumber IS NULL OR PInv.InvoiceNumber LIKE REPLACE(REPLACE(@InvoiceNumber,''_'',''[_]''),''*'',''%''))
AND (@InvoiceStatus IS NULL OR PInv.Status LIKE REPLACE(REPLACE(@InvoiceStatus,''_'',''[_]''),''*'',''%''))
AND (@CustomerNumber IS NULL OR (CASE WHEN AP.PartyNumber IS NULL THEN P.PartyNumber ELSE AP.PartyNumber END) LIKE REPLACE(REPLACE(@CustomerNumber,''_'',''[_]''),''*'',''%''))
AND (@CustomerName IS NULL OR (CASE WHEN AP.PartyName IS NULL THEN P.PartyName ELSE AP.PartyName END) LIKE REPLACE(REPLACE(@CustomerName,''_'',''[_]''),''*'',''%''))
AND (@SequenceNumber IS NULL OR Con.SequenceNumber  LIKE REPLACE(REPLACE(@SequenceNumber,''_'',''[_]''),''*'',''%''))
AND ((@InvoiceFromDueDate IS NULL OR CAST(@InvoiceFromDueDate AS DATE)  <= PInv.DueDate)
AND (@InvoiceToDueDate IS NULL OR CAST(@InvoiceToDueDate AS DATE) >= PInv.DueDate))
AND (LeaseFinanceFunding.IsCurrent = 1 OR LoanFinanceFunding.IsCurrent = 1 OR PInv.SourceTransaction <> ''CreateFromContract'')
),
CTE_PayableAmount
AS
(
SELECT
PayableInvoice.InvoiceId AS PayableInvoiceId
,SUM(Payable.Balance_Amount) AS AmountOutstanding
,SUM(DisbursementRequestPayee.PaidAmount_Amount) AS PaidAmount
FROM CTE_CustomerDetails PayableInvoice
JOIN Payables Payable ON  PayableInvoice.InvoiceId = Payable.EntityId AND Payable.EntityType=''PI''
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
AND ((@PaidDateFrom IS NULL OR CAST(@PaidDateFrom AS DATE) <=PaymentVoucher.PaymentDate)
AND (@PaidDateTo IS NULL OR CAST(@PaidDateTo AS DATE)>= PaymentVoucher.PaymentDate))
AND DisbursementRequestPaymentDetail.PayeeId=@CurrentVendorId
AND  TreasuryPayable.PayeeId=@CurrentVendorId
GROUP BY PayableInvoice.InvoiceId
),
CTE_CreditAppliedAmount_Temp
AS
(
SELECT	 PayableInvoice.InvoiceId as InvoiceId
,PayableInvoiceOtherCost.AllocationMethod
,ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00) ReceivablesApplied_Amount
,CASE WHEN PayableInvoice.InvoiceStatus=''Completed'' THEN (ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00) +  (ISNULL(PayableInvoiceOtherCost.Amount_Amount,0.00) * -1)) ELSE SUM(ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00) +  (ISNULL(PayableInvoiceOtherCost.Amount_Amount,0.00) * -1)) END AS ProgressPaymentCredit
FROM CTE_CustomerDetails PayableInvoice
LEFT JOIN Payables Payable ON PayableInvoice.InvoiceId = Payable.EntityId AND Payable.EntityType = ''PI'' AND Payable.Status!=''Inactive''
LEFT JOIN DisbursementRequestPayables DisbursementRequestPayable
ON Payable.Id=DisbursementRequestPayable.PayableId AND DisbursementRequestPayable.IsActive = 1
LEFT  JOIN DisbursementRequestPayees DisbursementRequestPayee
ON DisbursementRequestPayable.Id=DisbursementRequestPayee.DisbursementRequestPayableId AND DisbursementRequestPayee.IsActive = 1
LEFT JOIN DisbursementRequests DisbursementRequest ON DisbursementRequestPayable.DisbursementRequestId=DisbursementRequest.Id
LEFT JOIN PayableInvoiceOtherCosts PayableInvoiceOtherCost ON PayableInvoice.InvoiceId = PayableInvoiceOtherCost.PayableInvoiceId
AND PayableInvoiceOtherCost.IsActive = 1 AND PayableInvoiceOtherCost.AllocationMethod = ''ProgressPaymentCredit''
WHERE  (PayableInvoiceOtherCost.AllocationMethod = ''ProgressPaymentCredit'' OR DisbursementRequest.Status=''Completed'')
GROUP BY PayableInvoice.InvoiceId,PayableInvoiceOtherCost.AllocationMethod
,ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00)
,ISNULL(DisbursementRequestPayee.ReceivablesApplied_Amount,0.00) +  (ISNULL(PayableInvoiceOtherCost.Amount_Amount,0.00) * -1)
,PayableInvoice.InvoiceStatus
)
,CTE_CreditAppliedAmount AS
(
SELECT
InvoiceId
,CASE WHEN AllocationMethod = ''ProgressPaymentCredit'' THEN
SUM(ProgressPaymentCredit)
ELSE
SUM(ReceivablesApplied_Amount)
END AS CreditApplied_Amount
FROM
CTE_CreditAppliedAmount_Temp
GROUP BY
InvoiceId,AllocationMethod
)
,CTE_CreditApplied AS
(
SELECT
InvoiceId,
SUM(CreditApplied_Amount) CreditApplied_Amount
FROM
CTE_CreditAppliedAmount
GROUP BY
InvoiceId
)
SELECT DISTINCT
CustomerDetails.InvoiceId as Id
,CustomerDetails.InvoiceId
,ProgramVendor
,InvoiceNumber
,InvoiceDueDate
,InvoiceStatus
,InvoiceTotal_Amount
,InvoiceTotal_Currency
,CustomerDetails.Balance_Amount
,CustomerDetails.Balance_Currency
,CustomerNumber
,CustomerName
,ISNULL(SequenceNumber,''Unallocated'') AS SequenceNumber
,CustomerDetails.ContractId
,''''AS CreditApplication
,ISNULL(PA.PaidAmount,0.00) AS AmountPaid_Amount
,ISNULL(PA.AmountOutstanding,CustomerDetails.Balance_Amount) AS AmountOutstanding
,ISNULL(CTE_CreditApplied.CreditApplied_Amount,0) AS CreditApplied_Amount
,CustomerDetails.Balance_Currency AS CreditApplied_Currency
--Document Attachment Fields
,CustomerDetails.InvoiceFileContent
,CustomerDetails.InvoiceFileSource
,CustomerDetails.InvoiceFileType
,CustomerDetails.StorageSystem
,CustomerDetails.InvoiceFilePath
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFs.UDF1Label
,UDFs.UDF2Label
,UDFs.UDF3Label
,UDFs.UDF4Label
,UDFs.UDF5Label
FROM CTE_CustomerDetails CustomerDetails
PAIDDATEJOINCONDITION
LEFT JOIN UDFs ON CustomerDetails.InvoiceId = UDFs.InvoiceId AND UDFs.IsActive = 1
LEFT JOIN CTE_CreditApplied ON CustomerDetails.InvoiceId = CTE_CreditApplied.InvoiceId
GROUP BY
CustomerDetails.InvoiceId
,ProgramVendor
,InvoiceNumber
,InvoiceDueDate
,InvoiceStatus
,InvoiceTotal_Amount
,InvoiceTotal_Currency
,CustomerDetails.Balance_Amount
,CustomerDetails.Balance_Currency
,CustomerNumber
,CustomerName
,SequenceNumber
,CustomerDetails.ContractId
,PA.PaidAmount
,PA.AmountOutstanding
,CustomerDetails.InvoiceFileContent
,CustomerDetails.InvoiceFileSource
,CustomerDetails.InvoiceFileType
,CustomerDetails.StorageSystem
,CustomerDetails.InvoiceFilePath
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFs.UDF1Label
,UDFs.UDF2Label
,UDFs.UDF3Label
,UDFs.UDF4Label
,UDFs.UDF5Label
,CTE_CreditApplied.CreditApplied_Amount
'
IF(@CreditAppNumber IS NOT NULL)
SET @CREDITAPPJOINCONDITION = 'JOIN CreditApprovedStructures CPS ON Con.CreditApprovedStructureId =CPS.Id
JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
JOIN CreditApplications CApp ON Opp.Id= CApp.Id'
ELSE
SET @CREDITAPPJOINCONDITION = ''
IF(@PaidDateto IS NOT NULL OR  @PaidDateFrom  IS NOT NULL)
SET  @PAIDDATEJOINCONDITION ='JOIN CTE_PayableAmount PA ON CustomerDetails.InvoiceId = PA.PayableInvoiceId'
ELSE
SET @PAIDDATEJOINCONDITION='LEFT JOIN CTE_PayableAmount PA ON CustomerDetails.InvoiceId = PA.PayableInvoiceId'
IF(@CreditAppNumber IS NOT NULL)
SET @CREDITAPPWHERECONDITION = 'AND (Opp.Number LIKE REPLACE(@CreditAppNumber,''*'',''%''))'
ELSE
SET @CREDITAPPWHERECONDITION=''
SET @Sql =  REPLACE(@Sql,'CREDITAPPJOINCONDITION', @CREDITAPPJOINCONDITION);
SET @Sql =  REPLACE(@Sql,'CREDITAPPWHERECONDITION', @CREDITAPPWHERECONDITION);
SET @Sql =  REPLACE(@Sql,'PAIDDATEJOINCONDITION', @PAIDDATEJOINCONDITION);
EXEC sp_executesql @Sql,N'
@CurrentVendorId BIGINT,
@InvoiceId BIGINT=NULL,
@ProgramVendor NVARCHAR(250)=NULL,
@InvoiceNumber NVARCHAR(80)=NULL,
@InvoiceFromDueDate DATETIMEOFFSET=NULL,
@InvoiceToDueDate DATETIMEOFFSET=NULL,
@PaidDateFrom DATETIMEOFFSET=NULL,
@PaidDateTo DATETIMEOFFSET=NULL,
@InvoiceStatus NVARCHAR(250)=NULL,
@CustomerNumber NVARCHAR(80)=NULL,
@CustomerName NVARCHAR(250)=NULL,
@CreditAppNumber NVARCHAR(80)=NUL,
@SequenceNumber NVARCHAR(80)=NULL,
@PaymentStatus NVARCHAR(250)=NULL'
,@CurrentVendorId
,@InvoiceId
,@ProgramVendor
,@InvoiceNumber
,@InvoiceFromDueDate
,@InvoiceToDueDate
,@PaidDateFrom
,@PaidDateTo
,@InvoiceStatus
,@CustomerNumber
,@CustomerName
,@CreditAppNumber
,@SequenceNumber
,@PaymentStatus

GO
