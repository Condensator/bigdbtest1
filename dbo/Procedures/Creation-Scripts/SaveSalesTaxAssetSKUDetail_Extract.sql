SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesTaxAssetSKUDetail_Extract]
(
 @val [dbo].[SalesTaxAssetSKUDetail_Extract] READONLY
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
MERGE [dbo].[SalesTaxAssetSKUDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssetSKUId]=S.[AssetSKUId],[ContractId]=S.[ContractId],[IsExemptAtAssetSKU]=S.[IsExemptAtAssetSKU],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetId]=S.[LeaseAssetId],[LeaseAssetSKUId]=S.[LeaseAssetSKUId],[LeaseFinanceId]=S.[LeaseFinanceId],[NBVAmount]=S.[NBVAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetSKUId],[ContractId],[CreatedById],[CreatedTime],[IsExemptAtAssetSKU],[JobStepInstanceId],[LeaseAssetId],[LeaseAssetSKUId],[LeaseFinanceId],[NBVAmount])
    VALUES (S.[AssetId],S.[AssetSKUId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsExemptAtAssetSKU],S.[JobStepInstanceId],S.[LeaseAssetId],S.[LeaseAssetSKUId],S.[LeaseFinanceId],S.[NBVAmount])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
