SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDocumentRelatedEmailContact]
(
 @val [dbo].[DocumentRelatedEmailContact] READONLY
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
MERGE [dbo].[DocumentRelatedEmailContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContactName]=S.[ContactName],[ContactType]=S.[ContactType],[Email]=S.[Email],[EntityName]=S.[EntityName],[EntityNaturalId]=S.[EntityNaturalId],[RelationshipType]=S.[RelationshipType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContactName],[ContactType],[CreatedById],[CreatedTime],[DocumentEmailId],[Email],[EntityName],[EntityNaturalId],[RelationshipType])
    VALUES (S.[ContactName],S.[ContactType],S.[CreatedById],S.[CreatedTime],S.[DocumentEmailId],S.[Email],S.[EntityName],S.[EntityNaturalId],S.[RelationshipType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
