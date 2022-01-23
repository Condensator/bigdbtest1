SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexUpfrontRentalDetail_Extract]
(
 @val [dbo].[VertexUpfrontRentalDetail_Extract] READONLY
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
MERGE [dbo].[VertexUpfrontRentalDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssetSKUId]=S.[AssetSKUId],[FairMarketValue]=S.[FairMarketValue],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableDetailId]=S.[ReceivableDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetSKUId],[CreatedById],[CreatedTime],[FairMarketValue],[JobStepInstanceId],[ReceivableDetailId])
    VALUES (S.[AssetId],S.[AssetSKUId],S.[CreatedById],S.[CreatedTime],S.[FairMarketValue],S.[JobStepInstanceId],S.[ReceivableDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
