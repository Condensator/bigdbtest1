SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetReceiptReversalLog]
(
@ReceiptId BIGINT,
@IsFromNonAccrualLoanReceipt BIT,
@IsFromNonCash BIT,
@ContractId BIGINT,
@EntityType nvarchar(100),
@ReceiptClassification NVARCHAR(25),
@CreateAdjustmentPayable BIT,
@ReceiptApplication_CannotBeReversed_Reclassified NVARCHAR(200),
@ReceiptApplication_ReverseReceipts_DescOrder NVARCHAR(250),
@VatReceiptReversalReason NVARCHAR(250)
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #ErrorLogs
(
ErrorMessage NVARCHAR(MAX)
)
CREATE TABLE #DisbursementRequestTemp
(
DisbursementRequestId BIGINT
)
CREATE TABLE #PaymentVoucherTemp
(
VoucherNumber NVARCHAR(80)
)
CREATE TABLE #ContractIds
(
ContractId BIGINT
)
CREATE TABLE #ContractSequenceNumbers
(
SequenceNumber NVARCHAR(MAX)
)
CREATE TABLE #ReceiptInNonAccrual
(
ReceiptId BIGINT
)
CREATE TABLE #TreasuryPayableTemp
(
TreasuryPayableId BIGINT
)
INSERT INTO #ErrorLogs
SELECT 'System Generated Receipts of Type Payable Offset / Escrow Refund / Noncash-Escrow Application cannot be reversed'
FROM Receipts JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
WHERE Receipts.Id = @ReceiptId
AND ReceiptTypes.ReceiptTypeName in('PayableOffset','EscrowRefund','PPTEscrowNonCash')
INSERT INTO #ErrorLogs
SELECT
CASE WHEN Receipts.Status = 'Reversed' THEN 'Receipts that are reversed once cannot be reversed again' ELSE 'Only Receipts with Status Posted/Completed can be reversed' END
FROM
Receipts
WHERE
Receipts.Id = @ReceiptId
AND Receipts.Status NOT IN ('Posted','Completed')
INSERT INTO #ErrorLogs
SELECT
'Receipts belonging to an assumption could not be reversed'
FROM AssumptionReceipts
JOIN Assumptions ON AssumptionReceipts.AssumptionId = Assumptions.Id
WHERE AssumptionReceipts.ReceiptId = @ReceiptId
AND AssumptionReceipts.IsActive=1
AND Assumptions.Status NOT IN('Inactive','Approved')
INSERT INTO #ErrorLogs
SELECT
('Receipt cannot be reversed since it has been used for another receipt application')
WHERE EXISTS
(
SELECT * FROM UnappliedReceipts
JOIN Receipts ON UnappliedReceipts.ReceiptId = Receipts.Id
JOIN ReceiptAllocations ON UnappliedReceipts.ReceiptAllocationId = ReceiptAllocations.Id
WHERE
ReceiptAllocations.ReceiptId = @ReceiptId
AND Receipts.Status IN ('Posted','Completed')
AND UnappliedReceipts.IsActive = 1 AND Receipts.ReceiptClassification IN ('NonAccrualNonDSL' , 'NonAccrualNonDSLNonCash','DSL')
)
IF(@ReceiptClassification IN('Cash','NonCash'))
BEGIN
INSERT INTO #ReceiptInNonAccrual
SELECT DISTINCT ReceiptApplications.ReceiptId
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId=Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('LoanInterest','LoanPrincipal')
JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
JOIN Contracts ON Receivables.EntityId=CONtracts.Id
JOIN LoanFinances ON CONtracts.Id =LoanFinances.ContractId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND Contracts.NonAccrualDate is not null
AND Contracts.ContractType='Loan'
AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
AND LoanPaymentSchedules.StartDate>=Contracts.NonAccrualDate
AND ReceiptApplicationReceivableDetails.IsActive=1
AND ReceiptApplicationReceivableDetails.AmountApplied_Amount <> ReceiptApplicationReceivableDetails.BookAmountApplied_Amount
AND LoanFinances.IsDailySensitive=0
AND Receipts.Status IN ('Posted','Completed')
END
IF EXISTS(SELECT * FROM #ReceiptInNonAccrual)
BEGIN
INSERT INTO #ErrorLogs
SELECT @ReceiptApplication_CannotBeReversed_Reclassified;
END
ELSE IF( @EntityType='Loan' AND @IsFromNONAccrualLoanReceipt!=1  )
BEGIN
INSERT INTO #ContractSequenceNumbers
SELECT DISTINCT Contracts.sequencenumber
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId=Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('LoanInterest','LoanPrincipal')
JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
JOIN Contracts ON Receivables.EntityId=CONtracts.Id
JOIN LoanFinances ON CONtracts.Id =LoanFinances.ContractId
WHERE Contracts.NONAccrualDate is not null
AND LoanPaymentSchedules.StartDate>=Contracts.NONAccrualDate
AND Contracts.ContractType='Loan'
AND ReceiptApplications.ReceiptId>@ReceiptId
AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
AND ReceiptApplicatiONReceivableDetails.IsActive=1
AND LoanFinances.IsDailySensitive=0
AND Contracts.Id=@ContractId
AND Receipts.Status NOT IN ('Reversed','Inactive')
END
ELSE IF ( (@EntityType='Customer' OR @EntityType='_') AND @IsFromNONAccrualLoanReceipt!=1 )
BEGIN
SELECT DISTINCT Contracts.Id,CONtracts.SequenceNumber
INTO #tempcontracts
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId=Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('LoanInterest','LoanPrincipal')
JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
JOIN Contracts ON Receivables.EntityId=CONtracts.Id
JOIN LoanFinances ON Contracts.Id =LoanFinances.ContractId
WHERE Contracts.NONAccrualDate is not null
AND LoanPaymentSchedules.StartDate>=Contracts.NONAccrualDate
AND Contracts.ContractType='Loan'
AND ReceiptApplications.ReceiptId=@ReceiptId
AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
AND ReceiptApplicationReceivableDetails.IsActive=1
AND LoanFinances.IsDailySensitive=0
INSERT INTO #ContractSequenceNumbers
SELECT DISTINCT #tempcontracts.SequenceNumber
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId=ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId=Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.Name IN ('LoanInterest','LoanPrincipal')
JOIN #tempcontracts ON Receivables.EntityId=#tempcontracts.Id
WHERE Receipts.Id>@ReceiptId
AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
AND Receipts.Status NOT IN ('Reversed','Inactive')
END
IF EXISTS(SELECT * FROM #ContractSequenceNumbers)
INSERT INTO #ErrorLogs
SELECT REPLACE(@ReceiptApplication_ReverseReceipts_DescOrder, '@ContractSequenceNumbers' ,
STUFF(
(SELECT ',' + SequenceNumber
FROM #ContractSequenceNumbers
FOR XML PATH('')),1,1,'' ))
IF @IsFromNonAccrualLoanReceipt = 1
BEGIN
SELECT
Receipts.Number
,Contracts.SequenceNumber
INTO #NonAccrualLoanReversalTemp
FROM
Receipts
Join Contracts on Receipts.ContractId=Contracts.Id
WHERE
Receipts.Id > @ReceiptId
AND Receipts.Status NOT IN ('Reversed','Inactive')
AND Receipts.ContractId = @ContractId
AND Receipts.ReceiptClassification IN ('NonAccrualNonDSL','NonAccrualNonDSLNonCash')
IF EXISTS(SELECT * FROM #NonAccrualLoanReversalTemp)
INSERT INTO #ErrorLogs
SELECT TOP 1+
'There are some receipts created after this receipt for the contract(s) {'+ #NonAccrualLoanReversalTemp.SequenceNumber+
'}. Please reverse all those receipts in descending order (Last created receipt first and so on) and proceed to reverse this receipt'
FROM #NonAccrualLoanReversalTemp
END
SELECT
Receivables.Id as ReceivableId,
SecurityDeposits.Id as SecurityDepositId,
(ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) as TotalPostedAmount
INTO #SecurityDepositApplicationTemp
FROM
SecurityDeposits
JOIN Receivables ON SecurityDeposits.ReceivableId = Receivables.Id
JOIN SecurityDepositApplications ON SecurityDeposits.Id = SecurityDepositApplications.SecurityDepositId
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
WHERE
Receipts.Id = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND SecurityDeposits.IsActive = 1
AND SecurityDepositApplications.IsActive = 1
GROUP BY Receivables.Id,SecurityDeposits.Id,ReceiptApplicationReceivableDetails.AmountApplied_Amount,ReceiptApplicationReceivableDetails.TaxApplied_Amount
HAVING (ReceiptApplicationReceivableDetails.AmountApplied_Amount + ReceiptApplicationReceivableDetails.TaxApplied_Amount) > 0
IF EXISTS(SELECT * FROM #SecurityDepositApplicationTemp)
INSERT INTO #ErrorLogs
SELECT
('Receipt cannot be reversed as Security Deposit Applications are already made for the following Receivable(s) : { '+
(STUFF(
(SELECT ',' + CAST(ReceivableId AS NVARCHAR)
FROM #SecurityDepositApplicationTemp
FOR XML PATH('')),1,1,'')) + ' } associated with the following Security Deposit(s) : { '+
(STUFF(
(SELECT ',' + CAST(SecurityDepositId AS NVARCHAR)
FROM #SecurityDepositApplicationTemp
FOR XML PATH('')),1,1,'')) +' }')
SELECT DISTINCT
Contracts.SequenceNumber
INTO #TerminatedContractsTemp
FROM
ReceiptApplicationReceivableDetails
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN Contracts ON Receivables.EntityType = 'CT' AND Receivables.EntityId = Contracts.Id
WHERE
ReceiptApplicationReceivableDetails.IsActive = 1
AND Contracts.Status LIKE 'Terminated'
AND ReceiptApplications.ReceiptId = @ReceiptId
GROUP BY Contracts.SequenceNumber
IF EXISTS (SELECT * FROM #TerminatedContractsTemp)
INSERT INTO #ErrorLogs
SELECT
('Receipt cannot be reversed as receivables have been applied against the following Terminated Contract(s) : { '+
(STUFF(
(SELECT ',' + CAST(SequenceNumber AS NVARCHAR)
FROM #TerminatedContractsTemp
FOR XML PATH('')),1,1,'')) + ' }')
IF(@IsFromNonCash = 0 AND  @CreateAdjustmentPayable = 0)
BEGIN
INSERT INTO #ErrorLogs
SELECT
('Receipt attached to an approved Clearing/Refund cannot be reversed')
WHERE EXISTS
(
SELECT
UnallocatedRefunds.Id
FROM
UnallocatedRefunds
JOIN UnallocatedRefundDetails ON UnallocatedRefunds.Id = UnallocatedRefundDetails.UnallocatedRefundId
JOIN ReceiptAllocations ON UnallocatedRefundDetails.ReceiptAllocationId = ReceiptAllocations.Id
WHERE
UnallocatedRefunds.Status = 'Approved'
AND (UnallocatedRefunds.ReceiptId = @ReceiptId OR ReceiptAllocations.ReceiptId = @ReceiptId)
)
INSERT INTO #DisbursementRequestTemp
SELECT
DisbursementRequests.Id as DisbursementRequestId
FROM
DisbursementRequestPayables
JOIN Payables ON DisbursementRequestPayables.PayableId = Payables.Id
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
JOIN ReceiptApplicationReceivableDetails ON Payables.Id = ReceiptApplicationReceivableDetails.PayableId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
WHERE
ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Payables.Status <> 'Inactive'
AND DisbursementRequestPayables.IsActive = 1
AND DisbursementRequests.Status <> 'Inactive'
GROUP BY DisbursementRequests.Id
INSERT INTO #DisbursementRequestTemp
SELECT
DisbursementRequests.Id	as DisbursementRequestId
FROM
DisbursementRequestPayables
JOIN Payables ON DisbursementRequestPayables.PayableId = Payables.Id
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
JOIN Sundries ON Payables.Id = Sundries.PayableId
JOIN ReceiptApplicationReceivableDetails ON Sundries.Id = ReceiptApplicationReceivableDetails.SundryPayableId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
WHERE
ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Payables.Status <> 'Inactive'
AND DisbursementRequestPayables.IsActive = 1
AND DisbursementRequests.Status <> 'Inactive'
GROUP BY DisbursementRequests.Id
IF	EXISTS(SELECT * FROM #DisbursementRequestTemp)
INSERT INTO #ErrorLogs
SELECT
('Receipt associated with a Disbursement Request cannot be reversed. Please inactivate the following Disbursement Request(s) in order to proceed : { ' +
STUFF(
(SELECT ',' + CAST(DisbursementRequestId AS NVARCHAR)
FROM #DisbursementRequestTemp
FOR XML PATH('')),1,1,'') + ' }')
INSERT INTO #TreasuryPayableTemp
SELECT
TreasuryPayables.Id as TreasuryPayableId
FROM
TreasuryPayableDetails
JOIN Payables ON TreasuryPayableDetails.PayableId = Payables.Id
JOIN TreasuryPayables ON TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.Id
JOIN ReceiptApplicationReceivableDetails ON Payables.Id = ReceiptApplicationReceivableDetails.PayableId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
WHERE
ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Payables.Status <> 'Inactive'
AND TreasuryPayableDetails.IsActive = 1
AND TreasuryPayables.Status IN ('Approved','Partially Approved')
GROUP BY TreasuryPayables.Id
IF	EXISTS(SELECT * FROM #TreasuryPayableTemp)
INSERT INTO #ErrorLogs
SELECT
('Receipt associated with an approved Treasury Payable cannot be reversed. Please inactivate the following Treasury Payable(s) in order to proceed : { ' +
STUFF(
(SELECT ',' + CAST(TreasuryPayableId AS NVARCHAR)
FROM #TreasuryPayableTemp
FOR XML PATH('')),1,1,'') + ' }')
INSERT INTO #PaymentVoucherTemp
SELECT
PaymentVouchers.VoucherNumber as VoucherNumber
FROM
CPIReceivables
JOIN Payables ON CPIReceivables.Id = Payables.SourceId and Payables.SourceTable='CPIReceivable'
JOIN TreasuryPayableDetails ON TreasuryPayableDetails.PayableId = Payables.Id
JOIN TreasuryPayables ON TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.id
JOIN PaymentVoucherDetails on PaymentVoucherDetails.TreasuryPayableId = TreasuryPayables.Id
JOIN PaymentVouchers on PaymentVouchers.Id =  PaymentVoucherDetails.PaymentVoucherId
JOIN ReceiptApplicationReceivableDetails ON Payables.Id = ReceiptApplicationReceivableDetails.PayableId
JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
WHERE
ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND Payables.Status <> 'Inactive'
AND CPIReceivables.IsActive = 1
AND Payables.Status <> 'Inactive'
AND (PaymentVouchers.Status <> 'Reversed' AND
PaymentVouchers.Status <> 'Inactive')
GROUP BY PaymentVouchers.VoucherNumber
IF	EXISTS(SELECT * FROM #PaymentVoucherTemp)
INSERT INTO #ErrorLogs
SELECT
('Receipt associated with a Payment Voucher cannot be reversed. Please inactivate the following Payment Voucher(s) in order to proceed : { ' +
STUFF(
(SELECT ',' + VoucherNumber
FROM #PaymentVoucherTemp
FOR XML PATH('')),1,1,'') + ' }')
SELECT
Contracts.Id as ContractId,
CASE WHEN Contracts.ContractType = 'Lease' THEN 1 ELSE 0 END as IsLease,
Contracts.NonAccrualDate As NonAccrualDate,
CASE WHEN LeasePaymentSchedules.Id IS NOT NULL THEN LeasePaymentSchedules.PaymentType ELSE LoanPaymentSchedules.PaymentType END as PaymentType,
ReceivableTypes.Name as ReceivableType,
Receivables.FunderId,
ReceivableDetails.AssetComponentType
INTO #ContractTemp
FROM
ReceiptApplicationReceivableDetails
JOIN ReceiptApplications on ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Contracts ON Receivables.EntityId = Contracts.Id AND Receivables.EntityType = 'CT'
LEFT JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND Contracts.ContractType = 'Lease'
LEFT JOIN LoanPaymentSchedules ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id AND Contracts.ContractType = 'Loan'
WHERE
ReceiptApplications.ReceiptId = @ReceiptId
AND (Contracts.ContractType = 'Lease' OR Contracts.ContractType = 'Loan')
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND ReceiptApplicationReceivableDetails.AmountApplied_Amount <> 0
INSERT INTO #ContractIds
SELECT DISTINCT
#ContractTemp.ContractId as ContractId
FROM
BlendedItemDetails
JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BLendedItems.Id
JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id
JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id
JOIN #ContractTemp ON LeaseFinances.ContractId = #ContractTemp.ContractId AND #ContractTemp.IsLease = 1
WHERE
BlendedItems.IsActive = 1
AND BlendedItemDetails.IsActive = 1
AND BlendedItems.IsFAS91 = 1
AND BlendedItems.DueDate >= #ContractTemp.NonAccrualDate
AND Sundries.IsActive = 1
AND BlendedItems.BookRecognitionMode IN ('Accrete','Amortize')
GROUP BY #ContractTemp.ContractId
INSERT INTO #ContractIds
SELECT DISTINCT
#ContractTemp.ContractId as ContractId
FROM
#ContractTemp
WHERE
#ContractTemp.IsLease =1
AND (#ContractTemp.ReceivableType IN ('CapitalLeaseRental','LeaseFloatRateAdj')
OR (#ContractTemp.ReceivableType = 'OperatingLeaseRental' AND #ContractTemp.AssetComponentType = 'Finance'))
AND #ContractTemp.PaymentType IN ('FixedTerm','DownPayment','CustomerGuaranteedResidual','ThirdPartyGuaranteedResidual')
AND #ContractTemp.FunderId IS NULL
INSERT INTO #ContractIds
SELECT DISTINCT
#ContractTemp.ContractId as ContractId
FROM
BlendedItemDetails
JOIN BlendedItems ON BlendedItemDetails.BlendedItemId = BLendedItems.Id
JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id
JOIN LoanBlendedItems ON BlendedItems.Id = LoanBlendedItems.BlendedItemId
JOIN LoanFinances ON LoanBlendedItems.LoanFinanceId = LoanFinances.Id
JOIN #ContractTemp ON LoanFinances.ContractId = #ContractTemp.ContractId AND #ContractTemp.IsLease = 0
WHERE
BlendedItems.IsActive = 1
AND BlendedItemDetails.IsActive = 1
AND BlendedItems.IsFAS91 = 1
AND BlendedItems.DueDate >= #ContractTemp.NonAccrualDate
AND Sundries.IsActive = 1
AND BlendedItems.BookRecognitionMode IN ('Accrete','Amortize')
GROUP BY #ContractTemp.ContractId
INSERT INTO #ContractIds
SELECT DISTINCT
#ContractTemp.ContractId as ContractId
FROM
#ContractTemp
WHERE
#ContractTemp.IsLease = 0
AND #ContractTemp.ReceivableType IN ('LoanInterest','LoanPrincipal')
AND (#ContractTemp.PaymentType IN ('FixedTerm','DownPayment'))
AND #ContractTemp.FunderId IS NULL
END

--Vat 
SELECT CurrentReceipt.Id AS CurrentReceipt,CurrentRARD.ReceivableDetailId,SUM(CurrentRARD.TaxApplied_Amount) AS Amount
INTO #TaxAppliedDetails
FROM Receipts CurrentReceipt 
JOIN ReceiptApplications CurrentRA ON CurrentReceipt.Id = CurrentRA.ReceiptId
JOIN ReceiptApplicationReceivableDetails CurrentRARD ON CurrentRA.Id = CurrentRARD.ReceiptApplicationId
JOIN ReceivableDetails ON CurrentRARD.ReceivableDetailId = ReceivableDetails.Id    
JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id    
WHERE CurrentReceipt.Id = @ReceiptId
AND CurrentRARD.IsActive = 1
AND CurrentRARD.TaxApplied_Amount != 0.00
AND Receivables.ReceivableTaxType = 'VAT'
GROUP BY CurrentReceipt.Id,CurrentRARD.ReceivableDetailId
HAVING SUM(CurrentRARD.TaxApplied_Amount) != 0

SELECT Re.Id
INTO #VATTaxAppliedAmount
FROM #TaxAppliedDetails AppliedDetails
JOIN ReceiptApplicationReceivableDetails RARD ON AppliedDetails.ReceivableDetailId = RARD.ReceivableDetailId 
JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id AND RA.ReceiptId != AppliedDetails.CurrentReceipt
JOIN Receipts Re on Re.Id = Ra.ReceiptId
WHERE RARD.AmountApplied_Amount != 0
AND Re.ReceiptClassification != 'NonCash'
AND Re.Status NOT IN ('Inactive','Reversed','Pending')
GROUP BY Re.Id,RARD.ReceivableDetailId
HAVING SUM(RARD.AmountApplied_Amount) != 0

IF EXISTS(SELECT * FROM #VATTaxAppliedAmount)
BEGIN
INSERT INTO #ErrorLogs
SELECT @VatReceiptReversalReason
END

SELECT
#ErrorLogs.ErrorMessage
FROM
#ErrorLogs
DROP TABLE #ErrorLogs
DROP TABLE #TaxAppliedDetails
DROP TABLE #VATTaxAppliedAmount
DROP TABLE #DisbursementRequestTemp
DROP TABLE #ContractIds
DROP TABLE #ContractSequenceNumbers
DROP TABLE #TreasuryPayableTemp
DROP TABLE #ContractTemp
DROP TABLE #SecurityDepositApplicationTemp
DROP TABLE #PaymentVoucherTemp
IF OBJECT_ID('temp..#NonAccrualLoanReversalTemp') IS NOT NULL
DROP TABLE #NonAccrualLoanReversalTemp
END

GO
