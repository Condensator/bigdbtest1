SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWriteDown]
(
 @val [dbo].[WriteDown] READONLY
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
MERGE [dbo].[WriteDowns] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Comment]=S.[Comment],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[GLTemplateId]=S.[GLTemplateId],[GrossWritedown_Amount]=S.[GrossWritedown_Amount],[GrossWritedown_Currency]=S.[GrossWritedown_Currency],[IsActive]=S.[IsActive],[IsAssetWriteDown]=S.[IsAssetWriteDown],[IsRecovery]=S.[IsRecovery],[LeaseFinanceId]=S.[LeaseFinanceId],[LoanFinanceId]=S.[LoanFinanceId],[NetInvestmentWithBlended_Amount]=S.[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency]=S.[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount]=S.[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency]=S.[NetInvestmentWithReserve_Currency],[NetWritedown_Amount]=S.[NetWritedown_Amount],[NetWritedown_Currency]=S.[NetWritedown_Currency],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[RecoveryGLTemplateId]=S.[RecoveryGLTemplateId],[RecoveryReceivableCodeId]=S.[RecoveryReceivableCodeId],[SourceId]=S.[SourceId],[SourceModule]=S.[SourceModule],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WriteDownAmount_Amount]=S.[WriteDownAmount_Amount],[WriteDownAmount_Currency]=S.[WriteDownAmount_Currency],[WriteDownDate]=S.[WriteDownDate],[WriteDownGLJournalId]=S.[WriteDownGLJournalId],[WriteDownReason]=S.[WriteDownReason]
WHEN NOT MATCHED THEN
	INSERT ([Comment],[ContractId],[ContractType],[CreatedById],[CreatedTime],[GLTemplateId],[GrossWritedown_Amount],[GrossWritedown_Currency],[IsActive],[IsAssetWriteDown],[IsRecovery],[LeaseFinanceId],[LoanFinanceId],[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency],[NetWritedown_Amount],[NetWritedown_Currency],[PostDate],[ReceiptId],[RecoveryGLTemplateId],[RecoveryReceivableCodeId],[SourceId],[SourceModule],[Status],[WriteDownAmount_Amount],[WriteDownAmount_Currency],[WriteDownDate],[WriteDownGLJournalId],[WriteDownReason])
    VALUES (S.[Comment],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[GLTemplateId],S.[GrossWritedown_Amount],S.[GrossWritedown_Currency],S.[IsActive],S.[IsAssetWriteDown],S.[IsRecovery],S.[LeaseFinanceId],S.[LoanFinanceId],S.[NetInvestmentWithBlended_Amount],S.[NetInvestmentWithBlended_Currency],S.[NetInvestmentWithReserve_Amount],S.[NetInvestmentWithReserve_Currency],S.[NetWritedown_Amount],S.[NetWritedown_Currency],S.[PostDate],S.[ReceiptId],S.[RecoveryGLTemplateId],S.[RecoveryReceivableCodeId],S.[SourceId],S.[SourceModule],S.[Status],S.[WriteDownAmount_Amount],S.[WriteDownAmount_Currency],S.[WriteDownDate],S.[WriteDownGLJournalId],S.[WriteDownReason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
