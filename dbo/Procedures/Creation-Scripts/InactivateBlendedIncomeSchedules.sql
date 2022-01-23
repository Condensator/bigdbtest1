SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateBlendedIncomeSchedules]
(
@BlendedIncomeSchedules BlendedIncomeScheduleIdCollection READONLY,
@IsAccounting bit,
@PostDate DATETIMEOFFSET,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
Update BlendedIncomeSchedules
Set
IsSchedule = 0,
IsAccounting = @IsAccounting,
PostDate = Case When @IsAccounting = 1 then @PostDate else PostDate end,
UpdatedById = @UserId,
UpdatedTime = @Time
where BlendedIncomeSchedules.Id in (select * from @BlendedIncomeSchedules)
End

GO
