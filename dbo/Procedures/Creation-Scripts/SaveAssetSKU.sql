SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSKU]
(
 @val [dbo].[AssetSKU] READONLY
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
MERGE [dbo].[AssetSKUs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetCatalogId]=S.[AssetCatalogId],[AssetCategoryId]=S.[AssetCategoryId],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsLeaseComponent]=S.[IsLeaseComponent],[IsSalesTaxExempt]=S.[IsSalesTaxExempt],[MakeId]=S.[MakeId],[ManufacturerId]=S.[ManufacturerId],[ModelId]=S.[ModelId],[Name]=S.[Name],[PricingGroupId]=S.[PricingGroupId],[ProductId]=S.[ProductId],[Quantity]=S.[Quantity],[SerialNumber]=S.[SerialNumber],[TypeId]=S.[TypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetCatalogId],[AssetCategoryId],[AssetId],[CreatedById],[CreatedTime],[Description],[IsActive],[IsLeaseComponent],[IsSalesTaxExempt],[MakeId],[ManufacturerId],[ModelId],[Name],[PricingGroupId],[ProductId],[Quantity],[SerialNumber],[TypeId])
    VALUES (S.[Alias],S.[AssetCatalogId],S.[AssetCategoryId],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[IsLeaseComponent],S.[IsSalesTaxExempt],S.[MakeId],S.[ManufacturerId],S.[ModelId],S.[Name],S.[PricingGroupId],S.[ProductId],S.[Quantity],S.[SerialNumber],S.[TypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
