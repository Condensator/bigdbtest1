SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJobSchedule]
(
 @val [dbo].[JobSchedule] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[JobSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DayOfMonth]=S.[DayOfMonth],[DayOfWeek]=S.[DayOfWeek],[DayOfWeekType]=S.[DayOfWeekType],[Frequency]=S.[Frequency],[FrequencyType]=S.[FrequencyType],[FromTime]=S.[FromTime],[IsFriday]=S.[IsFriday],[IsMonday]=S.[IsMonday],[IsSaturday]=S.[IsSaturday],[IsSunday]=S.[IsSunday],[IsThursday]=S.[IsThursday],[IsTuesday]=S.[IsTuesday],[IsWednesday]=S.[IsWednesday],[MonthlyType]=S.[MonthlyType],[RepeatDaily]=S.[RepeatDaily],[RepeatHours]=S.[RepeatHours],[RepeatMinutes]=S.[RepeatMinutes],[RepeatMonthly]=S.[RepeatMonthly],[RunBetweenOption]=S.[RunBetweenOption],[Time]=S.[Time],[ToTime]=S.[ToTime],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DayOfMonth],[DayOfWeek],[DayOfWeekType],[Frequency],[FrequencyType],[FromTime],[Id],[IsFriday],[IsMonday],[IsSaturday],[IsSunday],[IsThursday],[IsTuesday],[IsWednesday],[MonthlyType],[RepeatDaily],[RepeatHours],[RepeatMinutes],[RepeatMonthly],[RunBetweenOption],[Time],[ToTime])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DayOfMonth],S.[DayOfWeek],S.[DayOfWeekType],S.[Frequency],S.[FrequencyType],S.[FromTime],S.[Id],S.[IsFriday],S.[IsMonday],S.[IsSaturday],S.[IsSunday],S.[IsThursday],S.[IsTuesday],S.[IsWednesday],S.[MonthlyType],S.[RepeatDaily],S.[RepeatHours],S.[RepeatMinutes],S.[RepeatMonthly],S.[RunBetweenOption],S.[Time],S.[ToTime])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
