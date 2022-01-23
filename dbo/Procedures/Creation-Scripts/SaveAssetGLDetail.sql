SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetGLDetail]
(
 @val [dbo].[AssetGLDetail] READONLY
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
MERGE [dbo].[AssetGLDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetBookValueAdjustmentGLTemplateId]=S.[AssetBookValueAdjustmentGLTemplateId],[BookDepreciationGLTemplateId]=S.[BookDepreciationGLTemplateId],[BranchId]=S.[BranchId],[CostCenterId]=S.[CostCenterId],[HoldingStatus]=S.[HoldingStatus],[InstrumentTypeId]=S.[InstrumentTypeId],[LineofBusinessId]=S.[LineofBusinessId],[OriginalInstrumentTypeId]=S.[OriginalInstrumentTypeId],[OriginalLineofBusinessId]=S.[OriginalLineofBusinessId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetBookValueAdjustmentGLTemplateId],[BookDepreciationGLTemplateId],[BranchId],[CostCenterId],[CreatedById],[CreatedTime],[HoldingStatus],[Id],[InstrumentTypeId],[LineofBusinessId],[OriginalInstrumentTypeId],[OriginalLineofBusinessId])
    VALUES (S.[AssetBookValueAdjustmentGLTemplateId],S.[BookDepreciationGLTemplateId],S.[BranchId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[HoldingStatus],S.[Id],S.[InstrumentTypeId],S.[LineofBusinessId],S.[OriginalInstrumentTypeId],S.[OriginalLineofBusinessId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
