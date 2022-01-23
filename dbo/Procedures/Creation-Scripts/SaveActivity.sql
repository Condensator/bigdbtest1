SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivity]
(
 @val [dbo].[Activity] READONLY
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
MERGE [dbo].[Activities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivityTypeId]=S.[ActivityTypeId],[CloseFollowUp]=S.[CloseFollowUp],[ClosingComments]=S.[ClosingComments],[CompletionDate]=S.[CompletionDate],[CreatedDate]=S.[CreatedDate],[DefaultPermission]=S.[DefaultPermission],[Description]=S.[Description],[DocumentListId]=S.[DocumentListId],[EntityId]=S.[EntityId],[EntityNaturalId]=S.[EntityNaturalId],[FollowUpDate]=S.[FollowUpDate],[InitiatedTransactionEntityId]=S.[InitiatedTransactionEntityId],[IsActive]=S.[IsActive],[IsFollowUpRequired]=S.[IsFollowUpRequired],[Name]=S.[Name],[OwnerGroupId]=S.[OwnerGroupId],[OwnerId]=S.[OwnerId],[PortfolioId]=S.[PortfolioId],[Solution]=S.[Solution],[StatusId]=S.[StatusId],[TargetCompletionDate]=S.[TargetCompletionDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivityTypeId],[CloseFollowUp],[ClosingComments],[CompletionDate],[CreatedById],[CreatedDate],[CreatedTime],[DefaultPermission],[Description],[DocumentListId],[EntityId],[EntityNaturalId],[FollowUpDate],[InitiatedTransactionEntityId],[IsActive],[IsFollowUpRequired],[Name],[OwnerGroupId],[OwnerId],[PortfolioId],[Solution],[StatusId],[TargetCompletionDate])
    VALUES (S.[ActivityTypeId],S.[CloseFollowUp],S.[ClosingComments],S.[CompletionDate],S.[CreatedById],S.[CreatedDate],S.[CreatedTime],S.[DefaultPermission],S.[Description],S.[DocumentListId],S.[EntityId],S.[EntityNaturalId],S.[FollowUpDate],S.[InitiatedTransactionEntityId],S.[IsActive],S.[IsFollowUpRequired],S.[Name],S.[OwnerGroupId],S.[OwnerId],S.[PortfolioId],S.[Solution],S.[StatusId],S.[TargetCompletionDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
