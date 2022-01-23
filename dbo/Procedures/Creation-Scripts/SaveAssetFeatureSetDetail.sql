SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetFeatureSetDetail]
(
 @val [dbo].[AssetFeatureSetDetail] READONLY
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
MERGE [dbo].[AssetFeatureSetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCatalogId]=S.[AssetCatalogId],[AssetCategoryId]=S.[AssetCategoryId],[CurrencyId]=S.[CurrencyId],[Description]=S.[Description],[IsActive]=S.[IsActive],[MakeId]=S.[MakeId],[ManufacturerId]=S.[ManufacturerId],[ModelId]=S.[ModelId],[Name]=S.[Name],[ProductId]=S.[ProductId],[Quantity]=S.[Quantity],[StateId]=S.[StateId],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Value_Amount]=S.[Value_Amount],[Value_Currency]=S.[Value_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetCatalogId],[AssetCategoryId],[AssetFeatureSetId],[CreatedById],[CreatedTime],[CurrencyId],[Description],[IsActive],[MakeId],[ManufacturerId],[ModelId],[Name],[ProductId],[Quantity],[StateId],[TypeId],[Value_Amount],[Value_Currency])
    VALUES (S.[AssetCatalogId],S.[AssetCategoryId],S.[AssetFeatureSetId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[Description],S.[IsActive],S.[MakeId],S.[ManufacturerId],S.[ModelId],S.[Name],S.[ProductId],S.[Quantity],S.[StateId],S.[TypeId],S.[Value_Amount],S.[Value_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
