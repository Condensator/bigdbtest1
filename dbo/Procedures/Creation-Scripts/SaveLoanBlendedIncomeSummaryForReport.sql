SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanBlendedIncomeSummaryForReport]
(
 @val [dbo].[LoanBlendedIncomeSummaryForReport] READONLY
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
MERGE [dbo].[LoanBlendedIncomeSummaryForReports] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BlendedItemCode]=S.[BlendedItemCode],[BlendedItemName]=S.[BlendedItemName],[BookRecognitionMode]=S.[BookRecognitionMode],[ContractId]=S.[ContractId],[DueDate]=S.[DueDate],[EndDate]=S.[EndDate],[Frequency]=S.[Frequency],[GeneratePayableOrReceivable]=S.[GeneratePayableOrReceivable],[IncludeInBlendedYield]=S.[IncludeInBlendedYield],[IsAccumulatedExpense]=S.[IsAccumulatedExpense],[IsFAS91]=S.[IsFAS91],[Occurrence]=S.[Occurrence],[RecognitionMethod]=S.[RecognitionMethod],[RecurringAmount_Amount]=S.[RecurringAmount_Amount],[RecurringAmount_Currency]=S.[RecurringAmount_Currency],[RecurringNumber]=S.[RecurringNumber],[StartDate]=S.[StartDate],[TaxRecognitionMode]=S.[TaxRecognitionMode],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BlendedItemCode],[BlendedItemName],[BookRecognitionMode],[ContractId],[CreatedById],[CreatedTime],[DueDate],[EndDate],[Frequency],[GeneratePayableOrReceivable],[IncludeInBlendedYield],[IsAccumulatedExpense],[IsFAS91],[Occurrence],[RecognitionMethod],[RecurringAmount_Amount],[RecurringAmount_Currency],[RecurringNumber],[StartDate],[TaxRecognitionMode],[Type])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BlendedItemCode],S.[BlendedItemName],S.[BookRecognitionMode],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[EndDate],S.[Frequency],S.[GeneratePayableOrReceivable],S.[IncludeInBlendedYield],S.[IsAccumulatedExpense],S.[IsFAS91],S.[Occurrence],S.[RecognitionMethod],S.[RecurringAmount_Amount],S.[RecurringAmount_Currency],S.[RecurringNumber],S.[StartDate],S.[TaxRecognitionMode],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
