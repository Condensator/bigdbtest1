SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEntityHeader]
(
 @val [dbo].[EntityHeader] READONLY
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
MERGE [dbo].[EntityHeaders] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccessScope]=S.[AccessScope],[AccessScopeId]=S.[AccessScopeId],[EntityId]=S.[EntityId],[EntityNaturalId]=S.[EntityNaturalId],[EntitySummary]=S.[EntitySummary],[EntityTypeId]=S.[EntityTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccessScope],[AccessScopeId],[CreatedById],[CreatedTime],[EntityId],[EntityNaturalId],[EntitySummary],[EntityTypeId])
    VALUES (S.[AccessScope],S.[AccessScopeId],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityNaturalId],S.[EntitySummary],S.[EntityTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
