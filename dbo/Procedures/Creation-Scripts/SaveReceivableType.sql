SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableType]
(
 @val [dbo].[ReceivableType] READONLY
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
MERGE [dbo].[ReceivableTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CashBasedAllowed]=S.[CashBasedAllowed],[EARApplicable]=S.[EARApplicable],[GLTransactionTypeId]=S.[GLTransactionTypeId],[InvoicePreferenceAllowed]=S.[InvoicePreferenceAllowed],[IsActive]=S.[IsActive],[IsRental]=S.[IsRental],[LeaseBased]=S.[LeaseBased],[LoanBased]=S.[LoanBased],[MemoAllowed]=S.[MemoAllowed],[Name]=S.[Name],[SyndicationGLTransactionTypeId]=S.[SyndicationGLTransactionTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CashBasedAllowed],[CreatedById],[CreatedTime],[EARApplicable],[GLTransactionTypeId],[InvoicePreferenceAllowed],[IsActive],[IsRental],[LeaseBased],[LoanBased],[MemoAllowed],[Name],[SyndicationGLTransactionTypeId])
    VALUES (S.[CashBasedAllowed],S.[CreatedById],S.[CreatedTime],S.[EARApplicable],S.[GLTransactionTypeId],S.[InvoicePreferenceAllowed],S.[IsActive],S.[IsRental],S.[LeaseBased],S.[LoanBased],S.[MemoAllowed],S.[Name],S.[SyndicationGLTransactionTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
