SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingNonAccrualDetail]
(
 @val [dbo].[DiscountingNonAccrualDetail] READONLY
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
MERGE [dbo].[DiscountingNonAccrualDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [APTemplateId]=S.[APTemplateId],[DiscountingId]=S.[DiscountingId],[ExpenseRecognizedAfterNonAccrual_Amount]=S.[ExpenseRecognizedAfterNonAccrual_Amount],[ExpenseRecognizedAfterNonAccrual_Currency]=S.[ExpenseRecognizedAfterNonAccrual_Currency],[IsActive]=S.[IsActive],[LastExpenseUpdateDate]=S.[LastExpenseUpdateDate],[LastPaymentDate]=S.[LastPaymentDate],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NBVPostAdjustments_Amount]=S.[NBVPostAdjustments_Amount],[NBVPostAdjustments_Currency]=S.[NBVPostAdjustments_Currency],[NonAccrualDate]=S.[NonAccrualDate],[TotalOutstandingPayment_Amount]=S.[TotalOutstandingPayment_Amount],[TotalOutstandingPayment_Currency]=S.[TotalOutstandingPayment_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([APTemplateId],[CreatedById],[CreatedTime],[DiscountingId],[DiscountingNonAccrualId],[ExpenseRecognizedAfterNonAccrual_Amount],[ExpenseRecognizedAfterNonAccrual_Currency],[IsActive],[LastExpenseUpdateDate],[LastPaymentDate],[NBV_Amount],[NBV_Currency],[NBVPostAdjustments_Amount],[NBVPostAdjustments_Currency],[NonAccrualDate],[TotalOutstandingPayment_Amount],[TotalOutstandingPayment_Currency])
    VALUES (S.[APTemplateId],S.[CreatedById],S.[CreatedTime],S.[DiscountingId],S.[DiscountingNonAccrualId],S.[ExpenseRecognizedAfterNonAccrual_Amount],S.[ExpenseRecognizedAfterNonAccrual_Currency],S.[IsActive],S.[LastExpenseUpdateDate],S.[LastPaymentDate],S.[NBV_Amount],S.[NBV_Currency],S.[NBVPostAdjustments_Amount],S.[NBVPostAdjustments_Currency],S.[NonAccrualDate],S.[TotalOutstandingPayment_Amount],S.[TotalOutstandingPayment_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
