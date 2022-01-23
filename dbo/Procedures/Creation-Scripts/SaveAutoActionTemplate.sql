SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoActionTemplate]
(
 @val [dbo].[AutoActionTemplate] READONLY
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
MERGE [dbo].[AutoActionTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CreateComment]=S.[CreateComment],[CreateNotification]=S.[CreateNotification],[CreateWorkItem]=S.[CreateWorkItem],[Description]=S.[Description],[EntitySelectionSQL]=S.[EntitySelectionSQL],[EntityTypeId]=S.[EntityTypeId],[IsActive]=S.[IsActive],[MasterStoredProc]=S.[MasterStoredProc],[Name]=S.[Name],[NotificationConfigId]=S.[NotificationConfigId],[TransactionConfigId]=S.[TransactionConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpdateStoredProc]=S.[UpdateStoredProc]
WHEN NOT MATCHED THEN
	INSERT ([CreateComment],[CreatedById],[CreatedTime],[CreateNotification],[CreateWorkItem],[Description],[EntitySelectionSQL],[EntityTypeId],[IsActive],[MasterStoredProc],[Name],[NotificationConfigId],[TransactionConfigId],[UpdateStoredProc])
    VALUES (S.[CreateComment],S.[CreatedById],S.[CreatedTime],S.[CreateNotification],S.[CreateWorkItem],S.[Description],S.[EntitySelectionSQL],S.[EntityTypeId],S.[IsActive],S.[MasterStoredProc],S.[Name],S.[NotificationConfigId],S.[TransactionConfigId],S.[UpdateStoredProc])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
