SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanPaydownPaymentSchedule]
(
 @val [dbo].[LoanPaydownPaymentSchedule] READONLY
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
MERGE [dbo].[LoanPaydownPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BeginBalance_Amount]=S.[BeginBalance_Amount],[BeginBalance_Currency]=S.[BeginBalance_Currency],[Calculate]=S.[Calculate],[CalculatedAmount_Amount]=S.[CalculatedAmount_Amount],[CalculatedAmount_Currency]=S.[CalculatedAmount_Currency],[DueDate]=S.[DueDate],[EndBalance_Amount]=S.[EndBalance_Amount],[EndBalance_Currency]=S.[EndBalance_Currency],[EndDate]=S.[EndDate],[FloatRateAdjustment_Amount]=S.[FloatRateAdjustment_Amount],[FloatRateAdjustment_Currency]=S.[FloatRateAdjustment_Currency],[Interest_Amount]=S.[Interest_Amount],[Interest_Currency]=S.[Interest_Currency],[IsActive]=S.[IsActive],[IsFromReceiptPosting]=S.[IsFromReceiptPosting],[IsSystemGenerated]=S.[IsSystemGenerated],[PaymentNumber]=S.[PaymentNumber],[PaymentStructure]=S.[PaymentStructure],[PaymentType]=S.[PaymentType],[Principal_Amount]=S.[Principal_Amount],[Principal_Currency]=S.[Principal_Currency],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BeginBalance_Amount],[BeginBalance_Currency],[Calculate],[CalculatedAmount_Amount],[CalculatedAmount_Currency],[CreatedById],[CreatedTime],[DueDate],[EndBalance_Amount],[EndBalance_Currency],[EndDate],[FloatRateAdjustment_Amount],[FloatRateAdjustment_Currency],[Interest_Amount],[Interest_Currency],[IsActive],[IsFromReceiptPosting],[IsSystemGenerated],[LoanPaydownId],[PaymentNumber],[PaymentStructure],[PaymentType],[Principal_Amount],[Principal_Currency],[StartDate])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BeginBalance_Amount],S.[BeginBalance_Currency],S.[Calculate],S.[CalculatedAmount_Amount],S.[CalculatedAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[EndBalance_Amount],S.[EndBalance_Currency],S.[EndDate],S.[FloatRateAdjustment_Amount],S.[FloatRateAdjustment_Currency],S.[Interest_Amount],S.[Interest_Currency],S.[IsActive],S.[IsFromReceiptPosting],S.[IsSystemGenerated],S.[LoanPaydownId],S.[PaymentNumber],S.[PaymentStructure],S.[PaymentType],S.[Principal_Amount],S.[Principal_Currency],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
