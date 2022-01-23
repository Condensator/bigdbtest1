SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHReceiptJobLog]
(
 @val [dbo].[ACHReceiptJobLog] READONLY
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
MERGE [dbo].[ACHReceiptJobLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHReceiptId]=S.[ACHReceiptId],[ACHRunId]=S.[ACHRunId],[ACHScheduleId]=S.[ACHScheduleId],[CostCenter]=S.[CostCenter],[ErrorCode]=S.[ErrorCode],[InvoiceNumber]=S.[InvoiceNumber],[JobstepInstanceId]=S.[JobstepInstanceId],[LegalEntityNumber]=S.[LegalEntityNumber],[LineofBusinessName]=S.[LineofBusinessName],[OneTimeACHId]=S.[OneTimeACHId],[PaymentNumber]=S.[PaymentNumber],[ReceiptNumber]=S.[ReceiptNumber],[ReceivableId]=S.[ReceivableId],[ReceivedDate]=S.[ReceivedDate],[SequenceNumber]=S.[SequenceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHReceiptId],[ACHRunId],[ACHScheduleId],[CostCenter],[CreatedById],[CreatedTime],[ErrorCode],[InvoiceNumber],[JobstepInstanceId],[LegalEntityNumber],[LineofBusinessName],[OneTimeACHId],[PaymentNumber],[ReceiptNumber],[ReceivableId],[ReceivedDate],[SequenceNumber])
    VALUES (S.[ACHReceiptId],S.[ACHRunId],S.[ACHScheduleId],S.[CostCenter],S.[CreatedById],S.[CreatedTime],S.[ErrorCode],S.[InvoiceNumber],S.[JobstepInstanceId],S.[LegalEntityNumber],S.[LineofBusinessName],S.[OneTimeACHId],S.[PaymentNumber],S.[ReceiptNumber],S.[ReceivableId],S.[ReceivedDate],S.[SequenceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
