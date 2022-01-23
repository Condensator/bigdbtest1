SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptUpfrontTaxDetails_Extract]
(
 @val [dbo].[ReceiptUpfrontTaxDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptUpfrontTaxDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ContractId]=S.[ContractId],[EffectiveTillDate]=S.[EffectiveTillDate],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseAssetSalesTaxResposibillity]=S.[LeaseAssetSalesTaxResposibillity],[LeaseAssetVendorRemitToId]=S.[LeaseAssetVendorRemitToId],[PayableCodeId]=S.[PayableCodeId],[ReceiptId]=S.[ReceiptId],[SalesTaxResposibillityFromHistories]=S.[SalesTaxResposibillityFromHistories],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId],[VendorRemitToIdFromHistories]=S.[VendorRemitToIdFromHistories]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[ContractId],[CreatedById],[CreatedTime],[EffectiveTillDate],[JobStepInstanceId],[LeaseAssetSalesTaxResposibillity],[LeaseAssetVendorRemitToId],[PayableCodeId],[ReceiptId],[SalesTaxResposibillityFromHistories],[VendorId],[VendorRemitToIdFromHistories])
    VALUES (S.[AssetId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[EffectiveTillDate],S.[JobStepInstanceId],S.[LeaseAssetSalesTaxResposibillity],S.[LeaseAssetVendorRemitToId],S.[PayableCodeId],S.[ReceiptId],S.[SalesTaxResposibillityFromHistories],S.[VendorId],S.[VendorRemitToIdFromHistories])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
