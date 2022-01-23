SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentGroupEmailConfig]
(
 @val [dbo].[DocumentGroupEmailConfig] READONLY
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
MERGE [dbo].[DocumentGroupEmailConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BccEmailConfigId]=S.[BccEmailConfigId],[CcEmailConfigId]=S.[CcEmailConfigId],[EmailTemplateId]=S.[EmailTemplateId],[FromEmailExpression]=S.[FromEmailExpression],[IsActive]=S.[IsActive],[ToEmailConfigId]=S.[ToEmailConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BccEmailConfigId],[CcEmailConfigId],[CreatedById],[CreatedTime],[EmailTemplateId],[FromEmailExpression],[Id],[IsActive],[ToEmailConfigId])
    VALUES (S.[BccEmailConfigId],S.[CcEmailConfigId],S.[CreatedById],S.[CreatedTime],S.[EmailTemplateId],S.[FromEmailExpression],S.[Id],S.[IsActive],S.[ToEmailConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
