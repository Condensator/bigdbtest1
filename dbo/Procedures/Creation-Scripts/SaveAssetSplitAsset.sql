SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSplitAsset]
(
 @val [dbo].[AssetSplitAsset] READONLY
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
MERGE [dbo].[AssetSplitAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [OriginalAssetCost_Amount]=S.[OriginalAssetCost_Amount],[OriginalAssetCost_Currency]=S.[OriginalAssetCost_Currency],[OriginalAssetId]=S.[OriginalAssetId],[OriginalQuantity]=S.[OriginalQuantity],[SplitByType]=S.[SplitByType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[OriginalAssetCost_Amount],[OriginalAssetCost_Currency],[OriginalAssetId],[OriginalQuantity],[SplitByType])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[OriginalAssetCost_Amount],S.[OriginalAssetCost_Currency],S.[OriginalAssetId],S.[OriginalQuantity],S.[SplitByType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
