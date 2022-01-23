SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptLateFeeReversalDetails_Extract]
(
 @val [dbo].[ReceiptLateFeeReversalDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptLateFeeReversalDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssessedTillDate]=S.[AssessedTillDate],[AssessmentId]=S.[AssessmentId],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[CurrencyCode]=S.[CurrencyCode],[InvoiceId]=S.[InvoiceId],[InvoiceNumbers]=S.[InvoiceNumbers],[JobStepInstanceId]=S.[JobStepInstanceId],[LateFeeReceivableId]=S.[LateFeeReceivableId],[ReceiptId]=S.[ReceiptId],[ReceiptNumbers]=S.[ReceiptNumbers],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[ReceivableId]=S.[ReceivableId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssessedTillDate],[AssessmentId],[ContractId],[ContractType],[CreatedById],[CreatedTime],[CurrencyCode],[InvoiceId],[InvoiceNumbers],[JobStepInstanceId],[LateFeeReceivableId],[ReceiptId],[ReceiptNumbers],[ReceivableAmendmentType],[ReceivableId])
    VALUES (S.[AssessedTillDate],S.[AssessmentId],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[CurrencyCode],S.[InvoiceId],S.[InvoiceNumbers],S.[JobStepInstanceId],S.[LateFeeReceivableId],S.[ReceiptId],S.[ReceiptNumbers],S.[ReceivableAmendmentType],S.[ReceivableId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
