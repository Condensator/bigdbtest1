SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCPUPayoffQuotesPostActivation]
(
@PendingPayoffQuoteToUpdate PendingPayoffQuoteToUpdate READONLY,
@CPUContractId BIGINT,
@CPUFinanceId BIGINT,
@CPUPayoffPendingStatusValue NVARCHAR(9),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE [dbo].[CPUPayoffs]
SET
OldCPUFinanceId = @CPUFinanceId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM
[dbo].[CPUPayoffs]
WHERE
CPUPayoffs.CPUContractId = @CPUContractId
AND CPUPayoffs.Status = @CPUPayoffPendingStatusValue
IF EXISTS (SELECT 1 FROM @PendingPayoffQuoteToUpdate)
BEGIN
UPDATE [dbo].[CPUPayoffSchedules]
SET
RefreshRequired = PPQ.IsRefreshRequired,
IsPaymentScheduleGenerationRequired = PPQ.IsPaymentGenerationRequired,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM
[dbo].[CPUPayoffSchedules]
JOIN @PendingPayoffQuoteToUpdate PPQ ON CPUPayoffSchedules.CPUPayoffId = PPQ.PayoffQuoteId AND CPUPayoffSchedules.ScheduleNumber = PPQ.ScheduleNumber
WHERE
CPUPayoffSchedules.IsActive = 1
END
SET NOCOUNT OFF;
END

GO
