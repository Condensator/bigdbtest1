SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJobInstance]
(
 @val [dbo].[JobInstance] READONLY
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
MERGE [dbo].[JobInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessDate]=S.[BusinessDate],[EndDate]=S.[EndDate],[InvocationReason]=S.[InvocationReason],[JobId]=S.[JobId],[JobServiceId]=S.[JobServiceId],[SourceJobInstanceId]=S.[SourceJobInstanceId],[StartDate]=S.[StartDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusinessDate],[CreatedById],[CreatedTime],[EndDate],[InvocationReason],[JobId],[JobServiceId],[SourceJobInstanceId],[StartDate],[Status])
    VALUES (S.[BusinessDate],S.[CreatedById],S.[CreatedTime],S.[EndDate],S.[InvocationReason],S.[JobId],S.[JobServiceId],S.[SourceJobInstanceId],S.[StartDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
