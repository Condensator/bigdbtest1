SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetCatalog]
(
 @val [dbo].[AssetCatalog] READONLY
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
MERGE [dbo].[AssetCatalogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCategoryId]=S.[AssetCategoryId],[AssetClassADRId]=S.[AssetClassADRId],[AssetTypeId]=S.[AssetTypeId],[Class2Id]=S.[Class2Id],[Class3]=S.[Class3],[CollateralCode]=S.[CollateralCode],[Comment]=S.[Comment],[FMV_Amount]=S.[FMV_Amount],[FMV_Currency]=S.[FMV_Currency],[IsActive]=S.[IsActive],[IsCollateralTrackingRequired]=S.[IsCollateralTrackingRequired],[IsInsuranceRequired]=S.[IsInsuranceRequired],[IsUpgradeEligible]=S.[IsUpgradeEligible],[MakeId]=S.[MakeId],[ManufacturerId]=S.[ManufacturerId],[ModelId]=S.[ModelId],[PortfolioId]=S.[PortfolioId],[ProductId]=S.[ProductId],[ProductSubTypeId]=S.[ProductSubTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Usefullife]=S.[Usefullife]
WHEN NOT MATCHED THEN
	INSERT ([AssetCategoryId],[AssetClassADRId],[AssetTypeId],[Class2Id],[Class3],[CollateralCode],[Comment],[CreatedById],[CreatedTime],[FMV_Amount],[FMV_Currency],[IsActive],[IsCollateralTrackingRequired],[IsInsuranceRequired],[IsUpgradeEligible],[MakeId],[ManufacturerId],[ModelId],[PortfolioId],[ProductId],[ProductSubTypeId],[Usefullife])
    VALUES (S.[AssetCategoryId],S.[AssetClassADRId],S.[AssetTypeId],S.[Class2Id],S.[Class3],S.[CollateralCode],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[FMV_Amount],S.[FMV_Currency],S.[IsActive],S.[IsCollateralTrackingRequired],S.[IsInsuranceRequired],S.[IsUpgradeEligible],S.[MakeId],S.[ManufacturerId],S.[ModelId],S.[PortfolioId],S.[ProductId],S.[ProductSubTypeId],S.[Usefullife])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
