SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAssetIncomeDetail]
(
 @val [dbo].[LeaseAssetIncomeDetail] READONLY
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
MERGE [dbo].[LeaseAssetIncomeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetYieldForFinanceComponents]=S.[AssetYieldForFinanceComponents],[AssetYieldForLeaseComponents]=S.[AssetYieldForLeaseComponents],[FinanceIncome_Amount]=S.[FinanceIncome_Amount],[FinanceIncome_Currency]=S.[FinanceIncome_Currency],[FinanceResidualIncome_Amount]=S.[FinanceResidualIncome_Amount],[FinanceResidualIncome_Currency]=S.[FinanceResidualIncome_Currency],[Income_Amount]=S.[Income_Amount],[Income_Currency]=S.[Income_Currency],[LeaseIncome_Amount]=S.[LeaseIncome_Amount],[LeaseIncome_Currency]=S.[LeaseIncome_Currency],[LeaseResidualIncome_Amount]=S.[LeaseResidualIncome_Amount],[LeaseResidualIncome_Currency]=S.[LeaseResidualIncome_Currency],[ResidualIncome_Amount]=S.[ResidualIncome_Amount],[ResidualIncome_Currency]=S.[ResidualIncome_Currency],[SalesTypeNBV_Amount]=S.[SalesTypeNBV_Amount],[SalesTypeNBV_Currency]=S.[SalesTypeNBV_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetYieldForFinanceComponents],[AssetYieldForLeaseComponents],[CreatedById],[CreatedTime],[FinanceIncome_Amount],[FinanceIncome_Currency],[FinanceResidualIncome_Amount],[FinanceResidualIncome_Currency],[Id],[Income_Amount],[Income_Currency],[LeaseIncome_Amount],[LeaseIncome_Currency],[LeaseResidualIncome_Amount],[LeaseResidualIncome_Currency],[ResidualIncome_Amount],[ResidualIncome_Currency],[SalesTypeNBV_Amount],[SalesTypeNBV_Currency])
    VALUES (S.[AssetYieldForFinanceComponents],S.[AssetYieldForLeaseComponents],S.[CreatedById],S.[CreatedTime],S.[FinanceIncome_Amount],S.[FinanceIncome_Currency],S.[FinanceResidualIncome_Amount],S.[FinanceResidualIncome_Currency],S.[Id],S.[Income_Amount],S.[Income_Currency],S.[LeaseIncome_Amount],S.[LeaseIncome_Currency],S.[LeaseResidualIncome_Amount],S.[LeaseResidualIncome_Currency],S.[ResidualIncome_Amount],S.[ResidualIncome_Currency],S.[SalesTypeNBV_Amount],S.[SalesTypeNBV_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
