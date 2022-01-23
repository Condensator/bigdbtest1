SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReverseLeaseFloatRateUpdateEntities]
(
@paymentSchedulesToModify ReverseLeaseFloatRateUpdateEntitiesParam ReadOnly,
@achSchedulesToModify ReverseLeaseFloatRateUpdateEntitiesParam ReadOnly,
@contractId BIGINT,
@ApprovedAmendmentStatus NVARCHAR(MAX),
@InactiveAmendmentStatus NVARCHAR(MAX),
@InactiveBookingStatus NVARCHAR(MAX),
@userId BIGINT,
@time DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
SELECT Id INTO #paymentSchedules FROM @paymentSchedulesToModify;
SELECT Id INTO #achSchedules FROM @achSchedulesToModify;
CREATE INDEX IX_Id ON #paymentSchedules(Id)
CREATE INDEX IX_Id ON #achSchedules(Id)
UPDATE LeasePaymentSchedules
SET ReceivableAdjustmentAmount_Amount = 0.0,
UpdatedById = @userId,
UpdatedTime = @time
FROM #paymentSchedules ps
WHERE LeasePaymentSchedules.Id = ps.Id
AND ReceivableAdjustmentAmount_Amount ! = 0.0
;
UPDATE OtherQuotesPaymentSchedules
SET ReceivableAdjustmentAmount_Amount = 0.0,
UpdatedById = @UserId,
UpdatedTime = @time
FROM LeasePaymentSchedules LPS
JOIN #paymentSchedules param ON LPS.Id = param.ID
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
UPDATE ACHSchedules
SET IsActive = 0,
UpdatedById = @userId,
UpdatedTime = @time
FROM ACHSchedules ASch
JOIN #achSchedules Sch ON ASch.Id = Sch.Id
;
SET NOCOUNT OFF;
END

GO
