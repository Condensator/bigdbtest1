SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesTaxAssetLocationDetail_Extract]
(
 @val [dbo].[SalesTaxAssetLocationDetail_Extract] READONLY
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
MERGE [dbo].[SalesTaxAssetLocationDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssetlocationId]=S.[AssetlocationId],[CustomerLocationId]=S.[CustomerLocationId],[JobStepInstanceId]=S.[JobStepInstanceId],[LienCredit]=S.[LienCredit],[LocationEffectiveDate]=S.[LocationEffectiveDate],[LocationId]=S.[LocationId],[LocationTaxBasisType]=S.[LocationTaxBasisType],[PreviousLocationId]=S.[PreviousLocationId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReciprocityAmount]=S.[ReciprocityAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontTaxAssessedInLegacySystem]=S.[UpfrontTaxAssessedInLegacySystem]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetlocationId],[CreatedById],[CreatedTime],[CustomerLocationId],[JobStepInstanceId],[LienCredit],[LocationEffectiveDate],[LocationId],[LocationTaxBasisType],[PreviousLocationId],[ReceivableDetailId],[ReceivableDueDate],[ReciprocityAmount],[UpfrontTaxAssessedInLegacySystem])
    VALUES (S.[AssetId],S.[AssetlocationId],S.[CreatedById],S.[CreatedTime],S.[CustomerLocationId],S.[JobStepInstanceId],S.[LienCredit],S.[LocationEffectiveDate],S.[LocationId],S.[LocationTaxBasisType],S.[PreviousLocationId],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReciprocityAmount],S.[UpfrontTaxAssessedInLegacySystem])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
