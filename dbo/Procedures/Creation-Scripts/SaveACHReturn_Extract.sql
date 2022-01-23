SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHReturn_Extract]
(
 @val [dbo].[ACHReturn_Extract] READONLY
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
MERGE [dbo].[ACHReturn_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountOnHoldCount]=S.[AccountOnHoldCount],[ACHRunDetailId]=S.[ACHRunDetailId],[ACHRunFileId]=S.[ACHRunFileId],[ACHRunId]=S.[ACHRunId],[ACHScheduleId]=S.[ACHScheduleId],[ContractId]=S.[ContractId],[CurrentACHFailureCount]=S.[CurrentACHFailureCount],[CurrentOnHoldStatus]=S.[CurrentOnHoldStatus],[CustomerBankAccountId]=S.[CustomerBankAccountId],[EntityType]=S.[EntityType],[EntryDetailLineNumber]=S.[EntryDetailLineNumber],[FileName]=S.[FileName],[GUID]=S.[GUID],[IsNSFChargeEligible]=S.[IsNSFChargeEligible],[IsOneTimeACH]=S.[IsOneTimeACH],[IsPending]=S.[IsPending],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityACHFailureLimit]=S.[LegalEntityACHFailureLimit],[LegalEntityId]=S.[LegalEntityId],[NSFBillToId]=S.[NSFBillToId],[NSFCustomerId]=S.[NSFCustomerId],[NSFLocationId]=S.[NSFLocationId],[OneTimeACHId]=S.[OneTimeACHId],[ReACH]=S.[ReACH],[ReasonCode]=S.[ReasonCode],[ReceiptAmount_Amount]=S.[ReceiptAmount_Amount],[ReceiptAmount_Currency]=S.[ReceiptAmount_Currency],[ReceiptClassification]=S.[ReceiptClassification],[ReceiptId]=S.[ReceiptId],[ReceiptNumber]=S.[ReceiptNumber],[ReceivedDate]=S.[ReceivedDate],[ReturnFileReceiptAmount_Amount]=S.[ReturnFileReceiptAmount_Amount],[ReturnFileReceiptAmount_Currency]=S.[ReturnFileReceiptAmount_Currency],[ReturnReasonCodeLineNumber]=S.[ReturnReasonCodeLineNumber],[Status]=S.[Status],[TraceNumber]=S.[TraceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountOnHoldCount],[ACHRunDetailId],[ACHRunFileId],[ACHRunId],[ACHScheduleId],[ContractId],[CreatedById],[CreatedTime],[CurrentACHFailureCount],[CurrentOnHoldStatus],[CustomerBankAccountId],[EntityType],[EntryDetailLineNumber],[FileName],[GUID],[IsNSFChargeEligible],[IsOneTimeACH],[IsPending],[JobStepInstanceId],[LegalEntityACHFailureLimit],[LegalEntityId],[NSFBillToId],[NSFCustomerId],[NSFLocationId],[OneTimeACHId],[ReACH],[ReasonCode],[ReceiptAmount_Amount],[ReceiptAmount_Currency],[ReceiptClassification],[ReceiptId],[ReceiptNumber],[ReceivedDate],[ReturnFileReceiptAmount_Amount],[ReturnFileReceiptAmount_Currency],[ReturnReasonCodeLineNumber],[Status],[TraceNumber])
    VALUES (S.[AccountOnHoldCount],S.[ACHRunDetailId],S.[ACHRunFileId],S.[ACHRunId],S.[ACHScheduleId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CurrentACHFailureCount],S.[CurrentOnHoldStatus],S.[CustomerBankAccountId],S.[EntityType],S.[EntryDetailLineNumber],S.[FileName],S.[GUID],S.[IsNSFChargeEligible],S.[IsOneTimeACH],S.[IsPending],S.[JobStepInstanceId],S.[LegalEntityACHFailureLimit],S.[LegalEntityId],S.[NSFBillToId],S.[NSFCustomerId],S.[NSFLocationId],S.[OneTimeACHId],S.[ReACH],S.[ReasonCode],S.[ReceiptAmount_Amount],S.[ReceiptAmount_Currency],S.[ReceiptClassification],S.[ReceiptId],S.[ReceiptNumber],S.[ReceivedDate],S.[ReturnFileReceiptAmount_Amount],S.[ReturnFileReceiptAmount_Currency],S.[ReturnReasonCodeLineNumber],S.[Status],S.[TraceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
