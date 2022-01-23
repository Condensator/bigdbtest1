SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanCapitalizedInterest]
(
 @val [dbo].[LoanCapitalizedInterest] READONLY
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
MERGE [dbo].[LoanCapitalizedInterests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[CapitalizedDate]=S.[CapitalizedDate],[GLJournalId]=S.[GLJournalId],[IsActive]=S.[IsActive],[PayableInvoiceOtherCostId]=S.[PayableInvoiceOtherCostId],[Source]=S.[Source],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[CapitalizedDate],[CreatedById],[CreatedTime],[GLJournalId],[IsActive],[LoanFinanceId],[PayableInvoiceOtherCostId],[Source])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[CapitalizedDate],S.[CreatedById],S.[CreatedTime],S.[GLJournalId],S.[IsActive],S.[LoanFinanceId],S.[PayableInvoiceOtherCostId],S.[Source])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
