SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReversalReceivableSKUDetail_Extract]
(
 @val [dbo].[ReversalReceivableSKUDetail_Extract] READONLY
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
MERGE [dbo].[ReversalReceivableSKUDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountBilledToDate]=S.[AmountBilledToDate],[AssetSKUId]=S.[AssetSKUId],[Cost]=S.[Cost],[Currency]=S.[Currency],[ExtendedPrice]=S.[ExtendedPrice],[FairMarketValue]=S.[FairMarketValue],[IsExemptAtAssetSKU]=S.[IsExemptAtAssetSKU],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableSKUId]=S.[ReceivableSKUId],[ReceivableTaxDetailId]=S.[ReceivableTaxDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountBilledToDate],[AssetSKUId],[Cost],[CreatedById],[CreatedTime],[Currency],[ExtendedPrice],[FairMarketValue],[IsExemptAtAssetSKU],[JobStepInstanceId],[ReceivableSKUId],[ReceivableTaxDetailId])
    VALUES (S.[AmountBilledToDate],S.[AssetSKUId],S.[Cost],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[ExtendedPrice],S.[FairMarketValue],S.[IsExemptAtAssetSKU],S.[JobStepInstanceId],S.[ReceivableSKUId],S.[ReceivableTaxDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
