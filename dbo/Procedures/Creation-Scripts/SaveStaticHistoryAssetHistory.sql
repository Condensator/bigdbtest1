SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveStaticHistoryAssetHistory]
(
 @val [dbo].[StaticHistoryAssetHistory] READONLY
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
MERGE [dbo].[StaticHistoryAssetHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionDate]=S.[AcquisitionDate],[AsofDate]=S.[AsofDate],[AssetStatus]=S.[AssetStatus],[Contract]=S.[Contract],[CustomerNumber]=S.[CustomerNumber],[ParentAssetAlias]=S.[ParentAssetAlias],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionDate],[AsofDate],[AssetStatus],[Contract],[CreatedById],[CreatedTime],[CustomerNumber],[ParentAssetAlias],[StaticHistoryAssetId])
    VALUES (S.[AcquisitionDate],S.[AsofDate],S.[AssetStatus],S.[Contract],S.[CreatedById],S.[CreatedTime],S.[CustomerNumber],S.[ParentAssetAlias],S.[StaticHistoryAssetId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
