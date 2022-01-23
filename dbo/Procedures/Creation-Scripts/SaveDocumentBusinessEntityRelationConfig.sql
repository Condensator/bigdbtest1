SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentBusinessEntityRelationConfig]
(
 @val [dbo].[DocumentBusinessEntityRelationConfig] READONLY
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
MERGE [dbo].[DocumentBusinessEntityRelationConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [GridName]=S.[GridName],[IsActive]=S.[IsActive],[NavigationPath]=S.[NavigationPath],[QuerySource]=S.[QuerySource],[RelatedEntityId]=S.[RelatedEntityId],[RelationshipType]=S.[RelationshipType],[RootEntityId]=S.[RootEntityId],[TextProperty]=S.[TextProperty],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[GridName],[IsActive],[NavigationPath],[QuerySource],[RelatedEntityId],[RelationshipType],[RootEntityId],[TextProperty])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[GridName],S.[IsActive],S.[NavigationPath],S.[QuerySource],S.[RelatedEntityId],S.[RelationshipType],S.[RootEntityId],S.[TextProperty])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO