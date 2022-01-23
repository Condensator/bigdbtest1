SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingRepaymentSchedule]
(
 @val [dbo].[DiscountingRepaymentSchedule] READONLY
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
MERGE [dbo].[DiscountingRepaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BeginBalance_Amount]=S.[BeginBalance_Amount],[BeginBalance_Currency]=S.[BeginBalance_Currency],[Calculate]=S.[Calculate],[DueDate]=S.[DueDate],[EffectiveExpenseBalance_Amount]=S.[EffectiveExpenseBalance_Amount],[EffectiveExpenseBalance_Currency]=S.[EffectiveExpenseBalance_Currency],[EffectivePrincipalBalance_Amount]=S.[EffectivePrincipalBalance_Amount],[EffectivePrincipalBalance_Currency]=S.[EffectivePrincipalBalance_Currency],[EndBalance_Amount]=S.[EndBalance_Amount],[EndBalance_Currency]=S.[EndBalance_Currency],[EndDate]=S.[EndDate],[ExpenseBookBalance_Amount]=S.[ExpenseBookBalance_Amount],[ExpenseBookBalance_Currency]=S.[ExpenseBookBalance_Currency],[GainLoss_Amount]=S.[GainLoss_Amount],[GainLoss_Currency]=S.[GainLoss_Currency],[Interest_Amount]=S.[Interest_Amount],[Interest_Currency]=S.[Interest_Currency],[InterestProcessed_Amount]=S.[InterestProcessed_Amount],[InterestProcessed_Currency]=S.[InterestProcessed_Currency],[IsActive]=S.[IsActive],[IsApportioned]=S.[IsApportioned],[PaymentNumber]=S.[PaymentNumber],[PaymentStructure]=S.[PaymentStructure],[PaymentType]=S.[PaymentType],[Principal_Amount]=S.[Principal_Amount],[Principal_Currency]=S.[Principal_Currency],[PrincipalBookBalance_Amount]=S.[PrincipalBookBalance_Amount],[PrincipalBookBalance_Currency]=S.[PrincipalBookBalance_Currency],[PrincipalProcessed_Amount]=S.[PrincipalProcessed_Amount],[PrincipalProcessed_Currency]=S.[PrincipalProcessed_Currency],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[Amount_Amount],[Amount_Currency],[BeginBalance_Amount],[BeginBalance_Currency],[Calculate],[CreatedById],[CreatedTime],[DiscountingFinanceId],[DueDate],[EffectiveExpenseBalance_Amount],[EffectiveExpenseBalance_Currency],[EffectivePrincipalBalance_Amount],[EffectivePrincipalBalance_Currency],[EndBalance_Amount],[EndBalance_Currency],[EndDate],[ExpenseBookBalance_Amount],[ExpenseBookBalance_Currency],[GainLoss_Amount],[GainLoss_Currency],[Interest_Amount],[Interest_Currency],[InterestProcessed_Amount],[InterestProcessed_Currency],[IsActive],[IsApportioned],[PaymentNumber],[PaymentStructure],[PaymentType],[Principal_Amount],[Principal_Currency],[PrincipalBookBalance_Amount],[PrincipalBookBalance_Currency],[PrincipalProcessed_Amount],[PrincipalProcessed_Currency],[StartDate])
    VALUES (S.[AdjustmentEntry],S.[Amount_Amount],S.[Amount_Currency],S.[BeginBalance_Amount],S.[BeginBalance_Currency],S.[Calculate],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[DueDate],S.[EffectiveExpenseBalance_Amount],S.[EffectiveExpenseBalance_Currency],S.[EffectivePrincipalBalance_Amount],S.[EffectivePrincipalBalance_Currency],S.[EndBalance_Amount],S.[EndBalance_Currency],S.[EndDate],S.[ExpenseBookBalance_Amount],S.[ExpenseBookBalance_Currency],S.[GainLoss_Amount],S.[GainLoss_Currency],S.[Interest_Amount],S.[Interest_Currency],S.[InterestProcessed_Amount],S.[InterestProcessed_Currency],S.[IsActive],S.[IsApportioned],S.[PaymentNumber],S.[PaymentStructure],S.[PaymentType],S.[Principal_Amount],S.[Principal_Currency],S.[PrincipalBookBalance_Amount],S.[PrincipalBookBalance_Currency],S.[PrincipalProcessed_Amount],S.[PrincipalProcessed_Currency],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
