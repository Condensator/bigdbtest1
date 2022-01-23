SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableSKUTaxReversalDetail]
(
 @val [dbo].[ReceivableSKUTaxReversalDetail] READONLY
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
MERGE [dbo].[ReceivableSKUTaxReversalDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AmountBilledToDate_Amount]=S.[AmountBilledToDate_Amount],[AmountBilledToDate_Currency]=S.[AmountBilledToDate_Currency],[AssetSKUId]=S.[AssetSKUId],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[FairMarketValue_Amount]=S.[FairMarketValue_Amount],[FairMarketValue_Currency]=S.[FairMarketValue_Currency],[IsActive]=S.[IsActive],[IsExemptAtAssetSKU]=S.[IsExemptAtAssetSKU],[ReceivableSKUId]=S.[ReceivableSKUId],[Revenue_Amount]=S.[Revenue_Amount],[Revenue_Currency]=S.[Revenue_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AmountBilledToDate_Amount],[AmountBilledToDate_Currency],[AssetSKUId],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[FairMarketValue_Amount],[FairMarketValue_Currency],[IsActive],[IsExemptAtAssetSKU],[ReceivableSKUId],[ReceivableTaxDetailId],[Revenue_Amount],[Revenue_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AmountBilledToDate_Amount],S.[AmountBilledToDate_Currency],S.[AssetSKUId],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[FairMarketValue_Amount],S.[FairMarketValue_Currency],S.[IsActive],S.[IsExemptAtAssetSKU],S.[ReceivableSKUId],S.[ReceivableTaxDetailId],S.[Revenue_Amount],S.[Revenue_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
