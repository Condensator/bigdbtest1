SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetTypeTaxDepreciation]
(
 @val [dbo].[AssetTypeTaxDepreciation] READONLY
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
MERGE [dbo].[AssetTypeTaxDepreciations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CountryId]=S.[CountryId],[DomesticTaxDepTemplateId]=S.[DomesticTaxDepTemplateId],[EffectiveDate]=S.[EffectiveDate],[InternationalTaxDepTemplateId]=S.[InternationalTaxDepTemplateId],[IsActive]=S.[IsActive],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[CountryId],[CreatedById],[CreatedTime],[DomesticTaxDepTemplateId],[EffectiveDate],[InternationalTaxDepTemplateId],[IsActive],[UniqueIdentifier])
    VALUES (S.[AssetTypeId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[DomesticTaxDepTemplateId],S.[EffectiveDate],S.[InternationalTaxDepTemplateId],S.[IsActive],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
