SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBlendedIncomeSchedule]
(
 @val [dbo].[BlendedIncomeSchedule] READONLY
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
MERGE [dbo].[BlendedIncomeSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdjustmentEntry]=S.[AdjustmentEntry],[BlendedItemId]=S.[BlendedItemId],[EffectiveInterest_Amount]=S.[EffectiveInterest_Amount],[EffectiveInterest_Currency]=S.[EffectiveInterest_Currency],[EffectiveYield]=S.[EffectiveYield],[Income_Amount]=S.[Income_Amount],[Income_Currency]=S.[Income_Currency],[IncomeBalance_Amount]=S.[IncomeBalance_Amount],[IncomeBalance_Currency]=S.[IncomeBalance_Currency],[IncomeDate]=S.[IncomeDate],[IsAccounting]=S.[IsAccounting],[IsNonAccrual]=S.[IsNonAccrual],[IsRecomputed]=S.[IsRecomputed],[IsSchedule]=S.[IsSchedule],[LeaseFinanceId]=S.[LeaseFinanceId],[LoanFinanceId]=S.[LoanFinanceId],[ModificationId]=S.[ModificationId],[ModificationType]=S.[ModificationType],[PostDate]=S.[PostDate],[ReversalPostDate]=S.[ReversalPostDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AdjustmentEntry],[BlendedItemId],[CreatedById],[CreatedTime],[EffectiveInterest_Amount],[EffectiveInterest_Currency],[EffectiveYield],[Income_Amount],[Income_Currency],[IncomeBalance_Amount],[IncomeBalance_Currency],[IncomeDate],[IsAccounting],[IsNonAccrual],[IsRecomputed],[IsSchedule],[LeaseFinanceId],[LoanFinanceId],[ModificationId],[ModificationType],[PostDate],[ReversalPostDate])
    VALUES (S.[AdjustmentEntry],S.[BlendedItemId],S.[CreatedById],S.[CreatedTime],S.[EffectiveInterest_Amount],S.[EffectiveInterest_Currency],S.[EffectiveYield],S.[Income_Amount],S.[Income_Currency],S.[IncomeBalance_Amount],S.[IncomeBalance_Currency],S.[IncomeDate],S.[IsAccounting],S.[IsNonAccrual],S.[IsRecomputed],S.[IsSchedule],S.[LeaseFinanceId],S.[LoanFinanceId],S.[ModificationId],S.[ModificationType],S.[PostDate],S.[ReversalPostDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
