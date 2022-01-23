SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveConvertFeatureToAssetDetail]
(
 @val [dbo].[ConvertFeatureToAssetDetail] READONLY
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
MERGE [dbo].[ConvertFeatureToAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetFeatureId]=S.[AssetFeatureId],[IsActive]=S.[IsActive],[NewAssetCost_Amount]=S.[NewAssetCost_Amount],[NewAssetCost_Currency]=S.[NewAssetCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetFeatureId],[AssetSplitId],[CreatedById],[CreatedTime],[IsActive],[NewAssetCost_Amount],[NewAssetCost_Currency])
    VALUES (S.[Alias],S.[AssetFeatureId],S.[AssetSplitId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[NewAssetCost_Amount],S.[NewAssetCost_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
