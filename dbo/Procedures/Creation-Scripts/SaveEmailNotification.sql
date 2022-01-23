SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEmailNotification]
(
 @val [dbo].[EmailNotification] READONLY
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
MERGE [dbo].[EmailNotifications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Body]=S.[Body],[BodyTemplate_Content]=S.[BodyTemplate_Content],[BodyTemplate_Source]=S.[BodyTemplate_Source],[BodyTemplate_Type]=S.[BodyTemplate_Type],[FromEmailId]=S.[FromEmailId],[Subject]=S.[Subject],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Body],[BodyTemplate_Content],[BodyTemplate_Source],[BodyTemplate_Type],[CreatedById],[CreatedTime],[FromEmailId],[Id],[Subject])
    VALUES (S.[Body],S.[BodyTemplate_Content],S.[BodyTemplate_Source],S.[BodyTemplate_Type],S.[CreatedById],S.[CreatedTime],S.[FromEmailId],S.[Id],S.[Subject])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
