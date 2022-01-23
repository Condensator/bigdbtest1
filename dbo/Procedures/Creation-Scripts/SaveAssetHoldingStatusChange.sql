SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetHoldingStatusChange]
(
 @val [dbo].[AssetHoldingStatusChange] READONLY
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
MERGE [dbo].[AssetHoldingStatusChanges] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[AssetBookValueAdjustmentGLTemplateId]=S.[AssetBookValueAdjustmentGLTemplateId],[BookDepreciationGLTemplateId]=S.[BookDepreciationGLTemplateId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[BusinessUnitId]=S.[BusinessUnitId],[GLTransferEffectiveDate]=S.[GLTransferEffectiveDate],[NewHoldingStatus]=S.[NewHoldingStatus],[PostDate]=S.[PostDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[AssetBookValueAdjustmentGLTemplateId],[BookDepreciationGLTemplateId],[BookDepreciationTemplateId],[BusinessUnitId],[CreatedById],[CreatedTime],[GLTransferEffectiveDate],[NewHoldingStatus],[PostDate],[Status])
    VALUES (S.[Alias],S.[AssetBookValueAdjustmentGLTemplateId],S.[BookDepreciationGLTemplateId],S.[BookDepreciationTemplateId],S.[BusinessUnitId],S.[CreatedById],S.[CreatedTime],S.[GLTransferEffectiveDate],S.[NewHoldingStatus],S.[PostDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
