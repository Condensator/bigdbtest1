SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWorkItemSubSystemConfig]
(
 @val [dbo].[WorkItemSubSystemConfig] READONLY
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
MERGE [dbo].[WorkItemSubSystemConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Form]=S.[Form],[IsActive]=S.[IsActive],[SubSystemId]=S.[SubSystemId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Viewable]=S.[Viewable]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Form],[IsActive],[SubSystemId],[Viewable],[WorkItemConfigId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Form],S.[IsActive],S.[SubSystemId],S.[Viewable],S.[WorkItemConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
