SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHEntryDetail]
(
 @val [dbo].[ACHEntryDetail] READONLY
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
MERGE [dbo].[ACHEntryDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHAmount]=S.[ACHAmount],[ACHEntryDetailAddendaRecordIndicator]=S.[ACHEntryDetailAddendaRecordIndicator],[ACHEntryDetailRecordTypeCode]=S.[ACHEntryDetailRecordTypeCode],[ACHEntryDetailTransactionCode]=S.[ACHEntryDetailTransactionCode],[ACHScheduleExtractIds]=S.[ACHScheduleExtractIds],[CostCenterId]=S.[CostCenterId],[Currency]=S.[Currency],[CustomerBankAccountACHRoutingNumber]=S.[CustomerBankAccountACHRoutingNumber],[CustomerBankAccountId]=S.[CustomerBankAccountId],[CustomerBankAccountNumber_CT]=S.[CustomerBankAccountNumber_CT],[CustomerBankDebitCode]=S.[CustomerBankDebitCode],[EntityId]=S.[EntityId],[EntryDetailId]=S.[EntryDetailId],[JobStepInstanceId]=S.[JobStepInstanceId],[OrigDFIID]=S.[OrigDFIID],[PAPEntryDetailClientShortName]=S.[PAPEntryDetailClientShortName],[PAPEntryDetailDestinationCountry]=S.[PAPEntryDetailDestinationCountry],[PAPEntryDetailLanguageCode]=S.[PAPEntryDetailLanguageCode],[PAPEntryDetailOptionalRecordIndicator]=S.[PAPEntryDetailOptionalRecordIndicator],[PAPEntryDetailPaymentNumber]=S.[PAPEntryDetailPaymentNumber],[PAPEntryDetailRecordTypeCode]=S.[PAPEntryDetailRecordTypeCode],[PartyName]=S.[PartyName],[TraceNumber]=S.[TraceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHAmount],[ACHBatchHeaderId],[ACHEntryDetailAddendaRecordIndicator],[ACHEntryDetailRecordTypeCode],[ACHEntryDetailTransactionCode],[ACHScheduleExtractIds],[CostCenterId],[CreatedById],[CreatedTime],[Currency],[CustomerBankAccountACHRoutingNumber],[CustomerBankAccountId],[CustomerBankAccountNumber_CT],[CustomerBankDebitCode],[EntityId],[EntryDetailId],[JobStepInstanceId],[OrigDFIID],[PAPEntryDetailClientShortName],[PAPEntryDetailDestinationCountry],[PAPEntryDetailLanguageCode],[PAPEntryDetailOptionalRecordIndicator],[PAPEntryDetailPaymentNumber],[PAPEntryDetailRecordTypeCode],[PartyName],[TraceNumber])
    VALUES (S.[ACHAmount],S.[ACHBatchHeaderId],S.[ACHEntryDetailAddendaRecordIndicator],S.[ACHEntryDetailRecordTypeCode],S.[ACHEntryDetailTransactionCode],S.[ACHScheduleExtractIds],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[Currency],S.[CustomerBankAccountACHRoutingNumber],S.[CustomerBankAccountId],S.[CustomerBankAccountNumber_CT],S.[CustomerBankDebitCode],S.[EntityId],S.[EntryDetailId],S.[JobStepInstanceId],S.[OrigDFIID],S.[PAPEntryDetailClientShortName],S.[PAPEntryDetailDestinationCountry],S.[PAPEntryDetailLanguageCode],S.[PAPEntryDetailOptionalRecordIndicator],S.[PAPEntryDetailPaymentNumber],S.[PAPEntryDetailRecordTypeCode],S.[PartyName],S.[TraceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
