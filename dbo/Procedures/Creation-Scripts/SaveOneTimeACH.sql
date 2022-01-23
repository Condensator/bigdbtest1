SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneTimeACH]
(
 @val [dbo].[OneTimeACH] READONLY
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
MERGE [dbo].[OneTimeACHes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHAmount_Amount]=S.[ACHAmount_Amount],[ACHAmount_Currency]=S.[ACHAmount_Currency],[AmountDistributionType]=S.[AmountDistributionType],[AppliedAmount_Amount]=S.[AppliedAmount_Amount],[AppliedAmount_Currency]=S.[AppliedAmount_Currency],[ApplyByReceivable]=S.[ApplyByReceivable],[BankAccountId]=S.[BankAccountId],[CashTypeId]=S.[CashTypeId],[CheckNumber]=S.[CheckNumber],[CostCenterId]=S.[CostCenterId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[FileGenerationDate]=S.[FileGenerationDate],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsAutoAllocate]=S.[IsAutoAllocate],[IsCreateBankAccount]=S.[IsCreateBankAccount],[LegalEntityBankAccountId]=S.[LegalEntityBankAccountId],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[OneTimeACHRequestId]=S.[OneTimeACHRequestId],[ReceiptGLTemplateId]=S.[ReceiptGLTemplateId],[SettlementDate]=S.[SettlementDate],[Status]=S.[Status],[UnAllocatedAmount_Amount]=S.[UnAllocatedAmount_Amount],[UnAllocatedAmount_Currency]=S.[UnAllocatedAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHAmount_Amount],[ACHAmount_Currency],[AmountDistributionType],[AppliedAmount_Amount],[AppliedAmount_Currency],[ApplyByReceivable],[BankAccountId],[CashTypeId],[CheckNumber],[CostCenterId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[FileGenerationDate],[InstrumentTypeId],[IsActive],[IsAutoAllocate],[IsCreateBankAccount],[LegalEntityBankAccountId],[LegalEntityId],[LineofBusinessId],[OneTimeACHRequestId],[ReceiptGLTemplateId],[SettlementDate],[Status],[UnAllocatedAmount_Amount],[UnAllocatedAmount_Currency])
    VALUES (S.[ACHAmount_Amount],S.[ACHAmount_Currency],S.[AmountDistributionType],S.[AppliedAmount_Amount],S.[AppliedAmount_Currency],S.[ApplyByReceivable],S.[BankAccountId],S.[CashTypeId],S.[CheckNumber],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[FileGenerationDate],S.[InstrumentTypeId],S.[IsActive],S.[IsAutoAllocate],S.[IsCreateBankAccount],S.[LegalEntityBankAccountId],S.[LegalEntityId],S.[LineofBusinessId],S.[OneTimeACHRequestId],S.[ReceiptGLTemplateId],S.[SettlementDate],S.[Status],S.[UnAllocatedAmount_Amount],S.[UnAllocatedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
