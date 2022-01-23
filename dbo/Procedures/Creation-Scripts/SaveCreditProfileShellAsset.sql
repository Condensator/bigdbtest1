SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfileShellAsset]
(
 @val [dbo].[CreditProfileShellAsset] READONLY
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
MERGE [dbo].[CreditProfileShellAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetCatalogId]=S.[AssetCatalogId],[AssetId]=S.[AssetId],[AssetTypeId]=S.[AssetTypeId],[EquipmentDescription]=S.[EquipmentDescription],[EquipmentLocation]=S.[EquipmentLocation],[InServiceDate]=S.[InServiceDate],[IsActive]=S.[IsActive],[IsRealAsset]=S.[IsRealAsset],[LocationId]=S.[LocationId],[ManufacturerName]=S.[ManufacturerName],[ModalityName]=S.[ModalityName],[Model]=S.[Model],[ModelYear]=S.[ModelYear],[ProposalShellAssetId]=S.[ProposalShellAssetId],[Quantity]=S.[Quantity],[SellingPrice_Amount]=S.[SellingPrice_Amount],[SellingPrice_Currency]=S.[SellingPrice_Currency],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetCatalogId],[AssetId],[AssetTypeId],[CreatedById],[CreatedTime],[CreditProfileId],[EquipmentDescription],[EquipmentLocation],[InServiceDate],[IsActive],[IsRealAsset],[LocationId],[ManufacturerName],[ModalityName],[Model],[ModelYear],[ProposalShellAssetId],[Quantity],[SellingPrice_Amount],[SellingPrice_Currency],[Status],[UsageCondition])
    VALUES (S.[Alias],S.[AssetCatalogId],S.[AssetId],S.[AssetTypeId],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[EquipmentDescription],S.[EquipmentLocation],S.[InServiceDate],S.[IsActive],S.[IsRealAsset],S.[LocationId],S.[ManufacturerName],S.[ModalityName],S.[Model],S.[ModelYear],S.[ProposalShellAssetId],S.[Quantity],S.[SellingPrice_Amount],S.[SellingPrice_Currency],S.[Status],S.[UsageCondition])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
