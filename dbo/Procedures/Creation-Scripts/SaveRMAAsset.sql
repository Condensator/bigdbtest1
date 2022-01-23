SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRMAAsset]
(
 @val [dbo].[RMAAsset] READONLY
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
MERGE [dbo].[RMAAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[EffectiveFromDate]=S.[EffectiveFromDate],[IsActive]=S.[IsActive],[RMAAssetStatus]=S.[RMAAssetStatus],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WarehouseLocationId]=S.[WarehouseLocationId]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[EffectiveFromDate],[IsActive],[RMAAssetStatus],[RMAProfileId],[WarehouseLocationId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[EffectiveFromDate],S.[IsActive],S.[RMAAssetStatus],S.[RMAProfileId],S.[WarehouseLocationId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
