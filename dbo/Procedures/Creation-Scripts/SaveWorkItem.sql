SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWorkItem]
(
 @val [dbo].[WorkItem] READONLY
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
MERGE [dbo].[WorkItems] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActionName]=S.[ActionName],[Comment]=S.[Comment],[CompletionComment]=S.[CompletionComment],[CreatedDate]=S.[CreatedDate],[DueDate]=S.[DueDate],[Duration]=S.[Duration],[EndDate]=S.[EndDate],[FollowupDate]=S.[FollowupDate],[GUID]=S.[GUID],[IsCanceledByUser]=S.[IsCanceledByUser],[IsOptional]=S.[IsOptional],[LateNotificationCount]=S.[LateNotificationCount],[OwnerUserId]=S.[OwnerUserId],[StartDate]=S.[StartDate],[Status]=S.[Status],[TransactionInstanceId]=S.[TransactionInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WorkItemConfigId]=S.[WorkItemConfigId]
WHEN NOT MATCHED THEN
	INSERT ([ActionName],[Comment],[CompletionComment],[CreatedById],[CreatedDate],[CreatedTime],[DueDate],[Duration],[EndDate],[FollowupDate],[GUID],[IsCanceledByUser],[IsOptional],[LateNotificationCount],[OwnerUserId],[StartDate],[Status],[TransactionInstanceId],[WorkItemConfigId])
    VALUES (S.[ActionName],S.[Comment],S.[CompletionComment],S.[CreatedById],S.[CreatedDate],S.[CreatedTime],S.[DueDate],S.[Duration],S.[EndDate],S.[FollowupDate],S.[GUID],S.[IsCanceledByUser],S.[IsOptional],S.[LateNotificationCount],S.[OwnerUserId],S.[StartDate],S.[Status],S.[TransactionInstanceId],S.[WorkItemConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
