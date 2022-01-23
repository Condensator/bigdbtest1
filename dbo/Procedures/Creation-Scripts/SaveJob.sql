SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJob]
(
 @val [dbo].[Job] READONLY
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
MERGE [dbo].[Jobs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApprovalStatus]=S.[ApprovalStatus],[BusinessUnitId]=S.[BusinessUnitId],[CronExpression]=S.[CronExpression],[CustomerId]=S.[CustomerId],[CutoffTime]=S.[CutoffTime],[Description]=S.[Description],[EffectiveDate]=S.[EffectiveDate],[ExpiryDate]=S.[ExpiryDate],[IsActive]=S.[IsActive],[IsCritical]=S.[IsCritical],[IsNotify]=S.[IsNotify],[IsServiceCall]=S.[IsServiceCall],[IsSystemJob]=S.[IsSystemJob],[JobServiceId]=S.[JobServiceId],[Name]=S.[Name],[OccurenceType]=S.[OccurenceType],[Privacy]=S.[Privacy],[RunDateOptions]=S.[RunDateOptions],[RunOnHolidayOption]=S.[RunOnHolidayOption],[ScheduleDate]=S.[ScheduleDate],[ScheduledStatus]=S.[ScheduledStatus],[ScheduleType]=S.[ScheduleType],[SourceSiteId]=S.[SourceSiteId],[SubmittedCulture]=S.[SubmittedCulture],[SubmittedUserId]=S.[SubmittedUserId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApprovalStatus],[BusinessUnitId],[CreatedById],[CreatedTime],[CronExpression],[CustomerId],[CutoffTime],[Description],[EffectiveDate],[ExpiryDate],[IsActive],[IsCritical],[IsNotify],[IsServiceCall],[IsSystemJob],[JobServiceId],[Name],[OccurenceType],[Privacy],[RunDateOptions],[RunOnHolidayOption],[ScheduleDate],[ScheduledStatus],[ScheduleType],[SourceSiteId],[SubmittedCulture],[SubmittedUserId])
    VALUES (S.[ApprovalStatus],S.[BusinessUnitId],S.[CreatedById],S.[CreatedTime],S.[CronExpression],S.[CustomerId],S.[CutoffTime],S.[Description],S.[EffectiveDate],S.[ExpiryDate],S.[IsActive],S.[IsCritical],S.[IsNotify],S.[IsServiceCall],S.[IsSystemJob],S.[JobServiceId],S.[Name],S.[OccurenceType],S.[Privacy],S.[RunDateOptions],S.[RunOnHolidayOption],S.[ScheduleDate],S.[ScheduledStatus],S.[ScheduleType],S.[SourceSiteId],S.[SubmittedCulture],S.[SubmittedUserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
