SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateBlendedIncomeSchedulesForReaccrual]
(
@BlendedIncomeSchedules BlendedIncomeScheduleIds READONLY,
@IsInClosedPeriod bit,
@ReversalPostDate DATETIMEOFFSET = NULL,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
Update BlendedIncomeSchedules
Set
IsSchedule = 0,
ReversalPostDate = Case When @IsInClosedPeriod = 1 then ReversalPostDate else @ReversalPostDate end,
IsAccounting = Case When @IsInClosedPeriod = 1 then IsAccounting else 0 end,
PostDate = Case When @IsInClosedPeriod = 1 then PostDate else NULL end,
UpdatedById = @UserId,
UpdatedTime = @Time
where BlendedIncomeSchedules.Id in (select * from @BlendedIncomeSchedules)
End

GO
