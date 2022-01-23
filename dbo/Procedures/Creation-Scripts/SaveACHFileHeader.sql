SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHFileHeader]
(
 @val [dbo].[ACHFileHeader] READONLY
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
MERGE [dbo].[ACHFileHeaders] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHFileControlRecordTypeCode]=S.[ACHFileControlRecordTypeCode],[ACHFileHeaderBlockingFactor]=S.[ACHFileHeaderBlockingFactor],[ACHFileHeaderFileIDModifier]=S.[ACHFileHeaderFileIDModifier],[ACHFileHeaderFormatCode]=S.[ACHFileHeaderFormatCode],[ACHFileHeaderPriorityCode]=S.[ACHFileHeaderPriorityCode],[ACHFileHeaderRecordSize]=S.[ACHFileHeaderRecordSize],[ACHFileHeaderRecordTypeCode]=S.[ACHFileHeaderRecordTypeCode],[ACHOperatorConfigId]=S.[ACHOperatorConfigId],[ACHRunFileId]=S.[ACHRunFileId],[ACISCustomerNumber]=S.[ACISCustomerNumber],[BankBranchName]=S.[BankBranchName],[CurrencyId]=S.[CurrencyId],[CurrencyName]=S.[CurrencyName],[CurrenySymbol]=S.[CurrenySymbol],[Destination]=S.[Destination],[DestName]=S.[DestName],[FileFormat]=S.[FileFormat],[FileHeaderId]=S.[FileHeaderId],[GenerateControlFile]=S.[GenerateControlFile],[GenerateSeparateOneTimeACH]=S.[GenerateSeparateOneTimeACH],[IsPrivateLabel]=S.[IsPrivateLabel],[JobStepInstanceId]=S.[JobStepInstanceId],[LegalEntityBankAccountId]=S.[LegalEntityBankAccountId],[LegalEntityNumber]=S.[LegalEntityNumber],[NACHAFilePaddingOption]=S.[NACHAFilePaddingOption],[Origin]=S.[Origin],[OriginName]=S.[OriginName],[PAPFileControlRecordTypeCode]=S.[PAPFileControlRecordTypeCode],[PAPFileControlTransactionCode]=S.[PAPFileControlTransactionCode],[PAPFileHeaderInputType]=S.[PAPFileHeaderInputType],[PAPFileHeaderRecordTypeCode]=S.[PAPFileHeaderRecordTypeCode],[PAPFileHeaderTransactionCode]=S.[PAPFileHeaderTransactionCode],[RemitToId]=S.[RemitToId],[RemitToName]=S.[RemitToName],[SourceOfInput]=S.[SourceOfInput],[TotalDebitAmount]=S.[TotalDebitAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHFileControlRecordTypeCode],[ACHFileHeaderBlockingFactor],[ACHFileHeaderFileIDModifier],[ACHFileHeaderFormatCode],[ACHFileHeaderPriorityCode],[ACHFileHeaderRecordSize],[ACHFileHeaderRecordTypeCode],[ACHOperatorConfigId],[ACHRunFileId],[ACISCustomerNumber],[BankBranchName],[CreatedById],[CreatedTime],[CurrencyId],[CurrencyName],[CurrenySymbol],[Destination],[DestName],[FileFormat],[FileHeaderId],[GenerateControlFile],[GenerateSeparateOneTimeACH],[IsPrivateLabel],[JobStepInstanceId],[LegalEntityBankAccountId],[LegalEntityNumber],[NACHAFilePaddingOption],[Origin],[OriginName],[PAPFileControlRecordTypeCode],[PAPFileControlTransactionCode],[PAPFileHeaderInputType],[PAPFileHeaderRecordTypeCode],[PAPFileHeaderTransactionCode],[RemitToId],[RemitToName],[SourceOfInput],[TotalDebitAmount])
    VALUES (S.[ACHFileControlRecordTypeCode],S.[ACHFileHeaderBlockingFactor],S.[ACHFileHeaderFileIDModifier],S.[ACHFileHeaderFormatCode],S.[ACHFileHeaderPriorityCode],S.[ACHFileHeaderRecordSize],S.[ACHFileHeaderRecordTypeCode],S.[ACHOperatorConfigId],S.[ACHRunFileId],S.[ACISCustomerNumber],S.[BankBranchName],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CurrencyName],S.[CurrenySymbol],S.[Destination],S.[DestName],S.[FileFormat],S.[FileHeaderId],S.[GenerateControlFile],S.[GenerateSeparateOneTimeACH],S.[IsPrivateLabel],S.[JobStepInstanceId],S.[LegalEntityBankAccountId],S.[LegalEntityNumber],S.[NACHAFilePaddingOption],S.[Origin],S.[OriginName],S.[PAPFileControlRecordTypeCode],S.[PAPFileControlTransactionCode],S.[PAPFileHeaderInputType],S.[PAPFileHeaderRecordTypeCode],S.[PAPFileHeaderTransactionCode],S.[RemitToId],S.[RemitToName],S.[SourceOfInput],S.[TotalDebitAmount])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
