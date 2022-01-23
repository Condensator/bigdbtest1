SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPayableDetails]
(
@PayableId PayableId READONLY,
@payableStatus NVARCHAR(16),
@disbursementStatus NVARCHAR(16),
@paymentVoucherReversedStatus NVARCHAR(16),
@paymentVoucherInactiveStatus NVARCHAR(16)
)
AS
BEGIN
SET NOCOUNT ON;
--DECLARE
--@PayableId PayableId,
--@payableStatus NVARCHAR(16) = 'Inactive',
--@disbursementStatus NVARCHAR(16) = 'Inactive',
--@paymentVoucherReversedStatus NVARCHAR(16) = 'Reversed',
--@paymentVoucherInactiveStatus NVARCHAR(16) = 'Inactive'
--INSERT INTO @PayableId Values (86797),(88085),(93818),(94450),(88717)
CREATE TABLE #PayableInfo
(
[PayableId] BIGINT,
[Status] NVARCHAR(100),
[Amount] Decimal(16,2),
[Currency] NVarchar(6) NOT NULL,
[DueDate] Date NOT NULL,
[EntityType] NVARCHAR(4),
[EntityId] BigInt NOT NULL,
[SourceId] BigInt NOT NULL,
[SourceTable] Nvarchar(24),
[InternalComment] NVarChar(200) NULL,
[IsGLPosted] Bit NOT NULL,
[CurrencyId] BigInt NOT NULL,
[PayableCodeId] BigInt NOT NULL,
[LegalEntityId] BigInt NOT NULL,
[PayeeId] BigInt NOT NULL,
[RemitToId] BigInt NULL,
[TaxPortion] Decimal(16,2),
[CreationSourceId] Bigint,
[CreationSourceTable] NVARCHAR(5)
)
CREATE TABLE #DisbursementRequestInfo
(
[PayableId] BIGINT,
[DisbursementRequestId] BIGINT,
[DisbursementRequestStatus] NVARCHAR(100)
)
CREATE TABLE #VoucherDetail
(
VoucherPayableId BIGINT,
VoucherNumber NVARCHAR(100)
)
INSERT INTO #PayableInfo
SELECT
Payables.Id,
Payables.Status,
Payables.Amount_Amount AS Amount,
Payables.Amount_Currency AS Currrency,
Payables.DueDate,
Payables.EntityType,
Payables.EntityId,
Payables.SourceId,
Payables.SourceTable,
Payables.InternalComment,
Payables.IsGLPosted,
Payables.CurrencyId,
Payables.PayableCodeId,
Payables.LegalEntityId,
Payables.PayeeId,
Payables.RemitToId,
Payables.TaxPortion_Amount as TaxPortion,
Payables.CreationSourceId,
Payables.CreationSourceTable
FROM
Payables
JOIN @PayableId PIds on Payables.Id = PIDs.Id
LEFT JOIN Payables adjustmentpayables on Payables.Id = adjustmentpayables.AdjustmentBasisPayableId
WHERE Payables.Status != @payableStatus
AND Payables.AdjustmentBasisPayableId is null
AND adjustmentpayables.Id is null
INSERT INTO #DisbursementRequestInfo
SELECT
PIds.PayableId,
DisbursementRequests.Id,
DisbursementRequests.Status
FROM #PayableInfo PIds
JOIN DisbursementRequestPayables on PIds.PayableId = DisbursementRequestPayables.PayableId
JOIN DisbursementRequests on DisbursementRequestPayables.DisbursementRequestId = DisbursementRequests.Id
WHERE DisbursementRequestPayables.IsActive = 1
AND DisbursementRequests.Status != @disbursementStatus
INSERT INTO #VoucherDetail
SELECT
Payables.Id,
PaymentVouchers.VoucherNumber
FROM
Payables
JOIN #PayableInfo PIds on Payables.Id = PIDs.PayableId
JOIN TreasuryPayableDetails on PIds.PayableId = TreasuryPayableDetails.PayableId
JOIN TreasuryPayables on TreasuryPayableDetails.TreasuryPayableId = TreasuryPayables.Id
join PaymentVoucherDetails on TreasuryPayables.Id = PaymentVoucherDetails.TreasuryPayableId
join PaymentVouchers on PaymentVoucherDetails.PaymentVoucherId = PaymentVouchers.Id
WHERE TreasuryPayableDetails.IsActive = 1
AND PaymentVouchers.Status != @paymentVoucherReversedStatus
AND PaymentVouchers.Status != @paymentVoucherInactiveStatus
SELECT
P.[PayableId],
P.[EntityType],
P.[EntityId],
P.[DueDate],
P.[Status],
P.[SourceTable],
P.[SourceId],
P.[CurrencyId],
P.[PayableCodeId],
P.[LegalEntityId],
P.[PayeeId],
P.[RemitToId],
P.[Amount],
P.[Currency],
DR.[DisbursementRequestId],
ISNULL(DR.[DisbursementRequestStatus],'_') DisbursementRequestStatus,
V.VoucherNumber,
p.[TaxPortion],
P.CreationSourceId,
P.CreationSourceTable
FROM #PayableInfo P
LEFT JOIN #DisbursementRequestInfo  DR on P.PayableId = DR.PayableId
LEFT JOIN #VoucherDetail V on P.PayableId = V.VoucherPayableId
DROP TABLE #PayableInfo
DROP TABLE #DisbursementRequestInfo
DROP TABLE #VoucherDetail
END

GO
