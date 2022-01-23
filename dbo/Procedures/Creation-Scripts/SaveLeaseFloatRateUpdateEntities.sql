SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SaveLeaseFloatRateUpdateEntities]
(
@contractId BIGINT,
@leasePaymentScheduleParam LeasePaymentScheduleUpdateParam READONLY,
@IsInactivationRequired BIT,
@InactiveBookingStatus VARCHAR(50),
@ApprovedAmendmentStatus VARCHAR(50),
@InactiveAmendmentStatus VARCHAR(50),
@FloatRateIndexDetailIds NVARCHAR(MAX),
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
UPDATE ContractFloatRates
SET IsProcessed = 1,
UpdatedById = @UserId,
UpdatedTime = @Time
WHERE ContractId = @contractId
AND IsActive = 1
AND IsProcessed = 0;
SELECT Id INTO #FloatRateIndexDetailIds FROM ConvertCSVToBigIntTable(@FloatRateIndexDetailIds, ',');
UPDATE FloatRateIndexDetails
SET IsRateUsed = 1,
UpdatedById = @UserId,
UpdatedTime = @Time
FROM FloatRateIndexDetails FRID
JOIN #FloatRateIndexDetailIds param ON FRID.Id = param.ID
WHERE FRID.IsRateUsed = 0;
UPDATE LeasePaymentSchedules
SET ReceivableAdjustmentAmount_Amount = param.Amount_Amount,
ReceivableAdjustmentAmount_Currency = param.Amount_Currency,
UpdatedById = @UserId,
UpdatedTime = @Time
FROM LeasePaymentSchedules LPS
JOIN @leasePaymentScheduleParam param ON LPS.Id = param.PaymentScheduleId
;
UPDATE OtherQuotesPaymentSchedules
SET ReceivableAdjustmentAmount_Amount = param.Amount_Amount,
ReceivableAdjustmentAmount_Currency = param.Amount_Currency,
UpdatedById = @UserId,
UpdatedTime = @Time
FROM LeasePaymentSchedules LPS
JOIN @leasePaymentScheduleParam param ON LPS.Id = param.PaymentScheduleId
JOIN LeasePaymentSchedules OtherQuotesPaymentSchedules ON LPS.PaymentNumber = OtherQuotesPaymentSchedules.PaymentNumber AND LPS.PaymentType = OtherQuotesPaymentSchedules.PaymentType AND OtherQuotesPaymentSchedules.IsActive = 1
JOIN LeaseFinanceDetails LFD ON OtherQuotesPaymentSchedules.LeaseFinanceDetailId = LFD.Id
JOIN LeaseFinances LF ON LFD.Id = LF.Id
JOIN LeaseAmendments LA ON LF.Id = LA.CurrentLeaseFinanceId
WHERE LF.ContractId = @contractId
AND LF.BookingStatus != @InactiveBookingStatus
AND LA.LeaseAmendmentStatus != @ApprovedAmendmentStatus
AND LA.LeaseAmendmentStatus != @InactiveAmendmentStatus
AND OtherQuotesPaymentSchedules.StartDate < LA.AmendmentDate
;
DROP TABLE #FloatRateIndexDetailIds;
SET NOCOUNT OFF;
END

GO
