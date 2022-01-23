SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetSaleDetail]
(
 @val [dbo].[AssetSaleDetail] READONLY
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
MERGE [dbo].[AssetSaleDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[EffectiveToDate]=S.[EffectiveToDate],[FairMarketValue_Amount]=S.[FairMarketValue_Amount],[FairMarketValue_Currency]=S.[FairMarketValue_Currency],[IsActive]=S.[IsActive],[IsPerfectPay]=S.[IsPerfectPay],[NetValue_Amount]=S.[NetValue_Amount],[NetValue_Currency]=S.[NetValue_Currency],[ProjectedVATAmount_Amount]=S.[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency]=S.[ProjectedVATAmount_Currency],[TerminationReasonConfigId]=S.[TerminationReasonConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssetSaleId],[CreatedById],[CreatedTime],[EffectiveToDate],[FairMarketValue_Amount],[FairMarketValue_Currency],[IsActive],[IsPerfectPay],[NetValue_Amount],[NetValue_Currency],[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency],[TerminationReasonConfigId])
    VALUES (S.[AssetId],S.[AssetSaleId],S.[CreatedById],S.[CreatedTime],S.[EffectiveToDate],S.[FairMarketValue_Amount],S.[FairMarketValue_Currency],S.[IsActive],S.[IsPerfectPay],S.[NetValue_Amount],S.[NetValue_Currency],S.[ProjectedVATAmount_Amount],S.[ProjectedVATAmount_Currency],S.[TerminationReasonConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
