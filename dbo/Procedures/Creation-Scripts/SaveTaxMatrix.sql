SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxMatrix]
(
 @val [dbo].[TaxMatrix] READONLY
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
MERGE [dbo].[TaxMatrices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BuyerCountryId]=S.[BuyerCountryId],[BuyerStateId]=S.[BuyerStateId],[EffectiveDate]=S.[EffectiveDate],[IsActive]=S.[IsActive],[PayableTypeId]=S.[PayableTypeId],[SellerCountryId]=S.[SellerCountryId],[SellerStateId]=S.[SellerStateId],[TaxAssetTypeId]=S.[TaxAssetTypeId],[TaxCodeId]=S.[TaxCodeId],[TaxLevel]=S.[TaxLevel],[TaxReceivableTypeId]=S.[TaxReceivableTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BuyerCountryId],[BuyerStateId],[CreatedById],[CreatedTime],[EffectiveDate],[IsActive],[PayableTypeId],[SellerCountryId],[SellerStateId],[TaxAssetTypeId],[TaxCodeId],[TaxLevel],[TaxReceivableTypeId])
    VALUES (S.[BuyerCountryId],S.[BuyerStateId],S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[IsActive],S.[PayableTypeId],S.[SellerCountryId],S.[SellerStateId],S.[TaxAssetTypeId],S.[TaxCodeId],S.[TaxLevel],S.[TaxReceivableTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
