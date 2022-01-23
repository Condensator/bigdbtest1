SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJobStep]
(
 @val [dbo].[JobStep] READONLY
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
MERGE [dbo].[JobSteps] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AbortOnFailure]=S.[AbortOnFailure],[EmailAttachment]=S.[EmailAttachment],[ExecutionOrder]=S.[ExecutionOrder],[IsActive]=S.[IsActive],[LatestInstanceStatus]=S.[LatestInstanceStatus],[OnHold]=S.[OnHold],[ReRun]=S.[ReRun],[RunOnHoliday]=S.[RunOnHoliday],[TaskId]=S.[TaskId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AbortOnFailure],[CreatedById],[CreatedTime],[EmailAttachment],[ExecutionOrder],[IsActive],[JobId],[LatestInstanceStatus],[OnHold],[ReRun],[RunOnHoliday],[TaskId],[TaskParam])
    VALUES (S.[AbortOnFailure],S.[CreatedById],S.[CreatedTime],S.[EmailAttachment],S.[ExecutionOrder],S.[IsActive],S.[JobId],S.[LatestInstanceStatus],S.[OnHold],S.[ReRun],S.[RunOnHoliday],S.[TaskId],S.[TaskParam])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
