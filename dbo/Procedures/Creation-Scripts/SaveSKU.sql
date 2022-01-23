SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSKU]
(
 @val [dbo].[SKU] READONLY
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
MERGE [dbo].[SKUs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCatalogId]=S.[AssetCatalogId],[AssetCategoryId]=S.[AssetCategoryId],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsSalesTaxExempt]=S.[IsSalesTaxExempt],[MakeId]=S.[MakeId],[ManufacturerId]=S.[ManufacturerId],[ModelId]=S.[ModelId],[Name]=S.[Name],[PricingGroupId]=S.[PricingGroupId],[ProductId]=S.[ProductId],[Quantity]=S.[Quantity],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetCatalogId],[AssetCategoryId],[CreatedById],[CreatedTime],[Description],[IsActive],[IsSalesTaxExempt],[MakeId],[ManufacturerId],[ModelId],[Name],[PricingGroupId],[ProductId],[Quantity],[SKUSetId],[TypeId])
    VALUES (S.[AssetCatalogId],S.[AssetCategoryId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[IsSalesTaxExempt],S.[MakeId],S.[ManufacturerId],S.[ModelId],S.[Name],S.[PricingGroupId],S.[ProductId],S.[Quantity],S.[SKUSetId],S.[TypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
