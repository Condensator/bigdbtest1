SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProcessPayablesForGLTransfer]
(
@EffectiveDate DATE,
@MovePLBalance BIT,
@PLEffectiveDate DATE = NULL,
@ContractInfo ContractIdCollection READONLY
)
AS
BEGIN
CREATE TABLE #PayableGLSummary
(
ContractId BIGINT,
GLTransactionType NVARCHAR(56),
GLTemplateId BIGINT,
GLEntryItem NVARCHAR(100),
Amount DECIMAL(16,2),
IsDebit BIT,
MatchingGLTemplateId BIGINT,
MatchingFilter NVARCHAR(80),
InstrumentTypeId BIGINT,
LineofBusinesssId BIGINT,
CostCenterId BIGINT,
LegalEntityId BIGINT
)
CREATE TABLE #PayableInfo
(
ContractId BIGINT,
PayableId BIGINT,
Amount DECIMAL(16,2),
Balance DECIMAL(16,2),
DueDate DATE,
GLTemplateId BIGINT,
GLTransactionType NVARCHAR(56),
EntityType NVARCHAR(6),
EntityId BIGINT,
IsAssociatedWithDR BIT,
IsForGLReversal BIT,
IsForReclass BIT,
IsForPLBalanceTransfer BIT,
IsGLPosted BIT,
Status NVARCHAR(34),
SourceTable NVARCHAR(48),
InitialExchangeRate DECIMAL(20,10)
);
INSERT INTO #PayableInfo
SELECT * FROM
(SELECT
Fundings.ContractId,
Payables.Id PayableId,
Payables.Amount_Amount,
Payables.Balance_Amount,
Payables.DueDate,
PayableCodes.GLTemplateId,
GLTransactionTypes.Name AS GLTransactionType,
Payables.EntityType,
Payables.EntityId,
CASE WHEN DisbursementRequests.Id IS NOT NULL THEN 1 ELSE 0 END AS IsAssociatedWithDR,
CASE WHEN Payables.DueDate >= @EffectiveDate THEN 1 ELSE 0 END AS IsForGLReversal,
CASE WHEN Payables.DueDate < @EffectiveDate THEN 1 ELSE 0 END AS IsForReclass,
CASE WHEN @MovePLBalance = 1 AND Payables.DueDate >= @PLEffectiveDate AND Payables.DueDate < @EffectiveDate AND Payables.IsGLPosted = 1 THEN 1 ELSE 0 END AS IsForPLBalanceTransfer,
Payables.IsGLPosted,
Payables.Status,
Payables.SourceTable,
ISNULL(Fundings.InitialExchangeRate,1) InitialExchangeRate
FROM
(SELECT C.ContractId,PayableInvoices.Id PayableInvoiceId,PayableInvoices.InitialExchangeRate FROM @ContractInfo C
JOIN LeaseFinances ON C.ContractId = LeaseFinances.ContractId
JOIN LeaseFundings ON LeaseFinances.Id = LeaseFundings.LeaseFinanceId AND LeaseFundings.IsActive=1
JOIN PayableInvoices ON LeaseFundings.FundingId = PayableInvoices.Id
GROUP BY C.ContractId,PayableInvoices.Id,PayableInvoices.InitialExchangeRate
UNION
SELECT C.ContractId,PayableInvoices.Id PayableInvoiceId,PayableInvoices.InitialExchangeRate FROM @ContractInfo C
JOIN LoanFinances ON C.ContractId = LoanFinances.ContractId
JOIN LoanFundings ON LoanFinances.Id = LoanFundings.LoanFinanceId AND LoanFundings.IsActive=1
JOIN PayableInvoices ON LoanFundings.FundingId = PayableInvoices.Id
GROUP BY C.ContractId,PayableInvoices.Id,PayableInvoices.InitialExchangeRate)
AS Fundings
JOIN Payables ON Fundings.PayableInvoiceId = Payables.EntityId AND Payables.EntityType = 'PI' AND Payables.Status <> 'Inactive'
AND (Payables.IsGLPosted=1 OR Payables.Amount_Amount <> Payables.Balance_Amount)
AND Payables.DueDate < @EffectiveDate
JOIN PayableCodes ON Payables.PayableCodeId = PayableCodes.Id
JOIN PayableTypes ON PayableCodes.PayableTypeId = PayableTypes.Id
JOIN GLTemplates ON PayableCodes.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN DisbursementRequestPayables ON Payables.Id = DisbursementRequestPayables.PayableId
LEFT JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
WHERE (DisbursementRequestPayables.PayableId IS NULL OR DisbursementRequestPayables.IsActive=1)
OR (DisbursementRequests.Id IS NULL OR DisbursementRequests.Status = 'Completed')
GROUP BY
Fundings.ContractId,
Payables.Id,
Payables.Amount_Amount,
Payables.Balance_Amount,
Payables.DueDate,
PayableCodes.GLTemplateId,
GLTransactionTypes.Name,
Payables.EntityType,
Payables.EntityId,
CASE WHEN DisbursementRequests.Id IS NOT NULL THEN 1 ELSE 0 END,
Payables.IsGLPosted,
Payables.Status,
Payables.SourceTable,
Fundings.InitialExchangeRate
UNION
SELECT
C.ContractId,
Payables.Id PayableId,
Payables.Amount_Amount,
Payables.Balance_Amount,
Payables.DueDate,
PayableCodes.GLTemplateId,
GLTransactionTypes.Name AS GLTransactionType,
Payables.EntityType,
Payables.EntityId,
CASE WHEN DisbursementRequests.Id IS NOT NULL THEN 1 ELSE 0 END AS IsAssociatedWithDR,
CASE WHEN Payables.DueDate >= @EffectiveDate THEN 1 ELSE 0 END AS IsForGLReversal,
CASE WHEN Payables.DueDate < @EffectiveDate THEN 1 ELSE 0 END AS IsForReclass,
CASE WHEN @MovePLBalance = 1 AND Payables.DueDate >= @PLEffectiveDate AND Payables.DueDate < @EffectiveDate AND Payables.IsGLPosted = 1 THEN 1 ELSE 0 END AS IsForPLBalanceTransfer,
Payables.IsGLPosted,
Payables.Status,
Payables.SourceTable,
1 AS InitialExchangeRate
FROM @ContractInfo C
JOIN Payables ON C.ContractId = Payables.EntityId AND Payables.EntityType = 'CT' AND Payables.Status <> 'Inactive'
AND (Payables.IsGLPosted=1 OR Payables.Amount_Amount <> Payables.Balance_Amount)
AND Payables.DueDate < @EffectiveDate
JOIN PayableCodes ON Payables.PayableCodeId = PayableCodes.Id
JOIN PayableTypes ON PayableCodes.PayableTypeId = PayableTypes.Id
JOIN GLTemplates ON PayableCodes.GLTemplateId = GLTemplates.Id
JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN DisbursementRequestPayables ON Payables.Id = DisbursementRequestPayables.PayableId
LEFT JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
WHERE (DisbursementRequestPayables.PayableId IS NULL OR DisbursementRequestPayables.IsActive=1)
OR (DisbursementRequests.Id IS NULL OR DisbursementRequests.Status = 'Completed')
GROUP BY
C.ContractId,
Payables.Id,
Payables.Amount_Amount,
Payables.Balance_Amount,
Payables.DueDate,
PayableCodes.GLTemplateId,
GLTransactionTypes.Name,
Payables.EntityType,
Payables.EntityId,
CASE WHEN DisbursementRequests.Id IS NOT NULL THEN 1 ELSE 0 END,
Payables.IsGLPosted,
Payables.Status,
Payables.SourceTable
) AS PayableInfo
CREATE TABLE #PayablePrepaymentSummary (ContractId BIGINT,PayableId BIGINT,ApprovedAmount DECIMAL(16,2),PrePaidAmountFromDR DECIMAL(16,2),IsFromDR BIT,PrePaidAmountFromAP DECIMAL(16,2));
CREATE TABLE #CashPostedPayableInfo (ContractId BIGINT,PayableId BIGINT,PaidAmount DECIMAL(16,2));
INSERT INTO #PayablePrepaymentSummary
SELECT P.ContractId,
P.PayableId,
SUM(DisbursementRequestPayees.ApprovedAmount_Amount) ApprovedAmount,
SUM(DisbursementRequestPayees.ReceivablesApplied_Amount) PrePaidAmountFromDR,
1 IsFromDR,
0.00 PrePaidAmountFromAP
FROM
(SELECT * FROM #PayableInfo WHERE IsAssociatedWithDR=1 AND IsForReclass=1) P
JOIN DisbursementRequestPayables ON P.PayableId = DisbursementRequestPayables.PayableId AND DisbursementRequestPayables.IsActive=1
JOIN DisbursementRequestPayees ON DisbursementRequestPayables.Id = DisbursementRequestPayees.DisbursementRequestPayableId AND DisbursementRequestPayees.IsActive=1
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id AND DisbursementRequests.Status = 'Completed'
--JOIN TreasuryPayableDetails ON DisbursementRequestPayables.Id = TreasuryPayableDetails.DisbursementRequestPayableId AND TreasuryPayableDetails.IsActive=1
GROUP BY P.ContractId,P.PayableId
UPDATE #PayablePrepaymentSummary SET PrePaidAmountFromAP = P.PrePaidAmountFromAP
FROM #PayablePrepaymentSummary
JOIN (
SELECT P.ContractId,
P.PayableId,
SUM(TreasuryPayableDetails.ReceivableOffsetAmount_Amount) PrePaidAmountFromAP
FROM
(SELECT * FROM #PayableInfo WHERE IsAssociatedWithDR=1 AND IsForReclass=1) P
JOIN DisbursementRequestPayables ON P.PayableId = DisbursementRequestPayables.PayableId AND DisbursementRequestPayables.IsActive=1
JOIN DisbursementRequestPayees ON DisbursementRequestPayables.Id = DisbursementRequestPayees.DisbursementRequestPayableId AND DisbursementRequestPayees.IsActive=1
JOIN DisbursementRequests ON DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id AND DisbursementRequests.Status = 'Completed'
JOIN TreasuryPayableDetails ON DisbursementRequestPayables.Id = TreasuryPayableDetails.DisbursementRequestPayableId AND TreasuryPayableDetails.IsActive=1
GROUP BY P.ContractId,P.PayableId) P ON P.PayableId = #PayablePrepaymentSummary.payableId AND P.ContractId = #PayablePrepaymentSummary.ContractId
INSERT INTO #PayablePrepaymentSummary
SELECT P.ContractId,
P.PayableId,
P.Amount ApprovedAmount,
0 PrePaidAmountFromDR,
0 IsFromDR,
P.Balance PrePaidAmountFromAP
FROM
(SELECT * FROM #PayableInfo WHERE IsAssociatedWithDR=0 AND IsForReclass=1) P
JOIN TreasuryPayableDetails ON P.PayableId = TreasuryPayableDetails.PayableId AND TreasuryPayableDetails.IsActive=1
JOIN TreasuryPayables ON TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.Id AND TreasuryPayables.Status <> 'Inactive'
JOIN PaymentVoucherDetails ON TreasuryPayables.Id = PaymentVoucherDetails.TreasuryPayableId
JOIN PaymentVouchers ON PaymentVoucherDetails.PaymentVoucherId = PaymentVouchers.Id AND PaymentVouchers.Status <> 'Inactive'
GROUP BY P.ContractId,P.PayableId,P.Amount,P.Balance
INSERT INTO #CashPostedPayableInfo
SELECT P.ContractId,P.PayableId,SUM(PaymentVoucherDetails.Amount_Amount) PaidAmount
FROM (SELECT * FROM #PayableInfo WHERE IsForReclass=1) P
JOIN TreasuryPayableDetails ON P.PayableId = TreasuryPayableDetails.PayableId AND TreasuryPayableDetails.IsActive=1
JOIN TreasuryPayables ON TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.Id AND TreasuryPayables.Status <> 'Inactive'
JOIN PaymentVoucherDetails ON TreasuryPayables.Id = PaymentVoucherDetails.TreasuryPayableId
JOIN PaymentVouchers ON PaymentVoucherDetails.PaymentVoucherId = PaymentVouchers.Id AND PaymentVouchers.Status = 'Paid'
GROUP BY P.PayableId,P.ContractId
IF EXISTS(SELECT ContractId FROM #PayableInfo WHERE GLTransactionType IN('AssetPurchaseAP','Disbursement'))
BEGIN
CREATE TABLE #AssetPurchaseAPAndDRInfo (ContractId BIGINT,GLTemplateId BIGINT,GLTransactionType NVARCHAR(56),PayableBalance DECIMAL(16,2),HoldBackAmountBalance DECIMAL(16,2));
INSERT INTO #AssetPurchaseAPAndDRInfo
SELECT Payables.ContractId,Payables.GLTemplateId,GLTransactionType,SUM(PayableBalance),SUM(HoldBackAmountBalance)
FROM
(SELECT P.ContractId,
P.PayableId,
P.GLTransactionType,
CASE WHEN CashPostedPayable.PayableId IS NULL THEN ROUND(ISNULL((PrepaidPayable.ApprovedAmount - PrepaidPayable.PrePaidAmountFromDR - PrepaidPayable.PrePaidAmountFromAP),0) * P.InitialExchangeRate,2) ELSE 0 END AS PayableBalance,
CASE WHEN P.Status <> 'Approved' THEN ROUND(P.Balance * P.InitialExchangeRate,2) ELSE 0 END AS HoldBackAmountBalance,
P.GLTemplateId
FROM
(SELECT * FROM #PayableInfo WHERE GLTransactionType IN('AssetPurchaseAP','Disbursement') AND IsForReclass=1 AND IsGLPosted=1) P
LEFT JOIN #CashPostedPayableInfo CashPostedPayable ON P.PayableId = CashPostedPayable.PayableId AND P.ContractId = CashPostedPayable.ContractId
LEFT JOIN #PayablePrepaymentSummary PrepaidPayable ON P.PayableId = PrepaidPayable.PayableId AND P.ContractId = PrepaidPayable.ContractId) AS Payables
GROUP BY Payables.ContractId,Payables.GLTemplateId,GLTransactionType
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
P.GLTransactionType,
P.GLTemplateId,
CASE WHEN P.GLTransactionType = 'AssetPurchaseAP' THEN 'AssetPurchasePayable' ELSE 'DisbursementPayable' END,
P.PayableBalance,
0
FROM #AssetPurchaseAPAndDRInfo P
WHERE PayableBalance <> 0
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
P.GLTransactionType,
P.GLTemplateId,
'HoldBack',
P.HoldBackAmountBalance,
0
FROM #AssetPurchaseAPAndDRInfo P
WHERE HoldBackAmountBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #PayableInfo WHERE GLTransactionType = 'MiscellaneousAccountsPayable')
BEGIN
CREATE TABLE #MiscellaneousAccountsPayableInfo (ContractId BIGINT,GLTemplateId BIGINT,IsGLPosted BIT,MiscellaneousPayableBalance DECIMAL(16,2),HoldBackAmountBalance DECIMAL(16,2));
INSERT INTO #MiscellaneousAccountsPayableInfo
SELECT ContractId,GLTemplateId,IsGLPosted,SUM(MiscellaneousPayableBalance),SUM(HoldBackAmountBalance)
FROM
(SELECT P.ContractId,
P.PayableId,
P.IsGLPosted,
CASE WHEN P.IsGLPosted=1 AND P.IsAssociatedWithDR=1
THEN CASE WHEN CashPostedPayable.PayableId IS NULL
THEN ROUND(ISNULL((PrepaidPayable.ApprovedAmount - PrepaidPayable.PrePaidAmountFromDR - PrepaidPayable.PrePaidAmountFromAP),0) * P.InitialExchangeRate,2)
ELSE 0 END
WHEN P.IsGLPosted=1 AND P.IsAssociatedWithDR=0
THEN ROUND((P.Amount - ISNULL(CashPostedPayable.PaidAmount,0)) * P.InitialExchangeRate,2)
WHEN P.IsGLPosted=0 AND P.IsAssociatedWithDR=0
THEN ROUND(((ISNULL(CashPostedPayable.PaidAmount,0) * P.InitialExchangeRate) * (-1)),2)
ELSE 0 END AS MiscellaneousPayableBalance,
CASE WHEN P.Status <> 'Approved' THEN ROUND(P.Balance * P.InitialExchangeRate,2) ELSE 0 END AS HoldBackAmountBalance,
P.GLTemplateId
FROM
(SELECT * FROM #PayableInfo WHERE GLTransactionType = 'MiscellaneousAccountsPayable' AND IsForReclass=1) P
LEFT JOIN #CashPostedPayableInfo CashPostedPayable ON P.PayableId = CashPostedPayable.PayableId AND P.ContractId = CashPostedPayable.ContractId
LEFT JOIN #PayablePrepaymentSummary PrepaidPayable ON P.PayableId = PrepaidPayable.PayableId AND P.ContractId = PrepaidPayable.ContractId AND PrepaidPayable.IsFromDR=1) AS Payables
GROUP BY ContractId,GLTemplateId,IsGLPosted
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
'MiscellaneousAccountsPayable',
P.GLTemplateId,
CASE WHEN P.IsGLPosted=1 THEN 'MiscellaneousPayable' ELSE 'PrepaidMiscellaneousPayable' END,
P.MiscellaneousPayableBalance,
0
FROM #MiscellaneousAccountsPayableInfo P
WHERE MiscellaneousPayableBalance <> 0
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
'MiscellaneousAccountsPayable',
P.GLTemplateId,
'HoldBack',
P.HoldBackAmountBalance,
0
FROM #MiscellaneousAccountsPayableInfo P
WHERE HoldBackAmountBalance <> 0
END
IF EXISTS(SELECT ContractId FROM #PayableInfo WHERE GLTransactionType = 'DueToInvestorAP')
BEGIN
CREATE TABLE #DueToInvestorAPInfo (ContractId BIGINT,GLTemplateId BIGINT,PayableBalance DECIMAL(16,2));
INSERT INTO #DueToInvestorAPInfo
SELECT Payables.ContractId,Payables.GLTemplateId,SUM(PayableBalance)
FROM
(SELECT P.ContractId,
P.PayableId,
CASE WHEN CashPostedPayable.PayableId IS NULL THEN ROUND(ISNULL((PrepaidPayable.ApprovedAmount - PrepaidPayable.PrePaidAmountFromDR - PrepaidPayable.PrePaidAmountFromAP),0) * P.InitialExchangeRate,2) ELSE 0 END AS PayableBalance,
P.GLTemplateId
FROM
(SELECT * FROM #PayableInfo WHERE GLTransactionType = 'DueToInvestorAP' AND IsForReclass=1 AND IsGLPosted=1) P
LEFT JOIN #CashPostedPayableInfo CashPostedPayable ON P.PayableId = CashPostedPayable.PayableId AND P.ContractId = CashPostedPayable.ContractId
LEFT JOIN #PayablePrepaymentSummary PrepaidPayable ON P.PayableId = PrepaidPayable.PayableId AND P.ContractId = PrepaidPayable.ContractId) AS Payables
GROUP BY Payables.ContractId,Payables.GLTemplateId
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
'DueToInvestorAP',
P.GLTemplateId,
'RentDueToInvestorAP',
P.PayableBalance,
0
FROM #DueToInvestorAPInfo P
WHERE PayableBalance <> 0
END
IF(@MovePLBalance=1)
BEGIN
IF EXISTS(SELECT ContractId FROM #PayableInfo WHERE GLTransactionType = 'MiscellaneousAccountsPayable' AND IsForPLBalanceTransfer = 1)
BEGIN
INSERT INTO #PayableGLSummary(ContractId,GLTransactionType,GLTemplateId,GLEntryItem,Amount,IsDebit)
SELECT
P.ContractId,
'MiscellaneousAccountsPayable',
P.GLTemplateId,
'Expense',
SUM(ROUND(P.Amount * P.InitialExchangeRate,2)),
1
FROM
(SELECT * FROM #PayableInfo WHERE GLTransactionType = 'MiscellaneousAccountsPayable' AND IsForPLBalanceTransfer = 1) P
LEFT JOIN Sundries ON P.PayableId = Sundries.PayableId
LEFT JOIN BlendedItemDetails ON Sundries.Id = BlendedItemDetails.SundryId
WHERE BlendedItemDetails.BlendedItemId IS NULL
GROUP BY P.GLTemplateId,P.ContractId
END
END
SELECT * FROM #PayableGLSummary
IF OBJECT_ID('tempdb..#PayableGLSummary') IS NOT NULL
DROP TABLE #PayableGLSummary
IF OBJECT_ID('tempdb..#PayableInfo') IS NOT NULL
DROP TABLE #PayableInfo
IF OBJECT_ID('tempdb..#PayablePrepaymentSummary') IS NOT NULL
DROP TABLE #PayablePrepaymentSummary
IF OBJECT_ID('tempdb..#CashPostedPayableInfo') IS NOT NULL
DROP TABLE #CashPostedPayableInfo
IF OBJECT_ID('tempdb..#AssetPurchaseAPAndDRInfo') IS NOT NULL
DROP TABLE #AssetPurchaseAPAndDRInfo
IF OBJECT_ID('tempdb..#MiscellaneousAccountsPayableInfo') IS NOT NULL
DROP TABLE #MiscellaneousAccountsPayableInfo
END

GO
