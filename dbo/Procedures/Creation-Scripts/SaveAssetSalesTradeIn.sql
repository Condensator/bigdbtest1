SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSalesTradeIn]
(
 @val [dbo].[AssetSalesTradeIn] READONLY
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
MERGE [dbo].[AssetSalesTradeIns] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[IsActive]=S.[IsActive],[NetValue_Amount]=S.[NetValue_Amount],[NetValue_Currency]=S.[NetValue_Currency],[ProjectedVATAmount_Amount]=S.[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency]=S.[ProjectedVATAmount_Currency],[TaxCodeId]=S.[TaxCodeId],[TaxCodeRateId]=S.[TaxCodeRateId],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATType]=S.[VATType]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetSaleId],[CreatedById],[CreatedTime],[IsActive],[NetValue_Amount],[NetValue_Currency],[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency],[TaxCodeId],[TaxCodeRateId],[TaxTypeId],[VATType])
    VALUES (S.[AssetId],S.[AssetSaleId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[NetValue_Amount],S.[NetValue_Currency],S.[ProjectedVATAmount_Amount],S.[ProjectedVATAmount_Currency],S.[TaxCodeId],S.[TaxCodeRateId],S.[TaxTypeId],S.[VATType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
