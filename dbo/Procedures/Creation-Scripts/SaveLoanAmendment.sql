SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanAmendment]
(
 @val [dbo].[LoanAmendment] READONLY
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
MERGE [dbo].[LoanAmendments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[AmendmentAtInception]=S.[AmendmentAtInception],[AmendmentDate]=S.[AmendmentDate],[AmendmentReasonComment]=S.[AmendmentReasonComment],[AmendmentReasonId]=S.[AmendmentReasonId],[AmendmentType]=S.[AmendmentType],[Comment]=S.[Comment],[DealProductTypeId]=S.[DealProductTypeId],[DealTypeId]=S.[DealTypeId],[FinalAcceptanceDate]=S.[FinalAcceptanceDate],[IsLienFilingException]=S.[IsLienFilingException],[IsLienFilingRequired]=S.[IsLienFilingRequired],[IsModified]=S.[IsModified],[IsRestructureDateConfirmed]=S.[IsRestructureDateConfirmed],[IsTDR]=S.[IsTDR],[LienExceptionComment]=S.[LienExceptionComment],[LienExceptionReason]=S.[LienExceptionReason],[LoanFinanceId]=S.[LoanFinanceId],[LoanPaymentScheduleId]=S.[LoanPaymentScheduleId],[NetWritedown_Amount]=S.[NetWritedown_Amount],[NetWritedown_Currency]=S.[NetWritedown_Currency],[PostDate]=S.[PostDate],[PostRestructureDateLoanNBV_Amount]=S.[PostRestructureDateLoanNBV_Amount],[PostRestructureDateLoanNBV_Currency]=S.[PostRestructureDateLoanNBV_Currency],[PostRestructureFAS91Balance_Amount]=S.[PostRestructureFAS91Balance_Amount],[PostRestructureFAS91Balance_Currency]=S.[PostRestructureFAS91Balance_Currency],[PreRestructureDateLoanNBV_Amount]=S.[PreRestructureDateLoanNBV_Amount],[PreRestructureDateLoanNBV_Currency]=S.[PreRestructureDateLoanNBV_Currency],[PreRestructureFAS91Balance_Amount]=S.[PreRestructureFAS91Balance_Amount],[PreRestructureFAS91Balance_Currency]=S.[PreRestructureFAS91Balance_Currency],[QuoteGoodThroughDate]=S.[QuoteGoodThroughDate],[QuoteName]=S.[QuoteName],[QuoteStatus]=S.[QuoteStatus],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[SourceId]=S.[SourceId],[TDRReason]=S.[TDRReason],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[AmendmentAtInception],[AmendmentDate],[AmendmentReasonComment],[AmendmentReasonId],[AmendmentType],[Comment],[CreatedById],[CreatedTime],[DealProductTypeId],[DealTypeId],[FinalAcceptanceDate],[IsLienFilingException],[IsLienFilingRequired],[IsModified],[IsRestructureDateConfirmed],[IsTDR],[LienExceptionComment],[LienExceptionReason],[LoanFinanceId],[LoanPaymentScheduleId],[NetWritedown_Amount],[NetWritedown_Currency],[PostDate],[PostRestructureDateLoanNBV_Amount],[PostRestructureDateLoanNBV_Currency],[PostRestructureFAS91Balance_Amount],[PostRestructureFAS91Balance_Currency],[PreRestructureDateLoanNBV_Amount],[PreRestructureDateLoanNBV_Currency],[PreRestructureFAS91Balance_Amount],[PreRestructureFAS91Balance_Currency],[QuoteGoodThroughDate],[QuoteName],[QuoteStatus],[ReceivableAmendmentType],[SourceId],[TDRReason])
    VALUES (S.[AccountingDate],S.[AmendmentAtInception],S.[AmendmentDate],S.[AmendmentReasonComment],S.[AmendmentReasonId],S.[AmendmentType],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DealProductTypeId],S.[DealTypeId],S.[FinalAcceptanceDate],S.[IsLienFilingException],S.[IsLienFilingRequired],S.[IsModified],S.[IsRestructureDateConfirmed],S.[IsTDR],S.[LienExceptionComment],S.[LienExceptionReason],S.[LoanFinanceId],S.[LoanPaymentScheduleId],S.[NetWritedown_Amount],S.[NetWritedown_Currency],S.[PostDate],S.[PostRestructureDateLoanNBV_Amount],S.[PostRestructureDateLoanNBV_Currency],S.[PostRestructureFAS91Balance_Amount],S.[PostRestructureFAS91Balance_Currency],S.[PreRestructureDateLoanNBV_Amount],S.[PreRestructureDateLoanNBV_Currency],S.[PreRestructureFAS91Balance_Amount],S.[PreRestructureFAS91Balance_Currency],S.[QuoteGoodThroughDate],S.[QuoteName],S.[QuoteStatus],S.[ReceivableAmendmentType],S.[SourceId],S.[TDRReason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
