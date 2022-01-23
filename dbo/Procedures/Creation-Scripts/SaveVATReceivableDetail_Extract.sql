SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVATReceivableDetail_Extract]
(
 @val [dbo].[VATReceivableDetail_Extract] READONLY
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
MERGE [dbo].[VATReceivableDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BatchStatus]=S.[BatchStatus],[BuyerLocation]=S.[BuyerLocation],[BuyerLocationId]=S.[BuyerLocationId],[BuyerTaxRegistrationId]=S.[BuyerTaxRegistrationId],[Currency]=S.[Currency],[GLTemplateId]=S.[GLTemplateId],[IsCapitalizedUpfront]=S.[IsCapitalizedUpfront],[IsCashBased]=S.[IsCashBased],[IsLateFeeProcessed]=S.[IsLateFeeProcessed],[IsReceivableCodeTaxExempt]=S.[IsReceivableCodeTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[PayableTypeId]=S.[PayableTypeId],[ReceivableDetailAmount]=S.[ReceivableDetailAmount],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[SellerLocation]=S.[SellerLocation],[SellerLocationId]=S.[SellerLocationId],[SellerTaxRegistrationId]=S.[SellerTaxRegistrationId],[TaxAssetType]=S.[TaxAssetType],[TaxAssetTypeId]=S.[TaxAssetTypeId],[TaxLevel]=S.[TaxLevel],[TaxReceivableType]=S.[TaxReceivableType],[TaxReceivableTypeId]=S.[TaxReceivableTypeId],[TaxRemittanceType]=S.[TaxRemittanceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BatchStatus],[BuyerLocation],[BuyerLocationId],[BuyerTaxRegistrationId],[CreatedById],[CreatedTime],[Currency],[GLTemplateId],[IsCapitalizedUpfront],[IsCashBased],[IsLateFeeProcessed],[IsReceivableCodeTaxExempt],[JobStepInstanceId],[PayableTypeId],[ReceivableDetailAmount],[ReceivableDetailId],[ReceivableDueDate],[ReceivableId],[SellerLocation],[SellerLocationId],[SellerTaxRegistrationId],[TaxAssetType],[TaxAssetTypeId],[TaxLevel],[TaxReceivableType],[TaxReceivableTypeId],[TaxRemittanceType])
    VALUES (S.[AssetId],S.[BatchStatus],S.[BuyerLocation],S.[BuyerLocationId],S.[BuyerTaxRegistrationId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[GLTemplateId],S.[IsCapitalizedUpfront],S.[IsCashBased],S.[IsLateFeeProcessed],S.[IsReceivableCodeTaxExempt],S.[JobStepInstanceId],S.[PayableTypeId],S.[ReceivableDetailAmount],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReceivableId],S.[SellerLocation],S.[SellerLocationId],S.[SellerTaxRegistrationId],S.[TaxAssetType],S.[TaxAssetTypeId],S.[TaxLevel],S.[TaxReceivableType],S.[TaxReceivableTypeId],S.[TaxRemittanceType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
