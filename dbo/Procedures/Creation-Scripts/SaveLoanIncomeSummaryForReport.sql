SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanIncomeSummaryForReport]
(
 @val [dbo].[LoanIncomeSummaryForReport] READONLY
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
MERGE [dbo].[LoanIncomeSummaryForReports] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BlendedIncome_Amount]=S.[BlendedIncome_Amount],[BlendedIncome_Currency]=S.[BlendedIncome_Currency],[BlendedIncomeBalance_Amount]=S.[BlendedIncomeBalance_Amount],[BlendedIncomeBalance_Currency]=S.[BlendedIncomeBalance_Currency],[BlendedItemName]=S.[BlendedItemName],[ContractId]=S.[ContractId],[EndBalance_Amount]=S.[EndBalance_Amount],[EndBalance_Currency]=S.[EndBalance_Currency],[IncomeDate]=S.[IncomeDate],[InterestAccrued_Amount]=S.[InterestAccrued_Amount],[InterestAccrued_Currency]=S.[InterestAccrued_Currency],[InterestPayment_Amount]=S.[InterestPayment_Amount],[InterestPayment_Currency]=S.[InterestPayment_Currency],[InterestRate]=S.[InterestRate],[IsActualBlendedIncomeRecord]=S.[IsActualBlendedIncomeRecord],[IsBlendedIncomeRecord]=S.[IsBlendedIncomeRecord],[IsGLPosted]=S.[IsGLPosted],[IsYieldExtreme]=S.[IsYieldExtreme],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentNumber]=S.[PaymentNumber],[PaymentType]=S.[PaymentType],[PrincipalAdded_Amount]=S.[PrincipalAdded_Amount],[PrincipalAdded_Currency]=S.[PrincipalAdded_Currency],[PrincipalPayment_Amount]=S.[PrincipalPayment_Amount],[PrincipalPayment_Currency]=S.[PrincipalPayment_Currency],[Suspended]=S.[Suspended],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BlendedIncome_Amount],[BlendedIncome_Currency],[BlendedIncomeBalance_Amount],[BlendedIncomeBalance_Currency],[BlendedItemName],[ContractId],[CreatedById],[CreatedTime],[EndBalance_Amount],[EndBalance_Currency],[IncomeDate],[InterestAccrued_Amount],[InterestAccrued_Currency],[InterestPayment_Amount],[InterestPayment_Currency],[InterestRate],[IsActualBlendedIncomeRecord],[IsBlendedIncomeRecord],[IsGLPosted],[IsYieldExtreme],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentNumber],[PaymentType],[PrincipalAdded_Amount],[PrincipalAdded_Currency],[PrincipalPayment_Amount],[PrincipalPayment_Currency],[Suspended])
    VALUES (S.[BlendedIncome_Amount],S.[BlendedIncome_Currency],S.[BlendedIncomeBalance_Amount],S.[BlendedIncomeBalance_Currency],S.[BlendedItemName],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[EndBalance_Amount],S.[EndBalance_Currency],S.[IncomeDate],S.[InterestAccrued_Amount],S.[InterestAccrued_Currency],S.[InterestPayment_Amount],S.[InterestPayment_Currency],S.[InterestRate],S.[IsActualBlendedIncomeRecord],S.[IsBlendedIncomeRecord],S.[IsGLPosted],S.[IsYieldExtreme],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentNumber],S.[PaymentType],S.[PrincipalAdded_Amount],S.[PrincipalAdded_Currency],S.[PrincipalPayment_Amount],S.[PrincipalPayment_Currency],S.[Suspended])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
