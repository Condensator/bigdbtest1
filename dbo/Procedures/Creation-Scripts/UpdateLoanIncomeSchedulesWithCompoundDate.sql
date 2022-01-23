SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLoanIncomeSchedulesWithCompoundDate]
(
@ContractId bigint,
@LoanFinanceId bigint,
@LastInterimIncomeDate date,
@ReversalStartDate date,
@CommencementDate date,
@UpdatedById bigint,
@UpdatedTime datetimeoffset
)
AS
BEGIN
SET NOCOUNT ON
UPDATE
LoanIncomeSchedules
SET
CompoundDate = @LastInterimIncomeDate,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
WHERE
LoanFinanceId = @LoanFinanceId
AND IncomeDate < @ReversalStartDate
AND CompoundDate >= @CommencementDate
AND IsSchedule = 1
END

GO
