SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SetFloatRateUpdateRunDate]
(
@contractId BIGINT,
@UpdateRunTillDate DATE,
@InactiveBookingStatus VARCHAR(50),
@ApprovedAmendmentStatus VARCHAR(50),
@InactiveAmendmentStatus VARCHAR(50),
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
UPDATE LF
SET LF.FloatRateUpdateRunDate = @UpdateRunTillDate,
UpdatedById = @UserId,
UpdatedTime = @Time
FROM LeaseFinances LF
LEFT JOIN LeaseAmendments LA ON LF.Id = LA.CurrentLeaseFinanceId
WHERE LF.ContractId = @contractId
AND LF.BookingStatus != @InactiveBookingStatus
AND (LF.IsCurrent = 1
OR (LA.Id IS NOT NULL AND (LA.LeaseAmendmentStatus != @ApprovedAmendmentStatus AND LA.LeaseAmendmentStatus != @InactiveAmendmentStatus)));
SET NOCOUNT OFF;
END

GO
