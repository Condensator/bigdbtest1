SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanInsuranceRequirement]
(
 @val [dbo].[LoanInsuranceRequirement] READONLY
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
MERGE [dbo].[LoanInsuranceRequirements] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AggregateAmount_Amount]=S.[AggregateAmount_Amount],[AggregateAmount_Currency]=S.[AggregateAmount_Currency],[AggregateDeductible_Amount]=S.[AggregateDeductible_Amount],[AggregateDeductible_Currency]=S.[AggregateDeductible_Currency],[CoverageTypeConfigId]=S.[CoverageTypeConfigId],[IsActive]=S.[IsActive],[IsContractAmount]=S.[IsContractAmount],[IsManual]=S.[IsManual],[PerOccurrenceAmount_Amount]=S.[PerOccurrenceAmount_Amount],[PerOccurrenceAmount_Currency]=S.[PerOccurrenceAmount_Currency],[PerOccurrenceDeductible_Amount]=S.[PerOccurrenceDeductible_Amount],[PerOccurrenceDeductible_Currency]=S.[PerOccurrenceDeductible_Currency],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AggregateAmount_Amount],[AggregateAmount_Currency],[AggregateDeductible_Amount],[AggregateDeductible_Currency],[CoverageTypeConfigId],[CreatedById],[CreatedTime],[IsActive],[IsContractAmount],[IsManual],[LoanFinanceId],[PerOccurrenceAmount_Amount],[PerOccurrenceAmount_Currency],[PerOccurrenceDeductible_Amount],[PerOccurrenceDeductible_Currency],[Status])
    VALUES (S.[AggregateAmount_Amount],S.[AggregateAmount_Currency],S.[AggregateDeductible_Amount],S.[AggregateDeductible_Currency],S.[CoverageTypeConfigId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsContractAmount],S.[IsManual],S.[LoanFinanceId],S.[PerOccurrenceAmount_Amount],S.[PerOccurrenceAmount_Currency],S.[PerOccurrenceDeductible_Amount],S.[PerOccurrenceDeductible_Currency],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
