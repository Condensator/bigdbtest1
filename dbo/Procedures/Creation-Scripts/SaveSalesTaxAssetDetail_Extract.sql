SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesTaxAssetDetail_Extract]
(
 @val [dbo].[SalesTaxAssetDetail_Extract] READONLY
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
MERGE [dbo].[SalesTaxAssetDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionLocationId]=S.[AcquisitionLocationId],[AssetId]=S.[AssetId],[CapitalizedOriginalAssetId]=S.[CapitalizedOriginalAssetId],[ContractId]=S.[ContractId],[IsAssetFromOldFinance]=S.[IsAssetFromOldFinance],[IsCapitalizedSalesTaxAsset]=S.[IsCapitalizedSalesTaxAsset],[IsExemptAtAsset]=S.[IsExemptAtAsset],[IsPrepaidUpfrontTax]=S.[IsPrepaidUpfrontTax],[IsSKU]=S.[IsSKU],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetId]=S.[LeaseAssetId],[LeaseFinanceId]=S.[LeaseFinanceId],[NBVAmount]=S.[NBVAmount],[OriginalTaxBasisType]=S.[OriginalTaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionLocationId],[AssetId],[CapitalizedOriginalAssetId],[ContractId],[CreatedById],[CreatedTime],[IsAssetFromOldFinance],[IsCapitalizedSalesTaxAsset],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsSKU],[JobStepInstanceId],[LeaseAssetId],[LeaseFinanceId],[NBVAmount],[OriginalTaxBasisType])
    VALUES (S.[AcquisitionLocationId],S.[AssetId],S.[CapitalizedOriginalAssetId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsAssetFromOldFinance],S.[IsCapitalizedSalesTaxAsset],S.[IsExemptAtAsset],S.[IsPrepaidUpfrontTax],S.[IsSKU],S.[JobStepInstanceId],S.[LeaseAssetId],S.[LeaseFinanceId],S.[NBVAmount],S.[OriginalTaxBasisType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
