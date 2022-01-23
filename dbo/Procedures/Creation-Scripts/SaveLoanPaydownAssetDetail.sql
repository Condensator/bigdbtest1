SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownAssetDetail]
(
 @val [dbo].[LoanPaydownAssetDetail] READONLY
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
MERGE [dbo].[LoanPaydownAssetDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCost_Amount]=S.[AssetCost_Amount],[AssetCost_Currency]=S.[AssetCost_Currency],[AssetId]=S.[AssetId],[AssetPaydownStatus]=S.[AssetPaydownStatus],[AssetValuation_Amount]=S.[AssetValuation_Amount],[AssetValuation_Currency]=S.[AssetValuation_Currency],[HoldingStatus]=S.[HoldingStatus],[IsActive]=S.[IsActive],[IsPartiallyOwned]=S.[IsPartiallyOwned],[NetWritedown_Amount]=S.[NetWritedown_Amount],[NetWritedown_Currency]=S.[NetWritedown_Currency],[PrePaymentAmount_Amount]=S.[PrePaymentAmount_Amount],[PrePaymentAmount_Currency]=S.[PrePaymentAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WrittenDownNBV_Amount]=S.[WrittenDownNBV_Amount],[WrittenDownNBV_Currency]=S.[WrittenDownNBV_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetCost_Amount],[AssetCost_Currency],[AssetId],[AssetPaydownStatus],[AssetValuation_Amount],[AssetValuation_Currency],[CreatedById],[CreatedTime],[HoldingStatus],[IsActive],[IsPartiallyOwned],[LoanPaydownId],[NetWritedown_Amount],[NetWritedown_Currency],[PrePaymentAmount_Amount],[PrePaymentAmount_Currency],[WrittenDownNBV_Amount],[WrittenDownNBV_Currency])
    VALUES (S.[AssetCost_Amount],S.[AssetCost_Currency],S.[AssetId],S.[AssetPaydownStatus],S.[AssetValuation_Amount],S.[AssetValuation_Currency],S.[CreatedById],S.[CreatedTime],S.[HoldingStatus],S.[IsActive],S.[IsPartiallyOwned],S.[LoanPaydownId],S.[NetWritedown_Amount],S.[NetWritedown_Currency],S.[PrePaymentAmount_Amount],S.[PrePaymentAmount_Currency],S.[WrittenDownNBV_Amount],S.[WrittenDownNBV_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
