SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveJobStepInstance]
(
 @val [dbo].[JobStepInstance] READONLY
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
MERGE [dbo].[JobStepInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Attachment_Content]=S.[Attachment_Content],[Attachment_Source]=S.[Attachment_Source],[Attachment_Type]=S.[Attachment_Type],[EndDate]=S.[EndDate],[JobServiceId]=S.[JobServiceId],[JobStepId]=S.[JobStepId],[StartDate]=S.[StartDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Attachment_Content],[Attachment_Source],[Attachment_Type],[CreatedById],[CreatedTime],[EndDate],[JobInstanceId],[JobServiceId],[JobStepId],[StartDate],[Status])
    VALUES (S.[Attachment_Content],S.[Attachment_Source],S.[Attachment_Type],S.[CreatedById],S.[CreatedTime],S.[EndDate],S.[JobInstanceId],S.[JobServiceId],S.[JobStepId],S.[StartDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
