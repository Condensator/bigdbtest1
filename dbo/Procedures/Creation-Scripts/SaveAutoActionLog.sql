SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoActionLog]
(
 @val [dbo].[AutoActionLog] READONLY
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
MERGE [dbo].[AutoActionLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AutoActionTemplateId]=S.[AutoActionTemplateId],[EntitySelectionSQL]=S.[EntitySelectionSQL],[JobStepInstanceId]=S.[JobStepInstanceId],[MasterSQL]=S.[MasterSQL],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpdateSQL]=S.[UpdateSQL]
WHEN NOT MATCHED THEN
	INSERT ([AutoActionTemplateId],[CreatedById],[CreatedTime],[EntitySelectionSQL],[JobStepInstanceId],[MasterSQL],[UpdateSQL])
    VALUES (S.[AutoActionTemplateId],S.[CreatedById],S.[CreatedTime],S.[EntitySelectionSQL],S.[JobStepInstanceId],S.[MasterSQL],S.[UpdateSQL])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
