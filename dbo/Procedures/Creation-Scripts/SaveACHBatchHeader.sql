SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHBatchHeader]
(
 @val [dbo].[ACHBatchHeader] READONLY
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
MERGE [dbo].[ACHBatchHeaders] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHBatchControlRecordTypeCode]=S.[ACHBatchControlRecordTypeCode],[ACHBatchControlServiceClassCode]=S.[ACHBatchControlServiceClassCode],[ACHBatchHeaderCompanyEntryDescription]=S.[ACHBatchHeaderCompanyEntryDescription],[ACHBatchHeaderOriginatorStatusCode]=S.[ACHBatchHeaderOriginatorStatusCode],[ACHBatchHeaderRecordTypeCode]=S.[ACHBatchHeaderRecordTypeCode],[ACHBatchHeaderServiceClassCode]=S.[ACHBatchHeaderServiceClassCode],[BatchHeaderId]=S.[BatchHeaderId],[FileHeaderId]=S.[FileHeaderId],[GenerateBalancedACH]=S.[GenerateBalancedACH],[JobStepInstanceId]=S.[JobStepInstanceId],[OrigDFIID]=S.[OrigDFIID],[Origin]=S.[Origin],[OriginName]=S.[OriginName],[PrivateLableName]=S.[PrivateLableName],[ReceiptLegalEntityBankAccountACHRoutingNumber]=S.[ReceiptLegalEntityBankAccountACHRoutingNumber],[ReceiptLegalEntityBankAccountCreditCode]=S.[ReceiptLegalEntityBankAccountCreditCode],[ReceiptLegalEntityBankAccountId]=S.[ReceiptLegalEntityBankAccountId],[ReceiptLegalEntityBankAccountNumber_CT]=S.[ReceiptLegalEntityBankAccountNumber_CT],[SEC]=S.[SEC],[Settlementdate]=S.[Settlementdate],[TaxID]=S.[TaxID],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHBatchControlRecordTypeCode],[ACHBatchControlServiceClassCode],[ACHBatchHeaderCompanyEntryDescription],[ACHBatchHeaderOriginatorStatusCode],[ACHBatchHeaderRecordTypeCode],[ACHBatchHeaderServiceClassCode],[ACHFileHeaderId],[BatchHeaderId],[CreatedById],[CreatedTime],[FileHeaderId],[GenerateBalancedACH],[JobStepInstanceId],[OrigDFIID],[Origin],[OriginName],[PrivateLableName],[ReceiptLegalEntityBankAccountACHRoutingNumber],[ReceiptLegalEntityBankAccountCreditCode],[ReceiptLegalEntityBankAccountId],[ReceiptLegalEntityBankAccountNumber_CT],[SEC],[Settlementdate],[TaxID])
    VALUES (S.[ACHBatchControlRecordTypeCode],S.[ACHBatchControlServiceClassCode],S.[ACHBatchHeaderCompanyEntryDescription],S.[ACHBatchHeaderOriginatorStatusCode],S.[ACHBatchHeaderRecordTypeCode],S.[ACHBatchHeaderServiceClassCode],S.[ACHFileHeaderId],S.[BatchHeaderId],S.[CreatedById],S.[CreatedTime],S.[FileHeaderId],S.[GenerateBalancedACH],S.[JobStepInstanceId],S.[OrigDFIID],S.[Origin],S.[OriginName],S.[PrivateLableName],S.[ReceiptLegalEntityBankAccountACHRoutingNumber],S.[ReceiptLegalEntityBankAccountCreditCode],S.[ReceiptLegalEntityBankAccountId],S.[ReceiptLegalEntityBankAccountNumber_CT],S.[SEC],S.[Settlementdate],S.[TaxID])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
