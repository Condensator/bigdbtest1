SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanAmendmentPaymentSchedule]
(
 @val [dbo].[LoanAmendmentPaymentSchedule] READONLY
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
MERGE [dbo].[LoanAmendmentPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccrualEndDate]=S.[AccrualEndDate],[Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BeginBalance_Amount]=S.[BeginBalance_Amount],[BeginBalance_Currency]=S.[BeginBalance_Currency],[Calculate]=S.[Calculate],[DueDate]=S.[DueDate],[EndBalance_Amount]=S.[EndBalance_Amount],[EndBalance_Currency]=S.[EndBalance_Currency],[EndDate]=S.[EndDate],[Interest_Amount]=S.[Interest_Amount],[Interest_Currency]=S.[Interest_Currency],[IsActive]=S.[IsActive],[IsFromReceiptPosting]=S.[IsFromReceiptPosting],[PaymentNumber]=S.[PaymentNumber],[PaymentStructure]=S.[PaymentStructure],[PaymentType]=S.[PaymentType],[Principal_Amount]=S.[Principal_Amount],[Principal_Currency]=S.[Principal_Currency],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccrualEndDate],[Amount_Amount],[Amount_Currency],[BeginBalance_Amount],[BeginBalance_Currency],[Calculate],[CreatedById],[CreatedTime],[DueDate],[EndBalance_Amount],[EndBalance_Currency],[EndDate],[Interest_Amount],[Interest_Currency],[IsActive],[IsFromReceiptPosting],[LoanAmendmentId],[PaymentNumber],[PaymentStructure],[PaymentType],[Principal_Amount],[Principal_Currency],[StartDate])
    VALUES (S.[AccrualEndDate],S.[Amount_Amount],S.[Amount_Currency],S.[BeginBalance_Amount],S.[BeginBalance_Currency],S.[Calculate],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[EndBalance_Amount],S.[EndBalance_Currency],S.[EndDate],S.[Interest_Amount],S.[Interest_Currency],S.[IsActive],S.[IsFromReceiptPosting],S.[LoanAmendmentId],S.[PaymentNumber],S.[PaymentStructure],S.[PaymentType],S.[Principal_Amount],S.[Principal_Currency],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
