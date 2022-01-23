SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSundryRecurringPaymentSchedule]
(
 @val [dbo].[SundryRecurringPaymentSchedule] READONLY
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
MERGE [dbo].[SundryRecurringPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[BillPastEndDate]=S.[BillPastEndDate],[DueDate]=S.[DueDate],[IsActive]=S.[IsActive],[Number]=S.[Number],[PayableAmount_Amount]=S.[PayableAmount_Amount],[PayableAmount_Currency]=S.[PayableAmount_Currency],[PayableId]=S.[PayableId],[ProjectedVATAmount_Amount]=S.[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency]=S.[ProjectedVATAmount_Currency],[ReceivableId]=S.[ReceivableId],[SourceId]=S.[SourceId],[SourceModule]=S.[SourceModule],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[BillPastEndDate],[CreatedById],[CreatedTime],[DueDate],[IsActive],[Number],[PayableAmount_Amount],[PayableAmount_Currency],[PayableId],[ProjectedVATAmount_Amount],[ProjectedVATAmount_Currency],[ReceivableId],[SourceId],[SourceModule],[SundryRecurringId])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[BillPastEndDate],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[IsActive],S.[Number],S.[PayableAmount_Amount],S.[PayableAmount_Currency],S.[PayableId],S.[ProjectedVATAmount_Amount],S.[ProjectedVATAmount_Currency],S.[ReceivableId],S.[SourceId],S.[SourceModule],S.[SundryRecurringId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
