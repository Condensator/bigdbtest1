SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseFloatRateIncome]
(
 @val [dbo].[LeaseFloatRateIncome] READONLY
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
MERGE [dbo].[LeaseFloatRateIncomes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[CustomerIncomeAccruedAmount_Amount]=S.[CustomerIncomeAccruedAmount_Amount],[CustomerIncomeAccruedAmount_Currency]=S.[CustomerIncomeAccruedAmount_Currency],[CustomerIncomeAmount_Amount]=S.[CustomerIncomeAmount_Amount],[CustomerIncomeAmount_Currency]=S.[CustomerIncomeAmount_Currency],[CustomerReceivableAmount_Amount]=S.[CustomerReceivableAmount_Amount],[CustomerReceivableAmount_Currency]=S.[CustomerReceivableAmount_Currency],[FloatRateIndexDetailId]=S.[FloatRateIndexDetailId],[IncomeDate]=S.[IncomeDate],[InterestRate]=S.[InterestRate],[IsAccounting]=S.[IsAccounting],[IsGLPosted]=S.[IsGLPosted],[IsLessorOwned]=S.[IsLessorOwned],[IsNonAccrual]=S.[IsNonAccrual],[IsScheduled]=S.[IsScheduled],[LeaseFinanceId]=S.[LeaseFinanceId],[ModificationId]=S.[ModificationId],[ModificationType]=S.[ModificationType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[CreatedById],[CreatedTime],[CustomerIncomeAccruedAmount_Amount],[CustomerIncomeAccruedAmount_Currency],[CustomerIncomeAmount_Amount],[CustomerIncomeAmount_Currency],[CustomerReceivableAmount_Amount],[CustomerReceivableAmount_Currency],[FloatRateIndexDetailId],[IncomeDate],[InterestRate],[IsAccounting],[IsGLPosted],[IsLessorOwned],[IsNonAccrual],[IsScheduled],[LeaseFinanceId],[ModificationId],[ModificationType])
    VALUES (S.[AdjustmentEntry],S.[CreatedById],S.[CreatedTime],S.[CustomerIncomeAccruedAmount_Amount],S.[CustomerIncomeAccruedAmount_Currency],S.[CustomerIncomeAmount_Amount],S.[CustomerIncomeAmount_Currency],S.[CustomerReceivableAmount_Amount],S.[CustomerReceivableAmount_Currency],S.[FloatRateIndexDetailId],S.[IncomeDate],S.[InterestRate],S.[IsAccounting],S.[IsGLPosted],S.[IsLessorOwned],S.[IsNonAccrual],S.[IsScheduled],S.[LeaseFinanceId],S.[ModificationId],S.[ModificationType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
