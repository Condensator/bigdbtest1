SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVATReceivableLocationDetail_Extract]
(
 @val [dbo].[VATReceivableLocationDetail_Extract] READONLY
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
MERGE [dbo].[VATReceivableLocationDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BasisAmount]=S.[BasisAmount],[BasisAmountCurrency]=S.[BasisAmountCurrency],[BuyerLocation]=S.[BuyerLocation],[BuyerLocationId]=S.[BuyerLocationId],[BuyerTaxRegistrationId]=S.[BuyerTaxRegistrationId],[CustomerId]=S.[CustomerId],[IsCapitalizedUpfront]=S.[IsCapitalizedUpfront],[IsReceivableCodeTaxExempt]=S.[IsReceivableCodeTaxExempt],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityId]=S.[LegalEntityId],[PayableTypeId]=S.[PayableTypeId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableDueDate]=S.[ReceivableDueDate],[ReceivableId]=S.[ReceivableId],[ReceivableTypeId]=S.[ReceivableTypeId],[SellerLocation]=S.[SellerLocation],[SellerLocationId]=S.[SellerLocationId],[SellerTaxRegistrationId]=S.[SellerTaxRegistrationId],[TaxAssetType]=S.[TaxAssetType],[TaxAssetTypeId]=S.[TaxAssetTypeId],[TaxLevel]=S.[TaxLevel],[TaxReceivableType]=S.[TaxReceivableType],[TaxReceivableTypeId]=S.[TaxReceivableTypeId],[TaxRemittanceType]=S.[TaxRemittanceType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BasisAmount],[BasisAmountCurrency],[BuyerLocation],[BuyerLocationId],[BuyerTaxRegistrationId],[CreatedById],[CreatedTime],[CustomerId],[IsCapitalizedUpfront],[IsReceivableCodeTaxExempt],[JobStepInstanceId],[LegalEntityId],[PayableTypeId],[ReceivableDetailId],[ReceivableDueDate],[ReceivableId],[ReceivableTypeId],[SellerLocation],[SellerLocationId],[SellerTaxRegistrationId],[TaxAssetType],[TaxAssetTypeId],[TaxLevel],[TaxReceivableType],[TaxReceivableTypeId],[TaxRemittanceType])
    VALUES (S.[AssetId],S.[BasisAmount],S.[BasisAmountCurrency],S.[BuyerLocation],S.[BuyerLocationId],S.[BuyerTaxRegistrationId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IsCapitalizedUpfront],S.[IsReceivableCodeTaxExempt],S.[JobStepInstanceId],S.[LegalEntityId],S.[PayableTypeId],S.[ReceivableDetailId],S.[ReceivableDueDate],S.[ReceivableId],S.[ReceivableTypeId],S.[SellerLocation],S.[SellerLocationId],S.[SellerTaxRegistrationId],S.[TaxAssetType],S.[TaxAssetTypeId],S.[TaxLevel],S.[TaxReceivableType],S.[TaxReceivableTypeId],S.[TaxRemittanceType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
