SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingAmendment]
(
 @val [dbo].[DiscountingAmendment] READONLY
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
MERGE [dbo].[DiscountingAmendments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[AdditionalLoanAmount_Amount]=S.[AdditionalLoanAmount_Amount],[AdditionalLoanAmount_Currency]=S.[AdditionalLoanAmount_Currency],[Alias]=S.[Alias],[AmendmentAtInception]=S.[AmendmentAtInception],[AmendmentDate]=S.[AmendmentDate],[AmendmentType]=S.[AmendmentType],[Comment]=S.[Comment],[DiscountingFinanceId]=S.[DiscountingFinanceId],[DiscountingRepaymentScheduleId]=S.[DiscountingRepaymentScheduleId],[OriginalDiscountingFinanceId]=S.[OriginalDiscountingFinanceId],[PostDate]=S.[PostDate],[PreRestructureLoanAmount_Amount]=S.[PreRestructureLoanAmount_Amount],[PreRestructureLoanAmount_Currency]=S.[PreRestructureLoanAmount_Currency],[PreRestructureYield]=S.[PreRestructureYield],[QuoteGoodThroughDate]=S.[QuoteGoodThroughDate],[QuoteNumber]=S.[QuoteNumber],[QuoteStatus]=S.[QuoteStatus],[RestructureAmortOption]=S.[RestructureAmortOption],[SourceId]=S.[SourceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[AdditionalLoanAmount_Amount],[AdditionalLoanAmount_Currency],[Alias],[AmendmentAtInception],[AmendmentDate],[AmendmentType],[Comment],[CreatedById],[CreatedTime],[DiscountingFinanceId],[DiscountingRepaymentScheduleId],[OriginalDiscountingFinanceId],[PostDate],[PreRestructureLoanAmount_Amount],[PreRestructureLoanAmount_Currency],[PreRestructureYield],[QuoteGoodThroughDate],[QuoteNumber],[QuoteStatus],[RestructureAmortOption],[SourceId])
    VALUES (S.[AccountingDate],S.[AdditionalLoanAmount_Amount],S.[AdditionalLoanAmount_Currency],S.[Alias],S.[AmendmentAtInception],S.[AmendmentDate],S.[AmendmentType],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DiscountingFinanceId],S.[DiscountingRepaymentScheduleId],S.[OriginalDiscountingFinanceId],S.[PostDate],S.[PreRestructureLoanAmount_Amount],S.[PreRestructureLoanAmount_Currency],S.[PreRestructureYield],S.[QuoteGoodThroughDate],S.[QuoteNumber],S.[QuoteStatus],S.[RestructureAmortOption],S.[SourceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
