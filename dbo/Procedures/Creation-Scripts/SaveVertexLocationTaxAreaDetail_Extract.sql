SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexLocationTaxAreaDetail_Extract]
(
 @val [dbo].[VertexLocationTaxAreaDetail_Extract] READONLY
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
MERGE [dbo].[VertexLocationTaxAreaDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[JobStepInstanceId]=S.[JobStepInstanceId],[LocationId]=S.[LocationId],[ReceivableDueDate]=S.[ReceivableDueDate],[TaxAreaEffectiveDate]=S.[TaxAreaEffectiveDate],[TaxAreaId]=S.[TaxAreaId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[JobStepInstanceId],[LocationId],[ReceivableDueDate],[TaxAreaEffectiveDate],[TaxAreaId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[JobStepInstanceId],S.[LocationId],S.[ReceivableDueDate],S.[TaxAreaEffectiveDate],S.[TaxAreaId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
