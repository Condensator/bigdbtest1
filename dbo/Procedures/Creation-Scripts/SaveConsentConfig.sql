SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveConsentConfig]
(
 @val [dbo].[ConsentConfig] READONLY
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
MERGE [dbo].[ConsentConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ConsentId]=S.[ConsentId],[CountryId]=S.[CountryId],[DocumentTypeId]=S.[DocumentTypeId],[EntityType]=S.[EntityType],[IsActive]=S.[IsActive],[IsMandatory]=S.[IsMandatory],[LegalDescription]=S.[LegalDescription],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ConsentId],[CountryId],[CreatedById],[CreatedTime],[DocumentTypeId],[EntityType],[IsActive],[IsMandatory],[LegalDescription])
    VALUES (S.[ConsentId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[DocumentTypeId],S.[EntityType],S.[IsActive],S.[IsMandatory],S.[LegalDescription])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
