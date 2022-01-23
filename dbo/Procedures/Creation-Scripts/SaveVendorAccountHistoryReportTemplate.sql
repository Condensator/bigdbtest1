SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorAccountHistoryReportTemplate]
(
 @val [dbo].[VendorAccountHistoryReportTemplate] READONLY
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
MERGE [dbo].[VendorAccountHistoryReportTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountDue_Amount]=S.[AmountDue_Amount],[AmountDue_Currency]=S.[AmountDue_Currency],[AmountPaid_Amount]=S.[AmountPaid_Amount],[AmountPaid_Currency]=S.[AmountPaid_Currency],[Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[CommencementDate]=S.[CommencementDate],[CommencementDateOptions]=S.[CommencementDateOptions],[CommencementRunDate]=S.[CommencementRunDate],[CommencementUpThrough]=S.[CommencementUpThrough],[ContractCurrency]=S.[ContractCurrency],[ContractFilterOption]=S.[ContractFilterOption],[CustomerId]=S.[CustomerId],[DealerOrDistributerId]=S.[DealerOrDistributerId],[DueDate]=S.[DueDate],[FromCommencementDate]=S.[FromCommencementDate],[FromMaturityDate]=S.[FromMaturityDate],[FromSequenceNumberId]=S.[FromSequenceNumberId],[InvoiceNumber]=S.[InvoiceNumber],[MaturityDate]=S.[MaturityDate],[MaturityDateOptions]=S.[MaturityDateOptions],[MaturityTillDate]=S.[MaturityTillDate],[MaturityTillXDaysFromRunDate]=S.[MaturityTillXDaysFromRunDate],[Name]=S.[Name],[OrderBy]=S.[OrderBy],[PaymentDate]=S.[PaymentDate],[PaymentFrequency]=S.[PaymentFrequency],[ProgramVendorId]=S.[ProgramVendorId],[SequenceNumber]=S.[SequenceNumber],[TaxAmount_Amount]=S.[TaxAmount_Amount],[TaxAmount_Currency]=S.[TaxAmount_Currency],[TaxAssessed_Amount]=S.[TaxAssessed_Amount],[TaxAssessed_Currency]=S.[TaxAssessed_Currency],[TaxBalance_Amount]=S.[TaxBalance_Amount],[TaxBalance_Currency]=S.[TaxBalance_Currency],[TaxPaid_Amount]=S.[TaxPaid_Amount],[TaxPaid_Currency]=S.[TaxPaid_Currency],[Term]=S.[Term],[ToCommencementDate]=S.[ToCommencementDate],[ToMaturityDate]=S.[ToMaturityDate],[ToSequenceNumberId]=S.[ToSequenceNumberId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AmountDue_Amount],[AmountDue_Currency],[AmountPaid_Amount],[AmountPaid_Currency],[Balance_Amount],[Balance_Currency],[CommencementDate],[CommencementDateOptions],[CommencementRunDate],[CommencementUpThrough],[ContractCurrency],[ContractFilterOption],[CreatedById],[CreatedTime],[CustomerId],[DealerOrDistributerId],[DueDate],[FromCommencementDate],[FromMaturityDate],[FromSequenceNumberId],[Id],[InvoiceNumber],[MaturityDate],[MaturityDateOptions],[MaturityTillDate],[MaturityTillXDaysFromRunDate],[Name],[OrderBy],[PaymentDate],[PaymentFrequency],[ProgramVendorId],[SequenceNumber],[TaxAmount_Amount],[TaxAmount_Currency],[TaxAssessed_Amount],[TaxAssessed_Currency],[TaxBalance_Amount],[TaxBalance_Currency],[TaxPaid_Amount],[TaxPaid_Currency],[Term],[ToCommencementDate],[ToMaturityDate],[ToSequenceNumberId],[UserId],[VendorId])
    VALUES (S.[AmountDue_Amount],S.[AmountDue_Currency],S.[AmountPaid_Amount],S.[AmountPaid_Currency],S.[Balance_Amount],S.[Balance_Currency],S.[CommencementDate],S.[CommencementDateOptions],S.[CommencementRunDate],S.[CommencementUpThrough],S.[ContractCurrency],S.[ContractFilterOption],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DealerOrDistributerId],S.[DueDate],S.[FromCommencementDate],S.[FromMaturityDate],S.[FromSequenceNumberId],S.[Id],S.[InvoiceNumber],S.[MaturityDate],S.[MaturityDateOptions],S.[MaturityTillDate],S.[MaturityTillXDaysFromRunDate],S.[Name],S.[OrderBy],S.[PaymentDate],S.[PaymentFrequency],S.[ProgramVendorId],S.[SequenceNumber],S.[TaxAmount_Amount],S.[TaxAmount_Currency],S.[TaxAssessed_Amount],S.[TaxAssessed_Currency],S.[TaxBalance_Amount],S.[TaxBalance_Currency],S.[TaxPaid_Amount],S.[TaxPaid_Currency],S.[Term],S.[ToCommencementDate],S.[ToMaturityDate],S.[ToSequenceNumberId],S.[UserId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
