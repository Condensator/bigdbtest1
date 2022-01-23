SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHReceiptApplicationReceivableDetail]
(
 @val [dbo].[ACHReceiptApplicationReceivableDetail] READONLY
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
MERGE [dbo].[ACHReceiptApplicationReceivableDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHReceiptId]=S.[ACHReceiptId],[AmountApplied]=S.[AmountApplied],[BookAmountApplied]=S.[BookAmountApplied],[ContractId]=S.[ContractId],[DiscountingId]=S.[DiscountingId],[InvoiceId]=S.[InvoiceId],[IsActive]=S.[IsActive],[LeaseComponentAmountApplied]=S.[LeaseComponentAmountApplied],[NonLeaseComponentAmountApplied]=S.[NonLeaseComponentAmountApplied],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableId]=S.[ReceivableId],[ScheduleId]=S.[ScheduleId],[TaxApplied]=S.[TaxApplied],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHReceiptId],[AmountApplied],[BookAmountApplied],[ContractId],[CreatedById],[CreatedTime],[DiscountingId],[InvoiceId],[IsActive],[LeaseComponentAmountApplied],[NonLeaseComponentAmountApplied],[ReceivableDetailId],[ReceivableId],[ScheduleId],[TaxApplied])
    VALUES (S.[ACHReceiptId],S.[AmountApplied],S.[BookAmountApplied],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingId],S.[InvoiceId],S.[IsActive],S.[LeaseComponentAmountApplied],S.[NonLeaseComponentAmountApplied],S.[ReceivableDetailId],S.[ReceivableId],S.[ScheduleId],S.[TaxApplied])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
