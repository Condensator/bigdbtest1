SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEuroStandardCoEfficient]
(
 @val [dbo].[EuroStandardCoEfficient] READONLY
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
MERGE [dbo].[EuroStandardCoEfficients] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetClassCodeId]=S.[AssetClassCodeId],[CoEfficient]=S.[CoEfficient],[IsActive]=S.[IsActive],[LegalEntityId]=S.[LegalEntityId],[PermissibleMassFrom]=S.[PermissibleMassFrom],[PermissibleMassTill]=S.[PermissibleMassTill],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetClassCodeId],[CoEfficient],[CreatedById],[CreatedTime],[IsActive],[LegalEntityId],[PermissibleMassFrom],[PermissibleMassTill])
    VALUES (S.[AssetClassCodeId],S.[CoEfficient],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[LegalEntityId],S.[PermissibleMassFrom],S.[PermissibleMassTill])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
