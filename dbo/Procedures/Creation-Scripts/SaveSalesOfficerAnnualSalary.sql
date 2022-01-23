SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSalesOfficerAnnualSalary]
(
 @val [dbo].[SalesOfficerAnnualSalary] READONLY
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
MERGE [dbo].[SalesOfficerAnnualSalaries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AnnualFeeIncomeGoal_Amount]=S.[AnnualFeeIncomeGoal_Amount],[AnnualFeeIncomeGoal_Currency]=S.[AnnualFeeIncomeGoal_Currency],[AnnualSalesGoals_Amount]=S.[AnnualSalesGoals_Amount],[AnnualSalesGoals_Currency]=S.[AnnualSalesGoals_Currency],[BaseSalary_Amount]=S.[BaseSalary_Amount],[BaseSalary_Currency]=S.[BaseSalary_Currency],[IsActive]=S.[IsActive],[RowNumber]=S.[RowNumber],[SalaryCap_Amount]=S.[SalaryCap_Amount],[SalaryCap_Currency]=S.[SalaryCap_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Year]=S.[Year]
WHEN NOT MATCHED THEN
	INSERT ([AnnualFeeIncomeGoal_Amount],[AnnualFeeIncomeGoal_Currency],[AnnualSalesGoals_Amount],[AnnualSalesGoals_Currency],[BaseSalary_Amount],[BaseSalary_Currency],[CreatedById],[CreatedTime],[IsActive],[RowNumber],[SalaryCap_Amount],[SalaryCap_Currency],[SalesOfficerId],[Year])
    VALUES (S.[AnnualFeeIncomeGoal_Amount],S.[AnnualFeeIncomeGoal_Currency],S.[AnnualSalesGoals_Amount],S.[AnnualSalesGoals_Currency],S.[BaseSalary_Amount],S.[BaseSalary_Currency],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[RowNumber],S.[SalaryCap_Amount],S.[SalaryCap_Currency],S.[SalesOfficerId],S.[Year])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
