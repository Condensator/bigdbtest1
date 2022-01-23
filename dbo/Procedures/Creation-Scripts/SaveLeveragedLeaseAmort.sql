SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeveragedLeaseAmort]
(
 @val [dbo].[LeveragedLeaseAmort] READONLY
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
MERGE [dbo].[LeveragedLeaseAmorts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AMTDepreciation_Amount]=S.[AMTDepreciation_Amount],[AMTDepreciation_Currency]=S.[AMTDepreciation_Currency],[DebtService_Amount]=S.[DebtService_Amount],[DebtService_Currency]=S.[DebtService_Currency],[DeferedIDCTaxUnAmort_Amount]=S.[DeferedIDCTaxUnAmort_Amount],[DeferedIDCTaxUnAmort_Currency]=S.[DeferedIDCTaxUnAmort_Currency],[DeferedITCTaxUnAmort_Amount]=S.[DeferedITCTaxUnAmort_Amount],[DeferedITCTaxUnAmort_Currency]=S.[DeferedITCTaxUnAmort_Currency],[DeferredTaxes_Amount]=S.[DeferredTaxes_Amount],[DeferredTaxes_Currency]=S.[DeferredTaxes_Currency],[DeferredTaxesAccrued_Amount]=S.[DeferredTaxesAccrued_Amount],[DeferredTaxesAccrued_Currency]=S.[DeferredTaxesAccrued_Currency],[DepreciationExpense_Amount]=S.[DepreciationExpense_Amount],[DepreciationExpense_Currency]=S.[DepreciationExpense_Currency],[DepreciationPreference_Amount]=S.[DepreciationPreference_Amount],[DepreciationPreference_Currency]=S.[DepreciationPreference_Currency],[FreeCash_Amount]=S.[FreeCash_Amount],[FreeCash_Currency]=S.[FreeCash_Currency],[FSCExclusion_Amount]=S.[FSCExclusion_Amount],[FSCExclusion_Currency]=S.[FSCExclusion_Currency],[IDC_Amount]=S.[IDC_Amount],[IDC_Currency]=S.[IDC_Currency],[IncomeDate]=S.[IncomeDate],[InterestOnLoan_Amount]=S.[InterestOnLoan_Amount],[InterestOnLoan_Currency]=S.[InterestOnLoan_Currency],[IsAccounting]=S.[IsAccounting],[IsActive]=S.[IsActive],[IsAddedAfterRestructure]=S.[IsAddedAfterRestructure],[IsGLPosted]=S.[IsGLPosted],[IsSchedule]=S.[IsSchedule],[ITC_Amount]=S.[ITC_Amount],[ITC_Currency]=S.[ITC_Currency],[NetRentReceivable_Amount]=S.[NetRentReceivable_Amount],[NetRentReceivable_Currency]=S.[NetRentReceivable_Currency],[NonRecourseDebtBalance_Amount]=S.[NonRecourseDebtBalance_Amount],[NonRecourseDebtBalance_Currency]=S.[NonRecourseDebtBalance_Currency],[OtherCash_Amount]=S.[OtherCash_Amount],[OtherCash_Currency]=S.[OtherCash_Currency],[OtherExpense_Amount]=S.[OtherExpense_Amount],[OtherExpense_Currency]=S.[OtherExpense_Currency],[ParentIncome_Amount]=S.[ParentIncome_Amount],[ParentIncome_Currency]=S.[ParentIncome_Currency],[PreTaxIncome_Amount]=S.[PreTaxIncome_Amount],[PreTaxIncome_Currency]=S.[PreTaxIncome_Currency],[RentalCash_Amount]=S.[RentalCash_Amount],[RentalCash_Currency]=S.[RentalCash_Currency],[ResidualIncome_Amount]=S.[ResidualIncome_Amount],[ResidualIncome_Currency]=S.[ResidualIncome_Currency],[ResidualReceivable_Amount]=S.[ResidualReceivable_Amount],[ResidualReceivable_Currency]=S.[ResidualReceivable_Currency],[SubpartFIncome_Amount]=S.[SubpartFIncome_Amount],[SubpartFIncome_Currency]=S.[SubpartFIncome_Currency],[TaxableIncome_Amount]=S.[TaxableIncome_Amount],[TaxableIncome_Currency]=S.[TaxableIncome_Currency],[TaxEffectOfPreTaxIncome_Amount]=S.[TaxEffectOfPreTaxIncome_Amount],[TaxEffectOfPreTaxIncome_Currency]=S.[TaxEffectOfPreTaxIncome_Currency],[TaxIDC_Amount]=S.[TaxIDC_Amount],[TaxIDC_Currency]=S.[TaxIDC_Currency],[UnearnedIncome_Amount]=S.[UnearnedIncome_Amount],[UnearnedIncome_Currency]=S.[UnearnedIncome_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AMTDepreciation_Amount],[AMTDepreciation_Currency],[CreatedById],[CreatedTime],[DebtService_Amount],[DebtService_Currency],[DeferedIDCTaxUnAmort_Amount],[DeferedIDCTaxUnAmort_Currency],[DeferedITCTaxUnAmort_Amount],[DeferedITCTaxUnAmort_Currency],[DeferredTaxes_Amount],[DeferredTaxes_Currency],[DeferredTaxesAccrued_Amount],[DeferredTaxesAccrued_Currency],[DepreciationExpense_Amount],[DepreciationExpense_Currency],[DepreciationPreference_Amount],[DepreciationPreference_Currency],[FreeCash_Amount],[FreeCash_Currency],[FSCExclusion_Amount],[FSCExclusion_Currency],[IDC_Amount],[IDC_Currency],[IncomeDate],[InterestOnLoan_Amount],[InterestOnLoan_Currency],[IsAccounting],[IsActive],[IsAddedAfterRestructure],[IsGLPosted],[IsSchedule],[ITC_Amount],[ITC_Currency],[LeveragedLeaseId],[NetRentReceivable_Amount],[NetRentReceivable_Currency],[NonRecourseDebtBalance_Amount],[NonRecourseDebtBalance_Currency],[OtherCash_Amount],[OtherCash_Currency],[OtherExpense_Amount],[OtherExpense_Currency],[ParentIncome_Amount],[ParentIncome_Currency],[PreTaxIncome_Amount],[PreTaxIncome_Currency],[RentalCash_Amount],[RentalCash_Currency],[ResidualIncome_Amount],[ResidualIncome_Currency],[ResidualReceivable_Amount],[ResidualReceivable_Currency],[SubpartFIncome_Amount],[SubpartFIncome_Currency],[TaxableIncome_Amount],[TaxableIncome_Currency],[TaxEffectOfPreTaxIncome_Amount],[TaxEffectOfPreTaxIncome_Currency],[TaxIDC_Amount],[TaxIDC_Currency],[UnearnedIncome_Amount],[UnearnedIncome_Currency])
    VALUES (S.[AMTDepreciation_Amount],S.[AMTDepreciation_Currency],S.[CreatedById],S.[CreatedTime],S.[DebtService_Amount],S.[DebtService_Currency],S.[DeferedIDCTaxUnAmort_Amount],S.[DeferedIDCTaxUnAmort_Currency],S.[DeferedITCTaxUnAmort_Amount],S.[DeferedITCTaxUnAmort_Currency],S.[DeferredTaxes_Amount],S.[DeferredTaxes_Currency],S.[DeferredTaxesAccrued_Amount],S.[DeferredTaxesAccrued_Currency],S.[DepreciationExpense_Amount],S.[DepreciationExpense_Currency],S.[DepreciationPreference_Amount],S.[DepreciationPreference_Currency],S.[FreeCash_Amount],S.[FreeCash_Currency],S.[FSCExclusion_Amount],S.[FSCExclusion_Currency],S.[IDC_Amount],S.[IDC_Currency],S.[IncomeDate],S.[InterestOnLoan_Amount],S.[InterestOnLoan_Currency],S.[IsAccounting],S.[IsActive],S.[IsAddedAfterRestructure],S.[IsGLPosted],S.[IsSchedule],S.[ITC_Amount],S.[ITC_Currency],S.[LeveragedLeaseId],S.[NetRentReceivable_Amount],S.[NetRentReceivable_Currency],S.[NonRecourseDebtBalance_Amount],S.[NonRecourseDebtBalance_Currency],S.[OtherCash_Amount],S.[OtherCash_Currency],S.[OtherExpense_Amount],S.[OtherExpense_Currency],S.[ParentIncome_Amount],S.[ParentIncome_Currency],S.[PreTaxIncome_Amount],S.[PreTaxIncome_Currency],S.[RentalCash_Amount],S.[RentalCash_Currency],S.[ResidualIncome_Amount],S.[ResidualIncome_Currency],S.[ResidualReceivable_Amount],S.[ResidualReceivable_Currency],S.[SubpartFIncome_Amount],S.[SubpartFIncome_Currency],S.[TaxableIncome_Amount],S.[TaxableIncome_Currency],S.[TaxEffectOfPreTaxIncome_Amount],S.[TaxEffectOfPreTaxIncome_Currency],S.[TaxIDC_Amount],S.[TaxIDC_Currency],S.[UnearnedIncome_Amount],S.[UnearnedIncome_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
