SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesTaxReceivableSKUDetail_Extract]
(
 @val [dbo].[SalesTaxReceivableSKUDetail_Extract] READONLY
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
MERGE [dbo].[SalesTaxReceivableSKUDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountBilledToDate]=S.[AmountBilledToDate],[AssetId]=S.[AssetId],[AssetSKUId]=S.[AssetSKUId],[ContractId]=S.[ContractId],[ExtendedPrice]=S.[ExtendedPrice],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetSKUId]=S.[LeaseAssetSKUId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableSKUId]=S.[ReceivableSKUId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountBilledToDate],[AssetId],[AssetSKUId],[ContractId],[CreatedById],[CreatedTime],[ExtendedPrice],[JobStepInstanceId],[LeaseAssetSKUId],[ReceivableDetailId],[ReceivableSKUId])
    VALUES (S.[AmountBilledToDate],S.[AssetId],S.[AssetSKUId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[ExtendedPrice],S.[JobStepInstanceId],S.[LeaseAssetSKUId],S.[ReceivableDetailId],S.[ReceivableSKUId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
