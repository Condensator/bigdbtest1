SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceExpense]
(
 @val [dbo].[AcceleratedBalanceExpense] READONLY
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
MERGE [dbo].[AcceleratedBalanceExpenses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountDue_Amount]=S.[AmountDue_Amount],[AmountDue_Currency]=S.[AmountDue_Currency],[Date]=S.[Date],[Description]=S.[Description],[ExpenseType]=S.[ExpenseType],[IsActive]=S.[IsActive],[IsJudgement]=S.[IsJudgement],[IsLease]=S.[IsLease],[Payee]=S.[Payee],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WaivedAmount_Amount]=S.[WaivedAmount_Amount],[WaivedAmount_Currency]=S.[WaivedAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AcceleratedBalanceDetailId],[AmountDue_Amount],[AmountDue_Currency],[CreatedById],[CreatedTime],[Date],[Description],[ExpenseType],[IsActive],[IsJudgement],[IsLease],[Payee],[WaivedAmount_Amount],[WaivedAmount_Currency])
    VALUES (S.[AcceleratedBalanceDetailId],S.[AmountDue_Amount],S.[AmountDue_Currency],S.[CreatedById],S.[CreatedTime],S.[Date],S.[Description],S.[ExpenseType],S.[IsActive],S.[IsJudgement],S.[IsLease],S.[Payee],S.[WaivedAmount_Amount],S.[WaivedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
