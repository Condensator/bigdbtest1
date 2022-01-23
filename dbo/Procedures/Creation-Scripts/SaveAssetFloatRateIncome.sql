SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetFloatRateIncome]
(
 @val [dbo].[AssetFloatRateIncome] READONLY
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
MERGE [dbo].[AssetFloatRateIncomes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[CustomerIncomeAccruedAmount_Amount]=S.[CustomerIncomeAccruedAmount_Amount],[CustomerIncomeAccruedAmount_Currency]=S.[CustomerIncomeAccruedAmount_Currency],[CustomerIncomeAmount_Amount]=S.[CustomerIncomeAmount_Amount],[CustomerIncomeAmount_Currency]=S.[CustomerIncomeAmount_Currency],[CustomerReceivableAmount_Amount]=S.[CustomerReceivableAmount_Amount],[CustomerReceivableAmount_Currency]=S.[CustomerReceivableAmount_Currency],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[CustomerIncomeAccruedAmount_Amount],[CustomerIncomeAccruedAmount_Currency],[CustomerIncomeAmount_Amount],[CustomerIncomeAmount_Currency],[CustomerReceivableAmount_Amount],[CustomerReceivableAmount_Currency],[IsActive],[LeaseFloatRateIncomeId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[CustomerIncomeAccruedAmount_Amount],S.[CustomerIncomeAccruedAmount_Currency],S.[CustomerIncomeAmount_Amount],S.[CustomerIncomeAmount_Currency],S.[CustomerReceivableAmount_Amount],S.[CustomerReceivableAmount_Currency],S.[IsActive],S.[LeaseFloatRateIncomeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
