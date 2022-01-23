SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanSyndication]
(
 @val [dbo].[LoanSyndication] READONLY
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
MERGE [dbo].[LoanSyndications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FundedAmount_Amount]=S.[FundedAmount_Amount],[FundedAmount_Currency]=S.[FundedAmount_Currency],[FundingDate]=S.[FundingDate],[IsActive]=S.[IsActive],[LoanPaydownGLTemplateId]=S.[LoanPaydownGLTemplateId],[ProgressPaymentReimbursementCodeId]=S.[ProgressPaymentReimbursementCodeId],[RentalProceedsPayableCodeId]=S.[RentalProceedsPayableCodeId],[RentalProceedsWithholdingTaxRate]=S.[RentalProceedsWithholdingTaxRate],[RetainedPercentage]=S.[RetainedPercentage],[ScrapeReceivableCodeId]=S.[ScrapeReceivableCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontSyndicationFeeCodeId]=S.[UpfrontSyndicationFeeCodeId]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[FundedAmount_Amount],[FundedAmount_Currency],[FundingDate],[Id],[IsActive],[LoanPaydownGLTemplateId],[ProgressPaymentReimbursementCodeId],[RentalProceedsPayableCodeId],[RentalProceedsWithholdingTaxRate],[RetainedPercentage],[ScrapeReceivableCodeId],[UpfrontSyndicationFeeCodeId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[FundedAmount_Amount],S.[FundedAmount_Currency],S.[FundingDate],S.[Id],S.[IsActive],S.[LoanPaydownGLTemplateId],S.[ProgressPaymentReimbursementCodeId],S.[RentalProceedsPayableCodeId],S.[RentalProceedsWithholdingTaxRate],S.[RetainedPercentage],S.[ScrapeReceivableCodeId],S.[UpfrontSyndicationFeeCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
