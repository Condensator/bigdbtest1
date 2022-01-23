SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownSundry]
(
 @val [dbo].[LoanPaydownSundry] READONLY
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
MERGE [dbo].[LoanPaydownSundries] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillToId]=S.[BillToId],[Description]=S.[Description],[DueDate]=S.[DueDate],[IncludeInPaydownInvoice]=S.[IncludeInPaydownInvoice],[IsActive]=S.[IsActive],[IsForSuggestedPaydownAmount]=S.[IsForSuggestedPaydownAmount],[IsPenalty]=S.[IsPenalty],[IsSystemGenerated]=S.[IsSystemGenerated],[LocationId]=S.[LocationId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[RemitToId]=S.[RemitToId],[SundryId]=S.[SundryId],[SundryPayableCodeId]=S.[SundryPayableCodeId],[SundryReceivableCodeId]=S.[SundryReceivableCodeId],[SundryType]=S.[SundryType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillToId],[CreatedById],[CreatedTime],[Description],[DueDate],[IncludeInPaydownInvoice],[IsActive],[IsForSuggestedPaydownAmount],[IsPenalty],[IsSystemGenerated],[LoanPaydownId],[LocationId],[PayableWithholdingTaxRate],[RemitToId],[SundryId],[SundryPayableCodeId],[SundryReceivableCodeId],[SundryType],[VendorId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillToId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[DueDate],S.[IncludeInPaydownInvoice],S.[IsActive],S.[IsForSuggestedPaydownAmount],S.[IsPenalty],S.[IsSystemGenerated],S.[LoanPaydownId],S.[LocationId],S.[PayableWithholdingTaxRate],S.[RemitToId],S.[SundryId],S.[SundryPayableCodeId],S.[SundryReceivableCodeId],S.[SundryType],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
